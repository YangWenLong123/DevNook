# Python HTTP 请求实战：传参、请求头、Cookie 与项目案例

在项目中，Python 请求接口通常是为了同步订单、查询库存、上传凭证、导出报表，或者调用第三方服务。要把接口调通，关键是弄清楚：**数据应该放在哪里、采用什么格式、服务端如何识别身份，以及如何处理响应。**

本文以同步 HTTP 客户端 **`requests`** 为主，从基础传参讲到一个完整的订单系统案例。示例适用于 Python 3.10+。

配套项目在仓库的 `docs/python/examples/requests-demo/`，包含本地模拟服务、客户端、附件样例和集成测试。**没有真实接口账号也能运行全部主流程。**

## 1. 先看懂一个 HTTP 请求

假设你在订单管理系统中查询订单，请求可能长这样：

```http
GET /api/orders?page=1&page_size=20&status=paid HTTP/1.1
Host: api.example.com
Accept: application/json
User-Agent: OrderLearningClient/1.0
X-Tenant-ID: shop-001
Cookie: session_id=example-session
```

这里各部分的含义不同：

| 位置 | 示例 | 用途 | `requests` 写法 |
| --- | --- | --- | --- |
| 请求方法 | `GET`、`POST`、`PATCH` | 表达查询、创建、更新等操作 | `requests.get()`、`requests.post()` 等 |
| 路径参数 Path | `/api/orders/ORD-1001` | 指定操作的资源 | 拼入 URL 的路径部分 |
| 查询参数 Query | `?page=1&status=paid` | 分页、筛选、排序 | `params=` |
| 请求头 Header | `X-Tenant-ID: shop-001` | 认证、租户、内容格式、追踪信息 | `headers=` |
| Cookie | `session_id=...` | 常用于维护登录会话 | `cookies=` 或 `Session` |
| 请求体 Body | 表单、JSON、文件等 | 提交业务数据 | `data=`、`json=`、`files=` |

Cookie 在网络上传输时也是请求头，通常放在 `Cookie` 字段里。`requests` 提供 `cookies=` 和 CookieJar，帮助你正确管理它。

**参数名称和位置都由接口协议决定。** 不能因为你喜欢 JSON，就把服务端要求的表单改成 JSON；也不能把要求放在头部的 Token 随意改放到 URL 中。

## 2. 运行环境与本地练习接口

先进入配套项目目录：

```bash
cd docs/python/examples/requests-demo
```

macOS / Linux：

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python server.py
```

Windows PowerShell：

```powershell
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python server.py
```

服务地址是 `http://127.0.0.1:8765`。另开一个终端，进入同一目录、激活虚拟环境，再运行下面的 Python 示例。

后面的基础片段共用这些定义：

```python
import requests

BASE_URL = "http://127.0.0.1:8765"
TIMEOUT = (3.05, 15)  # 建立连接超时、读取超时，单位：秒
```

`/api/echo` 是练习接口，会返回它收到的查询参数、请求体和部分请求头；订单接口则会真正检查登录态、租户、数据格式等。

## 3. Query：使用 `params` 传查询参数

### 3.1 分页、关键词、多个状态

```python
response = requests.get(
    f"{BASE_URL}/api/echo",
    params={
        "keyword": "张三 & VIP",
        "page": 1,
        "page_size": 20,
        "status": ["paid", "pending"],
        "unused": None,
    },
    timeout=TIMEOUT,
)
response.raise_for_status()
print(response.json()["data"]["query"])
```

本地接口会收到：

```python
{
    "keyword": ["张三 & VIP"],
    "page": ["1"],
    "page_size": ["20"],
    "status": ["paid", "pending"],
}
```

注意几个细节：

- `requests` 自动处理中文、空格、`&` 等字符的 URL 编码，不需要自己拼接查询字符串。
- 列表会成为重复的参数名，例如 `status=paid&status=pending`。
- 值为 `None` 的字段会被省略；空字符串 `""` 则会发送为空值。
- Query 到达服务端时是文本。上面的列表形式是本地回显接口的解析结果，真实接口可以把 `page` 校验并转换成整数。

有些接口要求 `status=paid,pending`，另一些要求 `status[]=paid&status[]=pending`。这三种格式不能擅自替换，要按文档传：

