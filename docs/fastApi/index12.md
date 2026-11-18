# 12. 进阶专题

本章目标：根据明确需求选择扩展能力，知道每种技术解决什么问题，以及最小练习应该验证什么。

这些内容不必在第一次学习时全部实现。先完成[任务管理 API 实战](./index13.md)，再选择真正需要的专题。

## 1. Redis 缓存

适用场景：数据库中的热点数据频繁读取、允许短时间过期，或者需要存放短期共享状态。

```text
请求 → 查询缓存 → 命中则返回
             → 未命中则查询数据库 → 写入缓存并设置过期时间 → 返回
```

设计缓存时明确 key、TTL、失效方式和故障降级。用户私有数据的 key 必须包含用户身份等隔离维度，不能让不同用户共用同一份私有列表缓存。

写入数据库后如何处理缓存，决定了读取一致性。初学可先做短 TTL 的任务统计，不要从高一致性交易数据开始。

练习：缓存当前用户的任务数量，更新任务后使缓存失效；关闭 Redis，确认接口按预期回退或返回受控错误。参考：[Redis Python](https://redis.io/docs/latest/develop/clients/redis-py/)。

## 2. 限流

限流保护登录、短信、昂贵查询等接口。常见维度是账号、IP、API key，常见算法有固定窗口、滑动窗口和令牌桶。

多 worker 部署时，单进程字典计数无法形成全局限制。需要共享存储与原子更新，还要明确信任哪些代理提供的客户端 IP。

超过限制通常返回 `429 Too Many Requests`，按策略附带 `Retry-After`。不能只靠前端禁用按钮限制请求。

练习：限制测试账号的登录尝试，测试窗口边界、并发请求和 Redis 故障策略。

## 3. WebSocket

适用场景：双向持续通信，例如协作编辑、实时聊天。下面是可独立运行的最小 echo 应用：

```python
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

app = FastAPI()


@app.websocket("/ws/echo")
async def echo(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            message = await websocket.receive_text()
            await websocket.send_text(f"echo: {message}")
    except WebSocketDisconnect:
        pass
```

可以在浏览器控制台连接 `new WebSocket('ws://127.0.0.1:8000/ws/echo')`，监听 `onmessage` 并在连接打开后发送文本。

生产还需要连接鉴权、Origin 检查、心跳、连接数限制、断线处理和背压。多进程下不能只靠全局连接列表向所有用户广播，应使用跨进程消息机制。

参考：[WebSockets](https://fastapi.tiangolo.com/advanced/websockets/)。

## 4. SSE

SSE 适合服务端向浏览器单向推送事件，例如任务进度。使用 `text/event-stream`，事件文本以空行分隔：

```text
event: progress
id: 1
data: {"percent": 10}

```

需要设计断线重连、事件编号、心跳与代理缓冲。原生浏览器 EventSource 不方便设置任意 Authorization 请求头，鉴权方案应结合 Cookie 或其他受控方式设计。

练习：发送导出进度事件，断开连接后确认服务端停止无用工作。不要把长期有效 Token 直接放进可能被日志记录的 URL。

## 5. 任务队列

需要持久化、重试、独立扩容的任务可以使用 Celery 等队列：

```text
API 接受任务 → 消息代理 → worker 执行 → 结果存储
      ↓
返回 202 和 job_id → 客户端查询状态或接收进度
```

队列常常允许重复投递，因此任务需要幂等。重试次数、退避、超时、失败状态与监控都属于实现的一部分。

数据库写入与消息发送不是天然同一个原子事务。重要业务可进一步学习事务发件箱模式，避免“数据提交了但消息没发出去”。

练习：异步导出当前用户任务，重复提交同一个幂等键只创建一个业务任务。参考：[Celery First Steps](https://docs.celeryq.dev/en/stable/getting-started/first-steps-with-celery.html)。

## 6. 对象存储与大文件

文件较大或服务需要多实例时，通常使用 S3 兼容对象存储，而不是容器本地磁盘。

常见流程：客户端申请受控上传凭证 → 上传到对象存储 → 后端验证并保存对象元数据。预签名 URL 应有较短有效期，并限制对象位置、大小等条件。

数据库保存服务端生成的对象 key 与所有者，不信任客户端给出的本地路径。下载也需要检查权限，不能因为知道对象名就允许读取私有文件。

练习：为任务增加附件，验证 bob 无法下载 alice 的私有附件。

## 7. 性能分析

先测量再优化。拆分总耗时：数据库查询、外部 HTTP、序列化、CPU 计算和排队等待。

| 现象 | 优先检查 |
| --- | --- |
| 数据量增加后列表变慢 | 索引、分页、查询列、执行计划 |
| 获取关联数据产生大量 SQL | N+1 查询、预加载策略 |
| 少量请求就阻塞其他请求 | async 路由中的同步 I/O 或 CPU 运算 |
| 扩 worker 后数据库压力暴涨 | 连接池总量、慢查询、重复计算 |
| 响应体很大 | 返回字段、分页、压缩、序列化耗时 |

压测要报告数据规模、并发、请求比例、错误率和 p95/p99 延迟。单次请求的最好结果不能代表稳定承载能力。

## 8. OpenAPI 与接口版本

使用 `summary`、`description`、`tags`、请求示例和明确响应模型改善接口文档。通过稳定且唯一的 `operation_id` 支持客户端代码生成。

存在破坏性变更时，可以设计 `/api/v1`、`/api/v2` 或其他明确版本策略。新增字段是否破坏兼容，需要结合客户端是否允许未知字段判断；不能只看服务端能否启动。

练习：为任务 API 增加错误响应文档，生成客户端后检查调用体验。参考：[Path Operation Configuration](https://fastapi.tiangolo.com/tutorial/path-operation-configuration/)。

## 9. 推荐选择顺序

先定位实际问题：读数据库成为瓶颈再评估缓存；重要后台工作需要可靠执行再上队列；产品需要持续推送再选 SSE 或 WebSocket。每次只引入一个能力，并为它的失败路径补充验证。

下一章：[13. 任务管理 API 实战](./index13.md)。
