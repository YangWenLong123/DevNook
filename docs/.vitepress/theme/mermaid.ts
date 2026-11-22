let renderQueue: Promise<unknown> = Promise.resolve()
let diagramId = 0

export function renderMermaid(source: string, dark: boolean): Promise<string> {
  // 同页多个图表共享 Mermaid 配置，串行初始化和渲染以避免主题互相覆盖。
  const task = renderQueue.then(async () => {
    const { default: mermaid } = await import('mermaid')
    mermaid.initialize({
      startOnLoad: false,
      securityLevel: 'strict',
      suppressErrorRendering: true,
      htmlLabels: false,
      theme: 'base',
      darkMode: dark,
      fontFamily: 'var(--vp-font-family-base)',
      themeVariables: {
        background: dark ? '#1b1b1f' : '#ffffff',
        primaryColor: dark ? '#253247' : '#eef4ff',
        primaryTextColor: dark ? '#e5e7eb' : '#1f2937',
        primaryBorderColor: dark ? '#8aafff' : '#4267a8',
        lineColor: dark ? '#a3b2c7' : '#64748b',
        secondaryColor: dark ? '#263c35' : '#edf7f2',
        tertiaryColor: dark ? '#353047' : '#f5f0ff',
        noteBkgColor: dark ? '#353047' : '#f5f0ff',
        noteTextColor: dark ? '#e5e7eb' : '#1f2937',
      },
    })
    const { svg } = await mermaid.render(`mermaid-diagram-${++diagramId}`, source)
    return svg
  })

  // 一张图语法错误时，后续图表仍然可以继续渲染。
  renderQueue = task.catch(() => undefined)
  return task
}