```python
params = {"status": "paid,pending"}
# 或者：
params = [("status[]", "paid"), ("status[]", "pending")]
```

布尔值也要看协议。如果接口要求小写文本，就明确写 `{"include_closed": "true"}`，不要依赖 Python 的 `True` 自动符合服务端要求。

### 3.2 `params` 不只用于 GET

POST 也可以同时有 Query 和 JSON：

```python
response = requests.post(
    f"{BASE_URL}/api/echo",
    params={"dry_run": "true"},
    json={"customer_name": "张三"},
    timeout=TIMEOUT,
)
response.raise_for_status()
print(response.json()["data"])
```

`params` 负责 URL 中的参数，`json` 负责请求体，两者可以同时使用。`dry_run` 在这里仅作回显；实际创建接口是否支持试运行，要看业务协议。

密码、Cookie 和访问令牌应按认证协议传输。不要随手塞进 Query，因为 URL 经常出现在代理日志和访问记录中。

## 4. Path：把资源标识放在路径中

获取指定订单通常使用：

```http
GET /api/orders/ORD-1001
```

Python 写法：

```python
from urllib.parse import quote

order_id = "ORD-1001"
path = f"/api/orders/{quote(order_id, safe='')}"
```

`quote(..., safe="")` 用于编码单个路径参数，避免参数里的空格、`/`、`?` 被误当成 URL 结构。不要对整个 URL 做同样的编码。

在真实项目中，路径参数也可能是用户 ID、文件 ID 或商品 SKU。订单接口需要先登录，完整调用见第 9 节。

## 5. Body：`data`、`json`、`files` 到底怎么选

先记住这张表：

| 服务端要求 | 写法 | 常见 `Content-Type` | 项目场景 |
| --- | --- | --- | --- |
| 普通表单 | `data={...}` | `application/x-www-form-urlencoded` | 登录、旧系统表单 |
| JSON | `json={...}` | `application/json` | 创建订单、复杂业务数据 |
| 文件和表单字段 | `files={...}, data={...}` | `multipart/form-data; boundary=...` | 上传凭证、头像、附件 |
| 原始文本/字节 | `data="..."` 或 `data=b"..."` | 按接口要求手动设置 | XML、纯文本、二进制上传 |

**一个请求体按一种协议组织。** 常见的有效组合是 `params + json`、`headers + json`、`data + files`。不要同时设置 `data` 和 `json` 来尝试“兼容两种格式”；有实际内容的 `data` 或 `files` 会使 `json` 不被采用。

### 5.1 `data=dict`：提交普通表单

```python
response = requests.post(
    f"{BASE_URL}/api/echo",
    data={"username": "demo", "password": "demo123"},
    timeout=TIMEOUT,
)
response.raise_for_status()
print(response.json()["data"]["form"])
```

请求体类似：

```text
username=demo&password=demo123
```

这里是表单编码，**Python 字典并不等于 JSON**。`data={...}` 不会自动变成 JSON。

不含文件时，`requests` 会为字典表单设置相应的 `Content-Type`。一般不需要你手写。

表单通常传平面的键值。若旧接口要求某个表单字段本身是 JSON 字符串，则只序列化那个字段：

```python
import json

form = {
    "action": "search",
    "filters": json.dumps({"status": "paid"}, ensure_ascii=False),
}
```

这种写法成立的前提是接口明确要求“表单中的 `filters` 字段是 JSON 字符串”。

### 5.2 `json=dict`：提交结构化业务数据

```python
payload = {
    "customer_name": "张三",
    "items": [
        {"sku": "SKU-001", "quantity": 2},
        {"sku": "SKU-002", "quantity": 1},
    ],
    "need_invoice": True,
    "remark": None,
}

response = requests.post(
    f"{BASE_URL}/api/echo",
    json=payload,
    timeout=TIMEOUT,
)
response.raise_for_status()
print(response.json()["data"]["json"])
```

`requests` 会序列化请求体，并在你没有覆盖时设置 `Content-Type: application/json`。Python 的 `True`、`False`、`None` 会转换成 JSON 的 `true`、`false`、`null`。

常见错误：

```python
# 错误：把已经序列化的字符串再交给 json=，服务端收到的是 JSON 字符串。
# requests.post(url, json=json.dumps(payload), timeout=TIMEOUT)

# 推荐：直接传 Python 对象。
# requests.post(url, json=payload, timeout=TIMEOUT)
```

