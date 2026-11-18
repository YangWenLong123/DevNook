-- 学生表：常见约束综合案例。适用于 MySQL 8.0.16+、InnoDB。
-- 先在客户端选择练习数据库，例如 USE db_01;，然后执行本文件。
-- 首次执行使用；不自动删除已有同名表。
-- 主表 demo_student 集中演示约束；demo_class 仅作为外键引用的班级表。
SET NAMES utf8mb4;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';

-- SECTION SCHEMA: 建表。
CREATE TABLE demo_class (
    class_id INT PRIMARY KEY COMMENT '班级编号',
    class_name VARCHAR(30) NOT NULL COMMENT '班级名称',
    CONSTRAINT uk_demo_class_name UNIQUE (class_name)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE demo_student (
    student_id INT AUTO_INCREMENT COMMENT '自动生成的学生 ID',
    student_no VARCHAR(20) NOT NULL COMMENT '学号',
    student_name VARCHAR(30) NOT NULL COMMENT '姓名',
    gender CHAR(1) NOT NULL DEFAULT '男' COMMENT '性别',
    age TINYINT UNSIGNED NOT NULL COMMENT '年龄',
    email VARCHAR(100) NULL COMMENT '邮箱，允许暂不填写',
    class_id INT NOT NULL COMMENT '所属班级',
    seat_no INT NOT NULL COMMENT '班内座位号',
    tuition DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT '学费',

    PRIMARY KEY (student_id),
    CONSTRAINT uk_demo_student_no UNIQUE (student_no),
    CONSTRAINT uk_demo_student_email UNIQUE (email),
    CONSTRAINT uk_demo_student_class_seat UNIQUE (class_id, seat_no),
    CONSTRAINT chk_demo_student_name
        CHECK (CHAR_LENGTH(TRIM(student_name)) > 0),
    CONSTRAINT chk_demo_student_gender CHECK (gender IN ('男', '女')),
    CONSTRAINT chk_demo_student_age CHECK (age BETWEEN 18 AND 60),
    CONSTRAINT chk_demo_student_seat CHECK (seat_no BETWEEN 1 AND 60),
    CONSTRAINT chk_demo_student_tuition CHECK (tuition >= 0),
    CONSTRAINT fk_demo_student_class
        FOREIGN KEY (class_id) REFERENCES demo_class(class_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- SECTION DATA: 先插入班级，再插入学生。
INSERT INTO demo_class (class_id, class_name) VALUES
    (101, 'SQL一班'), (102, 'SQL二班');

-- 省略 student_id、gender、tuition：分别使用自增编号、男、0.00。
INSERT INTO demo_student
    (student_no, student_name, age, email, class_id, seat_no)
VALUES
    ('S001', '张三', 20, 'zhang@example.com', 101, 1),
    ('S002', '李四', 21, NULL, 101, 2);

-- 班级不同，可以同样使用座位号 1；两个 NULL 邮箱可以共存。
INSERT INTO demo_student
    (student_no, student_name, gender, age, email, class_id, seat_no, tuition)
VALUES ('S003', '王五', '女', 22, NULL, 102, 1, 1500.00);

-- SECTION QUERY: 查看结果。
SELECT student_id, student_no, student_name, gender, age, email,
       class_id, seat_no, tuition
FROM demo_student
ORDER BY student_id;

-- SECTION METADATA: 查看约束名称与类型；列属性看 SHOW CREATE TABLE。
SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE, ENFORCED
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'demo_student'
ORDER BY CONSTRAINT_TYPE, CONSTRAINT_NAME;

SHOW CREATE TABLE demo_student;

-- 以下均为预期报错案例，已注释；请每次只选一条，去掉注释后执行。
-- 这些规则也适用于 UPDATE，并非只在 INSERT 时检查。

-- ERROR NOT_NULL / 1048: 姓名必填。
-- INSERT INTO demo_student (student_no, student_name, age, class_id, seat_no)
-- VALUES ('S004', NULL, 20, 101, 3);

-- ERROR EMPTY_NAME / 3819: NOT NULL 配合 CHECK，姓名也不能是空白。
-- INSERT INTO demo_student (student_no, student_name, age, class_id, seat_no)
-- VALUES ('S004', '   ', 20, 101, 3);

-- ERROR UNIQUE / 1062: 学号 S001 已存在。
-- INSERT INTO demo_student (student_no, student_name, age, class_id, seat_no)
-- VALUES ('S001', '重复学号', 20, 101, 3);

-- ERROR PRIMARY_KEY / 1062: 学生 ID 1 已存在。
-- INSERT INTO demo_student (student_id, student_no, student_name, age, class_id, seat_no)
-- VALUES (1, 'S004', '重复主键', 20, 101, 3);

-- ERROR EMAIL / 1062: 非 NULL 邮箱不得重复。
-- INSERT INTO demo_student (student_no, student_name, age, email, class_id, seat_no)
-- VALUES ('S004', '重复邮箱', 20, 'zhang@example.com', 101, 3);

-- ERROR COMPOSITE_UNIQUE / 1062: 同一班级的座位号不能重复。
-- INSERT INTO demo_student (student_no, student_name, age, class_id, seat_no)
-- VALUES ('S004', '重复座位', 20, 101, 1);

-- ERROR CHECK_AGE / 3819: 本例的年龄范围规定为 18～60 岁。
-- INSERT INTO demo_student (student_no, student_name, age, class_id, seat_no)
-- VALUES ('S004', '年龄越界', 17, 101, 3);

-- ERROR CHECK_TUITION / 3819: 学费不能为负数。
-- UPDATE demo_student SET tuition = -1 WHERE student_id = 1;

-- ERROR FOREIGN_KEY / 1452: 班级 999 不存在。
-- INSERT INTO demo_student (student_no, student_name, age, class_id, seat_no)
-- VALUES ('S004', '班级不存在', 20, 999, 3);

-- ERROR DELETE_RESTRICT / 1451: 班级 101 仍有学生，不能删除。
-- DELETE FROM demo_class WHERE class_id = 101;
