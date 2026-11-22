<script setup lang="ts">
import { useData } from 'vitepress'
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { renderMermaid } from '../mermaid'

const props = defineProps<{ source: string }>()
const { isDark } = useData()
const source = computed(() => decodeURIComponent(props.source))
const viewport = ref<HTMLDivElement>()
const content = ref<HTMLDivElement>()
const svg = ref('')
const loading = ref(true)
const failed = ref(false)
const width = ref(0)
const height = ref(0)
const scale = ref(1)
const fitScale = ref(1)
const minScale = computed(() => Math.min(0.25, fitScale.value))
const percentage = computed(() => `${Math.round(scale.value * 100)}%`)
let observer: ResizeObserver | undefined
let stopWatching: (() => void) | undefined
let renderVersion = 0

function resetZoom() {
  if (!viewport.value || !width.value) return
  fitScale.value = Math.min(1, (viewport.value.clientWidth - 32) / width.value)
  scale.value = fitScale.value
  viewport.value.scrollTo(0, 0)
}

function zoom(factor: number) {
  scale.value = Math.min(3, Math.max(minScale.value, scale.value * factor))
}

async function render() {
  const version = ++renderVersion
  loading.value = true
  failed.value = false

  try {
    const result = await renderMermaid(source.value, isDark.value)
    if (version !== renderVersion) return
    svg.value = result
    loading.value = false
    await nextTick()
    if (version !== renderVersion) return
    const bounds = content.value?.querySelector('svg')?.viewBox.baseVal
    if (bounds) {
      width.value = bounds.width
      height.value = bounds.height
      resetZoom()
    }
  } catch {
    if (version === renderVersion) {
      svg.value = ''
      failed.value = true
    }
  } finally {
    if (version === renderVersion) loading.value = false
  }
}

onMounted(() => {
  let viewportWidth = 0
  observer = new ResizeObserver(([entry]) => {
    // 缩放也会改变容器高度；只有宽度变化时才重新适配，保留用户的缩放操作。
    if (entry.contentRect.width === viewportWidth) return
    viewportWidth = entry.contentRect.width
    resetZoom()
  })
  if (viewport.value) observer.observe(viewport.value)
  stopWatching = watch([source, isDark], render, { immediate: true })
})

onUnmounted(() => {
  renderVersion++
  observer?.disconnect()
  stopWatching?.()
})
</script>

<template>
  <div class="mermaid-diagram" :aria-busy="loading">
    <div class="mermaid-toolbar" role="group" aria-label="图表缩放工具">
      <span class="mermaid-caption">图表</span>
      <span class="mermaid-percentage" aria-live="polite">{{ percentage }}</span>
      <button type="button" title="缩小" aria-label="缩小图表"
        :disabled="loading || failed || scale <= minScale" @click="zoom(1 / 1.25)">−</button>
      <button type="button" title="放大" aria-label="放大图表"
        :disabled="loading || failed || scale >= 3" @click="zoom(1.25)">+</button>
      <button type="button" title="重置缩放，适应宽度" aria-label="重置图表缩放"
        :disabled="loading || failed" @click="resetZoom">重置</button>
    </div>
    <div ref="viewport" class="mermaid-viewport" role="region" aria-label="图表预览，可滚动查看" tabindex="0">
      <p v-if="loading" class="mermaid-status" role="status">正在加载图表…</p>
      <p v-else-if="failed" class="mermaid-status" role="alert">图表渲染失败，请检查 Mermaid 语法或刷新重试。</p>
      <div v-else class="mermaid-canvas" :style="{ width: `${width * scale}px`, height: `${height * scale}px` }">
        <div ref="content" class="mermaid-content"
          :style="{ width: `${width}px`, height: `${height}px`, transform: `scale(${scale})` }" v-html="svg" />
      </div>
    </div>
    <details v-if="failed" class="mermaid-source">
      <summary>查看图表源码</summary>
      <pre><code>{{ source }}</code></pre>
    </details>
  </div>
</template>

<style scoped>
.mermaid-diagram {
  margin: 16px 0;
  overflow: hidden;
  border: 1px solid var(--vp-c-divider);
  border-radius: 8px;
  background: var(--vp-c-bg);
}

.mermaid-toolbar {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 8px 12px;
  border-bottom: 1px solid var(--vp-c-divider);
  background: var(--vp-c-bg-soft);
  color: var(--vp-c-text-2);
  font-size: 12px;
  line-height: 24px;
}

.mermaid-caption {
  flex: 1;
}

.mermaid-percentage {
  min-width: 40px;
  margin-right: 4px;
  text-align: right;
  font-variant-numeric: tabular-nums;
}

.mermaid-toolbar button {
  min-width: 32px;
  height: 28px;
  padding: 0 8px;
  border: 1px solid var(--vp-c-divider);
  border-radius: 4px;
  color: var(--vp-c-text-1);
  cursor: pointer;
}

.mermaid-toolbar button:hover:not(:disabled) {
  border-color: var(--vp-c-brand-1);
  color: var(--vp-c-brand-1);
}

.mermaid-toolbar button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.mermaid-toolbar button:focus-visible,
.mermaid-viewport:focus-visible {
  outline: 2px solid var(--vp-c-brand-1);
  outline-offset: -2px;
}

.mermaid-viewport {
  max-height: 640px;
  overflow: auto;
  padding: 16px;
}

.mermaid-canvas {
  position: relative;
  margin: 0 auto;
}

.mermaid-content {
  position: absolute;
  top: 0;
  left: 0;
  transform-origin: top left;
}

.mermaid-content :deep(svg) {
  display: block;
  width: 100%;
  height: 100%;
  max-width: none !important;
}

.mermaid-status {
  margin: 16px 0;
  color: var(--vp-c-text-2);
  text-align: center;
  font-size: 14px;
}

.mermaid-source {
  padding: 0 16px 16px;
}

.mermaid-source summary {
  cursor: pointer;
}

.mermaid-source pre {
  max-height: 320px;
  overflow: auto;
  white-space: pre;
}
</style>