如果你确实需要自行控制序列化后的字节，可以使用 `data=json.dumps(payload).encode("utf-8")`，并手动设置 JSON 的 `Content-Type`。普通接口优先使用 `json=`。

### 5.3 `data=bytes`：提交 XML、文本、二进制

```python
xml = "<order><customer>张三</customer></order>"

response = requests.post(
    f"{BASE_URL}/api/echo",
    data=xml.encode("utf-8"),
    headers={"Content-Type": "application/xml; charset=utf-8"},
    timeout=TIMEOUT,
)
response.raise_for_status()
print(response.json()["data"]["raw"])
```

当 `data` 是字符串或字节时，`requests` 不会替你把它改成表单或 JSON，也不会自动推断你想使用的媒体类型。中文文本显式编码成 UTF-8 字节，可以让发送内容与声明一致。

如果接口要求整个请求体都是某个二进制文件，用 `data=file`；如果要求名为 `file` 的文件表单字段，则用下一节的 `files`。两者的请求结构不同。

### 5.4 `files`：文件上传，同时携带表单字段

在配套项目目录执行：

```python
with open("receipt.txt", "rb") as file:
    response = requests.post(
        f"{BASE_URL}/api/echo",
        data={"attachment_type": "receipt", "order_id": "ORD-1001"},
        files={
            "file": ("receipt.txt", file, "text/plain"),
        },
        timeout=TIMEOUT,
    )
response.raise_for_status()
print(response.json()["data"]["files"])
```

文件三元组的含义：

```python
files = {
    "服务端要求的字段名": ("上传时的文件名", 文件对象, "文件的媒体类型"),
}
```

注意：

- 文件用 `rb` 打开，并在 `with` 块中完成请求。
- `file`、`upload`、`avatar` 等字段名由接口决定，不是任意命名。
- **不要手动写 `Content-Type: multipart/form-data`。** `requests` 要生成与请求体匹配的 `boundary`；手写时漏掉或写错会导致解析失败。
- 此时的 `data` 是 multipart 内的普通字段，不再是独立的 URL 编码表单体。

同一字段上传多个文件，使用二元组列表。例如下面的回显示例不需要额外文件：

```python
with open("receipt.txt", "rb") as first, open("receipt.txt", "rb") as second:
    response = requests.post(
        f"{BASE_URL}/api/echo",
        files=[
            ("files", ("first.txt", first, "text/plain")),
            ("files", ("second.txt", second, "text/plain")),
        ],
        timeout=TIMEOUT,
    )
response.raise_for_status()
print(len(response.json()["data"]["files"]))  # 2
```

普通 `files=` 上传会构建 multipart 请求体，不适合直接照搬到超大文件场景。大文件应根据接口选择流式 multipart、对象存储直传或分片上传。

## 6. Header：请求头上的参数怎么写

### 6.1 使用字符串字典

```python
response = requests.get(
    f"{BASE_URL}/api/echo",
    params={"page": 1},
    headers={
        "Accept": "application/json",
        "User-Agent": "OrderLearningClient/1.0",
        "X-Tenant-ID": "shop-001",
        "X-Trace-ID": "learning-request-001",
    },
    timeout=TIMEOUT,
)
response.raise_for_status()
print(response.json()["data"]["headers"])
```

头部名称和数值都建议写成字符串。比如租户 ID 是数字时写 `str(tenant_id)`，不要把整数、字典或 `None` 直接塞进 `headers`。

| 请求头 | 用途 | 容易混淆的地方 |
| --- | --- | --- |
| `Accept` | 告诉服务端期望收到什么响应格式 | 不会改变你发送的请求体格式 |
| `Content-Type` | 声明当前请求体的格式 | 写 JSON 头不会把 `data=dict` 变成 JSON |
| `Authorization` | 常用于 Bearer Token 或 Basic 认证 | 名称、认证方案和 Token 来源要按协议 |
| `User-Agent` | 标识客户端 | 改成浏览器名称不会获得浏览器执行能力 |
| `X-Tenant-ID` | 本例用它传租户标识 | 自定义协议，不是所有接口都使用 |
| `X-CSRF-Token` | 本例用它校验 Cookie 会话的写操作 | 不是登录 Cookie 本身 |
| `X-Trace-ID` | 关联请求日志 | 具体名称和生成方式由项目约定 |

