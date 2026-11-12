import argparse

from .core import normalize_spaces


def main() -> int:
    parser = argparse.ArgumentParser(description="合并文本中的连续空白字符")
    parser.add_argument("text", help="需要处理的文本")
    args = parser.parse_args()
    print(normalize_spaces(args.text))
    return 0
