<template>
  <Transition name="popup">
    <div v-if="visible" class="achievement-popup-overlay">
      <div class="achievement-popup pop-in">
        <div class="popup-confetti">🎉</div>
        <span class="popup-icon">{{ achievement.icon }}</span>
        <h3 class="popup-title">成就解锁！</h3>
        <p class="popup-name">{{ achievement.name }}</p>
        <p class="popup-desc">{{ achievement.description }}</p>
        <button class="btn btn-primary" @click="close">太棒了！</button>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  achievement: { type: Object, default: null }
})

const emit = defineEmits(['close'])
const visible = ref(false)

watch(() => props.achievement, (val) => {
  if (val) visible.value = true
})

function close() {
  visible.value = false
  emit('close')
}
</script>

<style scoped>
.achievement-popup-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 200;
}

.achievement-popup {
  background: #fff;
  border-radius: 20px;
  padding: 40px 50px;
  text-align: center;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.popup-confetti {
  font-size: 40px;
  margin-bottom: 8px;
}

.popup-icon {
  font-size: 64px;
  display: block;
  margin-bottom: 12px;
}

.popup-title {
  font-size: 14px;
  color: #f59e0b;
  text-transform: uppercase;
  letter-spacing: 2px;
  margin-bottom: 8px;
}

.popup-name {
  font-size: 24px;
  font-weight: 800;
  margin-bottom: 8px;
}

.popup-desc {
  font-size: 14px;
  color: #888;
  margin-bottom: 24px;
}

.popup-enter-active,
.popup-leave-active {
  transition: opacity 0.3s;
}

.popup-enter-from,
.popup-leave-to {
  opacity: 0;
}
</style>
