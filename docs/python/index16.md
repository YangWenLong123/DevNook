# Python 包管理与 PyPI 发布：从项目创建到自动发布

当你写好一个 Python 工具函数、接口 SDK 或命令行工具，希望其他人执行 `pip install` 就能使用时，就需要把项目制作成可分发的 Python 包，并发布到包索引。

本文用一个文本处理工具包演示完整流程：创建项目、编写 `pyproject.toml`、本地开发、构建 wheel 与源码包、验证安装、发布到 TestPyPI，再发布到正式 PyPI，最后配置 GitHub Actions 自动发布。

示例使用 **Python 3.10+、setuptools、build 和 Twine**，不需要编写 `setup.py`。仓库内的配套项目位于 `docs/python/examples/pypi-demo/`，可以复制到独立目录练习。

## 1. PyPI、pip 与打包工具分别负责什么

**PyPI（Python Package Index）是 Python 的公共软件包索引。** 它保存项目说明、版本信息和可下载的分发文件。`pip` 则负责查找、下载和安装这些包。

如果你熟悉前端开发，可以这样对应：

| Python 生态 | 前端中的相近概念 | 作用 |
| --- | --- | --- |
| PyPI | npm registry | 存放公开的软件包和版本 |
| `pip install` | `npm install` | 安装软件包及其依赖 |
| `pyproject.toml` | `package.json` 的部分职责 | 描述项目元数据、依赖及工具配置 |
| setuptools / Hatchling | 构建工具 | 把源码制作成分发文件 |
| `python -m build` | 调用构建脚本 | 通过标准接口调用构建后端 |
| Twine | `npm publish` 的发布职责 | 将已经构建好的文件上传到包索引 |

这些对应关系用于理解流程，不代表命令和配置可以直接互换。本文采用：

```text
源码 + pyproject.toml
        ↓ python -m build，调用 setuptools
wheel（.whl）+ 源码包（.tar.gz）
        ↓ python -m twine upload
PyPI / TestPyPI
        ↓ python -m pip install
用户的 Python 环境
```

## 2. 先理解三个不同的名字

下面三个名字不必完全相同：

| 名称 | 本文示例 | 使用位置 |
| --- | --- | --- |
| 分发名，也就是 PyPI 项目名 | `yourname-textkit-demo` | `pip install yourname-textkit-demo` |
| Python 导入包名 | `textkit_demo` | `import textkit_demo` |
| 命令行入口名 | `textkit-demo` | 在终端执行 `textkit-demo` |

分发名可以包含连字符，但 Python 的普通导入标识符不能包含连字符，因此通常使用下划线作为导入包名的一部分。

PyPI 会对分发名进行规范化：忽略大小写，并将连续的 `-`、`_`、`.` 视作同一种分隔符。例如 `my-tool`、`my_tool`、`My.Tool` 对应同一个规范化名称，不能用这些变化绕过名称占用。

**本文的 `yourname-textkit-demo` 是占位名，不保证可注册。** 发布前请全局替换为你拥有或可使用的唯一分发名。导入名与命令行入口可以保持不变，但也要避免与用户环境中的其他包和命令冲突。

## 3. 创建项目和虚拟环境

先创建独立的工作目录：

```bash
mkdir pypi-demo
cd pypi-demo
```

macOS / Linux：

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Windows PowerShell：

```powershell
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
```

如果 PowerShell 的执行策略限制激活脚本，也可以直接使用虚拟环境中的解释器，例如 `.\.venv\Scripts\python.exe -m pip --version`，后续同理替换 `python`。

激活后检查解释器，并安装工具：

```bash
python --version
python -m pip --version
python -m pip install --upgrade pip build twine
```

后文统一使用 `python -m pip`，让 pip 与当前 Python 解释器对应，减少“安装成功却无法导入”的环境混用问题。`build` 和 Twine 是开发、发布工具，不是示例包的运行时依赖。

## 4. 设计项目目录

按下面的结构创建文件：

