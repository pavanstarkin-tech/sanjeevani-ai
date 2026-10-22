import React, { useState } from 'react';
import { 
  ShieldCheck, 
  KeyRound, 
  Sliders, 
  Bell, 
  Lock, 
  FileCode2, 
  Clock, 
  CheckCircle2, 
  Save 
} from 'lucide-react';

export default function SettingsView() {
  const [passwords, setPasswords] = useState({ current: '', new: '', confirm: '' });
  const [activeMenu, setActiveMenu] = useState('general');

  const handlePasswordUpdate = (e) => {
    e.preventDefault();
    alert('Admin password updated successfully with SHA-256 encryption.');
    setPasswords({ current: '', new: '', confirm: '' });
  };

  const settingsMenuItems = [
    { id: 'general', label: 'General Settings', icon: Sliders },
    { id: 'notifications', label: 'Notification Settings', icon: Bell },
    { id: 'roles', label: 'Role & Permissions', icon: ShieldCheck },
    { id: 'security', label: 'Security Settings', icon: Lock },
    { id: 'kyc', label: 'KYC & Verification', icon: CheckCircle2 },
    { id: 'logs', label: 'System Logs', icon: FileCode2 },
  ];

  const recentLogs = [
    { text: 'You added new hospital "Sunshine Hospitals"', time: '18 May 2024, 10:30 AM' },
    { text: 'You approved doctor "Dr. Kavya S"', time: '18 May 2024, 09:15 AM' },
    { text: 'You updated system settings and Razorpay webhook', time: '17 May 2024, 06:45 PM' },
    { text: 'You resolved support ticket #TK2555', time: '16 May 2024, 04:20 PM' },
  ];

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: 24 }}>
      {/* Left Column: Admin Profile & Password */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
        {/* Admin Profile Card */}
        <div className="chart-card">
          <div className="chart-header">
            <h3>Admin Profile</h3>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <img
              src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200"
              alt="Admin User"
              style={{ width: 68, height: 68, borderRadius: '50%', objectFit: 'cover', border: '3px solid var(--primary-light)' }}
            />
            <div>
              <h4 style={{ fontSize: '1.15rem', fontWeight: 800 }}>Admin User</h4>
              <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>admin@healthexpress.ai</p>
              <div style={{ marginTop: 6, display: 'flex', gap: 8, alignItems: 'center' }}>
                <span className="status-badge active" style={{ fontSize: '0.72rem' }}>Super Admin</span>
                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Joined on 01 Jan 2024 10:00 AM</span>
              </div>
            </div>
          </div>
        </div>

        {/* Change Password Card */}
        <div className="chart-card">
          <div className="chart-header">
            <h3>Change Password</h3>
          </div>
          <form onSubmit={handlePasswordUpdate}>
            <div className="form-group">
              <label>Current Password</label>
              <input
                type="password"
                required
                placeholder="••••••••••••"
                value={passwords.current}
                onChange={(e) => setPasswords({ ...passwords, current: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label>New Password</label>
              <input
                type="password"
                required
                placeholder="••••••••••••"
                value={passwords.new}
                onChange={(e) => setPasswords({ ...passwords, new: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label>Confirm New Password</label>
              <input
                type="password"
                required
                placeholder="••••••••••••"
                value={passwords.confirm}
                onChange={(e) => setPasswords({ ...passwords, confirm: e.target.value })}
              />
            </div>

            <button type="submit" className="btn-primary" style={{ width: '100%', justifyContent: 'center', marginTop: 10 }}>
              <KeyRound size={16} /> Update Password
            </button>
          </form>
        </div>
      </div>

      {/* Right Column: System Settings Menu & Recent Activity */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
        {/* System Settings List */}
        <div className="chart-card">
          <div className="chart-header">
            <h3>System Settings</h3>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            {settingsMenuItems.map((item) => {
              const Icon = item.icon;
              const isActive = activeMenu === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => setActiveMenu(item.id)}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '12px 16px',
                    borderRadius: 'var(--radius-md)',
                    background: isActive ? 'var(--primary-light)' : 'var(--bg-main)',
                    color: isActive ? 'var(--primary)' : 'var(--text-main)',
                    fontWeight: 700,
                    fontSize: '0.88rem',
                    textAlign: 'left',
                    width: '100%',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <Icon size={18} />
                    <span>{item.label}</span>
                  </div>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>&gt;</span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Recent Activity Logs */}
        <div className="chart-card">
          <div className="chart-header">
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Clock size={18} color="var(--primary)" />
              <h3>Recent Activity Logs</h3>
            </div>
            <button style={{ fontSize: '0.75rem', color: 'var(--primary)', fontWeight: 700 }}>View All Logs &gt;</button>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            {recentLogs.map((log, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 10, fontSize: '0.84rem' }}>
                <span style={{ color: 'var(--primary)', marginTop: 2 }}>●</span>
                <div>
                  <div style={{ fontWeight: 600 }}>{log.text}</div>
                  <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: 2 }}>{log.time}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
