<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  conversation: {
    type: Object,
    default: null
  },
  loading: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['send-message'])

const message = ref('')
const textareaRef = ref(null)

// Reset message when conversation changes
watch(() => props.conversation, () => {
  message.value = ''
})

// Auto-resize textarea based on content
const adjustTextareaHeight = () => {
  const textarea = textareaRef.value
  if (!textarea) return
  
  textarea.style.height = 'auto'
  textarea.style.height = `${textarea.scrollHeight}px`
}

// Handle sending a message
const sendMessage = () => {
  if (!message.value.trim() || !props.conversation || props.loading) return
  
  emit('send-message', {
    conversationId: props.conversation.id,
    content: message.value.trim()
  })
  
  message.value = ''
  
  // Reset textarea height
  if (textareaRef.value) {
    textareaRef.value.style.height = 'auto'
  }
}

// Handle keydown events (send on Enter, unless Shift is pressed)
const handleKeydown = (event) => {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault()
    sendMessage()
  }
}
</script>

<template>
  <div class="message-input-container" :class="{ disabled: !conversation }">
    <textarea
      ref="textareaRef"
      v-model="message"
      placeholder="Type a message..."
      @input="adjustTextareaHeight"
      @keydown="handleKeydown"
      :disabled="!conversation || loading"
      rows="1"
      class="message-textarea"
    ></textarea>
    
    <button 
      class="send-button" 
      @click="sendMessage" 
      :disabled="!message.trim() || !conversation || loading"
      title="Send message"
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="currentColor">
        <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"></path>
      </svg>
    </button>
  </div>
</template>

<style scoped>
.message-input-container {
  display: flex;
  align-items: flex-end;
  background-color: #ffffff;
  border-radius: 24px;
  border: 1px solid #e0e0e0;
  padding: 8px 12px;
  transition: border-color 0.2s;
  width: 100%;
}

.message-input-container:focus-within {
  border-color: #2196F3;
}

.message-input-container.disabled {
  background-color: #f5f5f5;
  cursor: not-allowed;
}

.message-textarea {
  flex: 1;
  border: none;
  resize: none;
  padding: 8px;
  font-size: 0.95rem;
  line-height: 1.4;
  max-height: 120px;
  font-family: inherit;
  background: transparent;
  min-width: 0;
  width: 100%;
}

.message-textarea:focus {
  outline: none;
}

.message-textarea:disabled {
  background-color: transparent;
  color: #9e9e9e;
}

.send-button {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: none;
  background-color: #2196F3;
  color: white;
  cursor: pointer;
  transition: background-color 0.2s;
  margin-left: 8px;
  padding: 0;
}

.send-button:hover:not(:disabled) {
  background-color: #1976D2;
}

.send-button:disabled {
  background-color: #bdbdbd;
  cursor: not-allowed;
}

.send-button svg {
  width: 20px;
  height: 20px;
}

@media (max-width: 768px) {
  .message-input-container {
    padding: 6px 10px;
  }
  
  .message-textarea {
    padding: 6px;
    font-size: 0.9rem;
  }
  
  .send-button {
    width: 32px;
    height: 32px;
  }
  
  .send-button svg {
    width: 18px;
    height: 18px;
  }
}

@media (max-width: 480px) {
  .message-input-container {
    padding: 4px 8px;
    border-radius: 18px;
  }
  
  .message-textarea {
    padding: 4px;
    font-size: 0.85rem;
  }
  
  .send-button {
    width: 30px;
    height: 30px;
    margin-left: 6px;
  }
  
  .send-button svg {
    width: 16px;
    height: 16px;
  }
}
</style>