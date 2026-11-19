在其他 web 框架中，比如 Django 或 Flask，都有相应的表单类用来校验前端上传的数据是否合法。在 FastAPI 中则是通过 Pydantic 来实现的。Pydantic 有以下特点：
- 由类型提示提供支持——使用 Pydantic，模式验证和序列化由类型注释控制。更少的学习，更少的代码编写，以及与 IDE 和静态分析工具的集成。
- 速度——Pydantic 的核心验证逻辑是用 Rust 编写的。因此，Pydantic 是 Python 中最快的数据验证库之一。
- JSON 模式——Pydantic 模型可以发出 JSON 模式，允许与其他工具轻松集成。
- 生态系统——PyPI 上大约有 8000 个包使用 Pydantic，包括大量流行的库，如 FastAPI、huggingface、Django Ninja、SQLModel 和 LangChain。
- Battle 测试——Pydantic 每月下载量超过 7000 万次，被所有 FAANG 公司和纳斯达克 25 家最大公司中的 20 家使用。如果你想用 Pydantic 做点什么，别人可能已经做过了。
Pydantic 官网：https://docs.pydantic.dev/latest/


## 安装

由于 FastAPI 依赖 Pydantic，因此在安装 FastAPI 时会把 pydantic 也一起安装了。如果想手动装，可以通过以下命令即可安装：
```Python
uv add pydantic
```
## 基本使用
Pydantic 是通过定义模型，以及在模型中指定字段来对值进行校验的。示例代码如下：

```Python
from datetime import date
from pydantic import BaseModel
from typing import List


class User(BaseModel):
    id: int
    name: str = 'John Doe'
    date_joined: date | None
    departments: List[str] | None

external_data = {
    'id': 123,
    'date_joined': '2030-06-01',
    'departments': ['技术部', '产品部'],
}

user = User(**external_data)
print(user.id, user.name)
# 转换成字典
print(user.model_dump())
```

- 校验类必须继承自BaseModel，上述代码中类User(BaseModel)。
- id字段：必须为整形，或者可以转换为整形的值，并且由于没有指定默认值，或者使用Optional，所以id字段的值不能为空。
- name字段：必须为字符串类型，由于name指定了默认值，所以name字段可以为空。
- departments字段: 列表类型或者为None

传给User模型的字段的值有可能不满足要求，那么我们如何获取错误信息呢？看下面示例代码：

```Python
external_data = {'id': 'abc', 'date_joined': '2030-06-01', 'departments': ['技术部', '产品部']}

try:
    user = User(**external_data)
except  ValidationError as e:
    print(e.errors())
```

捕获错误结果：

```json
[{'type': 'int_parsing', 'loc': ('id',), 'msg': 'Input should be a valid integer, unable to parse string as an integer', 'input': 'abc', 'url': 'https://errors.pydantic.dev/2.14/v/int_parsing'}]
```

一个Pydantic模型可以通过model_dump()方法转化为字典，通过model_dump_json()方法转化为JSON格式的字符串。示例代码如下：

```Python
external_data = {
    'id': 123,
    'date_joined': '2030-06-01',
    'departments': ['技术部', '产品部'],
}

user = User(**external_data)
# 转换成字典
print(user.model_dump())

# 转换成json
print(user.model_dump_json())
```

字典：
```json
{'id': 123, 'name': 'John Doe', 'date_joined': datetime.date(2030, 6, 1), 'departments': ['技术部', '产品部']}
```

json:

```json
{"id":123,"name":"John Doe","date_joined":"2030-06-01","departments":["技术部","产品部"]}
```

## 内置类型约束 Field

