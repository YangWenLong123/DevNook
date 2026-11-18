# 07. 用户登录与权限

本章目标：理解注册、密码哈希、登录凭证与资源归属校验，避免出现“登录成功后能操作所有人的数据”。

本章代码摘自[第 13 章的完整项目](./index13.md)。不要把片段直接追加到第 6 章的单用户应用；需要运行时使用配套项目。

## 1. 认证与授权

- **认证**：你是谁？通过密码与 Token 识别用户。
- **授权**：你能做什么？检查角色、权限或资源所有者。

```text
注册：用户名 + 密码 → 校验 → 哈希密码 → 保存用户
登录：用户名 + 密码 → 验证哈希 → 签发短期访问 Token
访问：Authorization: Bearer <token> → 验证 Token → 读取用户 → 检查资源权限
```

JWT 是一种 Token 格式；Bearer 表示持有凭证即可使用。JWT 的 payload 通常只是编码并签名，不是加密，不应保存密码或敏感隐私。

## 2. 安装依赖与准备密钥

完整项目已经包含以下依赖：

```bash
python -m pip install "PyJWT>=2.9,<3" "pwdlib[argon2]>=0.2,<1" python-multipart
```

这里安装的是 `PyJWT`，导入名才是 `jwt`，不要误装同名的其他包。使用 `pwdlib` 的 Argon2 实现保存密码哈希。

生成随机密钥：

```bash
python -c 'import secrets; print(secrets.token_hex(32))'
```

把结果填入项目 `.env` 的 `SECRET_KEY`。服务的多个实例必须使用一致的有效密钥；不要每次启动随机生成，否则重启会让旧 Token 无法验证。

## 3. 密码哈希

```python
from pwdlib import PasswordHash

password_hash = PasswordHash.recommended()
stored_hash = password_hash.hash("a-demo-password")
assert password_hash.verify("a-demo-password", stored_hash)
```

数据库只保存 `stored_hash`，不保存明文，也不使用 MD5、普通 SHA256 代替密码哈希算法。哈希不是可以解密取回密码的加密方式。

注册响应使用独立的 `UserRead` 模型，只暴露 `id` 和 `username`。日志中也不要输出密码、完整 Token 或密码哈希。

## 4. 签发 JWT

完整项目 `app/security.py` 的核心函数：

```python
from datetime import datetime, timedelta, timezone

import jwt


def create_access_token(user_id: int, settings) -> str:
    now = datetime.now(timezone.utc)
    return jwt.encode(
        {
            "sub": str(user_id),
            "iat": now,
            "exp": now + timedelta(minutes=settings.access_token_expire_minutes),
        },
        settings.secret_key.get_secret_value(),
        algorithm="HS256",
    )
```

`sub` 是用户标识，使用字符串；`iat` 是签发时间；`exp` 是过期时间。使用带 UTC 时区的时间，避免本机时区混淆。

## 5. 登录接口与表单

配套项目使用 `OAuth2PasswordRequestForm` 接收标准字段：`username`、`password`，它们是表单，不是 JSON。

```bash
curl -X POST http://127.0.0.1:8000/auth/token \
  -d 'username=alice&password=learn-fastapi-123'
```

响应形状：

```json
{"access_token": "eyJ...", "token_type": "bearer"}
```

无论用户名不存在还是密码不正确，都返回相同的登录失败说明。示例对不存在的用户也验证一个预先生成的假哈希，减少两种路径明显的耗时差异；实际服务还应限制登录尝试。

本例演示自有应用的用户名密码登录与 Bearer 鉴权，不代表实现了完整 OAuth2 授权服务器。对接第三方身份提供方、单点登录等场景应学习 OIDC 与 Authorization Code + PKCE。

## 6. 从请求中提取并验证 Token

```python
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token")
```

`OAuth2PasswordBearer` 读取 Authorization 头，并为 OpenAPI 配置安全声明。它不会替你验证 JWT 签名、访问数据库或自动创建登录接口。

项目中的验证流程是：

```python
# 以下是 get_current_user 依赖内部的核心片段，省略了外层参数声明。
payload = jwt.decode(
    token,
    settings.secret_key.get_secret_value(),
    algorithms=["HS256"],
    options={"require": ["sub", "exp", "iat"]},
)
user_id = int(payload["sub"])
user = db.get(User, user_id)
```

算法白名单由服务器固定，不能根据 Token 自报的算法随意选择。项目会捕获签名、过期、声明及用户编号解析错误，再检查用户是否仍存在。

无有效身份时返回 401，并附带 `WWW-Authenticate: Bearer`；用户已登录但不具备某项业务权限时通常返回 403。

## 7. 任务归属必须由服务端决定

创建任务时使用当前用户的编号：

```python
# 当前路由已经通过依赖得到 payload、db 与 user。
task = Task(**payload.model_dump(), owner_id=user.id)
```

请求模型不接受 `owner_id`，防止客户端冒充其他人。详情、更新和删除都通过相同的归属查询获取任务：

```python
statement = select(Task).where(Task.id == task_id, Task.owner_id == user.id)
task = db.scalar(statement)
```

配套项目对“不存在”和“不属于当前用户”统一返回 404，避免暴露其他用户资源是否存在。列表同样按 owner_id 筛选，不能只限制详情接口。

角色权限是在此基础上的另一层判断，例如管理员可执行管理操作，不应该让客户端通过提交 `role="admin"` 获得权限。

## 8. Swagger UI 中测试登录

1. 调用 `POST /auth/register` 创建用户。
2. 点击文档右上角 `Authorize`，输入用户名和密码。
3. Swagger UI 会按配置向 `/auth/token` 发送表单并保存本次调试使用的 Token。
4. 调用带锁的 `/tasks` 接口，观察请求头。

Token 过期后重新登录。正式前端的 Token 保存方式取决于客户端与威胁模型；浏览器 Cookie 和 JavaScript 可读存储各有风险，不要直接把“放 localStorage”当成所有项目的默认答案。

## 9. 练习与验收

创建 alice 和 bob：alice 新建任务后，bob 的列表为空，且不能查询、修改或删除 alice 的任务。再测试无 Token、篡改 Token 和过期 Token，都应返回 401。

配套项目暂未实现刷新 Token、登出撤销、找回密码和邮件验证。JWT 在过期前通常仍然有效，真实的撤销需求需要额外存储和策略。

参考：[OAuth2 with Password and JWT](https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/)、[PyJWT Usage](https://pyjwt.readthedocs.io/en/stable/usage.html)。下一章：[08. 项目结构与配置](./index8.md)。
