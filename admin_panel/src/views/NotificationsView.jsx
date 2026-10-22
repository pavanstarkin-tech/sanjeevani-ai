import React, { useState } from 'react';
import { Bell, Send, Users, Smartphone, Clock, CheckCircle } from 'lucide-react';

export default function NotificationsView() {
  const [formData, setFormData] = useState({
    title: 'Consultation Reminder',
    message: 'Your upcoming video consultation with Dr. Sandeep Attawar starts in 30 minutes. Please ensure you have stable internet connection.',
    audience: 'All Patients',
    channelPush: true,
    channelInApp: true,
  });

  const [history, setHistory] = useState([
    { title: 'Aarogyasri Health Camp Alert', audience: 'All Patients', sentAt: '18 May 2024, 09:30 AM', delivered: '42,100', openRate: '68%' },
    { title: 'Doctor Verification Required', audience: 'Pending Doctors', sentAt: '17 May 2024, 02:15 PM', delivered: '32', openRate: '94%' },
    { title: '15-Min Pharmacy Express Now Live', audience: 'Hyderabad Region', sentAt: '16 May 2024, 11:00 AM', delivered: '28,400', openRate: '54%' },
  ]);

  const [sentSuccess, setSentSuccess] = useState(false);

  const handleSend = (e) => {
    e.preventDefault();
    setHistory([
      {
        title: formData.title,
        audience: formData.audience,
        sentAt: 'Just now',
        delivered: '45,231',
        openRate: '—'
      },
      ...history
    ]);
    setSentSuccess(true);
    setTimeout(() => setSentSuccess(false), 4000);
  };

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: 24 }}>
      {/* Notification Composer */}
      <div className="table-card" style={{ padding: '24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 18 }}>
          <Bell size={22} color="var(--primary)" />
          <h3 style={{ fontSize: '1.15rem', fontWeight: 800 }}>Notification Composer</h3>
        </div>

        {sentSuccess && (
          <div style={{ padding: '12px 16px', background: 'var(--success-bg)', color: 'var(--success-text)', borderRadius: 'var(--radius-md)', marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8, fontWeight: 700, fontSize: '0.88rem' }}>
            <CheckCircle size={18} /> Push Notification broadcasted to {formData.audience} via Firebase Cloud Messaging!
          </div>
        )}

        <form onSubmit={handleSend}>
          <div className="form-group">
            <label>Notification Headline / Title *</label>
            <input
              type="text"
              required
              value={formData.title}
              onChange={e => setFormData({ ...formData, title: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label>Message Body Content *</label>
            <textarea
              rows={4}
              required
              value={formData.message}
              onChange={e => setFormData({ ...formData, message: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label>Target Audience</label>
            <select
              value={formData.audience}
              onChange={e => setFormData({ ...formData, audience: e.target.value })}
            >
              <option>All Patients</option>
              <option>Patients with Upcoming Appointments</option>
              <option>Verified Doctors</option>
              <option>Hospital Administrators</option>
              <option>Aarogyasri Health Pass Holders</option>
            </select>
          </div>

          <div style={{ marginBottom: 20 }}>
            <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 700, marginBottom: 8 }}>Delivery Channels</label>
            <div style={{ display: 'flex', gap: 16 }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '0.88rem', fontWeight: 600, cursor: 'pointer' }}>
                <input type="checkbox" checked={formData.channelPush} onChange={e => setFormData({ ...formData, channelPush: e.target.checked })} />
                FCM Push Notification
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '0.88rem', fontWeight: 600, cursor: 'pointer' }}>
                <input type="checkbox" checked={formData.channelInApp} onChange={e => setFormData({ ...formData, channelInApp: e.target.checked })} />
                In-App Notification Bell
              </label>
            </div>
          </div>

          <button type="submit" className="btn-primary" style={{ width: '100%', justifyContent: 'center' }}>
            <Send size={16} /> Broadcast Notification Now
          </button>
        </form>
      </div>

      {/* Broadcast History */}
      <div className="table-card" style={{ padding: '24px' }}>
        <h3 style={{ fontSize: '1.15rem', fontWeight: 800, marginBottom: 16 }}>Broadcast Dispatch History</h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {history.map((h, i) => (
            <div key={i} style={{ padding: '14px', background: 'var(--bg-main)', borderRadius: 'var(--radius-md)', border: '1px solid var(--border)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                <strong style={{ fontSize: '0.9rem' }}>{h.title}</strong>
                <span className="status-badge active" style={{ fontSize: '0.7rem' }}>Sent</span>
              </div>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginBottom: 8 }}>
                Audience: <strong>{h.audience}</strong> • {h.sentAt}
              </div>
              <div style={{ display: 'flex', gap: 16, fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-main)' }}>
                <span>Delivered: {h.delivered}</span>
                <span>Open Rate: {h.openRate}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
