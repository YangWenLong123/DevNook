/*
 * @Author: along
 * @Description: 
 * @Date: 2026-10-30 15:52:25
 * @LastEditors: along
 * @LastEditTime: 2026-11-24 14:16:04
 * @FilePath: /DevNook/docs/.vitepress/config.ts
 */
import { readdirSync, statSync } from 'node:fs'
import { resolve } from 'node:path'
import type { DefaultTheme, UserConfig } from 'vitepress'

const reactCollator = new Intl.Collator('zh-CN', { numeric: true })

// 文件夹作为分组，Markdown 文件名作为目录项，按章节编号自然排序。
function createReactItems(
  directory = resolve(__dirname, '../awesome_react-main'),
  base = '/awesome_react-main',
): DefaultTheme.SidebarItem[] {
  return readdirSync(directory, { withFileTypes: true })
    .sort((a, b) => reactCollator.compare(a.name, b.name))
    .flatMap((entry): DefaultTheme.SidebarItem[] => {
      const link = `${base}/${entry.name}`
      if (entry.isDirectory()) {
        const items = createReactItems(resolve(directory, entry.name), link)
        return items.length ? [{ text: entry.name, collapsed: true, items }] : []
      }
      return entry.isFile() && entry.name.endsWith('.md')
        ? [{ text: entry.name.slice(0, -3), link }]
        : []
    })
}

const reactSidebar: DefaultTheme.SidebarItem[] = [
  {
    text: 'React',
    items: [{ text: 'React', link: '/react/index.md' }],
  },
  ...createReactItems(),
]

