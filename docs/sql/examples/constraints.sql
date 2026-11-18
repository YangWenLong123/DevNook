-- 第 13 章：约束。目标数据库：MySQL 8.0.16+、InnoDB。
-- 首次在练习环境执行；不包含 DROP TABLE，不会自动清空已存在的表。
-- 全文只包含应执行成功的 SQL；预期报错案例见 constraints-errors.sql。
-- ALTER TABLE / CREATE TABLE 会隐式提交；只有标出的 DML 事务会回滚。

-- SECTION SETUP: 三张业务表与初始数据。
CREATE DATABASE IF NOT EXISTS constraint_demo CHARACTER SET utf8mb4;
USE constraint_demo;
SET NAMES utf8mb4;

-- 严格模式使缺少必填值等问题直接报错，仅影响当前连接。
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';

CREATE TABLE ct_department (
    id INT PRIMARY KEY,
    department_name VARCHAR(30) NOT NULL,
    CONSTRAINT uk_ct_department_name UNIQUE (department_name)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE ct_employee (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_no VARCHAR(10) NOT NULL,
    employee_name VARCHAR(30) NOT NULL,
    email VARCHAR(100) NULL,
    department_id INT NULL,
    age TINYINT UNSIGNED NOT NULL,
    salary DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    employment_status VARCHAR(10) NOT NULL DEFAULT '在职',
    CONSTRAINT uk_ct_employee_email UNIQUE (email),
    CONSTRAINT uk_ct_employee_department_no UNIQUE (department_id, employee_no),
    CONSTRAINT chk_ct_employee_age CHECK (age BETWEEN 18 AND 65),
    CONSTRAINT chk_ct_employee_salary CHECK (salary >= 0),
    CONSTRAINT chk_ct_employee_status CHECK (employment_status IN ('在职', '离职')),
    CONSTRAINT fk_ct_employee_department
        FOREIGN KEY (department_id) REFERENCES ct_department(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE ct_employee_skill (
    employee_id INT NOT NULL,
    skill_code VARCHAR(20) NOT NULL,
    skill_level VARCHAR(10) NOT NULL DEFAULT '入门',
    PRIMARY KEY (employee_id, skill_code),
    CONSTRAINT fk_ct_skill_employee
        FOREIGN KEY (employee_id) REFERENCES ct_employee(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

INSERT INTO ct_department (id, department_name) VALUES
    (10, '技术部'), (20, '产品部'), (30, '财务部');

INSERT INTO ct_employee
    (id, employee_no, employee_name, email, department_id, age, salary)
VALUES
    (1, 'E001', '张三', 'zhang@example.com', 10, 28, 12000),
    (2, 'E002', '李四', NULL, 10, 24, 9000),
    (3, 'E001', '王五', 'wang@example.com', 20, 31, 11000);

-- 省略 salary / employment_status，分别使用默认值 0.00 / 在职。
INSERT INTO ct_employee
    (id, employee_no, employee_name, email, department_id, age)
VALUES (4, 'E001', '赵六', NULL, NULL, 22);

INSERT INTO ct_employee_skill (employee_id, skill_code, skill_level) VALUES
    (1, 'SQL', '熟练'), (1, 'Python', '入门'), (2, 'SQL', '入门');

-- SECTION DATA: 观察初始数据；结果按员工 ID 为张三、李四、王五、赵六。
SELECT e.id, e.employee_no, e.employee_name, e.email,
       d.department_name, e.age, e.salary, e.employment_status
FROM ct_employee AS e
LEFT JOIN ct_department AS d ON d.id = e.department_id
ORDER BY e.id;

-- SECTION NOT_NULL: 删除非空约束、处理 NULL，再恢复非空约束。
CREATE TABLE ct_not_null_demo (
    id INT PRIMARY KEY,
    note VARCHAR(30) NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

ALTER TABLE ct_not_null_demo MODIFY COLUMN note VARCHAR(30) NULL;
INSERT INTO ct_not_null_demo (id, note) VALUES (1, NULL);
UPDATE ct_not_null_demo SET note = '待补充' WHERE note IS NULL;
ALTER TABLE ct_not_null_demo MODIFY COLUMN note VARCHAR(30) NOT NULL;
SELECT id, note FROM ct_not_null_demo;

-- SECTION UNIQUE: 查看、删除、恢复单列唯一约束。
SHOW INDEX FROM ct_employee WHERE Non_unique = 0;
ALTER TABLE ct_employee DROP INDEX uk_ct_employee_email;
ALTER TABLE ct_employee
    ADD CONSTRAINT uk_ct_employee_email UNIQUE (email);

-- SECTION PRIMARY_KEY: 在独立表上添加、删除主键，避开自增与外键依赖。
CREATE TABLE ct_primary_key_demo (
    id INT NOT NULL,
    employee_name VARCHAR(30) NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

ALTER TABLE ct_primary_key_demo ADD PRIMARY KEY (id);
INSERT INTO ct_primary_key_demo (id, employee_name) VALUES (1, '张三');
ALTER TABLE ct_primary_key_demo DROP PRIMARY KEY;
-- 删除主键不会把 id 自动改为允许 NULL。
SHOW CREATE TABLE ct_primary_key_demo;

-- SECTION AUTO_INCREMENT: 自动生成 ID，然后删除自增属性，保留主键。
CREATE TABLE ct_auto_demo (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    employee_name VARCHAR(30) NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

INSERT INTO ct_auto_demo (employee_name) VALUES ('测试甲');
-- 同一连接、紧跟上述 INSERT 查询，结果为 1。
SELECT LAST_INSERT_ID() AS new_id;
INSERT INTO ct_auto_demo (employee_name) VALUES ('测试乙');
SELECT id, employee_name FROM ct_auto_demo ORDER BY id;
ALTER TABLE ct_auto_demo MODIFY COLUMN id INT NOT NULL;
INSERT INTO ct_auto_demo (id, employee_name) VALUES (100, '手动编号');

-- SECTION DEFAULT: 观察默认值、显式 NULL、修改默认值与删除默认值。
CREATE TABLE ct_default_demo (
    id INT PRIMARY KEY,
    employment_status VARCHAR(10) NOT NULL DEFAULT '在职',
    nickname VARCHAR(20) NULL DEFAULT '新员工'
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

INSERT INTO ct_default_demo (id) VALUES (1);
INSERT INTO ct_default_demo (id, nickname) VALUES (2, NULL);
ALTER TABLE ct_default_demo ALTER COLUMN employment_status SET DEFAULT '试用';
INSERT INTO ct_default_demo (id) VALUES (3);
-- 1: 在职 / 新员工；2: 在职 / NULL；3: 试用 / 新员工。
SELECT id, employment_status, nickname FROM ct_default_demo ORDER BY id;
ALTER TABLE ct_default_demo ALTER COLUMN employment_status DROP DEFAULT;

-- SECTION CHECK: 查看、删除、恢复检查约束。
SHOW CREATE TABLE ct_employee;
ALTER TABLE ct_employee DROP CHECK chk_ct_employee_age;
ALTER TABLE ct_employee
    ADD CONSTRAINT chk_ct_employee_age CHECK (age BETWEEN 18 AND 65);

-- SECTION FOREIGN_KEY: 查看外键、查看支持索引、删除并恢复外键。
SHOW CREATE TABLE ct_employee;
SELECT CONSTRAINT_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'ct_employee'
  AND REFERENCED_TABLE_NAME IS NOT NULL;

SHOW INDEX FROM ct_employee WHERE Column_name = 'department_id';
ALTER TABLE ct_employee DROP FOREIGN KEY fk_ct_employee_department;
ALTER TABLE ct_employee
    ADD CONSTRAINT fk_ct_employee_department
    FOREIGN KEY (department_id) REFERENCES ct_department(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- SECTION CASCADE: 删除员工，其技能记录跟随删除；最后回滚。
START TRANSACTION;
DELETE FROM ct_employee WHERE id = 1;
SELECT COUNT(*) AS skill_rows FROM ct_employee_skill WHERE employee_id = 1;
-- skill_rows = 0。
ROLLBACK;

-- SECTION FK_ACTION_SETUP: 用独立表比较三种外键动作。
CREATE TABLE ct_fk_parent (
    id INT PRIMARY KEY
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE ct_fk_restrict (
    id INT PRIMARY KEY,
    parent_id INT NOT NULL,
    CONSTRAINT fk_ct_restrict FOREIGN KEY (parent_id) REFERENCES ct_fk_parent(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE ct_fk_cascade (
    id INT PRIMARY KEY,
    parent_id INT NOT NULL,
    CONSTRAINT fk_ct_cascade FOREIGN KEY (parent_id) REFERENCES ct_fk_parent(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE ct_fk_set_null (
    id INT PRIMARY KEY,
    parent_id INT NULL,
    CONSTRAINT fk_ct_set_null FOREIGN KEY (parent_id) REFERENCES ct_fk_parent(id)
        ON DELETE SET NULL ON UPDATE SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

INSERT INTO ct_fk_parent (id) VALUES (1), (2), (3);
INSERT INTO ct_fk_restrict (id, parent_id) VALUES (1, 1);
INSERT INTO ct_fk_cascade (id, parent_id) VALUES (1, 2);
INSERT INTO ct_fk_set_null (id, parent_id) VALUES (1, 3);

-- SECTION FK_ACTIONS: 各轮事务都回滚，重复练习时仍保留原始数据。
START TRANSACTION;
UPDATE ct_fk_parent SET id = 20 WHERE id = 2;
SELECT id, parent_id FROM ct_fk_cascade;
-- parent_id = 20，ON UPDATE CASCADE 同步更新子表。
ROLLBACK;

START TRANSACTION;
DELETE FROM ct_fk_parent WHERE id = 2;
SELECT COUNT(*) AS child_rows FROM ct_fk_cascade;
-- child_rows = 0，ON DELETE CASCADE 删除子表记录。
ROLLBACK;

START TRANSACTION;
DELETE FROM ct_fk_parent WHERE id = 3;
SELECT id, parent_id FROM ct_fk_set_null;
-- parent_id = NULL，子表记录保留。
ROLLBACK;

-- SECTION METADATA: 汇总业务表的表级约束。
SELECT TABLE_NAME, CONSTRAINT_NAME, CONSTRAINT_TYPE
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('ct_department', 'ct_employee', 'ct_employee_skill')
ORDER BY TABLE_NAME, CONSTRAINT_TYPE, CONSTRAINT_NAME;
-- NOT NULL / DEFAULT / AUTO_INCREMENT 等列属性请看 SHOW CREATE TABLE / SHOW COLUMNS。
