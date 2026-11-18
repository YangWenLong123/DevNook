## 事务的特点

事务处理：保证所有事务都作为一个工作单元来执行，即使出现了故障，都不能改变这种执行方式。当在一个事务中执行多个操作时，要么所有的事务都被提交(commit)，那么这些修改就永久地保存下来；要么数据库管理系统将放弃所作的所有修改，整个事务回滚(rollback)到最初状态。

事务的ACID属性：
  - 原子性（Atomicity）：原子性是指事务是一个不可分割的工作单位，事务中的操作要么都发生，要么都不发生
    - 张三给李四转账500
    - 张三转账之前余额是1000
    - 李四转账之前余额是1000
    - 成功：张三账号变为500，李四变为1500
    - 失败：张三账号是1000，李四还是1000
  - 一致性（Consistency）：事务必须使数据库从一个一致性状态变换到另外一个一致性状态
      - 张三给李四转账500
      - 张三转账之前余额是1000
      - 李四转账之前余额是1000
      - 要么他俩的余额不变， 还是1000，总和就是2000
      - 要么他俩的余额有变化，张三500，李四1500，总和仍然是2000
      - 错误：
        - 张三500，李四1000，总和是1500，结果不对
        - 张三1000，李四1500，总和是2500，结果不对
  - 隔离性（Isolation）：事务的隔离性是指一个事务的执行不能被其他事务干扰，即一个事务内部的操作及使用的数据对并发的其他事务是隔离的，并发执行的各个事务之间不能互相干扰
    - 张三要给李四转500
    - 王五要给李四转500
    - 张三转账是否成功，和王五是否转账成功无关
  - 持久性（Durability）：持久性是指一个事务一旦被提交，它对数据库中数据的改变就是永久性的，接下来的其他操作和数据库故障不应该对其有任何影响
    - 张三要给李四转500，一旦成功提交，就转账成功，撤不回来了


## 事务的开启、提交、回滚

MySQL默认情况下是自动提交事务。每一条语句都是一个独立的事务，一旦成功就提交了。一条语句失败，单独一条语句不生效，其他语句是生效的。

### 手动提交模式

```SQL
-- 开启手动提交事务模式
set autocommit=false;
-- 或
set autocommit=0;
-- 上述语句执行之后，它之后的所有SQL，都需要手动提交才能生效，直到恢复自动提交模式
-- 恢复自动提交模式
set autocommit=true;
-- 或
set autocommit=1;
```

### 自动提交模式下开始起事务

```SQL
start transaction;
...

commit; 或 rollback; --(提交或回滚)
```

### 案例

```SQL
CREATE TABLE account_demo (
    id INT PRIMARY KEY,
    account_name VARCHAR(30) NOT NULL,
    balance DECIMAL(10, 2) NOT NULL
) ENGINE = InnoDB;

INSERT INTO account_demo (id, account_name, balance)
VALUES
    (1, '张三', 1000.00),
    (2, '李四', 500.00);
		
SELECT * FROM account_demo;
		
		
-- 张三向李四转账 200 元，两次余额更新必须一起成功，或者一起撤销。

-- 1. 开启事务
START TRANSACTION;

-- 2. 张三扣款；余额足够才扣款
UPDATE account_demo SET balance = balance - 200 WHERE id = 1 AND balance >= 200;

-- 检查受影响行数：1 表示扣款成功，0 表示未扣款
SELECT ROW_COUNT() AS affected_rows;

-- 3. 李四收款
UPDATE account_demo SET balance = balance + 200 WHERE id = 2;

-- 应为 1；如果不是 1，或执行报错，执行 ROLLBACK
SELECT ROW_COUNT() AS affected_rows;

-- 4. 提交事务，永久保存转账结果
COMMIT;

SELECT * FROM account_demo ORDER BY id;
```

| id | account_name | balance |
|---|---|---|
| 1 | 张三 | 800.00 |
| 2 | 李四 | 700.00 |