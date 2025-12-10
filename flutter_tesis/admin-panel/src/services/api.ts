import axios from 'axios'

const API_BASE_URL = 'http://localhost:8001/api'

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Types
export interface User {
  id: string
  email: string
  displayName?: string
  role?: string
  createdAt?: string
}

export interface Event {
  id: string
  title: string
  description: string
  date: string
  end_time: string
  type: string
  status: string
  reminder: boolean
  postponed_count?: number
}

export interface CalendarTemplate {
  name: string
  description: string
  events: Array<{
    title: string
    description: string
    type: string
    hour: number
    duration: number
    days: number[]
  }>
}

// User Management
export const userAPI = {
  getAllUsers: async (): Promise<User[]> => {
    const response = await api.get('/admin/users')
    return response.data
  },

  getUserByEmail: async (email: string): Promise<User> => {
    const response = await api.get(`/admin/users/${email}`)
    return response.data
  },

  createUser: async (userData: Partial<User>): Promise<User> => {
    const response = await api.post('/admin/users', userData)
    return response.data
  },

  updateUser: async (userId: string, userData: Partial<User>): Promise<User> => {
    const response = await api.put(`/admin/users/${userId}`, userData)
    return response.data
  },

  deleteUser: async (userId: string): Promise<void> => {
    await api.delete(`/admin/users/${userId}`)
  },

  resetUserData: async (userId: string): Promise<void> => {
    await api.post(`/admin/users/${userId}/reset`)
  },
}

// Calendar Management
export const calendarAPI = {
  getUserEvents: async (userEmail: string): Promise<Event[]> => {
    const response = await api.get(`/calendar/events?user_email=${userEmail}`)
    return response.data
  },

  deleteAllUserEvents: async (userEmail: string): Promise<void> => {
    await api.delete(`/admin/users/by-email/events?email=${userEmail}`)
  },

  generateCalendar: async (userEmail: string, templateId: string, duration: string = '1month'): Promise<any> => {
    const response = await api.post(`/admin/generate-calendar-by-email`, { 
      email: userEmail,
      templateId: templateId,
      duration: duration
    })
    return response.data
  },

  syncWithGoogle: async (userEmail: string): Promise<void> => {
    await api.post(`/sync/full-sync`, { user_email: userEmail })
  },
}

// Test Templates
export const testTemplatesAPI = {
  getTemplates: async (): Promise<CalendarTemplate[]> => {
    const response = await api.get('/admin/templates')
    return response.data
  },

  createTemplate: async (template: CalendarTemplate): Promise<CalendarTemplate> => {
    const response = await api.post('/admin/templates', template)
    return response.data
  },
}

// System Tests
export const systemTestsAPI = {
  testHabitML: async () => {
    const response = await api.get('/habit-ml/dashboard-stats')
    return response.data
  },

  testNotifications: async () => {
    const response = await api.post('/admin/test-notifications')
    return response.data
  },

  testEnhancedAI: async () => {
    const response = await api.get('/enhanced-ai/system-status')
    return response.data
  },

  runAllTests: async () => {
    const response = await api.post('/admin/run-tests')
    return response.data
  },
}

// Firebase Admin
export const firebaseAdminAPI = {
  clearFirestore: async (userId: string): Promise<void> => {
    await api.delete(`/admin/firebase/users/${userId}/data`)
  },

  backupUserData: async (userId: string): Promise<any> => {
    const response = await api.get(`/admin/firebase/users/${userId}/backup`)
    return response.data
  },

  restoreUserData: async (userId: string, backup: any): Promise<void> => {
    await api.post(`/admin/firebase/users/${userId}/restore`, backup)
  },
}

// Admin API
export const adminAPI = {
  getUsers: async (): Promise<User[]> => {
    const response = await api.get('/admin/users')
    return response.data
  },

  removeGoogleToken: async (): Promise<void> => {
    await api.delete('/admin/google-token')
  },

  authenticateGoogleAuto: async (): Promise<any> => {
    const response = await api.get('/auth/google')
    return response.data
  },

  deleteAllEventsDangerous: async (): Promise<any> => {
    const response = await api.delete('/admin/dangerous/delete-all-events')
    return response.data
  },
}

export default api