```text
pypi-demo/
├── .gitignore
├── LICENSE
├── README.md
├── pyproject.toml
└── src/
    └── textkit_demo/
        ├── __init__.py
        ├── __main__.py
        ├── cli.py
        └── core.py
```

这里采用 `src` 布局，把可安装的 Python 包放到 `src/` 中。它有助于避免在项目根目录运行代码时，意外导入当前目录的源码，从而掩盖“分发包实际上没有包含代码”的问题。

推荐的 `.gitignore`：

```text
.venv*/
__pycache__/
*.py[cod]
*.egg-info/
build/
dist/
.env
.env.*
.pypirc
```

`.gitignore` 只影响 Git 跟踪，**不会自动决定哪些文件进入 wheel 或源码包**。分发文件内容仍要通过构建配置和实际产物检查。

## 5. 编写包代码和命令行入口

### 5.1 核心功能：`core.py`

```python
def normalize_spaces(text: str) -> str:
    """去除首尾空白，并将连续空白字符合并为一个空格。"""
    return " ".join(text.split())
```

它会把空格、换行、制表符等连续空白合并成一个普通空格：

```python
normalize_spaces("  hello   PyPI  ")  # "hello PyPI"
normalize_spaces("hello\n\tPython")  # "hello Python"
```

### 5.2 暴露公共 API：`__init__.py`

```python
from .core import normalize_spaces

__all__ = ["normalize_spaces"]
```

用户可以直接写 `from textkit_demo import normalize_spaces`。这里的导入语句把函数暴露到包级别；`__all__` 则声明通配符导入时导出的名称。

### 5.3 命令行实现：`cli.py`

```python
import argparse

from .core import normalize_spaces


def main() -> int:
    parser = argparse.ArgumentParser(description="合并文本中的连续空白字符")
    parser.add_argument("text", help="需要处理的文本")
    args = parser.parse_args()
    print(normalize_spaces(args.text))
    return 0
```

`argparse` 来自 Python 标准库，不需要另外安装。终端中包含空格的文本需要用引号包裹，作为一个参数传入。

### 5.4 支持模块运行：`__main__.py`

```python
from .cli import main

if __name__ == "__main__":
    raise SystemExit(main())
```

安装后可以执行：

```bash
python -m textkit_demo "  hello   PyPI  "
```

这与后面的命令行入口是两套相关但独立的机制：`__main__.py` 支持 `python -m 包名`，`[project.scripts]` 则让安装器创建终端命令。

## 6. 配置 `pyproject.toml`

在项目根目录写入以下完整配置：

```toml
[build-system]
requires = ["setuptools>=77.0.3"]
build-backend = "setuptools.build_meta"

[project]
name = "yourname-textkit-demo"
version = "0.1.0"
description = "A small text normalization package for learning Python packaging"
readme = "README.md"
requires-python = ">=3.10"
license = "MIT"
license-files = ["LICENSE"]
authors = [{ name = "Your Name" }]
keywords = ["text", "tutorial", "packaging"]
classifiers = [
    "Programming Language :: Python :: 3",
    "Operating System :: OS Independent",
]
dependencies = []

[project.scripts]
textkit-demo = "textkit_demo.cli:main"

[tool.setuptools.packages.find]
where = ["src"]
```

### 6.1 构建系统与项目元数据

| 配置 | 含义 |
| --- | --- |
| `[build-system].requires` | 构建环境需要安装的工具，不是用户运行时依赖 |
| `build-backend` | 真正生成分发文件的构建后端 |
| `name` | PyPI 分发名，需要替换为自己的名称 |
| `version` | 当前发布版本，使用 PEP 440 支持的格式 |
| `description` | PyPI 展示的简短介绍 |
| `readme` | PyPI 项目详情页使用的长说明文件 |
| `requires-python` | 用户安装时需要满足的 Python 版本范围 |
| `license` | SPDX 许可证表达式，本文使用 MIT |
| `license-files` | 需要包含在分发文件中的许可证文件 |
| `dependencies` | 用户安装包时自动解析和安装的运行时依赖 |
| `where = ["src"]` | 告诉 setuptools 从 `src` 查找 Python 包 |

