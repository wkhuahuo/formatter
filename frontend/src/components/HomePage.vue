<template>
  <div class="home">
    <div class="hero">
      <h1>{{ APP.name }}</h1>
      <p class="subtitle">高效、安全的在线文档处理平台</p>
    </div>
    <div class="feature-grid">
      <div class="feature-card" @click="$router.push('/editor')">
        <div class="card-icon doc-icon">
          <svg viewBox="0 0 24 24" width="36" height="36" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
            <polyline points="14 2 14 8 20 8"/>
            <line x1="16" y1="13" x2="8" y2="13"/>
            <line x1="16" y1="17" x2="8" y2="17"/>
            <polyline points="10 9 9 9 8 9"/>
          </svg>
        </div>
        <h3>红头公文格式化</h3>
        <p>基于 GB/T 9704-2012 标准，在线编辑并生成规范的红头公文文档。支持自动版记格式化、标题检测、弹性间距协调等功能。</p>
        <span class="card-action">进入工具 &rarr;</span>
      </div>
      <div class="feature-card" @click="$router.push('/meeting-minutes')">
        <div class="card-icon meeting-icon">
          <svg viewBox="0 0 24 24" width="36" height="36" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="2" y="5" width="20" height="14" rx="2"/>
            <line x1="2" y1="10" x2="22" y2="10"/>
            <line x1="7" y1="2" x2="7" y2="5"/>
            <line x1="17" y1="2" x2="17" y2="5"/>
            <line x1="8" y1="14" x2="11" y2="14"/>
            <line x1="8" y1="17" x2="14" y2="17"/>
          </svg>
        </div>
        <h3>会议纪要格式化</h3>
        <p>在线编辑并生成规范的会议纪要文档。包含会议基本信息、议题、主要内容及议定事项、会议决议等标准格式。</p>
        <span class="card-action">进入工具 &rarr;</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { APP } from '../config.js'
</script>

<style scoped>
.home {
  max-width: 1100px;
  margin: 0 auto;
  padding: 60px 20px;
}

.hero {
  text-align: center;
  margin-bottom: 48px;
}

.hero h1 {
  font-size: 32px;
  font-weight: 800;
  color: #1a1a1a;
  margin-bottom: 12px;
}

.subtitle {
  font-size: 16px;
  color: #777;
}

.feature-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 20px;
  justify-content: center;
}

.feature-card {
  background: #fff;
  border: 1px solid #e8e8e8;
  border-radius: 12px;
  padding: 28px;
  cursor: pointer;
  transition: box-shadow 0.2s, transform 0.2s;
}

.feature-card:hover {
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.08);
  transform: translateY(-2px);
}

.card-icon {
  width: 56px;
  height: 56px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 16px;
}

.doc-icon {
  background: #e8f0fe;
  color: #4a90d9;
}

.meeting-icon {
  background: #e8f5e9;
  color: #2e7d32;
}

.feature-card h3 {
  font-size: 18px;
  font-weight: 700;
  color: #1a1a1a;
  margin-bottom: 8px;
}

.feature-card p {
  font-size: 14px;
  color: #888;
  line-height: 1.7;
  margin-bottom: 16px;
}

.card-action {
  font-size: 14px;
  font-weight: 600;
  color: #4a90d9;
}

@media (max-width: 600px) {
  .home {
    padding: 32px 16px;
  }

  .hero h1 {
    font-size: 22px;
  }

  .subtitle {
    font-size: 14px;
  }

  .feature-grid {
    grid-template-columns: 1fr;
  }

  .feature-card {
    padding: 20px;
  }
}
</style>
