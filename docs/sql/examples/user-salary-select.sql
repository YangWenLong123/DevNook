-- 单表工资示例：覆盖 SELECT / FROM / JOIN / WHERE / GROUP BY / HAVING / ORDER BY / LIMIT / OFFSET。
-- 目标数据库：MySQL 8.0；也可用 SQLite 执行。
-- 在练习数据库中执行。表名 db_salary_demo 与此前的 db_user_salary 区分。
-- 每行是一位员工的当前工资；manager_id 表示直属领导的 id，NULL 表示未设置领导。
-- 此表不设置外键，不依赖其他表；主键手动指定。

CREATE TABLE db_salary_demo (
    id INT PRIMARY KEY,
    user_name VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    manager_id INT
);

INSERT INTO db_salary_demo (id, user_name, department, salary, manager_id) VALUES
    (1, '张三', '技术部', 12000, NULL),
    (2, '李四', '技术部',  9000, 1),
    (3, '王五', '技术部',  8000, 1),
    (4, '赵六', '产品部', 11000, NULL),
    (5, '孙七', '产品部',  7500, 4),
    (6, '周八', '产品部',  7000, 4),
    (7, '吴九', '财务部', 10000, NULL),
    (8, '郑十', '财务部',  6500, 7);

-- CASE 01: SELECT / FROM：查询姓名、部门和工资。
SELECT user_name, department, salary
FROM db_salary_demo;

-- CASE 02: WHERE / ORDER BY：查询工资不少于 9000 元的员工，按工资降序。
-- 结果：张三 12000、赵六 11000、吴九 10000、李四 9000。
SELECT user_name, salary
FROM db_salary_demo
WHERE salary >= 9000
ORDER BY salary DESC, id ASC;

-- CASE 03: GROUP BY / HAVING：统计至少有 3 人的部门及平均工资。
-- 结果：技术部 3 人、平均 9666.67；产品部 3 人、平均 8500。
SELECT
    department,
    COUNT(*) AS employee_count,
    ROUND(AVG(salary), 2) AS average_salary
FROM db_salary_demo
GROUP BY department
HAVING COUNT(*) >= 3
ORDER BY average_salary DESC, department ASC;

-- CASE 04: LIMIT / OFFSET：按工资降序，每页 3 人，查询第 2 页。
-- OFFSET = (页码 - 1) * 每页条数。
-- 结果：李四 9000、王五 8000、孙七 7500。
SELECT user_name, salary
FROM db_salary_demo
ORDER BY salary DESC, id ASC
LIMIT 3 OFFSET 3;

-- CASE 05: JOIN / ON / AS：一张表自关联，查询每位员工及直属领导。
-- e 和 m 是同一张表的两个别名；e 代表员工，m 代表领导。
-- LEFT JOIN 保留未设置领导的员工，其 manager_name 为 NULL。
SELECT
    e.user_name AS employee_name,
    m.user_name AS manager_name
FROM db_salary_demo AS e
LEFT JOIN db_salary_demo AS m
    ON e.manager_id = m.id
ORDER BY e.id;

-- CASE 06: 综合案例，包含上述 9 个子句。
-- 在工资不少于 7000 元的直属下属中，统计每位领导的下属人数和平均工资；
-- 只保留至少有 2 位符合条件下属的领导，按下属平均工资降序取前 2 位。
-- 结果：张三 2 人、平均 8500；赵六 2 人、平均 7250。
SELECT
    m.user_name AS manager_name,
    COUNT(*) AS employee_count,
    ROUND(AVG(e.salary), 2) AS average_salary
FROM db_salary_demo AS e
INNER JOIN db_salary_demo AS m
    ON e.manager_id = m.id
WHERE e.salary >= 7000
GROUP BY m.id, m.user_name
HAVING COUNT(*) >= 2
ORDER BY average_salary DESC, m.id ASC
LIMIT 2 OFFSET 0;
