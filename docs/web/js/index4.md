JavaScript 有 8 种数据类型：7 种原始类型和 1 种对象类型。判断类型时，主要用 typeof、`Array.isArray()`、`instanceof` 和 Object.prototype.toString.call()。


## JavaScript 的数据类型

| 分类 | 类型 | 示例 | `typeof` 结果 |
|---|---|---|---|
| 原始类型 | Undefined | `undefined` | `"undefined"` |
| 原始类型 | Null | `null` | `"object"` ⚠️ |
| 原始类型 | Boolean | `true`、`false` | `"boolean"` |
| 原始类型 | Number | `123`、`3.14`、`NaN` | `"number"` |
| 原始类型 | BigInt | `123n` | `"bigint"` |
| 原始类型 | String | `"hello"` | `"string"` |
| 原始类型 | Symbol | `Symbol("id")` | `"symbol"` |
| 对象类型 | Object | `{}`、`[]`、`new Date()` | `"object"` |

数组、函数、日期等都属于对象类型。 不过，`typeof` 判断函数时会返回 "function"：

```js
typeof (() => {}) // "function"
```

## 如何判断数据类型

1. typeof：适合判断大部分原始类型，以及函数

```js
typeof 123       // "number"
typeof "hello"   // "string"
typeof true      // "boolean"
typeof undefined // "undefined"
typeof 123n      // "bigint"
typeof Symbol()  // "symbol"
```

它有两个常见限制：

```js
typeof null // "object"，历史遗留问题

typeof {}   // "object"
typeof []   // "object"，无法区分数组和普通对象
```

2. 判断 null：直接用严格相等

```js
const value = null

value === null // true
```

3. 判断数组：优先用 Array.isArray()

```js
Array.isArray([]) // true
Array.isArray({}) // false
```

4. `instanceof`：判断对象的原型链是否包含某个构造函数的 `prototype`

```js
[] instanceof Array           // true
[] instanceof Object          // true
new Date() instanceof Date    // true

class Person {}
const person = new Person()

person instanceof Person      // true[] instanceof Array           // true
[] instanceof Object          // true
new Date() instanceof Date    // true

class Person {}
const person = new Person()

person instanceof Person      // true
```

它适合判断类实例，但不适合判断原始值：

```js
123 instanceof Number // false
```

5. `Object.prototype.toString.call()`：区分常见内置类型

```js
Object.prototype.toString.call(123)        // "[object Number]"
Object.prototype.toString.call("hello")    // "[object String]"
Object.prototype.toString.call(null)       // "[object Null]"
Object.prototype.toString.call(undefined)  // "[object Undefined]"
Object.prototype.toString.call([])         // "[object Array]"
Object.prototype.toString.call({})         // "[object Object]"
Object.prototype.toString.call(new Date()) // "[object Date]"
Object.prototype.toString.call(/abc/)      // "[object RegExp]"
```

实际开发中通常这样选：
- 原始类型、函数：用 typeof。
- null：用 value === null。
- 数组：用 Array.isArray(value)。
- 类实例：用 instanceof。
- 区分日期、正则等常见内置类型：用 Object.prototype.toString.call(value)。


另外，`NaN` 属于 number，判断它要用：

```js
Number.isNaN(NaN) // true
Number.isNaN(123) // false
```