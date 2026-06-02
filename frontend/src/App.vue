<template>
  <div class="app-container">
    <LatexEditor />
  </div>
</template>

<script setup>
import LatexEditor from './components/LatexEditor.vue'
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Noto Sans SC', sans-serif;
  background: #f0f2f5;
  color: #333;
}

.app-container {
  min-height: 100vh;
}
</style>
