<template>
  <div v-if="visible" class="admin-overlay" @click.self="$emit('close')">
    <div class="admin-panel">
      <div class="panel-header">
        <h2>用户管理</h2>
        <button class="close-btn" @click="$emit('close')">&times;</button>
      </div>

      <div v-if="error" class="error-msg">{{ error }}</div>

      <table class="user-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>用户名</th>
            <th>状态</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="u in users" :key="u.id">
            <td>{{ u.id }}</td>
            <td>{{ u.username }}</td>
            <td>
              <span :class="u.approved ? 'badge approved' : 'badge pending'">
                {{ u.approved ? '已审批' : '待审批' }}
              </span>
            </td>
            <td>
              <button
                v-if="!u.approved"
                class="approve-btn"
                :disabled="approving === u.id"
                @click="doApprove(u)"
              >
                {{ approving === u.id ? '处理中...' : '通过审批' }}
              </button>
              <span v-else class="no-action">-</span>
            </td>
          </tr>
          <tr v-if="users.length === 0">
            <td colspan="4" class="empty-row">暂无用户</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { apiGet, apiPut } from '../api.js'

const props = defineProps({ visible: { type: Boolean, default: false } })
const emit = defineEmits(['close'])

const users = ref([])
const error = ref('')
const approving = ref(null)

async function loadUsers() {
  error.value = ''
  try {
    users.value = (await apiGet('/auth/users')).users
  } catch (e) {
    error.value = e.message
  }
}

async function doApprove(u) {
  approving.value = u.id
  try {
    await apiPut(`/auth/approve/${u.id}`)
    u.approved = true
  } catch (e) {
    error.value = e.message
  } finally {
    approving.value = null
  }
}

watch(() => props.visible, (val) => { if (val) loadUsers() })
</script>

<style scoped>
.admin-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.35);
  display: flex;
  justify-content: flex-end;
  z-index: 1100;
}

.admin-panel {
  width: 520px;
  background: #fff;
  height: 100%;
  box-shadow: -4px 0 20px rgba(0, 0, 0, 0.12);
  display: flex;
  flex-direction: column;
  overflow-y: auto;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px 16px;
  border-bottom: 1px solid #eee;
}

.panel-header h2 {
  font-size: 18px;
  font-weight: 700;
  margin: 0;
}

.close-btn {
  width: 32px;
  height: 32px;
  border: none;
  background: transparent;
  font-size: 22px;
  cursor: pointer;
  color: #888;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-btn:hover {
  background: #f0f0f0;
  color: #333;
}

.error-msg {
  margin: 16px 24px 0;
  color: #d32f2f;
  font-size: 13px;
  padding: 8px 12px;
  background: #fdecea;
  border-radius: 6px;
}

.user-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 8px;
}

.user-table th,
.user-table td {
  padding: 12px 24px;
  text-align: left;
  font-size: 14px;
  border-bottom: 1px solid #f2f2f2;
}

.user-table th {
  font-weight: 600;
  color: #888;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.badge {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
}

.badge.approved {
  background: #e8f5e9;
  color: #2e7d32;
}

.badge.pending {
  background: #fff3e0;
  color: #e65100;
}

.approve-btn {
  padding: 5px 14px;
  background: #4a90d9;
  color: #fff;
  border: none;
  border-radius: 5px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.approve-btn:hover:not(:disabled) {
  background: #357abd;
}

.approve-btn:disabled {
  background: #c0c0c0;
  cursor: not-allowed;
}

.no-action {
  color: #bbb;
  font-size: 14px;
}

.empty-row {
  text-align: center;
  color: #bbb;
  padding: 32px !important;
}
</style>
