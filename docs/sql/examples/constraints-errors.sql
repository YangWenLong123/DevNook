-- 约束的预期报错案例：MySQL 8.0.16+。
-- 先完整执行 constraints.sql，再在同一练习库中逐条选择执行本文件的语句。
-- 每条 INSERT / UPDATE / DELETE 都应失败，不应修改业务数据。
-- 命令行直接运行默认会停在第一个错误；不要把本文件当作成功脚本执行。
-- 如果某条语句意外成功，先检查约束是否被删除或 sql_mode 是否符合下述设置。
-- 不要依赖失败 INSERT 后自增编号连续。

USE constraint_demo;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';

-- ERROR NOT_NULL / 1048: 姓名不能为 NULL。
INSERT INTO ct_employee (employee_no, employee_name, department_id, age)
VALUES ('E100', NULL, 10, 25);

-- ERROR UNIQUE / 1062: 邮箱已被张三使用。
INSERT INTO ct_employee (employee_no, employee_name, email, department_id, age)
VALUES ('E101', '重复邮箱', 'zhang@example.com', 10, 25);

-- ERROR COMPOSITE_UNIQUE / 1062: 技术部已存在编号 E001。
INSERT INTO ct_employee (employee_no, employee_name, department_id, age)
VALUES ('E001', '重复部门编号', 10, 25);

-- ERROR PRIMARY_KEY / 1062: 员工 ID 1 已存在。
INSERT INTO ct_employee (id, employee_no, employee_name, department_id, age)
VALUES (1, 'E102', '重复主键', 10, 25);

-- ERROR COMPOSITE_PRIMARY_KEY / 1062: 员工 1 已登记 SQL 技能。
INSERT INTO ct_employee_skill (employee_id, skill_code)
VALUES (1, 'SQL');

-- ERROR AUTO_INCREMENT_REMOVED / 1364: 独立表已移除自增，id 无默认值。
INSERT INTO ct_auto_demo (employee_name) VALUES ('缺少编号');

-- ERROR DEFAULT_REMOVED / 1364: 默认值已删除，且该列不能为 NULL。
INSERT INTO ct_default_demo (id) VALUES (4);

-- ERROR CHECK_AGE / 3819: 年龄未达到 18。
INSERT INTO ct_employee (employee_no, employee_name, department_id, age)
VALUES ('E103', '年龄不合规', 10, 16);

-- ERROR CHECK_SALARY / 3819: 工资不能为负数；更新也会检查约束。
UPDATE ct_employee SET salary = -1 WHERE id = 2;

-- ERROR FOREIGN_KEY / 1452: 部门 99 不存在。
INSERT INTO ct_employee (employee_no, employee_name, department_id, age)
VALUES ('E104', '不存在的部门', 99, 25);

-- ERROR DELETE_RESTRICT / 1451: 技术部仍被员工引用。
DELETE FROM ct_department WHERE id = 10;

-- ERROR UPDATE_RESTRICT / 1451: 独立子表 ct_fk_restrict 仍引用父记录 1。
UPDATE ct_fk_parent SET id = 10 WHERE id = 1;
