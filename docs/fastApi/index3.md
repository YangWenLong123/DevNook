## Uvicorn

Uvicorn 是 Python 的 Web 服务器，用于运行支持 ASGI 协议的应用，常与 FastAPI、Starlette 搭配使用。

它主要负责：
- 接收请求：监听端口，接收浏览器或客户端发来的 HTTP 请求。
- 调用应用：把请求交给 FastAPI 等框架处理，再将结果返回给客户端。
- 支持异步通信：支持 async/await 和 WebSocket，适合大量等待数据库、网络请求的场景。

可以这样理解：

```Python
客户端 → Uvicorn → FastAPI 路由和业务逻辑 → 返回响应
```

例如，在 `main.py` 中编写：

```Python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def hello():
    return {"message": "Hello"}
```

使用 Uvicorn 启动：

```bash
uvicorn main:app --reload
```

其中，`main` 是文件名，`app` 是应用对象，`--reload` 表示代码变化后自动重启，适用于开发环境。启动后访问 http://127.0.0.1:8000 即可。

还可以监听地址：

```Python
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

| 地址 | 含义 |
|---|---|
| `127.0.0.1` | 默认值，只接受本机访问 |
| `0.0.0.0` | 监听所有 IPv4 网络接口，可供其他设备访问 |

## 推荐的完整写法

开发时：

```Python
uv run uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

需要局域网设备访问时：

```Python
uv run uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

生产运行的基础示例：

```Python
uv run uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

如果项目还没添加 Uvicorn 依赖，先执行：

```Python
uv add "uvicorn[standard]"
```