HTTP 头名称不区分大小写。除协议要求外，不用手动复制 `Host`、`Content-Length`、`Connection` 等头，交给客户端库管理。

### 6.2 Bearer Token 与 Basic 认证

Bearer 认证的格式是：

```python
import os

headers = {
    "Authorization": f"Bearer {os.environ['API_TOKEN']}",
}
```

`Bearer` 与 Token 之间有一个空格。Token 从登录接口或服务的凭证管理页面获得，不能凭空编造。上面的片段需要先在环境中设置有效的 `API_TOKEN`；本地服务获取 Token 的可运行例子见第 9 节。

如果接口要求 HTTP Basic，可以用 `auth=(username, password)`。Basic 并不提供加密，真实服务应通过 HTTPS 传输。Bearer、Basic、API Key、签名认证是不同的约定，不能混用。

## 7. Cookie：三种常用写法

### 7.1 `cookies=dict`：给单次请求传 Cookie

形式如下：

```python
cookies = {
    "session_id": "替换为你从该系统取得的有效会话值",
    "language": "zh-CN",
}

# 示意写法：占位值无法通过本地服务的登录验证。
# response = requests.get(
#     f"{BASE_URL}/api/orders",
#     cookies=cookies,
#     headers={"X-Tenant-ID": "shop-001"},
#     timeout=TIMEOUT,
# )
```

最终会以类似下面的请求头发出去：

```http
Cookie: session_id=...; language=zh-CN
```

这里的字典只表示名称和值，没有表达完整的域名、路径和有效期。跨多个站点或长期维护会话时，优先用 CookieJar 和 `Session`。

### 7.2 `headers["Cookie"]`：直接传原始 Cookie 字符串

```python
headers = {
    "Cookie": "session_id=example-session; language=zh-CN",
}
```

这种方式适合临时复现自己有权访问的请求，但你需要自己处理更新和作用域。**同一请求不要同时使用手写 `Cookie` 头和 `cookies=`，也不要把它们和 Session 的 Cookie 管理混在一起。**

从浏览器复制的请求 Cookie 可以包含多个 `name=value`，用分号分隔。Cookie 值本身可能含有 `=`，不要直接 `split("=")` 后假设只得到两段。

需要解析普通的请求 Cookie 字符串时，可以使用标准库：

```python
from http.cookies import SimpleCookie

cookie_header = "session_id=abc==; language=zh-CN"
parsed = SimpleCookie()
parsed.load(cookie_header)
cookies = {name: morsel.value for name, morsel in parsed.items()}
```

Cookie 的值应保留原样，不要随意进行 URL 解码、Base64 解码或重新编码。

### 7.3 `Session`：登录后自动维护 Cookie

这是本地可直接运行的登录流程：

```python
with requests.Session() as session:
    session.headers.update({
        "Accept": "application/json",
        "X-Tenant-ID": "shop-001",
    })

    login_response = session.post(
        f"{BASE_URL}/api/auth/login",
        data={"username": "demo", "password": "demo123"},
        timeout=TIMEOUT,
    )
    login_response.raise_for_status()
    login_result = login_response.json()
    if login_result["code"] != 0:
        raise RuntimeError("登录业务失败")

    # Set-Cookie 已被 session 自动读取和保存，不需要手抄 session_id。
    response = session.get(
        f"{BASE_URL}/api/orders",
        params={"page": 1, "page_size": 2},
        timeout=TIMEOUT,
    )
    response.raise_for_status()
    print(response.json()["data"]["items"])
```

流程是：登录响应返回 `Set-Cookie` → Session 保存 Cookie → 后续符合域名、路径等条件的请求自动带上 Cookie。

与 Cookie 有关的几个对象不要混淆：

| 写法 | 含义 |
| --- | --- |
| `response.cookies` | 这一次响应中收到的 Cookie |
| `session.cookies` | Session 当前维护的 Cookie 集合 |
| `cookies={...}` | 额外提供给某次请求的 Cookie；不会作为会话配置永久写入 Session |
| `session.cookies.set(...)` | 主动修改 Session 的 CookieJar |

如果确实要导入一个已有的有效 Cookie，可以明确限制作用域：

