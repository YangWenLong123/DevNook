def normalize_spaces(text: str) -> str:
    """去除首尾空白，并将连续空白字符合并为一个空格。"""
    return " ".join(text.split())
