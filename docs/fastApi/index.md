## 介绍

FastAPI 是一个用于构建 API 的现代、快速（高性能）的 Web 框架，使用 Python 并基于标准的 Python 类型提示。


关键特性：

- 快速：极高性能，可与 NodeJS 和 Go 并肩（归功于 Starlette 和 Pydantic）。最快的 Python 框架之一。
- 高效编码：功能开发速度提升约 200% ～ 300%。*
- 更少 bug：人为（开发者）错误减少约 40%。*
- 直观：极佳的编辑器支持。处处皆可自动补全。更少的调试时间。
- 易用：为易用和易学而设计。更少的文档阅读时间。
- 简短：最小化代码重复。一次参数声明即可获得多种功能。更少的 bug。
- 健壮：生产可用级代码。并带有自动生成的交互式文档。
- 标准化：基于（并完全兼容）API 的开放标准：OpenAPI（以前称为 Swagger）和 JSON Schema。


## 依赖

FastAPI 站在巨人的肩膀之上：
  - [Starlette](https://starlette.dev/) 负责 Web 部分。
  - [Pydantic](https://pydantic.dev/docs/) 负责数据部分。


## FastAPI的核心优势

### 高性能

  - FastAPI 基于异步 I/O，性能接近 Node.js 和 Go。
  - 使用 Uvicorn（ASGI 服务器），支持高并发请求。
  - 基于 TechEmpower 等基准测试，给出以下简化数据：

  | 框架 | 图片标注的请求量 | 图片给出的说明 |
| --- | --- | --- |
| FastAPI | 约 3000 请求/秒 | 异步、轻量 |
| Flask | 约 1000 请求/秒 | 同步，受 WSGI 限制 |
| Django | 约 800 请求/秒 | 同步，ORM 和中间件开销较大 |

### 类型提示提升开发效率

FastAPI 利用 Python 类型注解和 Pydantic 自动解析、校验请求数据，减少手动检查代码。 类型信息也能帮助编辑器提供自动补全和错误提示

```Python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()


class Item(BaseModel):
    name: str
    price: float
    is_offer: bool | None = None


@app.post("/items/")
async def create_item(item: Item):
    return item
```

1. Item 定义请求体的数据结构

继承 BaseModel 后，Pydantic 会按照字段声明解析和校验输入。

| 字段 | 类型 | 是否必须提交 | 说明 |
| --- | --- | --- | --- |
| `name` | `str` | 是 | 商品名称 |
| `price` | `float` | 是 | 商品价格 |
| `is_offer` | `bool \| None` | 否 | 是否优惠，默认 `None` |

例如，向 POST /items/ 提交：

```json
{
  "name": "键盘",
  "price": 199.9,
  "is_offer": true
}
```
FastAPI 会把 JSON 解析成一个 Item 对象。接口里可以直接访问：

```Python
item.name      # "键盘"
item.price     # 199.9
item.is_offer  # True
```

2. item: Item 表示接收符合模型的请求体

```Python
async def create_item(item: Item):
    return item
```

FastAPI 发现参数类型是 Pydantic 模型，就会按请求体处理。你不必手动读取 JSON，再逐个判断字段是否存在、类型是否正确。

校验通过后执行函数；例如缺少 name，或者 price 是无法解析的 "abc"，通常会返回 422，并指出出错字段。

`return item` 会将模型序列化为 JSON 响应。这个示例只是接收并返回数据，尚未保存到数据库。



## 自动生成 API 文档：
- FastAPI 内置 Swagger UI 和 ReDoc，自动生成交互式 API 文档。
- 开发者只需编写代码，文档即自动生成，减少维护成本。

## 异步支持
- 支持 async/await 语法，适合高并发场景（如实时聊天、流处理）。
- 比传统同步框架（如 Flask）更适合现代 Web 应用。


## CGI/WSGI/ASGI 了解

浏览器 → 服务器 ── CGI/WSGI/ASGI ──→ APP
- CGI 是最早的通用接口，解决服务器与动态内容生成程序的通信问题，但性能低下。
- WSGI 针对 Python 生态优化，取代 CGI，成为 Python Web 开发的主流标准，专注于同步 Web 应用。
- ASGI 是 WSGI 的升级，适应异步编程和现代 Web 需求（如 WebSocket、HTTP/2），兼容 WSGI 应用。


## 为什么选择 FastAPI

- 开发速度快：类型提示和自动文档减少重复工作。
- 性能优异：异步架构支持高并发，适合生产环境。
- 社区活跃：快速增长的生态，兼容 Starlette 和 Pydantic 的扩展。
- 易于上手：Python 开发者只需掌握基本类型提示即可快速构建 API。