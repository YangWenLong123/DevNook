# 11. 部署与运行

本章目标：区分本地开发与生产运行，掌握 Uvicorn、Docker、配置注入、持久化与基本运维。

## 1. 开发与生产启动

在配套项目目录：

```bash
# 开发：监听文件变化。
python -m uvicorn app.main:app --reload

# 部署：由进程管理器或容器平台负责重启。
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

`0.0.0.0` 表示监听容器或主机的所有网络接口，不是客户端访问时使用的域名。生产不要启用 reload。

容器平台通常从一个容器一个进程起步，再通过副本扩容。直接在主机运行时也可以评估 `--workers`，但不要与 `--reload` 同时使用。每个 worker 都有自己的应用内存与连接池。

## 2. 部署前应锁定依赖

教学项目的 requirements 使用版本范围，便于表达兼容 API。实际交付前，先在干净环境安装和测试，再生成并维护锁定结果：

```bash
python -m pip freeze > requirements.lock.txt
```

这会记录当前环境全部包，应在专用运行环境执行，避免把无关开发包带入。也可以使用 uv 或 pip-tools 等工具维护可重复解析的锁文件。

## 3. Dockerfile

配套项目已经提供以下配置：

```dockerfile
FROM python:3.12-slim
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN useradd --create-home appuser && mkdir -p /data && chown appuser:appuser /data
COPY --chown=appuser:appuser app ./app
USER appuser
EXPOSE 8000
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

这个镜像只复制应用代码与运行依赖，不复制 `.env`、测试数据库或本地虚拟环境。进程以普通用户运行，SQLite 数据文件写到 `/data`。

`.dockerignore` 排除 `.env`、`.venv`、数据库、缓存和测试文件。若切换到精确锁文件，应同时更新 Dockerfile 的安装输入。

## 4. 构建与启动

先按第 13 章生成 `.env` 中的密钥，再执行：

```bash
docker build -t fastapi-task-api:learning .

docker run --rm --name fastapi-task-api \
  -p 127.0.0.1:8000:8000 \
  --env-file .env \
  -e DATABASE_URL=sqlite:////data/tasks.db \
  -v fastapi-task-data:/data \
  fastapi-task-api:learning
```

打开 `http://127.0.0.1:8000/docs`。这个演示只把主机端口暴露给本机访问；正式对外服务时由网络和反向代理配置决定入口。

`-v` 使用命名卷保存数据库；容器删除后数据仍保留。`sqlite:////data/tasks.db` 的四个斜杠表示 SQLite 的 Unix 绝对路径。

如果没有挂载存储，重建容器可能丢失数据。SQLite 教学容器适合单实例练习；需要多实例写入时应使用服务型数据库。

## 5. 反向代理与 HTTPS

常见链路：

```text
用户 HTTPS 请求 → 反向代理 / 负载均衡 → 容器中的 Uvicorn → 数据库
```

反向代理负责域名、证书、HTTPS、部分请求限制和流量转发。需要同时考虑上传大小、请求超时、流式响应缓冲与 WebSocket 升级。

应用在代理后面时，仅信任真实代理地址传入的转发头，避免客户端伪造来源或协议。子路径部署还涉及 `root_path` 和外部路径配置，部署后应实际打开文档并执行登录验证。

## 6. 数据库迁移的执行顺序

```text
验证迁移与备份方案 → 执行兼容迁移 → 启动 / 更新应用 → 冒烟测试 → 观察指标
```

迁移通常由单独的一次性任务执行，不应让所有 worker 启动时争相修改结构。模型定义与已有数据库不一致时，`create_all()` 不会替你修复。

配套项目保留教学用自动建表。真实部署需要按[第 6 章](./index6.md)接入迁移，并在发布流程中替换它。不要在没有审查迁移脚本和数据恢复计划时直接执行删除字段的变更。

## 7. 健康检查与日志

配套项目 `GET /health` 返回 `{"status":"ok"}`，只表示应用能处理请求，不代表数据库和外部服务都可用。

生产可以拆分：存活检查判断进程是否应重启，就绪检查判断是否适合接收请求。检查不应返回密钥或完整内部配置，也不应让短暂外部故障触发无限重启。

日志输出到 stdout/stderr 方便平台收集。观察错误率、响应耗时、连接池使用、数据库慢查询和资源占用；用请求编号关联日志。

## 8. 最小部署验收

1. `/health` 可访问，应用能正常启动和优雅关闭。
2. 注册、登录、创建任务成功；重启容器后任务仍存在。
3. 未登录访问返回 401，其他用户不能访问任务。
4. 生产配置不启用 reload，密钥通过运行时配置注入。
5. 数据库迁移、备份与恢复流程有实际验证。

本文提供本地部署练习，不替用户向远程服务器发布应用。配套示例的自动测试也不等于已验证所有容器或生产环境。

参考：[Uvicorn Settings](https://www.uvicorn.org/settings/)、[FastAPI in Containers](https://fastapi.tiangolo.com/deployment/docker/)。下一章：[12. 进阶专题](./index12.md)。
