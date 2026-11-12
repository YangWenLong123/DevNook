# TextKit Demo

一个用于学习 Python 打包与发布的文本工具包，需要 Python 3.10 或更高版本。

本项目的发布名 `yourname-textkit-demo` 是教学占位名。发布前请更换为自己拥有或可用的唯一名称，并修改作者信息；本示例没有预先发布到 PyPI。

## 本地开发

在本目录创建并激活虚拟环境，然后执行：

```bash
python -m pip install -e .
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
python -m textkit_demo "  hello   PyPI  "
```

## 打包与检查

```bash
python -m pip install --upgrade build twine
python -m build
python -m twine check --strict dist/*
```

完整步骤、TestPyPI 发布和可信发布配置见仓库中的 `docs/python/index16.md`。