```python
# 在 with requests.Session() as session: 中使用；value 必须替换为有效会话。
# session.cookies.set(
#     "session_id", value,
#     domain="127.0.0.1",  # 只写主机名，不带协议、端口或路径
#     path="/api",
# )
```

没有域名限制的手工 Cookie 可能被用于 Session 访问的多个主机。项目中应将带认证的 Session 限定用于对应服务。

### 7.4 请求 Cookie 与响应 `Set-Cookie` 的区别

服务端响应可能包含：

```http
Set-Cookie: session_id=abc; Path=/api; HttpOnly; Secure; SameSite=Lax
```

客户端请求携带的是：

```http
Cookie: session_id=abc
```

`Path`、`Domain`、`HttpOnly`、`Secure`、`SameSite` 是 Cookie 属性，不要把整条 `Set-Cookie` 原样粘成请求 `Cookie`。多个 `Set-Cookie` 响应头也不应简单按逗号拆分，因为有效期等内容可能包含逗号。

`HttpOnly` 限制浏览器 JavaScript 读取 Cookie，不妨碍 `requests` 保存和发送它。`Secure` Cookie 只应通过安全连接发送；本例为了使用本机 HTTP 调试，演示 Cookie 未启用 `Secure`。`SameSite` 属于浏览器的跨站策略，不能假设 `requests` 会按浏览器一样执行它。

Cookie 过期、作用域不匹配，或者服务端会话失效时，即使字符串还在，接口也可能返回 401。

## 8. Session：统一公共头、会话与连接配置

可以把多个请求共用的设置放在 Session 上：

```python
with requests.Session() as session:
    session.headers.update({
        "User-Agent": "OrderLearningClient/1.0",
        "Accept": "application/json",
        "X-Tenant-ID": "shop-001",
    })

    response = session.get(
        f"{BASE_URL}/api/echo",
        headers={"X-Trace-ID": "request-002"},
        params={"page": 2},
        timeout=TIMEOUT,
    )
    response.raise_for_status()
```

单次 `headers` 会与 Session 公共头合并，同名字段在该次请求中覆盖默认值。

Session 可以维护 Cookie、复用连接池、统一公共配置。配套的标准库模拟服务使用 HTTP/1.0，不用于展示连接复用带来的性能收益。

**不要认为 `session.timeout = 10` 能设置通用默认超时。** `requests.Session` 不会自动读取你加上的这个属性；应每次传 `timeout`，或者像配套客户端一样在统一请求方法中使用 `kwargs.setdefault("timeout", ...)`。

## 9. 项目案例：订单同步与附件上传

业务需求是：登录管理系统 → 分页获取订单 → 创建一笔订单 → 上传付款凭证 → 导出订单 CSV。

本例的接口约定如下：

| 接口 | 传参方式 | 认证要求 |
| --- | --- | --- |
| `POST /api/auth/login` | 表单 `username`、`password` | 无；成功后返回会话与 Token |
| `GET /api/orders` | Query 分页、状态、关键词 | 租户头 + Cookie 或 Bearer |
| `GET /api/orders/{order_id}` | Path | 同上 |
| `POST /api/orders` | JSON 订单数据 | 同上；Cookie 方式还需 CSRF 头 |
| `POST /api/orders/{order_id}/attachments` | 文件 + 普通表单字段 | 同上；Cookie 方式还需 CSRF 头 |
| `GET /api/orders/export` | 可选 Query，响应为 CSV | 租户头 + Cookie 或 Bearer |

### 9.1 先用直观的代码跑通整个流程

下面的代码可以保存为 `quickstart.py`，放在配套项目目录运行。需要先启动 `server.py`。

