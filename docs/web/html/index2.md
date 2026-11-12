rel是relationship（关系）的缩写，是HTML属性，用来描述“当前页面与链接目标之间是什么关系”。

例如，同样是链接一个文件，rel 决定它是样式表、图标，还是需要提前加载的资源：

```css
<link rel="stylesheet" href="/style.css">
<link rel="icon" href="/favicon.ico">
<link rel="preload" href="/cover.webp" as="image">
```

它主要影响资源加载、链接安全、SEO和页面语义。

## 基本规则

1. rel可用于`<link>`、`<a>`、`<area>`、`<form>`,但不同元素支持的值不同。

```html
<a
  href="https://example.com"
  target="_blank"
  rel="external noopener noreferrer"
>
  访问外部网站
</a>
```

规则如下：
  - 多个值用空格分隔，不使用逗号。
  - 关键字不区分大小写，通常写成小写。
  - 同一个值不应重复。
  - `href` 指定目标地址，`target` 指定打开位置，`rel` 指定关系或相关行为。
  - `rel` 允许扩展，因此不存在一个永远不变、涵盖所有生态的固定列表。

2. 资源加载相关的值

这一组都用于`<link>`。

| 值 | 作用 | 项目中的应用 |
|---|---|---|
| `stylesheet` | 加载并应用 CSS | 引入样式文件 |
| `icon` | 指定页面图标 | 浏览器标签页 favicon |
| `manifest` | 引入 Web App Manifest | 配置 PWA 名称、图标、启动方式等 |
| `preload` | 提前获取当前页面需要的资源 | 首屏字体、关键图片 |
| `modulepreload` | 提前获取、解析和编译 JavaScript 模块，供之后执行 | 提前准备 ES Module |
| `prefetch` | 提示浏览器获取后续可能需要的资源 | 用户可能访问的下一页 |
| `preconnect` | 提前建立连接，包括 DNS、TCP，HTTPS 下还包括 TLS | 关键 CDN、字体服务 |
| `dns-prefetch` | 提前解析域名 | 后续可能使用的第三方域名 |
| `compression-dictionary` | 获取后续资源压缩所用的共享字典 | 高级传输优化，支持范围需核实 |
| `expect` | 配合 `blocking="render"`，等待文档中的特定内容解析后再渲染 | 跨文档视图过渡等场景，需关注兼容性 |

例如：

```css
<!-- 正常加载并应用样式 -->
<link rel="stylesheet" href="/styles.css">

<!-- 提前准备当前页面需要的字体 -->
<link
  rel="preload"
  href="/fonts/main.woff2"
  as="font"
  type="font/woff2"
  crossorigin
>

<!-- 提前连接关键资源所在的服务器 -->
<link rel="preconnect" href="https://cdn.example.com" crossorigin>

<!-- 提前准备后续可能访问的页面 -->
<link rel="prefetch" href="/guide/next.html">
```

3. 安全和外链相关的值

这一组适用于 `<a>`、`<area>`、`<form>`。

| 值 | 作用 | 使用场景 |
|---|---|---|
| `noopener` | 让新打开的页面无法通过 `window.opener` 访问来源窗口 | 新窗口打开外链 |
| `noreferrer` | 不发送 `Referer` 请求头，同时具有 `noopener` 效果 | 不希望向目标站点透露来源 |
| `opener` | 显式保留新窗口与来源窗口的 opener 关系 | 确实需要窗口交互的场景 |
| `nofollow` | 表明不为目标内容背书，供搜索引擎解释 | 不可信链接等 |
| `external` | 标记目标属于其他站点 | 外链语义、CSS 选择器 |


需要保留来源统计时，可以这样写：

```html
<a href="https://example.com" target="_blank" rel="noopener">
  外部资料
</a>
```

需要隐藏来源时：

```html
<a
  href="https://example.com"
  target="_blank"
  rel="noopener noreferrer"
>
  外部资料
</a>
```

这里有几个关键区别：
  - noopener 不会主动移除 Referer；具体发送多少来源信息由 Referrer Policy 等决定。
  - noreferrer 会隐藏来源，可能影响对方的流量归因。
  - 现代浏览器的 target="_blank" 通常已隐含 noopener，显式声明仍便于表达意图。
  - nofollow 是搜索引擎处理链接的信号，不能保证目标页面不会被抓取或收录。
  - external 不会自动打开新标签页，也不会自动提供安全隔离。