这里设置 setuptools 的版本下限，是为了支持配置中采用的 SPDX 许可证表达式与 `license-files` 写法。其他构建后端的配置和版本要求可能不同，不要直接混用后端专用字段。

`requires-python = ">=3.10"` 是兼容性声明，不会自动保证代码在所有这些版本上正确运行。真实项目应在声明支持的 Python 版本上进行验证。

### 6.2 配置终端命令

```toml
[project.scripts]
textkit-demo = "textkit_demo.cli:main"
```

它表示：安装时创建名为 `textkit-demo` 的命令，运行时调用 `textkit_demo/cli.py` 中的 `main()`。

不要把右侧写成文件系统路径，也不要加调用括号。正确格式是 `可导入模块:函数名`。

### 6.3 项目链接，可按需添加

如果代码有公开仓库，可以加入以下配置，并将地址换成真实地址：

```toml
[project.urls]
Homepage = "https://github.com/YOUR_USERNAME/YOUR_REPOSITORY"
Issues = "https://github.com/YOUR_USERNAME/YOUR_REPOSITORY/issues"
```

## 7. 运行时依赖和可选依赖如何声明

示例只使用标准库，因此 `dependencies = []`。

假设你的真实项目需要 HTTP 客户端，可以在已有的 `[project]` 区块中修改依赖，**不要重复创建第二个 `[project]`**：

```toml
dependencies = [
    "httpx>=0.27,<1",
]
```

如果某些功能是可选的，可以新增：

```toml
[project.optional-dependencies]
http = ["httpx>=0.27,<1"]
```

用户按需安装：

```bash
python -m pip install "yourname-textkit-demo[http]"
```

依赖版本范围应依据你实际验证过的兼容性设置。对于给其他项目使用的库，不建议不加判断地把整个开发环境的 `pip freeze` 结果作为运行时依赖。

`requirements.txt` 可以用于安装某个应用或环境的依赖，但不会自动成为已发布包的依赖元数据。消费者安装包时，主要依据分发文件中由 `pyproject.toml` 等配置生成的元数据解析依赖。

## 8. 编写 README 和许可证

### 8.1 `README.md`

一个基础 README 应说明包的用途、Python 版本、安装方法和使用示例。可按下面的结构编写；其中从 PyPI 安装的命令，要在正式发布成功后才可使用：

````markdown
# TextKit Demo

一个用于合并文本空白字符的小工具，需要 Python 3.10 或更高版本。

## 安装

```bash
python -m pip install yourname-textkit-demo
```

## Python 调用

```python
from textkit_demo import normalize_spaces

print(normalize_spaces("  hello   PyPI  "))
# hello PyPI
```

## 命令行调用

```bash
textkit-demo "  hello   PyPI  "
```

## 许可证

MIT
````

PyPI 不会把仓库中的图片和附件自动复制过去。README 如需展示图片，应使用用户可公开访问的完整 URL，并在上传后检查实际渲染效果。

### 8.2 `LICENSE`

示例选择 MIT，因此 `LICENSE` 文件也应放入对应的完整文本，修改年份和版权所有者：