```python
from pathlib import Path
from urllib.parse import quote

import requests

BASE_URL = "http://127.0.0.1:8765"
TIMEOUT = (3.05, 15)


def read_data(response):
    response.raise_for_status()
    result = response.json()
    if result["code"] != 0:
        raise RuntimeError("接口业务失败")
    return result["data"]


with requests.Session() as session:
    session.headers.update({
        "Accept": "application/json",
        "User-Agent": "OrderLearningClient/1.0",
        "X-Tenant-ID": "shop-001",
    })

    # 1. 登录：服务要求表单，Session 自动保存响应 Cookie。
    credentials = read_data(session.post(
        f"{BASE_URL}/api/auth/login",
        data={"username": "demo", "password": "demo123"},
        timeout=TIMEOUT,
    ))

    # 2. 本例中，Cookie 认证的写操作还需要 CSRF Token。
    session.headers["X-CSRF-Token"] = credentials["csrf_token"]

    # 3. 分页查询：每次只取一页，直到到达总数。
    page, page_size = 1, 2
    while True:
        data = read_data(session.get(
            f"{BASE_URL}/api/orders",
            params={
                "page": page,
                "page_size": page_size,
                "status": ["paid", "pending"],
            },
            timeout=TIMEOUT,
        ))
        print("订单页：", data["items"])
        if not data["items"] or page * page_size >= data["total"]:
            break
        page += 1

    # 4. 创建订单：嵌套商品信息用 JSON。
    order = read_data(session.post(
        f"{BASE_URL}/api/orders",
        json={
            "customer_name": "赵六",
            "items": [{"sku": "SKU-001", "quantity": 2}],
            "remark": "工作日配送",
        },
        timeout=TIMEOUT,
    ))
    order_id = quote(order["id"], safe="")

    # 5. 查询刚创建的订单：ID 放在路径中。
    detail = read_data(session.get(
        f"{BASE_URL}/api/orders/{order_id}",
        timeout=TIMEOUT,
    ))
    print("创建成功：", detail["id"])

    # 6. 上传凭证：files + data，不手写 multipart Content-Type。
    with open("receipt.txt", "rb") as file:
        attachment = read_data(session.post(
            f"{BASE_URL}/api/orders/{order_id}/attachments",
            data={"attachment_type": "receipt"},
            files={"file": ("receipt.txt", file, "text/plain")},
            timeout=TIMEOUT,
        ))
    print("上传字节数：", attachment["files"][0]["size"])

    # 7. 下载：响应是文件，不调用 .json()。
    destination = Path("downloads/orders-quickstart.csv")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with session.get(
        f"{BASE_URL}/api/orders/export",
        headers={"Accept": "text/csv"},
        stream=True,
        timeout=TIMEOUT,
    ) as response:
        response.raise_for_status()
        if not response.headers.get("Content-Type", "").startswith("text/csv"):
            raise RuntimeError("导出接口未返回 CSV")
        with destination.open("wb") as output:
            for chunk in response.iter_content(chunk_size=64 * 1024):
                if chunk:
                    output.write(chunk)
    print("导出完成：", destination)
```

这里同时出现了 Path、Query、Header、Cookie、表单、JSON、文件和下载。判断用法时，要逐个看接口的协议，而不是按“GET 传一个字典、POST 传另一个字典”来记。

快速示例直接写下载目标文件；配套 `client.py` 更进一步：先写 `.part` 临时文件，完成后再替换目标文件，失败时清理临时文件。

### 9.2 如果接口使用 Bearer Token

本例登录响应也返回 `access_token`，用于演示另一种认证方式。接着上面的代码，可以用一个**全新的、没有登录 Cookie 的 Session** 查询订单：

```python
with requests.Session() as token_session:
    token_session.headers.update({
        "Authorization": f"Bearer {credentials['access_token']}",
        "X-Tenant-ID": "shop-001",
        "Accept": "application/json",
    })
    response = token_session.get(
        f"{BASE_URL}/api/orders/ORD-1001",
        timeout=TIMEOUT,
    )
    response.raise_for_status()
    print(response.json()["data"]["id"])
```

Cookie 会话和 Bearer Token 是本例支持的两条认证路径。真实系统未必同时支持它们；CSRF Token 的取得方式、头部名称和适用范围也要按服务端约定处理，`requests` 不会替你自动推断。

### 9.3 把重复请求封装为客户端

当接口增多时，不必到处复制 `headers`、`timeout` 和错误处理。配套项目的 `client.py` 提供 `OrderClient`：

```python
from pathlib import Path

from client import OrderClient

with OrderClient("http://127.0.0.1:8765") as client:
    client.login("demo", "demo123")

    for order in client.iter_orders(statuses=["paid"], page_size=2):
        print(order["id"], order["customer_name"])

    created = client.create_order(
        customer_name="赵六",
        items=[{"sku": "SKU-001", "quantity": 2}],
    )
    client.upload_receipt(created["id"], Path("receipt.txt"))
    client.export_orders(Path("downloads/orders.csv"))
```

