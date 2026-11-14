import mediumZoom, { type Zoom } from 'medium-zoom'
import { onContentUpdated, type Theme } from 'vitepress'
import DefaultTheme from 'vitepress/theme'
import { defineComponent, h, onMounted, onUnmounted } from 'vue'
import './style.css'

export default {
  extends: DefaultTheme,
  Layout: defineComponent({
    setup() {
      let zoom: Zoom | undefined

      function refreshImages() {
        if (!zoom) return

        // 文档切换或热更新后，释放旧图片并绑定最新的正文图片。
        zoom.detach()
        const images = document.querySelectorAll<HTMLImageElement>(
          '.vp-doc img[src]:not(a img):not(.no-zoom)',
        )
        zoom.attach(images)
        images.forEach((image) => {
          image.setAttribute('tabindex', '0')
          image.setAttribute('role', 'button')
          image.setAttribute('aria-label', `放大图片${image.alt ? `：${image.alt}` : ''}`)
        })
      }

      function handleKeydown(event: KeyboardEvent) {
        const target = event.target
        if (
          (event.key === 'Enter' || event.key === ' ') &&
          target instanceof HTMLImageElement &&
          zoom?.getImages().includes(target)
        ) {
          event.preventDefault()
          void zoom.toggle({ target })
        }
      }

      onMounted(() => {
        zoom = mediumZoom({
          background: 'var(--vp-c-bg)',
          margin: 24,
        })
        refreshImages()
        document.addEventListener('keydown', handleKeydown)
      })
      onContentUpdated(refreshImages)
      onUnmounted(() => {
        zoom?.detach()
        document.removeEventListener('keydown', handleKeydown)
      })

      return () => h(DefaultTheme.Layout)
    },
  }),
} satisfies Theme
