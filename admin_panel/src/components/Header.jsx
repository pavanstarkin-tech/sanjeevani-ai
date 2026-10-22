import React, { useState } from 'react';
import { Search, Bell, Moon, ChevronDown, LogOut, ShieldCheck } from 'lucide-react';

export default function Header({ activeTab, onLogout, user }) {
  const [showProfileMenu, setShowProfileMenu] = useState(false);

  const titles = {
    dashboard: { title: 'Dashboard Overview', subtitle: 'Real-time operational health metrics and telemetry' },
    hospitals: { title: 'Hospitals Management', subtitle: 'Manage partner hospital empanelment, beds & departments' },
    doctors: { title: 'Doctors Directory & Verification', subtitle: 'MCI Council verification, hospital affiliations and schedules' },
    users: { title: 'Users & Patients Management', subtitle: 'Registered patients, Aarogyasri health ID passes & medical vault' },
    appointments: { title: 'Central Appointments Queue', subtitle: 'Consultation requests, video room dispatch & rescheduling' },
    payments: { title: 'Payments & Revenue Ledger', subtitle: 'Platform earnings ledger, doctor payouts & Razorpay gateway' },
    business: { title: 'AI Business Wing & Lead Monetization', subtitle: 'User interest segmentation, commercial product recommendation & GMV analytics' },
    products: { title: 'Health Products & Diagnostic Packages', subtitle: 'Manage commercial catalog, smart devices, care plans & margins' },
    tickets: { title: 'Support & Dispute Desk', subtitle: 'Customer support resolution and dispute ticketing' },
    ai: { title: 'AI Rule Engine & Clinical Triage', subtitle: 'Configure symptom-to-specialty escalation rules and thresholds' },
    content: { title: 'Content & CMS Advisory', subtitle: 'Manage public health protocols and outbreak notifications' },
    notifications: { title: 'Broadcast Notification Center', subtitle: 'Compose FCM push and in-app health advisories' },
    analytics: { title: 'Reports & Analytics', subtitle: 'Hospital booking volumes, patient retention and platform growth' },
    audit: { title: 'Security & Audit Logs', subtitle: 'Immutable ABDM consent and administrative access trails' },
    settings: { title: 'Admin Settings & Security', subtitle: 'System preferences, password security and role permissions' },
  };

  const current = titles[activeTab] || titles.dashboard;

  return (
    <header className="top-header">
      <div className="header-left">
        <h1>{current.title}</h1>
        <p>{current.subtitle}</p>
      </div>

      <div className="header-right">
        <div className="search-box">
          <Search size={17} />
          <input type="text" placeholder="Search anything (ID, name)..." />
        </div>

        <button className="icon-btn" title="Notifications">
          <Bell size={18} />
          <span className="notification-badge"></span>
        </button>

        <button className="icon-btn" title="Theme Toggle">
          <Moon size={18} />
        </button>

        {/* Admin Profile Dropdown */}
        <div style={{ position: 'relative' }}>
          <div
            className="user-profile-menu"
            style={{ cursor: 'pointer' }}
            onClick={() => setShowProfileMenu(!showProfileMenu)}
          >
            <img
              src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200"
              alt="Admin User"
            />
            <div style={{ textAlign: 'left' }}>
              <span style={{ display: 'block', fontSize: '0.85rem', fontWeight: 700 }}>{user?.email ? user.email.split('@')[0] : 'Super Admin'}</span>
              <span style={{ display: 'block', fontSize: '0.7rem', color: 'var(--text-muted)' }}>{user?.role || 'Super Admin'}</span>
            </div>
            <ChevronDown size={15} color="var(--text-muted)" />
          </div>

          {showProfileMenu && (
            <div style={{
              position: 'absolute',
              top: '110%',
              right: 0,
              width: 200,
              background: 'var(--bg-card)',
              border: '1px solid var(--border)',
              borderRadius: 8,
              boxShadow: 'var(--shadow-md)',
              padding: 6,
              zIndex: 100
            }}>
              <div style={{ padding: '8px 12px', borderBottom: '1px solid var(--border)', fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                Signed in as<br />
                <strong style={{ color: 'var(--text-main)' }}>{user?.email || 'admin@healthexpress.ai'}</strong>
              </div>
              <button
                type="button"
                style={{
                  width: '100%',
                  padding: '8px 12px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  background: 'none',
                  border: 'none',
                  color: 'var(--error)',
                  fontSize: '0.82rem',
                  fontWeight: 600,
                  cursor: 'pointer',
                  borderRadius: 6,
                  marginTop: 4
                }}
                onClick={() => {
                  setShowProfileMenu(false);
                  if (onLogout) onLogout();
                }}
              >
                <LogOut size={15} /> Log Out
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