它把工作分成两层：统一请求方法负责超时、HTTP 状态、JSON 和业务状态检查；业务方法负责 URL、字段和传参位置。接口改动时，优先修改对应的业务方法。

可以直接运行现成的完整客户端：

```bash
python client.py
```

初始服务只有 3 条订单，第一次运行会创建 `ORD-1004`，上传 `receipt.txt`，生成 `downloads/orders.csv`，并演示 Bearer 查询。重复运行会继续新增订单；重启服务会重置数据。

## 10. 拿到响应以后，该读哪个属性

| 写法 | 读取内容 | 使用场景 |
| --- | --- | --- |
| `response.status_code` | HTTP 状态码 | 判断成功、认证失败、限流等 |
| `response.headers` | 响应头 | 判断格式、下载信息、重试提示 |
| `response.text` | 按编码解码后的文本 | HTML、普通文本 |
| `response.content` | 完整响应字节 | 小文件、二进制数据 |
| `response.json()` | 将响应体解析成 Python 对象 | 确认响应是 JSON 时 |
| `response.iter_content(...)` | 分块读取响应字节 | 配合 `stream=True` 下载 |
| `response.request` | 实际发送的请求对象 | 排查参数与头部 |

**`response.json()` 不会自动证明请求成功。** 一个 HTTP 401 的响应也可以是合法 JSON；一个 HTTP 200 的响应也可能是登录页面，或者返回业务失败码。

推荐依次判断：

1. 网络请求是否成功完成。
2. HTTP 状态是否符合预期。
3. 响应格式是否符合接口约定。
4. 业务状态是否成功。
5. 数据结构是否满足当前业务使用要求。

本例约定 `code == 0` 为成功，其他项目可能使用 `success`、`error_code`，或者完全依靠 HTTP 状态码。不要把这个判断照搬到所有服务。

204 通常没有响应体，不应直接调用 `.json()`。`raise_for_status()` 对 4xx、5xx 抛出异常，对 3xx 不会抛错；需要严格处理 API 重定向时，可设置 `allow_redirects=False` 并自行检查状态。

## 11. 真实项目必须处理的超时和异常

### 11.1 区分网络异常、HTTP 失败与 JSON 解析失败

```python
try:
    response = requests.get(
        f"{BASE_URL}/api/echo",
        timeout=(3.05, 15),
    )
    response.raise_for_status()
except requests.Timeout:
    print("连接或读取超时")
except requests.ConnectionError:
    print("连接失败，请检查服务地址、网络或代理")
except requests.HTTPError as exc:
    print("HTTP 失败：", exc.response.status_code)
except requests.RequestException:
    print("其他请求错误")
else:
    try:
        result = response.json()
    except requests.exceptions.JSONDecodeError:
        print("接口没有返回有效 JSON")
    else:
        print(result["data"])
```

`requests` 默认没有请求超时，项目里应显式设置。`timeout=(3.05, 15)` 分别控制建立连接和读取等待；读取超时主要指等待响应数据时的间隔，**不是整个请求从开始到结束的 15 秒总时限**。下载、DNS、多次尝试和重试等待等都可能让总耗时更长。

### 11.2 重试要考虑业务是否会重复执行

查询接口遇到短暂的 429、502、503、504 时，可以按策略重试；创建订单遇到超时则需要更谨慎。因为“客户端没有收到结果”不等于“服务端没有创建订单”。

配套客户端配置了有限的 GET/HEAD 状态码重试和退避，不对读取中断或 POST 状态失败自动重试。连接建立前的失败也可能重试，因为这类失败尚未发送请求。

真实下单若要支持重试，应先确认服务端是否提供幂等机制，例如 `Idempotency-Key`。同一笔逻辑订单的多次尝试复用同一个键，并由服务端识别重复请求。**只加一个自定义头，不会让普通接口自动具备幂等能力；本例没有实现服务端幂等。**

重试次数和 `Retry-After` 等等待也会增加总耗时。项目若有总时限，还需要单独设计整个操作的时间预算。

## 12. 排查“浏览器能请求，Python 不行”

先在浏览器开发者工具的 Network 中选中真实的接口请求，按下面的顺序对照：

