-- 子查询完整练习：MySQL 8.0+。
-- 首次在练习环境中执行；重复运行会因表已存在而报错，不会自动删除旧表。
-- UPDATE、DELETE 案例使用 InnoDB 事务并回滚，后面的案例仍基于原始数据。

-- SETUP: 建库、建表、插入数据。
CREATE DATABASE IF NOT EXISTS subquery_demo CHARACTER SET utf8mb4;
USE subquery_demo;

CREATE TABLE db_sq_department (
    id INT PRIMARY KEY,
    department_name VARCHAR(50) NOT NULL UNIQUE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE db_sq_employee (
    id INT PRIMARY KEY,
    employee_name VARCHAR(50) NOT NULL,
    department_id INT,
    salary DECIMAL(10, 2) NOT NULL,
    manager_id INT,
    employment_status VARCHAR(10) NOT NULL,
    FOREIGN KEY (department_id) REFERENCES db_sq_department(id),
    FOREIGN KEY (manager_id) REFERENCES db_sq_employee(id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE db_sq_salary_rule (
    department_id INT PRIMARY KEY,
    raise_amount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (department_id) REFERENCES db_sq_department(id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

INSERT INTO db_sq_department (id, department_name) VALUES
    (10, '技术部'),
    (20, '产品部'),
    (30, '财务部'),
    (40, '运营部');

INSERT INTO db_sq_employee
    (id, employee_name, department_id, salary, manager_id, employment_status)
VALUES
    (1, '张三', 10, 12000, NULL, '在职'),
    (2, '李四', 10,  9000,    1, '在职'),
    (3, '王五', 10,  8000,    1, '在职'),
    (4, '赵六', 20, 11000, NULL, '在职'),
    (5, '孙七', 20,  7500,    4, '在职'),
    (6, '周八', 20,  7000,    4, '离职'),
    (7, '吴九', 30, 10000, NULL, '在职'),
    (8, '郑十', 30,  6500,    7, '在职'),
    (9, '钱一', NULL, 6000, NULL, '在职');

INSERT INTO db_sq_salary_rule (department_id, raise_amount) VALUES
    (10, 1000),
    (20,  500);

-- CASE 01: SELECT 中嵌套子查询：显示每位员工的部门和全公司平均工资。
-- 钱一的部门为 NULL；所有行 company_avg_salary 均为 8555.56。
SELECT
    e.id,
    e.employee_name,
    (SELECT d.department_name
     FROM db_sq_department AS d
     WHERE d.id = e.department_id) AS department_name,
    e.salary,
    (SELECT ROUND(AVG(salary), 2)
     FROM db_sq_employee) AS company_avg_salary
FROM db_sq_employee AS e
ORDER BY e.id;

-- CASE 02: WHERE 标量子查询：工资高于全公司平均工资。
-- 结果：张三 12000、李四 9000、赵六 11000、吴九 10000。
SELECT id, employee_name, salary
FROM db_sq_employee
WHERE salary > (SELECT AVG(salary) FROM db_sq_employee)
ORDER BY id;

-- CASE 03: WHERE 多行子查询：查询技术部或产品部员工。
-- 结果：ID 1、2、3、4、5、6。
SELECT id, employee_name, department_id
FROM db_sq_employee
WHERE department_id IN (
    SELECT id
    FROM db_sq_department
    WHERE department_name IN ('技术部', '产品部')
)
ORDER BY id;

-- CASE 04: WHERE 关联子查询：工资高于本部门平均工资。
-- 结果：张三 12000、赵六 11000、吴九 10000。
SELECT e.id, e.employee_name, e.salary
FROM db_sq_employee AS e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM db_sq_employee AS e2
    WHERE e2.department_id = e.department_id
)
ORDER BY e.id;

-- CASE 05: HAVING 子查询：部门平均工资高于全公司平均工资。
-- 结果：技术部（10），平均工资 9666.67。
SELECT department_id, ROUND(AVG(salary), 2) AS avg_salary
FROM db_sq_employee
WHERE department_id IS NOT NULL
GROUP BY department_id
HAVING AVG(salary) > (SELECT AVG(salary) FROM db_sq_employee)
ORDER BY department_id;

-- CASE 06: EXISTS：查询至少有一位员工的部门。
-- 结果：技术部、产品部、财务部。
SELECT d.id, d.department_name
FROM db_sq_department AS d
WHERE EXISTS (
    SELECT 1
    FROM db_sq_employee AS e
    WHERE e.department_id = d.id
)
ORDER BY d.id;

-- CASE 07: NOT EXISTS：查询没有员工的部门。
-- 结果：运营部（40）。
SELECT d.id, d.department_name
FROM db_sq_department AS d
WHERE NOT EXISTS (
    SELECT 1
    FROM db_sq_employee AS e
    WHERE e.department_id = d.id
)
ORDER BY d.id;

-- CASE 08: FROM 派生表：统计所有部门人数和平均工资，保留空部门。
-- 结果：技术部 3 / 9666.67；产品部 3 / 8500；财务部 2 / 8250；运营部 0 / NULL。
SELECT
    d.id,
    d.department_name,
    COALESCE(s.employee_count, 0) AS employee_count,
    s.avg_salary
FROM db_sq_department AS d
LEFT JOIN (
    SELECT department_id, COUNT(*) AS employee_count,
           ROUND(AVG(salary), 2) AS avg_salary
    FROM db_sq_employee
    WHERE department_id IS NOT NULL
    GROUP BY department_id
) AS s ON s.department_id = d.id
ORDER BY d.id;

-- CASE 09: UPDATE 关联子查询：按规则给在职员工加薪。
-- 影响 5 行：张三 13000、李四 10000、王五 9000、赵六 11500、孙七 8000。
-- EXISTS 防止没有调薪规则的员工被赋值为 NULL。
START TRANSACTION;

UPDATE db_sq_employee AS e
SET salary = salary + (
    SELECT r.raise_amount
    FROM db_sq_salary_rule AS r
    WHERE r.department_id = e.department_id
)
WHERE e.employment_status = '在职'
  AND EXISTS (
      SELECT 1
      FROM db_sq_salary_rule AS r
      WHERE r.department_id = e.department_id
  );

SELECT id, employee_name, salary
FROM db_sq_employee
ORDER BY id;

ROLLBACK;

-- CASE 10: DELETE 子查询：删除产品部的离职员工。
-- 删除周八（ID 6），剩余 8 人；回滚后恢复为 9 人。
START TRANSACTION;

DELETE FROM db_sq_employee
WHERE employment_status = '离职'
  AND department_id IN (
      SELECT id
      FROM db_sq_department
      WHERE department_name = '产品部'
  );

SELECT id, employee_name, employment_status
FROM db_sq_employee
ORDER BY id;

ROLLBACK;

-- CASE 11: CREATE TABLE ... AS SELECT：复制查询列及全部数据（9 行）。
-- 不完整复制主键、外键、索引等表定义，也不与原表保持同步。
CREATE TABLE db_sq_employee_copy AS
SELECT * FROM db_sq_employee;

SELECT COUNT(*) AS copied_rows FROM db_sq_employee_copy;

-- CASE 12: WHERE 1 = 0：只创建查询结果的列，不复制数据（0 行）。
CREATE TABLE db_sq_employee_empty AS
SELECT * FROM db_sq_employee WHERE 1 = 0;

SELECT COUNT(*) AS copied_rows FROM db_sq_employee_empty;

-- CASE 13: LIKE + INSERT ... SELECT：先复制更完整的表定义，再复制数据（9 行）。
-- MySQL 的 LIKE 保留列定义、索引等，但不复制外键。
CREATE TABLE db_sq_employee_like LIKE db_sq_employee;

INSERT INTO db_sq_employee_like
    (id, employee_name, department_id, salary, manager_id, employment_status)
SELECT id, employee_name, department_id, salary, manager_id, employment_status
FROM db_sq_employee;

SELECT COUNT(*) AS copied_rows FROM db_sq_employee_like;

-- CASE 14: CTE（公用表表达式）：查询工资高于本部门平均工资的员工。
-- 结果：张三 12000 / 9666.67；赵六 11000 / 8500；吴九 10000 / 8250。
WITH department_avg AS (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM db_sq_employee
    WHERE department_id IS NOT NULL
    GROUP BY department_id
)
SELECT e.id, e.employee_name, e.salary, ROUND(a.avg_salary, 2) AS department_avg_salary
FROM db_sq_employee AS e
INNER JOIN department_avg AS a ON a.department_id = e.department_id
WHERE e.salary > a.avg_salary
ORDER BY e.id;

-- CASE 15: 递归 CTE：查询张三及其所有层级的下属。
-- 结果：张三 level_no = 1；李四、王五 level_no = 2。
WITH RECURSIVE employee_tree AS (
    SELECT id, employee_name, manager_id, 1 AS level_no
    FROM db_sq_employee
    WHERE id = 1

    UNION ALL

    SELECT e.id, e.employee_name, e.manager_id, t.level_no + 1
    FROM db_sq_employee AS e
    INNER JOIN employee_tree AS t ON e.manager_id = t.id
)
SELECT id, employee_name, manager_id, level_no
FROM employee_tree
ORDER BY level_no, id;