export default {
  title: '大前端笔记',
  lastUpdated: true,
  markdown: {
    config(md) {
      const defaultFence = md.renderer.rules.fence!;
      md.renderer.rules.fence = (tokens, index, options, env, renderer) => {
        const token = tokens[index];
        if (token.info.trim().split(/\s+/)[0] === 'mermaid') {
          // 编码后作为组件属性传递，避免图表文本被当作 HTML 或 Vue 模板解析。
          return `<MermaidDiagram source="${encodeURIComponent(token.content)}" />\n`;
        }
        return defaultFence(tokens, index, options, env, renderer);
      };
    },
  },
  transformPageData(pageData, { siteConfig }) {
    if (pageData.frontmatter.lastUpdated !== false && !pageData.lastUpdated) {
      // 尚无 Git 提交记录的文档使用文件修改时间。
      pageData.lastUpdated = statSync(
        resolve(siteConfig.srcDir, pageData.filePath),
      ).mtimeMs;
    }
  },
  themeConfig: {
    outline: {
      level: [1, 4],
    },
    lastUpdated: {
      text: '最后更新于',
      formatOptions: {
        dateStyle: 'short',
        timeStyle: 'medium',
      },
    },
    nav: [{ text: '小记', link: '/record/index.md' }],
    sidebar: {
      '/record/': [
        {
          // text: '小记',
          items: [{ text: '认知', link: '/record/index.md' }],
        },
      ],
      '/web/html/': [
        {
          text: 'HTML5',
          // collapsed: false,
          items: [
            { text: '如何使用 Referrer', link: '/web/html/index.md' },
            { text: 'rel关键字', link: '/web/html/index2.md' },
          ],
        },
      ],
      '/web/css/': [
        {
          text: 'CSS3',
          items: [{ text: '三角形', link: '/web/css/index.md' }],
        },
      ],
      '/web/js/': [
        {
          text: 'JavaScript',
          items: [
            // { text: '标签页通信方案', link: '/web/js/index.md' },
            // { text: '如何解决系统更新页面不刷新', link: '/web/js/index2.md' },
            // { text: '笛卡尔乘积', link: '/web/js/index3.md' },
            { text: '数据类型', link: '/web/js/index4.md' },
            { text: '闭包', link: '/web/js/index5.md' },
          ],
        },
      ],
      '/es6/': [
        {
          text: 'ES6',
          items: [{ text: 'ES6', link: '/es6/index.md' }],
        },
      ],
      '/webapi/': [
        {
          text: 'Web Apis',
          items: [{ text: 'Web Apis', link: '/webapi/index.md' }],
        },
      ],
      '/ts/': [
        {
          text: 'Typescript',
          items: [
            { text: '为什么学习TypeScript', link: '/ts/index.md' },
            { text: '学习知识图谱', link: '/ts/ts-1.md' },
            { text: 'ts-2', link: '/ts/ts-2.md' },
            { text: '布尔值', link: '/ts/ts-3.md' },
            { text: '前言', link: '/ts/ts-4.md' },
            { text: '介绍', link: '/ts/ts-5.md' },
            { text: 'ts-6', link: '/ts/ts-6.md' },
            { text: '前言', link: '/ts/ts-7.md' },
            { text: '介绍', link: '/ts/ts-8.md' },
            { text: '介绍', link: '/ts/ts-9.md' },
            { text: '前言', link: '/ts/ts-10.md' },
            { text: '前言', link: '/ts/ts-11.md' },
            { text: '函数声明', link: '/ts/ts-12.md' },
            { text: '前言', link: '/ts/ts-13.md' },
            { text: '前言', link: '/ts/ts-14.md' },
            { text: '什么是字面量？', link: '/ts/ts-15.md' },
            {
              text: '模板字面量类型（Template Literal Types）',
              link: '/ts/ts-16.md',
            },
            { text: '前言', link: '/ts/ts-17.md' },
            { text: '案例代码1：使用Map内置对象', link: '/ts/ts-18.md' },
            { text: '前言', link: '/ts/ts-19.md' },
            { text: '泛型', link: '/ts/ts-20.md' },
            { text: '前言', link: '/ts/ts-21.md' },
            { text: '前言', link: '/ts/ts-22.md' },
            { text: '前言', link: '/ts/ts-23.md' },
            { text: 'ts-24', link: '/ts/ts-24.md' },
            { text: 'ts-25', link: '/ts/ts-25.md' },
            { text: '前言', link: '/ts/ts-26.md' },
            { text: 'ts-27', link: '/ts/ts-27.md' },
            { text: '编译上下文', link: '/ts/ts-28.md' },
            { text: 'ts-29', link: '/ts/ts-29.md' },
            { text: '前言', link: '/ts/ts-30.md' },
            { text: '前言', link: '/ts/ts-31.md' },
            { text: 'ts-32', link: '/ts/ts-32.md' },
            { text: 'ts-33', link: '/ts/ts-33.md' },
            { text: 'ts-34', link: '/ts/ts-34.md' },
            { text: 'ts-35', link: '/ts/ts-35.md' },
          ],
        },
      ],
      '/design/': [
        {
          text: '设计模式',
          items: [{ text: '设计模式', link: '/design/index.md' }],
        },
      ],
      '/vue3/': [
        {
          text: 'Vue3',
          items: [
            { text: '介绍', link: '/vue3/index.md' },
            { text: '尤大大的github', link: '/vue3/index1.md' },
            { text: '介绍', link: '/vue3/index2.md' },
            {
              text: '生命周期 2.x 与 Composition 之间的映射关系',
              link: '/vue3/index3.md',
            },
            { text: '基本使用', link: '/vue3/index4.md' },
            { text: 'ref()', link: '/vue3/index5.md' },
            { text: 'reactive()', link: '/vue3/index6.md' },
            { text: 'computed()', link: '/vue3/index7.md' },
            { text: 'readonly()', link: '/vue3/index8.md' },
            { text: 'watchEffect', link: '/vue3/index9.md' },
            { text: 'watch', link: '/vue3/index10.md' },
            { text: 'isRef()', link: '/vue3/index11.md' },
            { text: 'shallowRef', link: '/vue3/index12.md' },
            { text: 'triggerRef', link: '/vue3/index13.md' },
            { text: 'customRef', link: '/vue3/index14.md' },
            { text: 'shallowReactive', link: '/vue3/index15.md' },
            { text: 'shallowReadonly', link: '/vue3/index16.md' },
            { text: 'toRaw', link: '/vue3/index17.md' },
            { text: 'markRaw', link: '/vue3/index18.md' },
            { text: 'effectScope', link: '/vue3/index19.md' },
            { text: 'getCurrentScope', link: '/vue3/index20.md' },
            { text: 'onScopeDispose', link: '/vue3/index21.md' },
            { text: '手写功能函数', link: '/vue3/index22.md' },
            { text: 'unref()', link: '/vue3/index23.md' },
            { text: 'toRef()', link: '/vue3/index24.md' },
            { text: 'toRefs()', link: '/vue3/index25.md' },
            {
              text: 'toValue() <sup style="color:#42b883">3.3+</sup>',
              link: '/vue3/index26.md',
            },
            { text: 'isProxy()', link: '/vue3/index27.md' },
            { text: 'isReactive()', link: '/vue3/index28.md' },
            { text: 'isReadonly()', link: '/vue3/index29.md' },
            { text: 'Effect Scope API实战', link: '/vue3/index30.md' },
            { text: '依赖注入', link: '/vue3/index31.md' },
            { text: 'version', link: '/vue3/index32.md' },
            { text: 'nextTick', link: '/vue3/index33.md' },
            { text: 'defineComponent', link: '/vue3/index34.md' },
            { text: 'defineAsyncComponent()', link: '/vue3/index35.md' },
            { text: 'defineCustomElement', link: '/vue3/index36.md' },
            { text: '前言', link: '/vue3/index37.md' },
            { text: '前言', link: '/vue3/index38.md' },
            { text: '资讯', link: '/vue3/index39.md' },
            { text: 'V3源码', link: '/vue3/index40.md' },
            { text: 'Teleport', link: '/vue3/index41.md' },
            { text: 'Suspense', link: '/vue3/index42.md' },
            { text: '前言', link: '/vue3/index43.md' },
            { text: 'index44', link: '/vue3/index44.md' },
            { text: '介绍', link: '/vue3/index45.md' },
            { text: 'Fragments', link: '/vue3/index46.md' },
            { text: '更新日志', link: '/vue3/index47.md' },
            { text: 'setup', link: '/vue3/index48.md' },
            { text: 'index49', link: '/vue3/index49.md' },
            { text: 'index50', link: '/vue3/index50.md' },
            { text: 'index51', link: '/vue3/index51.md' },
            { text: 'index52', link: '/vue3/index52.md' },
            { text: 'index53', link: '/vue3/index53.md' },
            { text: 'index54', link: '/vue3/index54.md' },
            { text: 'index55', link: '/vue3/index55.md' },
            { text: 'index56', link: '/vue3/index56.md' },
            { text: 'index57', link: '/vue3/index57.md' },
            { text: '首字母大写', link: '/vue3/index58.md' },
            { text: 'Prop 验证', link: '/vue3/index59.md' },
            { text: '可写的计算属性', link: '/vue3/index60.md' },
            { text: 'watch 全家桶', link: '/vue3/index61.md' },
            { text: '浅层 ref', link: '/vue3/index62.md' },
            { text: '切换器', link: '/vue3/index63.md' },
            { text: '计数器', link: '/vue3/index64.md' },
            { text: '切换焦点指令', link: '/vue3/index65.md' },
            { text: '防抖点击指令', link: '/vue3/index66.md' },
            { text: '按键修饰符', link: '/vue3/index67.md' },
            { text: '鼠标坐标', link: '/vue3/index68.md' },
            { text: '全局 CSS', link: '/vue3/index69.md' },
            { text: '迁移变化内容', link: '/vue3/index70.md' },
            { text: 'Effect 作用域 API', link: '/vue3/index71.md' },
            { text: '树组件', link: '/vue3/index72.md' },
            { text: '实现简易版 v-model 指令', link: '/vue3/index73.md' },
            { text: 'index74', link: '/vue3/index74.md' },
            { text: 'index75', link: '/vue3/index75.md' },
            { text: 'index76', link: '/vue3/index76.md' },
            { text: 'index77', link: '/vue3/index77.md' },
            { text: 'index78', link: '/vue3/index78.md' },
            { text: 'index79', link: '/vue3/index79.md' },
            { text: 'index80', link: '/vue3/index80.md' },
          ],
        },
      ],
      '/react/': reactSidebar,
      '/awesome_react-main/': reactSidebar,
      '/performance/': [
        {
          text: '前端性能优化',
          items: [{ text: '前端性能优化', link: '/performance/index.md' }],
        },
      ],
      '/project/': [
        {
          text: '前端工程化建设',
          items: [
            { text: '前端工程化建设', link: '/project/index.md' },
            { text: 'VitePress 宝塔部署', link: '/project/deploy-baota.md' },
          ],
        },
      ],
      '/safety/': [
        {
          text: '前端安全',
          items: [{ text: '前端安全', link: '/safety/index.md' }],
        },
      ],
      '/uniapp/': [
        {
          text: 'uniapp跨端开发',
          items: [{ text: 'uniapp跨端开发', link: '/uniapp/index.md' }],
        },
      ],
      '/algorithm/': [
        {
          text: '数据结构与算法',
          items: [
            { text: '能解决什么？', link: '/algorithm/index.md' },
            { text: '介绍', link: '/algorithm/index-0.md' },
            { text: '介绍', link: '/algorithm/index-1.md' },
            { text: '介绍', link: '/algorithm/index-2.md' },
            { text: '介绍', link: '/algorithm/index-3.md' },
            { text: '介绍', link: '/algorithm/index-4.md' },
            { text: '前言', link: '/algorithm/index-5.md' },
            { text: '介绍', link: '/algorithm/index-6.md' },
            { text: '树数据结构', link: '/algorithm/index-7.md' },
            { text: 'index-8', link: '/algorithm/index-8.md' },
            { text: '冒泡排序', link: '/algorithm/index-9.md' },
            {
              text: '例：数组值为字符，使用new Set()去重，适用于基本数据类型，引用类型不可以',
              link: '/algorithm/index-10.md',
            },
            { text: '前言', link: '/algorithm/index-11.md' },
            { text: '介绍', link: '/algorithm/index-12.md' },
            { text: '前言', link: '/algorithm/index-13.md' },
            { text: '动态规划', link: '/algorithm/index-14.md' },
            { text: 'index-15', link: '/algorithm/index-15.md' },
            { text: 'index-16', link: '/algorithm/index-16.md' },
            { text: 'index-17', link: '/algorithm/index-17.md' },
            { text: '示例', link: '/algorithm/index-18.md' },
            { text: '描述', link: '/algorithm/index-19.md' },
            { text: '描述', link: '/algorithm/index-20.md' },
            { text: '描述', link: '/algorithm/index-21.md' },
            { text: '描述', link: '/algorithm/index-22.md' },
            { text: '描述', link: '/algorithm/index-23.md' },
            { text: 'index-24', link: '/algorithm/index-24.md' },
            { text: '查询星座', link: '/algorithm/index-25.md' },
            { text: '前言', link: '/algorithm/index-141.md' },
          ],
        },
      ],
      '/http/': [
        {
          text: 'HTTP小册',
          items: [
            { text: 'HTTP 概述', link: '/http/http1.md' },
            { text: 'index', link: '/http/index.md' },
            { text: 'HTTP 的发展', link: '/http/http2.md' },
            { text: 'HTTP 消息', link: '/http/http3.md' },
            { text: '典型的 HTTP 会话', link: '/http/http4.md' },
            { text: '内容安全策略（CSP）', link: '/http/http5.md' },
            { text: 'Strict-Transport-Security', link: '/http/http6.md' },
            { text: 'HTTP Cookie', link: '/http/http7.md' },
            { text: 'X-Content-Type-Options', link: '/http/http8.md' },
            { text: 'X-Frame-Options', link: '/http/http9.md' },
            { text: 'http10', link: '/http/http10.md' },
            { text: 'http11', link: '/http/http11.md' },
            { text: 'http12', link: '/http/http12.md' },
            { text: 'http13', link: '/http/http13.md' },
            { text: 'http14', link: '/http/http14.md' },
            { text: 'http15', link: '/http/http15.md' },
            { text: 'http16', link: '/http/http16.md' },
            { text: 'http17', link: '/http/http17.md' },
            { text: 'http18', link: '/http/http18.md' },
            { text: '缓存介绍', link: '/http/http19.md' },
            { text: '介绍', link: '/http/http20.md' },
            { text: '前言', link: '/http/http21.md' },
            { text: '协商缓存', link: '/http/http22.md' },
            { text: '前言', link: '/http/http23.md' },
            { text: '什么是 Nginx', link: '/http/http24.md' },
            { text: 'http25', link: '/http/http25.md' },
            { text: 'http26', link: '/http/http26.md' },
            { text: 'http27', link: '/http/http27.md' },
            { text: 'http28', link: '/http/http28.md' },
            { text: 'http29', link: '/http/http29.md' },
            { text: 'http30', link: '/http/http30.md' },
            { text: 'http31', link: '/http/http31.md' },
            { text: 'http32', link: '/http/http32.md' },
            { text: 'http33', link: '/http/http33.md' },
            { text: 'http34', link: '/http/http34.md' },
            { text: 'http35', link: '/http/http35.md' },
            { text: 'http36', link: '/http/http36.md' },
            { text: 'http37', link: '/http/http37.md' },
            { text: 'http38', link: '/http/http38.md' },
            { text: 'http39', link: '/http/http39.md' },
            { text: 'http40', link: '/http/http40.md' },
            { text: 'http41', link: '/http/http41.md' },
            { text: 'http42', link: '/http/http42.md' },
            { text: 'http43', link: '/http/http43.md' },
            { text: 'http44', link: '/http/http44.md' },
            { text: 'http45', link: '/http/http45.md' },
            { text: 'http46', link: '/http/http46.md' },
            { text: 'http47', link: '/http/http47.md' },
            { text: 'http48', link: '/http/http48.md' },
            { text: 'http49', link: '/http/http49.md' },
            { text: 'http50', link: '/http/http50.md' },
          ],
        },
      ],
      '/linux/': [
        {
          text: 'Linux手册',
          items: [
            { text: '什么是Linux？', link: '/linux/index.md' },
            { text: 'linux-1', link: '/linux/linux-1.md' },
            { text: 'linux-2', link: '/linux/linux-2.md' },
            { text: 'Linux 中的 ls 命令', link: '/linux/linux-3.md' },
            { text: 'Linux 中的 cd 命令', link: '/linux/linux-4.md' },
            { text: 'Linux 中的 pwd 命令', link: '/linux/linux-5.md' },
            { text: 'Linux 中的 mkdir 命令', link: '/linux/linux-6.md' },
            { text: 'Linux 中的 rmdir 命令', link: '/linux/linux-7.md' },
            { text: 'Linux 中的 mv 命令', link: '/linux/linux-8.md' },
            { text: 'Linux 中的 cp 命令', link: '/linux/linux-9.md' },
            { text: 'Linux 中的 open 命令', link: '/linux/linux-10.md' },
            { text: 'Linux 中的 touch 命令', link: '/linux/linux-11.md' },
            { text: 'Linux 中的 find 命令', link: '/linux/linux-12.md' },
            { text: 'Linux 中的  ln  命令', link: '/linux/linux-13.md' },
            { text: 'Linux 中的  gzip  命令', link: '/linux/linux-14.md' },
            { text: 'Linux 中的  gunzip  命令', link: '/linux/linux-15.md' },
            { text: 'Linux 中的  tar  命令', link: '/linux/linux-16.md' },
            { text: 'Linux 中的  alias  命令', link: '/linux/linux-17.md' },
            { text: 'Linux 中的  cat  命令', link: '/linux/linux-18.md' },
            { text: 'Linux 中的  less  命令', link: '/linux/linux-19.md' },
            { text: 'Linux 中的  tail  命令', link: '/linux/linux-20.md' },
            { text: 'Linux 中的  wc  命令', link: '/linux/linux-21.md' },
            { text: 'Linux 中的  grep  命令', link: '/linux/linux-22.md' },
            { text: 'Linux 中的  sort  命令', link: '/linux/linux-23.md' },
            { text: 'Linux 中的  uniq  命令', link: '/linux/linux-24.md' },
            { text: 'Linux 中的  diff  命令', link: '/linux/linux-25.md' },
            { text: 'Linux 中的  echo  命令', link: '/linux/linux-26.md' },
            { text: 'Linux 中的  chown  命令', link: '/linux/linux-27.md' },
            { text: 'Linux 中的  chmod  命令', link: '/linux/linux-28.md' },
            { text: 'Linux 中的  umask  命令', link: '/linux/linux-29.md' },
            { text: 'Linux 中的  du  命令', link: '/linux/linux-30.md' },
            { text: 'Linux 中的  df  命令', link: '/linux/linux-31.md' },
            { text: 'Linux 中的  basename  命令', link: '/linux/linux-32.md' },
            { text: 'Linux 中的  dirname  命令', link: '/linux/linux-33.md' },
            { text: 'Linux 中的  ps  命令', link: '/linux/linux-34.md' },
            { text: 'Linux 中的  top  命令', link: '/linux/linux-35.md' },
            { text: 'Linux 中的  kill  命令', link: '/linux/linux-36.md' },
            { text: 'Linux 中的  killall  命令', link: '/linux/linux-37.md' },
            { text: 'Linux 中的  jobs  命令', link: '/linux/linux-38.md' },
            { text: 'Linux 中的  bg  命令', link: '/linux/linux-39.md' },
            { text: 'Linux 中的  fg  命令', link: '/linux/linux-40.md' },
            { text: 'Linux 中的  type  命令', link: '/linux/linux-41.md' },
            { text: 'Linux 中的  which  命令', link: '/linux/linux-42.md' },
            { text: 'Linux 中的  nohup  命令', link: '/linux/linux-43.md' },
            { text: 'Linux 中的  xargs  命令', link: '/linux/linux-44.md' },
            { text: 'Linux 中的  vim  编辑器命令', link: '/linux/linux-45.md' },
            {
              text: 'Linux 中的  emacs  编辑器命令',
              link: '/linux/linux-46.md',
            },
            {
              text: 'Linux 中的  nano  编辑器命令',
              link: '/linux/linux-47.md',
            },
            { text: 'Linux 中的  whoami  命令', link: '/linux/linux-48.md' },
            { text: 'Linux 中的  who  命令', link: '/linux/linux-49.md' },
            { text: 'Linux 中的  su  命令', link: '/linux/linux-50.md' },
            { text: 'Linux 中的  sudo  命令', link: '/linux/linux-51.md' },
            { text: 'Linux 中的  passwd  命令', link: '/linux/linux-52.md' },
            { text: 'Linux 中的  ping  命令', link: '/linux/linux-53.md' },
            {
              text: 'Linux 中的  traceroute  命令',
              link: '/linux/linux-54.md',
            },
            { text: 'Linux 中的  clear  命令', link: '/linux/linux-55.md' },
            { text: 'Linux 中的  history  命令', link: '/linux/linux-56.md' },
            { text: 'Linux 中的  export  命令', link: '/linux/linux-57.md' },
            { text: 'Linux 中的  crontab  命令', link: '/linux/linux-58.md' },
            { text: 'Linux 中的  uname  命令', link: '/linux/linux-59.md' },
            { text: 'Linux 中的  env  命令', link: '/linux/linux-60.md' },
            { text: 'Linux 中的  printenv  命令', link: '/linux/linux-61.md' },
          ],
        },
      ],
      '/nestjs/': [
        {
          text: 'NestJS通关秘籍',
          items: [{ text: 'NestJS通关秘籍', link: '/nestjs/index.md' }],
        },
      ],
      '/python/': [
        {
          text: 'Python语法通关',
          items: [
            { text: 'Python初始', link: '/python/index.md' },
            { text: '数据的存储与运算', link: '/python/index2.md' },
            { text: '数据的逻辑处理', link: '/python/index3.md' },
            { text: '数据存储容器', link: '/python/index4.md' },
            { text: '列表推导式', link: '/python/index5.md' },
            { text: '函数与作用域', link: '/python/index6.md' },
            { text: '面向对象基础', link: '/python/index7.md' },
            { text: '模块', link: '/python/index8.md' },
            { text: '枚举', link: '/python/index9.md' },
            { text: '闭包', link: '/python/index10.md' },
            { text: '装饰器', link: '/python/index11.md' },
            { text: '异常处理', link: '/python/index12.md' },
            { text: 'async与await', link: '/python/index13.md' },
            { text: 'pyproject.toml + uv', link: '/python/index14.md' },
            { text: '日志logging', link: '/python/index15.md' },
            { text: '打包发布PyPI', link: '/python/index16.md' },
            { text: 'HTTP请求与传参实战', link: '/python/index17.md' },
          ],
        },
      ],
      '/sql/': [
        {
          text: 'MySQL',
          items: [
            { text: 'MySQL常用命令', link: '/sql/index1.md' },
            { text: '可视化工具Navicat', link: '/sql/index2.md' },
            { text: 'SQL基础语法', link: '/sql/index3.md' },
            { text: 'MySQL的数据类型', link: '/sql/index4.md' },
            { text: '运算符', link: '/sql/index5.md' },
            { text: '表的关系', link: '/sql/index6.md' },
            { text: '函数', link: '/sql/index7.md' },
            { text: '关联查询', link: '/sql/index8.md' },
            { text: 'select的7个子句', link: '/sql/index9.md' },
            { text: '子查询', link: '/sql/index10.md' },
            { text: '约束', link: '/sql/index11.md' },
            { text: '事物', link: '/sql/index12.md' },
          ],
        },
      ],

      '/fastApi/': [
        {
          text: 'FastApi',
          items: [
            { text: 'FastAPI介绍', link: '/fastApi/index.md' },
            { text: '环境搭建', link: '/fastApi/index1.md' },
            { text: '类型提示', link: '/fastApi/index2.md' },
            { text: '启动命令', link: '/fastApi/index3.md' },
            { text: 'Pydantic数据验证', link: '/fastApi/index4.md' },
            { text: '请求数据的方式', link: '/fastApi/index5.md' },
            { text: 'APIRouter', link: '/fastApi/index6.md' },
            { text: '数据库连接配置', link: '/fastApi/index7.md' },
            { text: '流式传输 JSON Lines', link: '/fastApi/index8.md' },
            // { text: '07. 用户登录与权限', link: '/fastApi/index7.md' },
            // { text: '08. 项目结构与配置', link: '/fastApi/index8.md' },
            // { text: '09. 异步与常见集成', link: '/fastApi/index9.md' },
            // { text: '10. 接口测试', link: '/fastApi/index10.md' },
            // { text: '11. 部署与运行', link: '/fastApi/index11.md' },
            // { text: '12. 进阶专题', link: '/fastApi/index12.md' },
            // { text: '13. 任务管理API实战', link: '/fastApi/index13.md' },
          ],
        },
      ],
      '/agent/': [
        {
          text: 'Agent通关秘籍',
          items: [{ text: 'Agent通关秘籍', link: '/agent/index.md' }],
        },
      ],
      '/aiGuide/': [
        {
          text: 'Ai编程指南',
          items: [{ text: 'Ai编程指南', link: '/aiGuide/index.md' }],
        },
      ],
    },
  },
} satisfies UserConfig<DefaultTheme.Config>;
