# FastAPI 基础与学习指南

FastAPI 是一个使用 Python 类型注解构建 Web API 的框架。你定义接口路径、输入类型和返回类型，它会协助完成参数解析、数据校验、响应序列化与 OpenAPI 文档生成。

这套文档面向刚开始学习后端开发的读者，按照「基础 → 接口 → 数据库 → 登录鉴权 → 测试部署」展开。最终目标是独立完成一个有用户系统、任务管理、权限隔离和自动测试的 API。

## 1. 先理解 FastAPI 在做什么

假设前端需要查询任务列表：

```text
浏览器 / 移动端 / curl
        ↓ GET /tasks?limit=10
Uvicorn 接收 HTTP 请求
        ↓ ASGI
FastAPI 匹配路由、校验参数、执行依赖
        ↓
接口函数读取数据库并返回结果
        ↓
FastAPI 校验和序列化响应 → JSON → 客户端
```

| 组成部分 | 主要职责 |
| --- | --- |
| FastAPI | 路由声明、依赖注入、接口输入输出与 OpenAPI 集成 |
| Starlette | ASGI Web 基础能力，例如请求、响应、中间件和 WebSocket |
| Pydantic | 根据类型定义校验数据、构造模型和序列化数据 |
| Uvicorn | 运行 ASGI 应用的服务器 |
| SQLAlchemy | 操作关系型数据库；需要单独安装 |

自动生成文档并不等于自动实现业务。用户能否删除某条任务、数据库何时提交事务，都需要你编写代码。

## 2. 学习目录

| 章节 | 学习内容 | 本章完成后可以做什么 |
| --- | --- | --- |
| [01. 前置基础](./index1.md) | 类型注解、异常、HTTP、REST、虚拟环境 | 看懂接口定义与请求 |
| [02. FastAPI 入门](./index2.md) | 安装、路由、Swagger、请求流程 | 启动并调用第一个接口 |
| [03. 请求参数与数据校验](./index3.md) | 路径、查询、请求体、表单、上传 | 接收并限制客户端输入 |
| [04. 响应与异常处理](./index4.md) | 响应模型、状态码、自定义异常 | 返回明确且可预期的结果 |
| [05. 依赖注入](./index5.md) | Depends、子依赖、yield | 复用公共逻辑和管理资源 |
| [06. 数据库与 CRUD](./index6.md) | SQLAlchemy 2.x、事务、分页、Alembic | 让任务永久保存 |
| [07. 用户登录与权限](./index7.md) | 密码哈希、JWT、用户身份、资源归属 | 区分不同用户及其数据 |
| [08. 项目结构与配置](./index8.md) | APIRouter、Settings、lifespan、CORS | 组织可维护的项目 |
| [09. 异步与常见集成](./index9.md) | async/await、HTTPX、异步会话、后台任务 | 正确调用外部服务 |
| [10. 接口测试](./index10.md) | pytest、TestClient、依赖覆盖、测试数据库 | 自动验证正常和异常流程 |
| [11. 部署与运行](./index11.md) | Uvicorn、Docker、代理、健康检查 | 把应用交付到运行环境 |
| [12. 进阶专题](./index12.md) | 缓存、限流、实时通信、任务队列、性能 | 按实际需求扩展应用 |
| [13. 任务管理 API 实战](./index13.md) | 完整项目、操作步骤、验收要求 | 串起前面各章 |

## 3. 环境与代码约定

- 教程以 **Python 3.12+、Pydantic v2、SQLAlchemy 2.x** 为基础。
- 激活虚拟环境后统一使用 `python -m pip`、`python -m uvicorn`，避免解释器混用。
- 第 2～5 章的完整示例默认分别保存为独立目录中的 `main.py`。不同章节的应用不要直接拼接；注明“补充”的代码才追加到本章示例。
- 第 6 章是独立的数据库练习；第 13 章提供可直接运行的完整项目，位于 `docs/fastApi/examples/task-api/`。
- 数据库入门使用同步 SQLAlchemy，异步数据库在第 9 章单独学习。
- JSON 示例中的 `true`、`false`、`null` 对应 Python 的 `True`、`False`、`None`。

旧教程中的 `model.dict()`、`orm_mode = True`、`@validator` 在新项目中分别优先使用 `model_dump()`、`ConfigDict(from_attributes=True)`、`@field_validator`。不要混用两个大版本的写法。

## 4. 四个学习阶段

1. **内存版**：学完 1～5 章，完成任务的增删改查与参数校验。
2. **数据库版**：学完第 6 章，完成持久化、分页和事务处理。
3. **多用户版**：学完 7～9 章，完成注册、登录与用户数据隔离。
4. **可交付版**：学完 10～11 章，补齐自动测试与部署配置。进阶章节按需要选学。

每学完一章，先运行示例，再修改一个参数或故意触发一次错误，最后完成练习。能够解释错误发生在哪一层，比只看到接口返回 200 更重要。

## 5. 建议收藏的官方资料

- [FastAPI 中文教程](https://fastapi.tiangolo.com/zh/tutorial/)
- [Pydantic 模型](https://docs.pydantic.dev/latest/concepts/models/)
- [SQLAlchemy 2.0 教程](https://docs.sqlalchemy.org/en/20/tutorial/)
- [Python 类型注解](https://docs.python.org/zh-cn/3/library/typing.html)

开始学习：[01. 前置基础](./index1.md)。