Field 用来给 Pydantic 模型的字段设置默认值、校验规则、别名和文档信息。[Pydantic 官方 Field API 文档](https://pydantic.dev/docs/validation/latest/api/pydantic/fields/#pydantic.fields.Field)

### 参数

1. 默认值和类型校验相关的参数

| 参数 | 作用 | 示例 |
|---|---|---|
| `default` | 设置默认值；`...` 表示必填 | `Field(default=0)` |
| `default_factory` | 调用函数生成默认值 | `Field(default_factory=list)` |
| `validate_default` | 是否校验默认值，通常默认不校验 | `Field(default=10, validate_default=True)` |
| `strict` | 是否使用严格类型校验，限制自动类型转换 | `Field(strict=True)` |
| `coerce_numbers_to_str` | 是否允许将数字转换为字符串，严格模式下不生效 | `Field(coerce_numbers_to_str=True)` |

2. 数值、长度和格式约束

| 参数 | 作用 | 示例 |
|---|---|---|
| `gt` | 大于指定值，即 `>` | `Field(gt=0)` |
| `ge` | 大于等于指定值，即 `>=` | `Field(ge=0)` |
| `lt` | 小于指定值，即 `<` | `Field(lt=100)` |
| `le` | 小于等于指定值，即 `<=` | `Field(le=100)` |
| `multiple_of` | 必须是指定数值的整数倍 | `Field(multiple_of=5)` |
| `allow_inf_nan` | 是否允许无穷大和 `NaN`，用于 `float`、`Decimal` | `Field(allow_inf_nan=False)` |
| `max_digits` | `Decimal` 允许的最大数字总位数 | `Field(max_digits=10)` |
| `decimal_places` | `Decimal` 允许的最大小数位数 | `Field(decimal_places=2)` |
| `min_length` | 字符串的最小长度，或集合的最少元素数量 | `Field(min_length=1)` |
| `max_length` | 字符串的最大长度，或集合的最多元素数量 | `Field(max_length=50)` |
| `pattern` | 字符串必须满足的正则表达式 | `Field(pattern=r"^[A-Z]+$")` |

> 其中，输出使用别名通常需要调用 model_dump(by_alias=True)；`repr=False` 只影响模型的显示，不会从 model_dump() 中排除字段。

3. 字段名称和输出控制

| 参数 | 作用 | 示例 |
|---|---|---|
| `alias` | 设置输入和输出时使用的别名 | `Field(alias="userName")` |
| `alias_priority` | 控制别名是否被模型的别名生成器覆盖；`2` 不覆盖，`1` 允许覆盖 | `Field(alias="userName", alias_priority=2)` |
| `validation_alias` | 设置输入校验时使用的别名，支持字符串、路径或多个候选名称 | `Field(validation_alias="userName")` |
| `serialization_alias` | 设置输出时使用的别名 | `Field(serialization_alias="userName")` |
| `exclude` | 是否在序列化输出中排除该字段 | `Field(exclude=True)` |
| `exclude_if` | 根据字段值决定是否在输出中排除 | `Field(exclude_if=lambda v: v is None)` |
| `repr` | 是否在模型的字符串表示中显示该字段 | `Field(repr=False)` |
| `frozen` | 是否禁止在实例创建后重新给该字段赋值 | `Field(frozen=True)` |

4. 文档和 JSON Schema 相关的参数

| 参数 | 作用 | 示例 |
|---|---|---|
| `title` | 设置字段标题 | `Field(title="支付金额")` |
| `field_title_generator` | 根据字段名称和字段信息动态生成标题 | `Field(field_title_generator=lambda name, info: name.upper())` |
| `description` | 设置字段说明 | `Field(description="金额必须大于零")` |
| `examples` | 提供示例值，用于文档展示 | `Field(examples=["19.99", "100.00"])` |
| `json_schema_extra` | 补充或修改字段的 JSON Schema | `Field(json_schema_extra={"format": "custom"})` |
| `deprecated` | 标记字段已弃用，访问时可发出弃用警告 | `Field(deprecated="请使用新字段")` |

5. 联合类型和集合校验相关的参数

| 参数 | 作用 | 示例 |
|---|---|---|
| `discriminator` | 根据指定字段或判别器，确定联合类型应使用哪个模型 | `Field(discriminator="kind")` |
| `union_mode` | 联合类型的校验策略：默认 `"smart"`，也可按顺序尝试 | `Field(union_mode="left_to_right")` |
| `fail_fast` | 集合元素校验遇到首个错误时是否停止；支持 `list`、`tuple`、`set`、`frozenset` | `Field(fail_fast=True)` |

6. 还有三个参数仅适用于 Pydantic 数据类 dataclass

| 参数 | 作用 | 示例 |
|---|---|---|
| `init` | 是否将字段纳入数据类构造函数 | `Field(init=False)` |
| `init_var` | 是否仅作为初始化参数使用，不保存为实例字段 | `Field(init_var=True)` |
| `kw_only` | 构造时是否必须通过关键字传入 | `Field(kw_only=True)` |

### 描述信息

在Pydantic中，可以通过Field添加一些额外的数据，比如描述信息、数据范围等。示例代码如下：

```Python
from pydantic import BaseModel, EmailStr, PositiveInt, Field
from datetime import date

class UserSchema(BaseModel):
    id: int = Field(..., description="用户id")
    name: str = Field(..., description="用户名")
    email: EmailStr = Field(..., description="邮箱")
    date_joined: date | None = Field(None, description="加入时间")
    tastes: dict[str, PositiveInt] = Field(..., description="用户口味")



# 测试：
user_dict= {
    'id': "123",
    'name': 'John Doe',
    'email': 'xx@aa.com',
    'date_joined': '2030-06-01',
    'tastes': {
        'wine': 9,
        b'cheese': 7,
    }
}

user_schema = UserSchema(**user_dict)
print(user_schema.model_dump_json())
```

为什么定义字段的时候指定类型后，可以赋值为Field对象呢？解释如下。

在 Pydantic V2 中，Field 是一个工厂函数，它返回一个特殊的对象（FieldInfo 实例），本身不是值，而是对字段的元数据描述（如默认值、约束、描述等）。
关键点：

  - Field(18, ...) 的第一个位置参数 18 就是默认值（default）；
  - Pydantic 在模型构建时，会通过元类（metaclass） 遍历类定义中的所有注解（annotations）和类属性；
  - 当它发现某个字段（如 age）的类属性是一个 FieldInfo 实例时，就会：
    - a. 提取其 default（这里是 18）作为默认值；
    - b. 把其他参数（description, ge, le）作为验证/序列化/文档的元数据；
    - c. 把 FieldInfo 对象从类属性中“吃掉”（不会成为实例属性）；
    - d. 用注解 int + FieldInfo 构建 ModelField（V2 中是 FieldDefinition）。

所以你写的是：
```Python
age: int = Field(18, description="年龄")
```
但实例创建后，person.age 的值是 18（或你传入的值），而不是 FieldInfo 对象！

> 注意：Field只能用在 BaseModel 的字段定义中，不能用在普通类或函数里，否则会报错或行为异常。

### 默认值、字段规则

```Python
from pydantic import BaseModel, Field

class User(BaseModel):
    name: str = Field(
        ...,                   # 必填
        min_length=2,          # 最少 2 个字符
        max_length=20,         # 最多 20 个字符
        description="用户名",   # 文档说明
    )
    age: int = Field(default=18, ge=0, le=150)
```

这里，`str`、`int` 规定字段类型，`Field()` 补充约束。创建模型时，Pydantic 会执行校验：

```Python
user = User(name="张三")
print(user.age)  # 18

User(name="张")              # 校验失败：姓名长度不足
User(name="张三", age=-1)    # 校验失败：年龄不能小于 0
```

### 必填字段和默认值

```Python
class User(BaseModel):
    # 以下三个字段都必填
    id: int
    name: str = Field(...)
    email: str = Field(description="邮箱")

    # 有默认值，调用时可以省略
    age: int = Field(default=18)

    # 允许传 None，但仍然必填
    nickname: str | None = Field(...)

    # 允许传 None，也可以省略
    avatar: str | None = Field(default=None)
```

注意两个不同的概念：

| 定义 | 可以省略 | 可以传 `None` |
|---|---|---|
| `name: str` | 否 | 否 |
| `name: str = "匿名"` | 是 | 否 |
| `name: str \| None` | 否 | 是 |
| `name: str \| None = None` | 是 | 是 |

允许 None 由类型决定；能否省略由是否存在默认值决定。

Field(...) 中的 ... 是 Python 的 Ellipsis，在这里表示必填。没有默认值的 Field() 也表示必填。

### 数字范围与倍数校验

| 参数 | 含义 | 示例 |
|---|---|---|
| `gt` | 大于 | `gt=0` |
| `ge` | 大于等于 | `ge=0` |
| `lt` | 小于 | `lt=100` |
| `le` | 小于等于 | `le=100` |
| `multiple_of` | 必须是某个数的整数倍 | `multiple_of=5` |

```Python
class Product(BaseModel):
    price: float = Field(gt=0)
    stock: int = Field(ge=0)
    discount: float = Field(ge=0, le=1)
    quantity: int = Field(gt=0, multiple_of=5)
```

对于 Decimal，还可以限制总位数和小数位数：

```Python
from decimal import Decimal

class Payment(BaseModel):
    amount: Decimal = Field(
        gt=0,
        max_digits=10,
        decimal_places=2,
    )
```

max_digits=10 表示允许最大数字总位数为10；decimal_places=2 表示最多两位小数；它不会自动把输入四舍五入到两位。

### 字符串长度与格式校验

```Python
class Account(BaseModel):
    username: str = Field(min_length=3, max_length=20)
    password: str = Field(min_length=8)
    code: str = Field(pattern=r"^[A-Z]{2}[0-9]{4}$")
```

这里的 code 必须符合“两位大写字母 + 四位数字”：

```Python
Account(
    username="alice",
    password="password123",
    code="AB1234",
)
```

### 列表长度与元素约束

Field 可以限制集合中元素的数量：

```Python
class Article(BaseModel):
    tags: list[str] = Field(min_length=1, max_length=5)
```

这里限制的是：`tags` 至少一项、最多五项。列表中的每个元素由 str 约束。

如果还要限制每个字符串的长度，可以结合 Annotated：

```Python
from typing import Annotated

Tag = Annotated[str, Field(min_length=2, max_length=10)]

class Article(BaseModel):
    tags: list[Tag] = Field(min_length=1, max_length=5)
```

这样同时限制了列表长度和每个标签的长度。

### default_factory：动态生成默认值

默认值需要在每次创建对象时生成，可以使用 default_factory：

```Python
from datetime import datetime, timezone
from uuid import UUID, uuid4

class Order(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc)
    )
    items: list[str] = Field(default_factory=list)
```

每次创建 `Order()` 都会生成新的 ID、时间和列表。

注意传入的是函数本身：

```Python
Field(default_factory=uuid4)    # 正确：创建实例时调用
```

而下面这种写法会在定义模型类时就生成默认值：

```Python
Field(default=uuid4())
```
default 和 default_factory 不能同时设置。


### 字段别名：对接前端或其他接口

当外部字段名与 Python 字段名不一致时，可以使用 alias：

```Python
class User(BaseModel):
    user_id: int = Field(alias="userId")

user = User(userId=1001)

print(user.user_id)                  # 1001
print(user.model_dump())             # {'user_id': 1001}
print(user.model_dump(by_alias=True)) # {'userId': 1001}
```

几个别名参数的区别：

| 参数 | 作用 |
|---|---|
| `alias` | 同时设置输入和输出别名 |
| `validation_alias` | 只设置输入别名 |
| `serialization_alias` | 只设置输出别名 |

输出时通常需要使用 model_dump(by_alias=True) 才会采用输出别名。

也可以接受多个输入名称：

```Python
from pydantic import AliasChoices

class User(BaseModel):
    user_id: int = Field(
        validation_alias=AliasChoices("user_id", "userId"),
        serialization_alias="userId",
    )

User(user_id=1)  # 可以
User(userId=1)   # 也可以
```

### 文档信息：用于 FastAPI 接口文档

```Python
class Product(BaseModel):
    name: str = Field(
        title="商品名称",
        description="商品展示名称，长度为 1～50 个字符",
        examples=["机械键盘", "无线鼠标"],
        min_length=1,
        max_length=50,
    )
```

| 参数 | 作用 |
|---|---|
| `title` | 字段标题 |
| `description` | 字段说明 |
| `examples` | 示例值列表 |
| `json_schema_extra` | 额外的 JSON Schema 信息 |

这些信息会进入模型的 JSON Schema，FastAPI 可以据此生成接口文档。

examples 只是示例，不会成为默认值，也不会限制只能输入这些值。

### `strict`：严格类型校验

Pydantic 默认允许部分类型转换：

```Python
class User(BaseModel):
    age: int

user = User(age="18")
print(user.age)  # 18，字符串被转换成整数
```

使用严格模式后：

```Python
class User(BaseModel):
    age: int = Field(strict=True)

User(age=18)    # 可以
User(age="18")  # 校验失败
```

### validate_default：校验默认值

Pydantic 默认不校验字段的默认值：

```Python
class User(BaseModel):
    age: int = Field(default=-1, ge=0)

user = User()  # 默认值不会触发 ge=0 校验
```

需要校验默认值时：

```Python
class User(BaseModel):
    age: int = Field(
        default=-1,
        ge=0,
        validate_default=True,
    )

User()  # 校验失败
```

### 控制修改、显示和导出

```Python
class Account(BaseModel):
    id: int = Field(frozen=True)
    password: str = Field(repr=False, exclude=True)
```

| 参数 | 作用 |
|---|---|
| `frozen=True` | 实例创建后，禁止重新给该字段赋值 |
| `repr=False` | 模型的字符串表示中不显示该字段 |
| `exclude=True` | `model_dump()` 等序列化操作中排除该字段 |

```Python
account = Account(id=1, password="secret")

print(account)              # id=1
print(account.model_dump()) # {'id': 1}

account.id = 2              # 校验失败
```
repr=False 只控制显示，不会自动排除序列化结果；`frozen=True` 也不会阻止列表、字典内部内容被修改。

### discriminator：区分联合类型

当一个字段可以接收几种不同结构时，可以指定用哪个字段判断类型：

```Python
from typing import Literal

class Cat(BaseModel):
    kind: Literal["cat"]
    lives: int

class Dog(BaseModel):
    kind: Literal["dog"]
    bark: bool

class PetOwner(BaseModel):
    pet: Cat | Dog = Field(discriminator="kind")

owner = PetOwner(
    pet={"kind": "cat", "lives": 9}
)

print(type(owner.pet))  # Cat
```

Pydantic 会根据 kind 判断应该使用 Cat 还是 Dog 校验。


## 自定义验证器

自定义验证器主要用于处理 Field() 无法直接表达的业务规则

| 装饰器 | 作用 | 常见场景 |
|---|---|---|
| `@field_validator()` | 校验或处理指定字段 | 去除空格、检查用户名、转换输入格式 |
| `@model_validator()` | 校验整个模型 | 两次密码一致、结束时间晚于开始时间 |

例如，注册接口需要：清理用户名空格、禁止保留用户名、检查两次密码一致。

```Python
from typing import Any

from pydantic import (
    BaseModel,
    Field,
    ValidationError,
    field_validator,
    model_validator,
)


class RegisterRequest(BaseModel):
    username: str = Field(min_length=3, max_length=20)
    password: str = Field(min_length=8, repr=False)
    confirm_password: str = Field(min_length=8, repr=False)

    # 案例一：内置校验之前，先清理输入
    @field_validator("username", mode="before")
    @classmethod
    def strip_username(cls, value: Any) -> Any:
        if isinstance(value, str):
            return value.strip()
        return value

    # 案例二：内置校验之后，检查业务规则
    @field_validator("username", mode="after")
    @classmethod
    def check_username(cls, value: str) -> str:
        if value.lower() in {"admin", "root"}:
            raise ValueError("不能使用系统保留的用户名")
        return value

    # 案例三：所有字段校验通过后，检查字段之间的关系
    @model_validator(mode="after")
    def check_passwords(self) -> "RegisterRequest":
        if self.password != self.confirm_password:
            raise ValueError("两次输入的密码不一致")
        return self
```

创建模型时，验证器会自动执行：

```Python
user = RegisterRequest(
    username="  alice  ",
    password="abc12345",
    confirm_password="abc12345",
)

print(user.username)  # alice
```
对于这个例子，执行顺序如下：

```Plain text
原始用户名 "  alice  "
        ↓
strip_username：去除首尾空格
        ↓
Pydantic 内置校验：检查 str 类型和长度
        ↓
check_username：检查保留用户名
        ↓
所有字段校验通过
        ↓
check_passwords：检查两次密码一致
```

校验失败时，Pydantic 会抛出 ValidationError：

```Python
try:
    RegisterRequest(
        username="alice",
        password="abc12345",
        confirm_password="different123",
    )
except ValidationError as exc:
    print(exc)
    # 错误信息包含：两次输入的密码不一致
```

mode 决定验证器的执行时机：

| 写法 | 接收到的数据 | 执行时机 |
|---|---|---|
| `field_validator(..., mode="before")` | 原始字段输入，类型可能不确定 | 字段内置校验之前 |
| `field_validator(..., mode="after")` | 已完成类型转换和约束校验的字段值 | 字段内置校验之后，默认模式 |
| `model_validator(mode="before")` | 整个模型的原始输入，通常是字典 | 模型解析之前 |
| `model_validator(mode="after")` | 已通过字段校验的模型实例 `self` | 模型解析之后 |