```text
MIT License

Copyright (c) 2026 Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

其他项目应根据实际授权选择许可证，配置中的表达式与文件内容需要一致。

## 9. 本地开发：使用可编辑安装

在 `pyproject.toml` 所在目录执行：

```bash
python -m pip install -e .
```

`-e` 表示 editable install，也就是可编辑安装。修改 Python 源码后，通常不需要重新安装，就可以在当前环境中使用修改后的逻辑。

验证 Python API：

```bash
python -c "from textkit_demo import normalize_spaces; print(normalize_spaces('  hello   PyPI  '))"
```

验证两种命令行调用：

```bash
textkit-demo "  hello   PyPI  "
python -m textkit_demo "  hello   PyPI  "
```

这三条命令都应输出：

```text
hello PyPI
```

如果修改了依赖、版本或命令行入口等安装元数据，需要重新执行安装。**可编辑安装成功只说明开发环境可用，发布前仍然要检查构建产物。**

## 10. 构建 wheel 和源码包

在项目根目录执行：

```bash
python -m build
```

默认情况下，`build` 会创建隔离的构建环境，按照 `[build-system]` 安装构建依赖，先生成源码包，再从源码包构建 wheel。这也有助于发现“本地源码有文件，但源码包遗漏文件”的问题。

隔离构建通常需要下载构建依赖。已经在当前开发环境安装 setuptools，并不意味着隔离环境就不需要安装它。

构建成功后：

```text
dist/
├── yourname_textkit_demo-0.1.0-py3-none-any.whl
└── yourname_textkit_demo-0.1.0.tar.gz
```

| 文件 | 作用 |
| --- | --- |
| `.whl` | wheel，已经构建好的分发包，通常可以直接安装 |
| `.tar.gz` | sdist，源码分发包，需要在安装或构建时生成 wheel |

示例 wheel 文件名中的 `py3-none-any` 表示适用于 Python 3、无特定 ABI 限制、无特定平台限制。**它不覆盖 `Requires-Python` 的约束**，本例依然要求 Python 3.10+。

包含 C / Rust 扩展的项目通常需要按 Python 版本、ABI 和操作系统构建相应的 wheel，不能照搬纯 Python 包的产物名称与发布策略。

如果你在旧教程中看到 `python setup.py sdist bdist_wheel` 或 `python setup.py upload`，新项目建议使用本文的标准构建与上传流程。

## 11. 发布前验证产物

### 11.1 检查元数据和 README

```bash
python -m twine check --strict dist/*
```

正常应看到每个文件都显示 `PASSED`。这个命令用于检查分发元数据和长说明等问题，**不会运行你的代码，也不会证明包已经通过功能测试**。

### 11.2 检查文件是否真的进入分发包

```bash
python -m zipfile -l dist/yourname_textkit_demo-0.1.0-py3-none-any.whl
python -m tarfile -l dist/yourname_textkit_demo-0.1.0.tar.gz
```

wheel 中应该包含 `textkit_demo/` 下的 Python 文件，以及记录元数据的 `.dist-info/` 目录。检查名称、版本、许可证和入口点，同时确认没有误放入环境文件或无关的大文件。

### 11.3 在独立环境中安装 wheel

先退出开发环境，再创建专门的安装验证环境。

macOS / Linux：

```bash
deactivate
python3 -m venv .venv-wheel
source .venv-wheel/bin/activate
```

Windows PowerShell：

```powershell
deactivate
py -3 -m venv .venv-wheel
.\.venv-wheel\Scripts\Activate.ps1
```

安装刚刚生成的 wheel，注意按你的实际分发名和版本修改文件名：

```bash
python -m pip install --no-deps ./dist/yourname_textkit_demo-0.1.0-py3-none-any.whl
python -c "from textkit_demo import normalize_spaces; assert normalize_spaces('  hello   PyPI  ') == 'hello PyPI'; print('wheel OK')"
python -c "import textkit_demo; print(textkit_demo.__file__)"
textkit-demo "  hello   PyPI  "
python -m textkit_demo "  hello   PyPI  "
python -m pip check
```

`__file__` 应指向验证环境中的 `site-packages`，从而确认导入的是已安装的 wheel。

示例没有第三方依赖，所以可以使用 `--no-deps`。真实项目如果需要验证依赖安装，应在干净环境中按正常方式安装，并检查依赖是否齐全。

验证完成后，退出 `.venv-wheel`，重新激活开发环境，后续 Twine 命令在开发环境中运行：

```bash
deactivate
```

macOS / Linux 执行 `source .venv/bin/activate`；Windows PowerShell 执行 `.\.venv\Scripts\Activate.ps1`。

## 12. 准备 TestPyPI 和 PyPI 账号

两套服务彼此独立：

| 服务 | 地址 | 用途 |
| --- | --- | --- |
| TestPyPI | [test.pypi.org](https://test.pypi.org/) | 练习上传、检查页面与安装流程 |
| PyPI | [pypi.org](https://pypi.org/) | 面向用户的正式发布 |

账号、Token、项目和发布文件不会自动同步。TestPyPI 发布成功后，还需要将文件上传到正式 PyPI。

在相应站点完成账号注册、邮箱验证，并按网站要求配置双因素认证（2FA）。手动上传使用 API Token，**不是把网站登录密码直接交给 Twine**。

### 12.1 第一次发布的 Token

在账号设置中创建 API Token：

- [TestPyPI 账号设置](https://test.pypi.org/manage/account/)
- [正式 PyPI 账号设置](https://pypi.org/manage/account/)

首次手动上传新项目时，项目还不存在，通常需要使用账号范围的 Token 创建项目。项目创建成功后，日常发布可以改用仅对该项目有效的 Token；不再需要的宽权限 Token 可以撤销。

Token 只在创建时完整显示，应妥善保存。TestPyPI 的 Token 不能用于正式 PyPI，反之亦然。

## 13. 先发布到 TestPyPI

确认 `dist/` 中只有本次需要发布的版本，然后执行：

```bash
python -m twine upload --repository testpypi --username __token__ dist/*
```

根据提示输入 TestPyPI API Token，包含完整的 `pypi-` 前缀。输入时终端通常不会显示字符。

这里 `__token__` 是固定用户名，不是你的 PyPI 登录名。较新的 Twine 可能直接提示输入 Token，具体提示文本会随版本变化。

如果本地仓库配置影响了别名解析，也可以明确指定上传地址：

```bash
python -m twine upload --repository-url https://test.pypi.org/legacy/ --username __token__ dist/*
```

上传后，访问 TestPyPI 中对应项目的详情页，检查版本、README、Python 版本要求和下载文件。

**上传地址和安装索引地址不同：** Twine 上传使用 `/legacy/`，pip 安装使用 `/simple/`，不要把两者混在一起。

### 13.1 从 TestPyPI 验证安装

新开终端，创建并激活另一个干净的虚拟环境，例如 `.venv-testpypi`，避免本地已安装的同名包影响判断。然后执行：

```bash
python -m pip install --index-url https://test.pypi.org/simple/ --no-deps "yourname-textkit-demo==0.1.0"
python -c "from textkit_demo import normalize_spaces; print(normalize_spaces('  hello   PyPI  '))"
textkit-demo "  hello   PyPI  "
```

示例没有运行时依赖，使用 `--no-deps` 可以避免在 TestPyPI 中寻找依赖。TestPyPI 的内容与正式 PyPI 不同，也不保证长期保留项目和文件。

如果真实项目依赖 `httpx` 等包，可以先从明确的正式索引安装相应依赖，再从 TestPyPI 以 `--no-deps` 安装待测包，最后运行 `python -m pip check` 检查依赖完整性。

不建议为了省一步，直接把 TestPyPI 和正式 PyPI 通过 `--extra-index-url` 混在一起。pip 会综合候选版本进行解析，并不保证“主索引缺失时才使用额外索引”，可能选到意外的同名包。

## 14. 发布到正式 PyPI

TestPyPI 验证通过后，回到已经安装 Twine 的开发环境。确认已经替换占位的分发名、作者等信息，然后使用正式 PyPI 的 Token：

```bash
python -m twine upload --repository-url https://upload.pypi.org/legacy/ --username __token__ dist/*
```

如果没有设置覆盖默认仓库的配置或环境变量，也可以使用简写：

```bash
python -m twine upload --username __token__ dist/*
```

TestPyPI 与正式 PyPI 是独立索引，因此**可以把已经在 TestPyPI 验证过的同一组文件上传到正式 PyPI**，不需要仅为切换索引而修改版本或重新构建。

正式上传成功后，新建并激活干净环境，从正式 PyPI 安装验证：

```bash
python -m pip install --index-url https://pypi.org/simple/ "yourname-textkit-demo==0.1.0"
python -c "from textkit_demo import normalize_spaces; print(normalize_spaces('  hello   PyPI  '))"
textkit-demo "  hello   PyPI  "
python -m pip check
```

当所有功能正常，其他用户就可以通过分发名安装和使用你的包。

## 15. 发布新版本：不要覆盖旧文件

修改功能后，更新 `pyproject.toml`：

```toml
version = "0.1.1"
```

常见版本格式：

| 版本 | 含义 |
| --- | --- |
| `0.1.0` | 普通发布版本 |
| `0.1.1` | 通常用于修复问题 |
| `0.2.0` | 通常用于增加功能 |
| `1.0.0` | 通常用于标记稳定公共接口 |
| `1.1.0a1` | alpha 预发布 |
| `1.1.0rc1` | 候选发布 |
| `1.1.0.dev1` | 开发版本 |

PEP 440 规定版本格式与比较规则；“修复升 patch、功能升 minor、破坏兼容升 major”是项目可以采用的语义化版本约定，并不是 PyPI 强制执行的行为。

为避免把旧版本一起上传，可以在项目根目录使用跨平台清理命令：

```bash
python -c "from pathlib import Path; import shutil; [shutil.rmtree(p) for p in (Path('dist'), Path('build')) if p.is_dir()]"
python -m build
python -m twine check --strict dist/*
```

清理命令会删除当前目录下的 `dist/` 和 `build/`，因此要确认终端位于示例包的项目根目录。随后重复独立环境安装、TestPyPI 验证和正式发布流程。

PyPI 上已经使用过的分发文件名不能再次上传，即使删除该文件也不能复用。同一版本可以新增尚未上传过的其他平台 wheel，但**修复已经发布的代码通常应发布新版本**。

如果已发布版本有问题，可以使用 PyPI 的 yank 功能提示安装器避开该版本，再发布修复版本。Yank 是撤回标记，不等同于删除，也不会让已经安装的用户自动升级；特定精确版本要求仍可能安装被 yank 的版本。

用户升级命令：

```bash
python -m pip install --upgrade yourname-textkit-demo
```

## 16. 模板、JSON 等资源文件怎么打包

真实项目可能还包含提示词模板、JSON 配置或其他随包资源。例如新增：

```text
src/textkit_demo/templates/default.json
```

针对 setuptools，在 `pyproject.toml` 中增加：

```toml
[tool.setuptools.package-data]
textkit_demo = ["templates/*.json"]
```

运行时使用 `importlib.resources` 读取：

```python
import json
from importlib.resources import files

content = (
    files("textkit_demo")
    .joinpath("templates")
    .joinpath("default.json")
    .read_text(encoding="utf-8")
)
config = json.loads(content)
```

不要依赖终端的当前目录来读取随包文件。新增资源后，需要同时检查 wheel 和源码包内容；若使用 `MANIFEST.in`，也要理解它主要控制源码分发，不能仅凭源码包中存在文件就认定 wheel 一定包含该文件。

## 17. 进阶：GitHub Actions 可信自动发布

手动发布适合学习和偶尔发布。维护长期项目时，推荐使用 **Trusted Publishing（可信发布）**：GitHub Actions 通过 OIDC 向 PyPI 证明工作流身份，获取短期发布凭据，不需要在仓库 Secret 中长期保存 PyPI Token。

### 17.1 配置可信发布者

1. 将包项目放进自己的 GitHub 仓库。本节工作流假设 `pyproject.toml` 位于仓库根目录；如果只发布本教程的嵌套示例，需要调整工作目录和产物路径。
2. 在 GitHub 仓库的 Environments 中创建名为 `pypi` 的环境，并按团队发布流程配置审批和允许部署的标签规则。
3. 已有 PyPI 项目可在项目管理页面的 Publishing 中添加可信发布者；尚未创建的项目可在[账号的 Publishing 页面](https://pypi.org/manage/account/publishing/)添加 pending publisher。
4. 填写 GitHub 仓库所有者、仓库名、工作流文件名 `publish.yml` 和环境名 `pypi`。新项目还需要填写分发名。

这里的工作流文件名填写 `publish.yml`，不是整个 `.github/workflows/publish.yml` 路径。仓库、文件名和环境名必须与工作流一致。

### 17.2 创建工作流

在包项目仓库中新建 `.github/workflows/publish.yml`：

```yaml
name: Publish Python package

on:
  push:
    tags:
      - "v*"

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          persist-credentials: false

      - uses: actions/setup-python@v6
        with:
          python-version: "3.12"

      - name: Install build tools
        run: python -m pip install --upgrade build twine

      - name: Verify tag matches package version
        run: |
          python - <<'PY'
          import os
          import tomllib
          from pathlib import Path

          project = tomllib.loads(Path("pyproject.toml").read_text(encoding="utf-8"))
          expected = "v" + project["project"]["version"]
          actual = os.environ["GITHUB_REF_NAME"]
          if actual != expected:
              raise SystemExit(f"Tag {actual!r} does not match {expected!r}")
          PY

      - name: Build and check distributions
        run: |
          python -m build
          python -m twine check --strict dist/*

      - name: Smoke test installed wheel
        run: |
          python -m venv /tmp/textkit-wheel-check
          /tmp/textkit-wheel-check/bin/python -m pip install dist/*.whl
          /tmp/textkit-wheel-check/bin/python -c "from textkit_demo import normalize_spaces; assert normalize_spaces('  hello   PyPI  ') == 'hello PyPI'"
          /tmp/textkit-wheel-check/bin/textkit-demo "  hello   PyPI  "
          /tmp/textkit-wheel-check/bin/python -m pip check

      - uses: actions/upload-artifact@v5
        with:
          name: python-distributions
          path: dist/
          if-no-files-found: error

  publish:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: pypi
    permissions:
      id-token: write
    steps:
      - uses: actions/download-artifact@v6
        with:
          name: python-distributions
          path: dist/

      - name: Publish to PyPI
        uses: pypa/gh-action-pypi-publish@release/v1
```

工作流把构建、检查和安装验证放在 `build` 作业中，`publish` 作业只下载已验证产物并上传。`id-token: write` 允许发布作业获取 OIDC 身份凭据，不代表它可以绕过 PyPI 上已配置的发布者规则。

示例为便于阅读使用 action 版本标签；团队可按自身规范固定提交 SHA，并持续维护依赖更新。这里用 Python 3.12 构建，不表示已验证项目声明的全部 Python 版本；正式项目应另设覆盖支持版本的测试流程。

### 17.3 触发发布

确认代码和版本修改已经提交，然后创建与版本一致的标签：

```bash
git tag v0.1.0
git push origin v0.1.0
```

标签本身不会修改 `pyproject.toml` 的版本。上面的校验步骤可以阻止“标签为 `v0.2.0`，包内版本仍是 `0.1.0`”的误发布。

这条标签推送会触发正式发布流程。如果同版本文件已经通过手动方式上传，重复发布会失败；可以先用下一个未发布版本练习自动流程。

### 17.4 改为 TestPyPI 自动发布

需要在 TestPyPI 单独添加可信发布者，并创建对应的 GitHub Environment，例如 `testpypi`。将发布作业的环境名改成 `testpypi`，并给发布 action 增加：

```yaml
with:
  repository-url: https://test.pypi.org/legacy/
```

正式 PyPI 和 TestPyPI 的发布者配置各自生效。可以先验证 TestPyPI 的自动发布，再配置正式环境。

## 18. 常见问题排查

### 18.1 上传时报 403 或认证失败

检查是否使用了目标站点的 Token、是否完整复制 `pypi-` 前缀、用户名是否为 `__token__`，以及 Token 是否有目标项目的发布权限。首次创建项目还要检查名称是否被占用或受到限制。

如果使用可信发布，检查仓库所有者、仓库名、工作流文件名、GitHub Environment 和 `id-token: write` 是否对应。

### 18.2 提示 `File already exists`

该文件名已经上传过。若是修复代码，更新版本并重新构建；如果只是网络中断后继续上传同一批产物，应先确认远端已有文件的状态。

`--skip-existing` 可以在支持的索引上跳过已存在文件，但不会覆盖旧内容，也不能把它当作修复已发布代码的办法。

### 18.3 安装成功，却提示 `ModuleNotFoundError`

优先检查：

- 导入时是否误用了带连字符的分发名。
- `src/` 下是否有正确的包目录和 `__init__.py`。
- setuptools 是否从正确目录发现包，wheel 内是否包含代码。
- 安装与运行是否使用同一个 Python 环境。

可以执行 `python -m pip show -f yourname-textkit-demo` 查看安装位置及文件列表。

### 18.4 `No matching distribution found`

检查包名、版本、索引地址、`requires-python` 和平台兼容性。比如本包要求 Python 3.10+，在 Python 3.9 环境中不能安装该版本。

如果从 TestPyPI 安装，先确认文件确实上传到了 TestPyPI。安装正式版本时，也要确认 pip 没有被全局配置指向其他镜像或索引。

### 18.5 在源码目录能运行，安装后缺模板或 JSON

检查 package data 配置，并查看 wheel 文件列表。开发目录中存在资源文件，不代表它已经被打进分发文件。

### 18.6 命令行入口找不到

确认虚拟环境已经激活，并且安装时包含最新 `[project.scripts]` 配置。也可以使用 `python -m textkit_demo`，判断问题是在包本身还是终端入口与 PATH。

### 18.7 想只给公司内部使用

可以构建 wheel 后通过内部制品库、私有包索引或明确的文件路径安装；无需发布到公开 PyPI。包索引的访问控制与构建流程是不同层面的配置。

## 19. 发布流程速查

以下命令假设你已完成文件编写、名称替换、账号准备，并处于开发虚拟环境和包项目根目录：

```bash
# 安装工具
python -m pip install --upgrade pip build twine

# 开发安装并检查 API
python -m pip install -e .
python -c "from textkit_demo import normalize_spaces; assert normalize_spaces('  hello   PyPI  ') == 'hello PyPI'"

# 清理上一次构建的产物
python -c "from pathlib import Path; import shutil; [shutil.rmtree(p) for p in (Path('dist'), Path('build')) if p.is_dir()]"

# 构建并检查
python -m build
python -m twine check --strict dist/*
```

接着按第 11 节，在干净环境中验证 wheel 的安装和命令行功能。验证通过并切回开发环境后：

```bash
# 先上传测试索引，使用 TestPyPI Token
python -m twine upload --repository testpypi --username __token__ dist/*
```

从 TestPyPI 安装检查通过后，再使用正式 PyPI Token 发布同一组产物：

```bash
python -m twine upload --repository-url https://upload.pypi.org/legacy/ --username __token__ dist/*
```

对于长期维护的项目，建议把人工打包上传升级为可信发布工作流，并把支持版本验证、变更记录和版本管理纳入日常交付流程。

## 20. 官方参考资料

本文命令与配置按 2026-11-09 查阅的官方资料整理，实际使用时可进一步阅读：

- [Python Packaging User Guide：打包 Python 项目](https://packaging.python.org/en/latest/tutorials/packaging-projects/)
- [编写 pyproject.toml](https://packaging.python.org/en/latest/guides/writing-pyproject-toml/)
- [setuptools 的 pyproject.toml 配置](https://setuptools.pypa.io/en/latest/userguide/pyproject_config.html)
- [使用 TestPyPI](https://packaging.python.org/en/latest/guides/using-testpypi/)
- [PyPI：发布项目与 API Token](https://docs.pypi.org/publishing/publishing-to-pypi/)
- [PyPI：可信发布](https://docs.pypi.org/trusted-publishers/)
- [使用 GitHub Actions 发布 Python 包](https://packaging.python.org/en/latest/guides/publishing-package-distribution-releases-using-github-actions-ci-cd-workflows/)
- [Twine 文档](https://twine.readthedocs.io/en/stable/)
- [PEP 440：版本标识与依赖规范](https://peps.python.org/pep-0440/)
