import axios from 'axios';

const getApiBaseUrl = () => {
  if (import.meta.env.VITE_API_BASE_URL) return import.meta.env.VITE_API_BASE_URL;
  if (typeof window !== 'undefined') {
    if (window.location.hostname.includes('vedvaidyam.com')) {
      return '/healthexpress/api';
    }
    if (window.location.hostname.includes('acheva.in')) {
      return '/api';
    }
  }
  return 'https://vedvaidyam.com/healthexpress/api';
};

const API_BASE_URL = getApiBaseUrl();

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 15000,
});

export const healthApi = {
  // Live Telemetry & Computed Stats
  getHealth: () => api.get('/health'),
  getAdminStats: () => api.get('/admin/stats'),
  getAiStats: () => api.get('/admin/ai-stats'),
  getAiSessions: () => api.get('/admin/ai-sessions'),
  getHospitalRankings: () => api.get('/admin/hospital-rankings'),
  getConsultationDistribution: () => api.get('/admin/consultation-distribution'),
  getActivityLogs: () => api.get('/admin/activity-logs'),

  // Users & Patients Ledger
  getUsers: () => api.get('/users'),

  // Hospitals
  getHospitals: () => api.get('/hospitals'),
  getHospitalDetail: (id) => api.get(`/hospitals/${id}`),
  createHospital: (data) => api.post('/hospitals', data),

  // Doctors
  getDoctors: (params) => api.get('/doctors', { params }),
  getDoctorDetail: (id) => api.get(`/doctors/${id}`),
  toggleDoctorStatus: (id, isOnline) => api.put(`/doctors/${id}/status`, { isOnline }),
  verifyDoctor: (id, status, notes) => api.put(`/doctors/${id}/verify`, { status, notes }),

  // Appointments
  getAllAppointments: () => api.get('/appointments'),
  getBookings: () => api.get('/appointments/user/USR-101'),
  getDoctorQueue: (doctorId) => api.get(`/appointments/doctor/${doctorId}`),

  // Payments & Ledger
  getPayments: () => api.get('/payments'),

  // Support & Dispute Desk
  getTickets: () => api.get('/tickets'),
  createTicket: (data) => api.post('/tickets', data),

  // Pharmacy & Medical Stores
  getMedicines: () => api.get('/pharmacy/medicines'),
  getStores: () => api.get('/pharmacy/stores'),
  getPendingStores: () => api.get('/admin/pending-stores'),
  verifyStore: (id, status, notes) => api.put(`/admin/verify-store/${id}`, { status, notes }),
  createStore: (data) => api.post('/pharmacy/onboard', data),

  // Aarogyasri Health Pass
  getAarogyasriProfile: (id) => api.get(`/auth/aarogyasri/${id}`),

  // RAG Knowledge Chunks & Clinical Layer
  getRagChunks: () => api.get('/ai/rag-chunks'),
  getLatestRagVersion: () => api.get('/ai/rag-chunks/latest-version'),
  addRagChunk: (data) => api.post('/ai/rag-chunks', data),
  publishRagUpdates: () => api.post('/ai/rag-chunks/publish'),

  // Sarvam AI Multi-Key Pool (Zero Authentication)
  getSarvamKeys: () => api.get('/public/sarvam-keys'),
  getActiveSarvamKey: () => api.get('/public/sarvam-keys/active'),
  addSarvamKeys: (data) => api.post('/public/sarvam-keys', data),
  markSarvamKeyExhausted: (data) => api.post('/public/sarvam-keys/mark-exhausted', data),
  markSarvamKeyInvalid: (data) => api.post('/public/sarvam-keys/mark-invalid', data),
  reactivateSarvamKey: (data) => api.post('/public/sarvam-keys/reactivate', data),
  setSarvamActiveKey: (data) => api.post('/public/sarvam-keys/set-active', data),
  deleteSarvamKey: (id) => api.delete(`/public/sarvam-keys?id=${id}`),
};

export default api;
