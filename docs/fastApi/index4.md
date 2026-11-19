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

## Field

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