| 检查项 | 浏览器中常见位置 | Python 对应写法 |
| --- | --- | --- |
| 方法与 URL | General | `get/post/patch/...` 和准确的接口地址 |
| URL 查询 | Query String Parameters | `params=` |
| JSON 请求体 | Request Payload | `json=` |
| 普通表单 | Form Data，结合 Content-Type 判断 | `data=` |
| multipart 文件 | Form Data + 文件项 | `files=`，必要时加 `data=` |
| 认证信息 | Authorization / Cookie | 认证头、Cookie 或登录 Session |
| CSRF、租户等字段 | Request Headers | 按协议设置自定义头 |
| 响应类型 | Response Headers、Response | 区分 JSON、HTML、文件 |

常见现象：

| 现象 | 优先排查 |
| --- | --- |
| 400 / 422 | 字段名、类型、必填项、日期格式、分页范围 |
| 401 | 未登录、Cookie 失效、Token 错误或过期 |
| 403 | 权限、租户、CSRF、服务端访问策略；不只一种原因 |
| 404 | 地址、接口版本、路径参数或资源是否存在 |
| 415 | `Content-Type` 与实际请求体是否匹配 |
| 429 | 频率限制和 `Retry-After`，降低请求速率 |
| 200 但 JSON 解析失败 | 是否重定向到了登录页，或返回了 HTML |
| 文件上传“缺少 file” | 文件字段名、multipart boundary、是否误用 `data=file` |
| Cookie 明明有但不生效 | 域名、路径、Secure、有效期和服务端会话状态 |

浏览器的 CORS 限制不直接适用于 Python 客户端，但服务端仍然可以验证来源、权限和签名。`requests` 也不会执行页面 JavaScript，所以依赖浏览器执行后才能产生的动态值，需要按该系统的合法接口流程获取。

如果怀疑实际发送的内容，可以在本地先构建请求：

```python
with requests.Session() as session:
    session.headers["X-Tenant-ID"] = "shop-001"
    request = requests.Request(
        "POST",
        f"{BASE_URL}/api/echo",
        params={"page": 1},
        json={"customer_name": "张三"},
    )
    prepared = session.prepare_request(request)
    print(prepared.method)
    print(prepared.url)  # 此例只含非敏感分页参数
    print(prepared.headers.get("Content-Type"))
```

使用 `session.prepare_request()` 可以合并会话配置。真实项目不要整包打印 `prepared.headers`、Cookie、Token 或含有密码和个人信息的请求体。

TLS 证书校验默认开启。遇到企业自签证书时，应按环境配置受信任 CA，例如 `verify="/path/to/company-ca.pem"`，不要通过长期设置 `verify=False` 处理。

## 13. 如何验证自己真的掌握了

在配套目录执行：

```bash
python -m unittest -v test_demo.py
```

测试会自动启动随机本地端口，不需要公网，覆盖成功流程与常见失败：Query 编码、表单/JSON/XML、Cookie 会话、CSRF、Bearer、分页、上传内容哈希、导出文件，以及 401/403/404/415/422。

也可以手动改几处观察结果：

1. 把创建订单的 `json=` 改成 `data=`，观察 415。
2. 登录后删除 `X-CSRF-Token` 再创建订单，观察 403。
3. 清空 `session.cookies` 后查询订单，观察 401。
4. 把 `quantity` 改为 0，观察 422。
5. 手写不带 boundary 的 multipart 头，观察上传失败。

本例为讲清请求方式而简化了后端：凭证与订单只在内存中，附件不落盘，不包含库存、价格计算、支付、生产权限体系与并发控制。实际订单同步若面对持续变化的数据，还需要考虑排序稳定性、游标分页、去重与断点记录。

学习时可以先跑通第 9.1 节，再阅读 `client.py` 的封装。遇到新接口时，先按第 1 节确定参数位置，再用第 5 节确定请求体格式。

## 14. 官方参考

- [Requests Quickstart：参数、头部、Cookie、上传与响应](https://requests.readthedocs.io/en/latest/user/quickstart/)
- [Requests Advanced Usage：Session、PreparedRequest、流式请求](https://requests.readthedocs.io/en/latest/user/advanced/)
- [Requests Authentication：认证方式](https://requests.readthedocs.io/en/latest/user/authentication/)
- [urllib3 Retry：重试参数](https://urllib3.readthedocs.io/en/stable/reference/urllib3.util.html#urllib3.util.Retry)
