## 常用数学函数

按 MySQL 8.4 官方“[数学函数](https://dev.mysql.com/doc/refman/8.4/en/mathematical-functions.html)”分类，共有 30 个函数名，包含别名。下面按用途全部列出，示例结果中的 ≈ 表示近似值。

### 数值处理与取整

| 函数 | 作用 | 示例 | 结果 |
| --- | --- | --- | --- |
| `ABS(x)` | 返回绝对值 | `ABS(-10)` | `10` |
| `CEIL(x)` | 向上取整，是 `CEILING()` 的别名 | `CEIL(3.2)` | `4` |
| `CEILING(x)` | 返回不小于 x 的最小整数 | `CEILING(-3.2)` | `-3` |
| `FLOOR(x)` | 向下取整，返回不大于 x 的最大整数 | `FLOOR(-3.2)` | `-4` |
| `ROUND(x[, d])` | 舍入到小数点后 d 位，省略 d 时取整数 | `ROUND(12.345, 2)` | `12.35` |
| `TRUNCATE(x, d)` | 截断到小数点后 d 位，不进行四舍五入 | `TRUNCATE(12.349, 2)` | `12.34` |
| `SIGN(x)` | 返回符号：负数为 -1，零为 0，正数为 1 | `SIGN(-20)` | `-1` |

注意负数取整的区别：

```SQL
SELECT
    CEIL(-3.8),         -- -3：向正无穷方向取整
    FLOOR(-3.8),        -- -4：向负无穷方向取整
    TRUNCATE(-3.8, 0);  -- -3：直接截去小数部分
```

```SQL
SELECT
    ROUND(1234.56, -2),     -- 1200：舍入到百位
    ROUND(1250.56, -2),     -- 1300：舍入到百位
    TRUNCATE(1299.99, -2);  -- 1200：截断到百位
```

### 幂、平方根与对数

| 函数 | 作用 | 示例 | 结果 |
| --- | --- | --- | --- |
| `POW(x, y)` | 返回 x 的 y 次幂 | `POW(2, 3)` | `8` |
| `POWER(x, y)` | `POW()` 的别名 | `POWER(2, 3)` | `8` |
| `SQRT(x)` | 返回非负平方根 | `SQRT(81)` | `9` |
| `EXP(x)` | 返回 e 的 x 次幂 | `EXP(1)` | ≈ `2.718282` |
| `LN(x)` | 返回自然对数，以 e 为底 | `LN(EXP(1))` | ≈ `1` |
| `LOG(x)`、`LOG(b, x)` | 一个参数时返回自然对数；两个参数时返回以 b 为底的对数 | `LOG(2, 8)` | `3` |
| `LOG2(x)` | 返回以 2 为底的对数 | `LOG2(16)` | `4` |
| `LOG10(x)` | 返回以 10 为底的对数 | `LOG10(1000)` | `3` |


### 三角函数、反三角函数与角度转换

三角函数的参数通常使用弧度；反三角函数返回的也是弧度。180° = π 弧度。

| 函数 | 作用 | 示例 | 结果 |
| --- | --- | --- | --- |
| `SIN(x)` | 返回正弦值 | `SIN(PI() / 2)` | ≈ `1` |
| `COS(x)` | 返回余弦值 | `COS(0)` | `1` |
| `TAN(x)` | 返回正切值 | `TAN(PI() / 4)` | ≈ `1` |
| `COT(x)` | 返回余切值 | `COT(PI() / 4)` | ≈ `1` |
| `ASIN(x)` | 返回反正弦，x 的范围为 -1～1 | `ASIN(1)` | ≈ `1.570796` |
| `ACOS(x)` | 返回反余弦，x 的范围为 -1～1 | `ACOS(0)` | ≈ `1.570796` |
| `ATAN(x)`、`ATAN(y, x)` | 返回反正切；两个参数时根据 x、y 的符号确定象限 | `ATAN(1)` | ≈ `0.785398` |
| `ATAN2(y, x)` | 等价于双参数形式的 `ATAN(y, x)` | `ATAN2(1, -1)` | ≈ `2.356194` |
| `PI()` | 返回圆周率 π | `PI()` | ≈ `3.141593` |
| `RADIANS(x)` | 将角度转换为弧度 | `RADIANS(180)` | ≈ `3.141593` |
| `DEGREES(x)` | 将弧度转换为角度 | `DEGREES(PI())` | `180` |

### 取余、随机数、进制转换与校验

| 函数 | 作用 | 示例 | 结果 |
| --- | --- | --- | --- |
| `MOD(n, m)` | 返回 n 除以 m 的余数，也支持小数 | `MOD(10, 3)` | `1` |
| `RAND([seed])` | 返回大于等于 0、小于 1 的随机浮点数，可指定种子 | `RAND()` | `0 <= 结果 < 1` |
| `CONV(n, from_base, to_base)` | 进制转换，结果为字符串；常用进制范围为 2～36 | `CONV('FF', 16, 10)` | `'255'` |
| `CRC32(str)` | 返回字符串的 32 位无符号 CRC 校验值 | `CRC32('MySQL')` | `3259397556` |

## 常用字符串函数和运算符

| 函数或运算符 | 说明 | SQL 案例 | 结果 |
| --- | --- | --- | --- |
| `ASCII()` | 返回字符串最左侧字符的第一个字节的数值 | `SELECT ASCII('ABC');` | `65` |
| `BIN()` | 将整数转换为二进制表示的字符串 | `SELECT BIN(10);` | `'1010'` |
| `BIT_LENGTH()` | 返回字符串的位数，即字节数乘以 8 | `SELECT BIT_LENGTH('abc');` | `24` |
| `CHAR()` | 将整数对应的编码字节转换为字符串，可指定字符集 | `SELECT CHAR(65, 66, 67 USING utf8mb4);` | `'ABC'` |
| `CHAR_LENGTH()` | 返回字符串的字符数 | `SELECT CHAR_LENGTH('你好');` | `2` |
| `CHARACTER_LENGTH()` | `CHAR_LENGTH()` 的别名 | `SELECT CHARACTER_LENGTH('你好');` | `2` |
| `CONCAT()` | 拼接多个字符串 | `SELECT CONCAT('Hello', ' ', 'MySQL');` | `'Hello MySQL'` |
| `CONCAT_WS()` | 使用指定分隔符拼接字符串，第一个参数为分隔符 | `SELECT CONCAT_WS('-', '2026', '11', '13');` | `'2026-11-13'` |
| `ELT()` | 返回指定序号对应的字符串，序号从 1 开始 | `SELECT ELT(2, '技术部', '财务部', '市场部');` | `'财务部'` |
| `EXPORT_SET()` | 从最低位开始，将各个位转换为指定的开、关字符串 | `SELECT EXPORT_SET(5, 'Y', 'N', ',', 4);` | `'Y,N,Y,N'` |
| `FIELD()` | 返回第一个参数在后续参数列表中的位置，未找到返回 0 | `SELECT FIELD('B', 'A', 'B', 'C');` | `2` |
| `FIND_IN_SET()` | 返回指定字符串在逗号分隔列表中的位置，未找到返回 0 | `SELECT FIND_IN_SET('Vue', 'MySQL,Vue,Java');` | `2` |
| `FORMAT()` | 对数字舍入并添加分组分隔符，返回字符串 | `SELECT FORMAT(12345.678, 2, 'en_US');` | `'12,345.68'` |
| `FROM_BASE64()` | 解码 Base64 字符串，返回二进制字符串 | `SELECT CAST(FROM_BASE64('SGVsbG8=') AS CHAR CHARACTER SET utf8mb4);` | `'Hello'` |
| `HEX()` | 返回数字的十六进制表示，或字符串各字节的十六进制表示 | `SELECT HEX('ABC');` | `'414243'` |
| `INSERT()` | 从指定位置开始，替换指定字符数的内容 | `SELECT INSERT('abcdef', 2, 3, 'XYZ');` | `'aXYZef'` |
| `INSTR()` | 返回子字符串首次出现的位置，未找到返回 0 | `SELECT INSTR('hello world', 'world');` | `7` |
| `LCASE()` | `LOWER()` 的别名，将字母转换为小写 | `SELECT LCASE('MySQL');` | `'mysql'` |
| `LEFT()` | 返回字符串左侧指定数量的字符 | `SELECT LEFT('MySQL', 2);` | `'My'` |
| `LENGTH()` | 返回字符串的字节数 | `SELECT LENGTH('你好');` | `6` |
| `LIKE` | 使用 `%` 和 `_` 进行模式匹配 | `SELECT 'MySQL' LIKE 'My%';` | `1` |
| `LOAD_FILE()` | 读取数据库服务器上指定文件的内容 | `SELECT LOAD_FILE('/var/lib/mysql-files/demo.txt');` | 文件内容；不满足读取条件时返回 `NULL` |
| `LOCATE()` | 返回子字符串的位置，可指定搜索起点 | `SELECT LOCATE('bar', 'foobarbar', 5);` | `7` |
| `LOWER()` | 将字符串中的字母转换为小写 | `SELECT LOWER('HELLO');` | `'hello'` |
| `LPAD()` | 在左侧填充字符串，使结果达到指定字符长度；原串过长时截短 | `SELECT LPAD('123', 6, '0');` | `'000123'` |
| `LTRIM()` | 删除字符串开头的空格 | `SELECT LTRIM('   hello');` | `'hello'` |
| `MAKE_SET()` | 根据位掩码选择对应字符串，并使用逗号连接 | `SELECT MAKE_SET(5, '查看', '修改', '导出');` | `'查看,导出'` |
| `MATCH() ... AGAINST()` | 配合全文索引执行全文检索 | `SELECT id FROM string_articles WHERE MATCH(title) AGAINST('MySQL' IN BOOLEAN MODE) ORDER BY id;` | 基于下方示例表返回 `1、3` |
| `MID()` | `SUBSTRING()` 的别名，从指定位置截取字符串 | `SELECT MID('abcdef', 2, 3);` | `'bcd'` |
| `NOT LIKE` | 返回 LIKE 模式匹配的否定结果 | `SELECT 'MySQL' NOT LIKE 'Java%';` | `1` |
| `NOT REGEXP` | 判断字符串是否不匹配指定正则表达式 | `SELECT 'abc' NOT REGEXP '[0-9]';` | `1` |
| `OCT()` | 将整数转换为八进制表示的字符串 | `SELECT OCT(10);` | `'12'` |
| `OCTET_LENGTH()` | `LENGTH()` 的别名，返回字节数 | `SELECT OCTET_LENGTH('你好');` | `6` |
| `ORD()` | 返回首字符按其编码字节组合得到的数值，不一定是 Unicode 码点 | `SELECT ORD('A');` | `65` |
| `POSITION()` | 使用 `POSITION(子串 IN 字符串)` 查找首次出现位置 | `SELECT POSITION('world' IN 'hello world');` | `7` |
| `QUOTE()` | 添加外围单引号，并转义字符串中的特殊字符 | `SELECT QUOTE('O''Reilly');` | 结果内容为 `'O\'Reilly'`，包含外围单引号 |
| `REGEXP` | 判断字符串是否匹配指定正则表达式 | `SELECT 'abc123' REGEXP '[0-9]+';` | `1` |
| `REGEXP_INSTR()` | 返回正则表达式匹配内容的起始位置，未找到返回 0 | `SELECT REGEXP_INSTR('abc123def', '[0-9]+');` | `4` |
| `REGEXP_LIKE()` | 判断字符串是否匹配正则表达式，可指定匹配选项 | `SELECT REGEXP_LIKE('abc123', '^[a-z]+[0-9]+$');` | `1` |
| `REGEXP_REPLACE()` | 使用指定字符串替换正则表达式匹配的内容 | `SELECT REGEXP_REPLACE('a1b2c3', '[0-9]', '');` | `'abc'` |
| `REGEXP_SUBSTR()` | 返回匹配正则表达式的子字符串，未找到返回 NULL | `SELECT REGEXP_SUBSTR('abc123def', '[0-9]+');` | `'123'` |
| `REPEAT()` | 将字符串重复指定次数 | `SELECT REPEAT('Hi', 3);` | `'HiHiHi'` |
| `REPLACE()` | 替换全部匹配的子字符串，匹配时区分大小写 | `SELECT REPLACE('hello world', 'world', 'MySQL');` | `'hello MySQL'` |
| `REVERSE()` | 反转字符串中的字符顺序 | `SELECT REVERSE('abc');` | `'cba'` |
| `RIGHT()` | 返回字符串右侧指定数量的字符 | `SELECT RIGHT('MySQL', 3);` | `'SQL'` |
| `RLIKE` | `REGEXP` 的别名 | `SELECT 'abc123' RLIKE '[0-9]+';` | `1` |
| `RPAD()` | 在右侧填充字符串，使结果达到指定字符长度；原串过长时截短 | `SELECT RPAD('abc', 5, '*');` | `'abc**'` |
| `RTRIM()` | 删除字符串结尾的空格 | `SELECT RTRIM('hello   ');` | `'hello'` |
| `SOUNDEX()` | 返回字符串的 Soundex 发音编码，主要用于英文单词或姓名 | `SELECT SOUNDEX('Robert');` | `'R163'` |
| `SOUNDS LIKE` | 比较两个字符串的 Soundex 编码是否相同 | `SELECT 'Robert' SOUNDS LIKE 'Rupert';` | `1` |
| `SPACE()` | 返回由指定数量空格组成的字符串 | `SELECT CONCAT('A', SPACE(3), 'B');` | `'A   B'`，中间有 3 个空格 |
| `STRCMP()` | 按排序规则比较字符串，小于、等于、大于分别返回 -1、0、1 | `SELECT STRCMP('abc', 'abd');` | `-1` |
| `SUBSTR()` | `SUBSTRING()` 的别名，支持负数起始位置 | `SELECT SUBSTR('abcdef', -3);` | `'def'` |
| `SUBSTRING()` | 从指定位置截取字符串，可指定长度 | `SELECT SUBSTRING('abcdef', 2, 3);` | `'bcd'` |
| `SUBSTRING_INDEX()` | 根据分隔符出现次数截取；正数从左侧取，负数从右侧取 | `SELECT SUBSTRING_INDEX('www.mysql.com', '.', 2);` | `'www.mysql'` |
| `TO_BASE64()` | 将字符串编码为 Base64 字符串 | `SELECT TO_BASE64('Hello');` | `'SGVsbG8='` |
| `TRIM()` | 默认删除字符串两端的空格，也可指定要删除的内容 | `SELECT TRIM('   hello   ');` | `'hello'` |
| `UCASE()` | `UPPER()` 的别名，将字母转换为大写 | `SELECT UCASE('MySQL');` | `'MYSQL'` |
| `UNHEX()` | 将十六进制字符串解码为二进制字符串 | `SELECT CAST(UNHEX('414243') AS CHAR CHARACTER SET utf8mb4);` | `'ABC'` |
| `UPPER()` | 将字符串中的字母转换为大写 | `SELECT UPPER('hello');` | `'HELLO'` |
| `WEIGHT_STRING()` | 返回用于比较、排序的二进制权重字符串，主要用于排序规则调试 | `SELECT HEX(WEIGHT_STRING(_utf8mb4'AB' COLLATE utf8mb4_0900_ai_ci));` | `'1C471C60'` |

## 日期和时间函数

当前时间假设为 2026-11-13 10:20:30，会话时区为 +08:00，日期名称语言为 en_US。涉及“当前时间”的实际结果随执行时间变化。

| 函数 / 语法 | 作用 | SQL 案例 | 示例结果 |
|---|---|---|---|
| `ADDDATE()` | 给日期增加指定时间间隔 | `SELECT ADDDATE('2026-11-13', INTERVAL 7 DAY);` | `2026-11-20` |
| `ADDTIME()` | 给时间或日期时间增加一段时间 | `SELECT ADDTIME('10:20:30', '01:10:00');` | `11:30:30` |
| `CONVERT_TZ()` | 将日期时间从一个时区转换到另一个时区 | `SELECT CONVERT_TZ('2026-11-13 10:20:30', '+08:00', '+00:00');` | `2026-11-13 02:20:30` |
| `CURDATE()` | 返回当前日期 | `SELECT CURDATE();` | `2026-11-13` |
| `CURRENT_DATE()` / `CURRENT_DATE` | `CURDATE()` 的同义写法 | `SELECT CURRENT_DATE;` | `2026-11-13` |
| `CURRENT_TIME()` / `CURRENT_TIME` | `CURTIME()` 的同义写法 | `SELECT CURRENT_TIME;` | `10:20:30` |
| `CURRENT_TIMESTAMP()` / `CURRENT_TIMESTAMP` | `NOW()` 的同义写法 | `SELECT CURRENT_TIMESTAMP;` | `2026-11-13 10:20:30` |
| `CURTIME()` | 返回当前时间 | `SELECT CURTIME();` | `10:20:30` |
| `DATE()` | 提取日期时间中的日期部分 | `SELECT DATE('2026-11-13 10:20:30');` | `2026-11-13` |
| `DATE_ADD()` | 给日期增加指定时间间隔 | `SELECT DATE_ADD('2026-11-13', INTERVAL 1 MONTH);` | `2026-12-13` |
| `DATE_FORMAT()` | 按格式输出日期或日期时间 | `SELECT DATE_FORMAT('2026-11-13', '%Y年%m月%d日');` | `2026年11月13日` |
| `DATE_SUB()` | 从日期减去指定时间间隔 | `SELECT DATE_SUB('2026-11-13', INTERVAL 7 DAY);` | `2026-11-06` |
| `DATEDIFF()` | 返回第一个日期减第二个日期的天数，忽略时间部分 | `SELECT DATEDIFF('2026-11-20', '2026-11-13');` | `7` |
| `DAY()` | `DAYOFMONTH()` 的同义写法 | `SELECT DAY('2026-11-13');` | `13` |
| `DAYNAME()` | 返回星期名称 | `SELECT DAYNAME('2026-11-13');` | `Friday` |
| `DAYOFMONTH()` | 返回日期是当月的第几天 | `SELECT DAYOFMONTH('2026-11-13');` | `13` |
| `DAYOFWEEK()` | 返回星期编号：周日为 1，周六为 7 | `SELECT DAYOFWEEK('2026-11-13');` | `6`，即周五 |
| `DAYOFYEAR()` | 返回日期是当年的第几天，范围 1～366 | `SELECT DAYOFYEAR('2026-11-13');` | `317` |
| `EXTRACT()` | 提取指定的日期或时间部分 | `SELECT EXTRACT(YEAR_MONTH FROM '2026-11-13');` | `202611` |
| `FROM_DAYS()` | 将 MySQL 日期天数编号转换为日期 | `SELECT FROM_DAYS(740298);` | `2026-11-13` |
| `FROM_UNIXTIME()` | 将 Unix 时间戳转换为会话时区的日期时间 | `SELECT FROM_UNIXTIME(1794536430);` | `2026-11-13 10:20:30` |
| `GET_FORMAT()` | 返回预定义的日期或时间格式字符串 | `SELECT GET_FORMAT(DATE, 'ISO');` | `%Y-%m-%d` |
| `HOUR()` | 提取小时部分 | `SELECT HOUR('10:20:30');` | `10` |
| `LAST_DAY()` | 返回指定日期所在月份的最后一天 | `SELECT LAST_DAY('2026-02-10');` | `2026-02-28` |
| `LOCALTIME()` / `LOCALTIME` | `NOW()` 的同义写法 | `SELECT LOCALTIME();` | `2026-11-13 10:20:30` |
| `LOCALTIMESTAMP()` / `LOCALTIMESTAMP` | `NOW()` 的同义写法 | `SELECT LOCALTIMESTAMP();` | `2026-11-13 10:20:30` |
| `MAKEDATE()` | 根据年份和年内天数生成日期 | `SELECT MAKEDATE(2026, 317);` | `2026-11-13` |
| `MAKETIME()` | 根据小时、分钟、秒生成时间 | `SELECT MAKETIME(10, 20, 30);` | `10:20:30` |
| `MICROSECOND()` | 提取微秒部分，范围 0～999999 | `SELECT MICROSECOND('10:20:30.123456');` | `123456` |
| `MINUTE()` | 提取分钟部分，范围 0～59 | `SELECT MINUTE('10:20:30');` | `20` |
| `MONTH()` | 提取月份 | `SELECT MONTH('2026-11-13');` | `11` |
| `MONTHNAME()` | 返回月份名称 | `SELECT MONTHNAME('2026-11-13');` | `November` |
| `NOW()` | 返回当前语句开始执行时的日期时间 | `SELECT NOW();` | `2026-11-13 10:20:30` |
| `PERIOD_ADD()` | 给年月增加指定月数，年月通常采用 `YYYYMM` 格式 | `SELECT PERIOD_ADD(202611, 3);` | `202702` |
| `PERIOD_DIFF()` | 返回第一个年月减第二个年月的月份数 | `SELECT PERIOD_DIFF(202702, 202611);` | `3` |
| `QUARTER()` | 返回日期所在季度，范围 1～4 | `SELECT QUARTER('2026-11-13');` | `4` |
| `SEC_TO_TIME()` | 将秒数转换为时间 | `SELECT SEC_TO_TIME(3661);` | `01:01:01` |
| `SECOND()` | 提取秒部分，范围 0～59 | `SELECT SECOND('10:20:30');` | `30` |
| `STR_TO_DATE()` | 按指定格式将字符串解析为日期或时间 | `SELECT STR_TO_DATE('13/11/2026', '%d/%m/%Y');` | `2026-11-13` |
| `SUBDATE()` | 减去时间间隔；第二个参数为整数时表示天数 | `SELECT SUBDATE('2026-11-13', 7);` | `2026-11-06` |
| `SUBTIME()` | 从时间或日期时间中减去一段时间 | `SELECT SUBTIME('10:20:30', '01:10:00');` | `09:10:30` |
| `SYSDATE()` | 返回函数实际执行时的日期时间 | `SELECT SYSDATE();` | `2026-11-13 10:20:30` |
| `TIME()` | 提取日期时间中的时间部分 | `SELECT TIME('2026-11-13 10:20:30');` | `10:20:30` |
| `TIME_FORMAT()` | 按指定格式输出时间 | `SELECT TIME_FORMAT('10:20:30', '%H:%i');` | `10:20` |
| `TIME_TO_SEC()` | 将时间转换为秒数 | `SELECT TIME_TO_SEC('01:01:01');` | `3661` |
| `TIMEDIFF()` | 返回第一个时间减第二个时间的差值 | `SELECT TIMEDIFF('12:00:00', '10:20:30');` | `01:39:30` |
| `TIMESTAMP()` | 一个参数时转换为日期时间；两个参数时将时间加到日期或日期时间上 | `SELECT TIMESTAMP('2026-11-13', '10:20:30');` | `2026-11-13 10:20:30` |
| `TIMESTAMPADD()` | 按指定单位给日期时间增加间隔 | `SELECT TIMESTAMPADD(MINUTE, 30, '2026-11-13 10:20:30');` | `2026-11-13 10:50:30` |
| `TIMESTAMPDIFF()` | 按指定单位返回第二个日期时间减第一个日期时间的整数差值 | `SELECT TIMESTAMPDIFF(DAY, '2026-11-13', '2026-11-20');` | `7` |
| `TO_DAYS()` | 返回日期对应的天数编号，以公元 0 年为计算基准 | `SELECT TO_DAYS('2026-11-13');` | `740298` |
| `TO_SECONDS()` | 返回日期时间对应的秒数，以公元 0 年为计算基准 | `SELECT TO_SECONDS('2026-11-13 10:20:30');` | `63961784430` |
| `UNIX_TIMESTAMP()` | 返回当前 Unix 时间戳；传参时将会话时区的日期时间转换为 Unix 时间戳 | `SELECT UNIX_TIMESTAMP('2026-11-13 10:20:30');` | `1794536430` |
| `UTC_DATE()` | 返回当前 UTC 日期 | `SELECT UTC_DATE();` | `2026-11-13` |
| `UTC_TIME()` | 返回当前 UTC 时间 | `SELECT UTC_TIME();` | `02:20:30` |
| `UTC_TIMESTAMP()` | 返回当前 UTC 日期时间 | `SELECT UTC_TIMESTAMP();` | `2026-11-13 02:20:30` |
| `WEEK()` | 返回周数；第二个参数控制周编号规则 | `SELECT WEEK('2026-11-13', 3);` | `46` |
| `WEEKDAY()` | 返回星期编号：周一为 0，周日为 6 | `SELECT WEEKDAY('2026-11-13');` | `4`，即周五 |
| `WEEKOFYEAR()` | 返回一年中的周数，等价于 `WEEK(date, 3)` | `SELECT WEEKOFYEAR('2026-11-13');` | `46` |
| `YEAR()` | 提取年份 | `SELECT YEAR('2026-11-13');` | `2026` |
| `YEARWEEK()` | 返回周所属年份和周数；第二个参数控制周编号规则 | `SELECT YEARWEEK('2026-11-13', 3);` | `202646` |

## 常用加密和压缩函数
| 函数 / 语法 | 作用 | SQL 案例 | 示例结果 / 说明 |
|---|---|---|---|
| `AES_DECRYPT()` | 使用 AES 解密，返回二进制明文 | `SELECT CAST(AES_DECRYPT(AES_ENCRYPT('hello', 'demo-key'), 'demo-key') AS CHAR);` | `hello` |
| `AES_ENCRYPT()` | 使用 AES 加密，返回二进制密文 | `SELECT HEX(AES_ENCRYPT('hello', 'demo-key'));` | 返回十六进制形式的密文 |
| `COMPRESS()` | 压缩字符串，返回二进制压缩数据 | `SELECT COMPRESS('hello');` | 返回压缩后的二进制数据 |
| `MD5()` | 计算 128 位 MD5 摘要，返回 32 个十六进制字符 | `SELECT MD5('hello');` | `5d41402abc4b2a76b9719d911017c592` |
| `RANDOM_BYTES()` | 生成指定字节数的随机二进制数据 | `SELECT HEX(RANDOM_BYTES(16));` | 返回 32 个十六进制字符，每次结果可能不同 |
| `SHA1()` / `SHA()` | 计算 160 位 SHA-1 摘要，二者等价 | `SELECT SHA1('hello');` | `aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d` |
| `SHA2()` | 按指定摘要位数计算 SHA-2 摘要 | `SELECT SHA2('hello', 256);` | `2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824` |
| `STATEMENT_DIGEST()` | 计算 SQL 语句规范化后的摘要哈希 | `SELECT STATEMENT_DIGEST('SELECT * FROM users WHERE id = 123');` | 返回 64 个十六进制字符的摘要 |
| `STATEMENT_DIGEST_TEXT()` | 返回规范化的 SQL 文本，将字面值替换为占位符等 | `SELECT STATEMENT_DIGEST_TEXT('SELECT * FROM users WHERE id = 123');` | ``SELECT * FROM `users` WHERE `id` = ?`` |
| `UNCOMPRESS()` | 解压由 `COMPRESS()` 生成的数据 | `SELECT CAST(UNCOMPRESS(COMPRESS('hello')) AS CHAR);` | `hello` |
| `UNCOMPRESSED_LENGTH()` | 返回压缩前数据的**字节长度** | `SELECT UNCOMPRESSED_LENGTH(COMPRESS('hello'));` | `5` |
| `VALIDATE_PASSWORD_STRENGTH()` | 返回密码强度评分，范围 0～100 | `SELECT VALIDATE_PASSWORD_STRENGTH('abc');` | `0`，密码长度不足 4 |

## 常用系统信息函数

| 函数 | 作用 | SQL 案例 | 示例结果 |
|---|---|---|---|
| `DATABASE()` | 返回当前选中的数据库名称 | `SELECT DATABASE();` | `test_db` |
| `VERSION()` | 返回 MySQL 服务器版本 | `SELECT VERSION();` | `8.0.36` |
| `USER()` | 返回客户端连接时指定的用户名及客户端主机信息 | `SELECT USER();` | `root@localhost` |

## 条件判断函数

| 函数 | 说明 |
|---|---|
| `IF(a, x, y)` | 如果 a 为真，返回 x，否则返回 y。 |
| `IFNULL(x, y)` | 如果 x 不为 NULL，返回 x，否则返回 y。 |
| `CASE`<br>`WHEN 条件1 THEN result1`<br>`WHEN 条件2 THEN result2`<br>`ELSE resultn`<br>`END` | 依次判断条件，返回第一个满足条件对应的 result。所有条件都不满足时，返回 ELSE 中的 result；如果没有 ELSE 子句，则返回 NULL。 |
| `CASE 表达式`<br>`WHEN 常量值1 THEN 值1`<br>`WHEN 常量值2 THEN 值2`<br>`ELSE 值n`<br>`END` | 将表达式与各常量值依次比较，返回第一个匹配项对应的值。全部不匹配时，返回 ELSE 中的值；如果没有 ELSE 子句，则返回 NULL。 |

## JSON函数

### 创建与读取

| 函数语法 | 作用 | SQL 案例 | 结果 |
|---|---|---|---|
| `JSON_OBJECT(key, value, ...)` | 创建 JSON 对象 | `SELECT JSON_OBJECT('name', '张三', 'age', 20);` | `{"name":"张三","age":20}` |
| `JSON_ARRAY(value, ...)` | 创建 JSON 数组 | `SELECT JSON_ARRAY('Java', 'MySQL', 100);` | `["Java","MySQL",100]` |
| `JSON_EXTRACT(json, path, ...)` | 按路径提取 JSON 值 | `SELECT JSON_EXTRACT('{"name":"张三","age":20}', '$.name');` | `"张三"`，保留 JSON 字符串引号 |
| `JSON_UNQUOTE(value)` | 将 JSON 字符串转换为普通字符串 | `SELECT JSON_UNQUOTE(JSON_EXTRACT('{"name":"张三"}', '$.name'));` | `张三`，不带引号 |
| `JSON_KEYS(json[, path])` | 返回 JSON 对象的键名数组 | `SELECT JSON_KEYS('{"name":"张三","age":20}');` | `["age","name"]` |

### 新增、修改与删除
| 函数语法 | 作用 | SQL 案例 | 结果 |
|---|---|---|---|
| `JSON_SET(json, path, value, ...)` | 路径存在则修改，不存在则新增 | `SELECT JSON_SET('{"age":20}', '$.age', 21, '$.name', '张三');` | `{"age":21,"name":"张三"}` |
| `JSON_INSERT(json, path, value, ...)` | 新增不存在的路径，已有值保持不变 | `SELECT JSON_INSERT('{"age":20}', '$.age', 21, '$.name', '张三');` | `{"age":20,"name":"张三"}` |
| `JSON_REPLACE(json, path, value, ...)` | 只修改已存在的路径 | `SELECT JSON_REPLACE('{"age":20}', '$.age', 21, '$.name', '张三');` | `{"age":21}` |
| `JSON_REMOVE(json, path, ...)` | 删除指定路径的数据 | `SELECT JSON_REMOVE('{"name":"张三","age":20}', '$.age');` | `{"name":"张三"}` |
| `JSON_ARRAY_APPEND(json, path, value, ...)` | 向指定数组末尾追加元素 | `SELECT JSON_ARRAY_APPEND('["Java","MySQL"]', '$', 'Python');` | `["Java","MySQL","Python"]` |
| `JSON_ARRAY_INSERT(json, path, value, ...)` | 在指定数组位置之前插入元素 | `SELECT JSON_ARRAY_INSERT('["Java","MySQL"]', '$[1]', 'Python');` | `["Java","Python","MySQL"]` |
| `JSON_MERGE_PATCH(json, json, ...)` | 合并 JSON 对象，后面的同名键覆盖前面的值 | `SELECT JSON_MERGE_PATCH('{"name":"张三","age":20}', '{"age":21}');` | `{"name":"张三","age":21}` |

### 判断与搜索

| 函数语法 | 作用 | SQL 案例 | 结果 |
|---|---|---|---|
| `JSON_CONTAINS(target, candidate[, path])` | 判断是否包含指定 JSON 值 | `SELECT JSON_CONTAINS('["Java","MySQL"]', '"MySQL"');` | `1` |
| `JSON_CONTAINS_PATH(json, 'one或all', path, ...)` | 判断指定路径是否存在 | `SELECT JSON_CONTAINS_PATH('{"name":"张三"}', 'one', '$.name', '$.age');` | `1`，至少一个路径存在 |
| `JSON_SEARCH(json, 'one或all', search_str)` | 搜索 JSON 中的字符串，返回匹配路径 | `SELECT JSON_SEARCH('["Java","MySQL"]', 'one', 'MySQL');` | `"$[1]"` |
| `JSON_VALID(value)` | 判断内容是否为合法 JSON | `SELECT JSON_VALID('{"name":"张三"}');` | `1`；不合法则返回 `0` |
one 表示至少一个路径存在或返回一个匹配；`all` 表示所有路径都存在或返回全部匹配，具体取决于所用函数。

### 长度、类型与格式

| 函数语法 | 作用 | SQL 案例 | 结果 |
|---|---|---|---|
| `JSON_LENGTH(json[, path])` | 返回数组元素数或对象成员数 | `SELECT JSON_LENGTH('{"name":"张三","tags":["Java","MySQL"]}');` | `2`，只统计当前层级 |
| `JSON_TYPE(json)` | 返回 JSON 值的类型 | `SELECT JSON_TYPE('[1,2,3]');` | `ARRAY` |
| `JSON_PRETTY(json)` | 将 JSON 格式化，增加缩进和换行 | `SELECT JSON_PRETTY('{"name":"张三","age":20}');` | 格式化后的 JSON 文本 |


### 常用 JSON 路径

| 路径 | 含义 |
|---|---|
| `$` | 整个 JSON 文档 |
| `$.name` | 根对象中的 `name` 字段 |
| `$.address.city` | `address` 对象中的 `city` 字段 |
| `$[0]` | 根数组中的第一个元素 |
| `$.tags[0]` | `tags` 数组中的第一个元素 |
| `$.tags[*]` | `tags` 数组中的所有元素 |

### 读取字段的简写

假设 users 表中的 info 是 JSON 列，其内容为 {"name":"张三"}：

| 语法 | SQL 案例 | 结果 |
|---|---|---|
| `列名 -> 路径` | `SELECT info->'$.name' FROM users;` | `"张三"`，相当于 `JSON_EXTRACT()` |
| `列名 ->> 路径` | `SELECT info->>'$.name' FROM users;` | `张三`，相当于提取后再调用 `JSON_UNQUOTE()` |

将 JSON 数组转换为表：`JSON_TABLE()`

```SQL
SELECT jt.*
FROM JSON_TABLE(
    '[{"name":"张三","age":20},{"name":"李四","age":25}]',
    '$[*]' COLUMNS (
        name VARCHAR(20) PATH '$.name',
        age INT PATH '$.age'
    )
) AS jt;
```

| name | age |
|---|---:|
| 张三 | 20 |
| 李四 | 25 |

## 分组函数

| 函数 | 说明 |
|---|---|
| `AVG(x)` | 平均值 |
| `SUM(x)` | 求和 |
| `MAX(x)` | 最大值 |
| `MIN(x)` | 最小值 |
| `COUNT(x)` | 计数 |

## 窗口函数

窗口函数也叫OLAP函数（Online Anallytical Processing，联机分析处理），可以对数据进行实时分析处理。窗口函数是每条记录都会分析，有几条记录执行完还是几条，因此也属于单行函数。

| 函数 | 说明 |
|---|---|
| `CUME_DIST()` | 累积分布值 |
| `DENSE_RANK()` | 当前行在分区内的排名，无间隔 |
| `FIRST_VALUE()` | 窗口帧中第一行的参数值 |
| `LAG()` | 分区内当前行之前指定偏移行的参数值，默认上一行 |
| `LAST_VALUE()` | 窗口帧中最后一行的参数值 |
| `LEAD()` | 分区内当前行之后指定偏移行的参数值，默认下一行 |
| `NTH_VALUE()` | 窗口帧中第 N 行的参数值 |
| `NTILE()` | 当前行在分区内所属的桶编号 |
| `PERCENT_RANK()` | 百分比排名值 |
| `RANK()` | 当前行在分区内的排名，并列后会跳过名次 |
| `ROW_NUMBER()` | 当前行在分区内的行号 |