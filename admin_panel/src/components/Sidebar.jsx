import React from 'react';
import { 
  LayoutDashboard, 
  Building2, 
  UserRound, 
  Users, 
  CalendarCheck, 
  CreditCard, 
  LifeBuoy, 
  Sparkles,
  FileText,
  Bell,
  BarChart3, 
  ShieldCheck,
  Settings,
  Activity,
  ChevronRight,
  TrendingUp,
  ShoppingBag,
  Database,
  Key
} from 'lucide-react';

const NAV_SECTIONS = [
  {
    title: 'OPERATIONS',
    items: [
      { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
      { id: 'hospitals', label: 'Hospitals', icon: Building2 },
      { id: 'doctors', label: 'Doctors', icon: UserRound },
      { id: 'users', label: 'Users & Patients', icon: Users },
      { id: 'appointments', label: 'Appointments', icon: CalendarCheck },
      { id: 'payments', label: 'Payments & Ledger', icon: CreditCard },
      { id: 'tickets', label: 'Support Tickets', icon: LifeBuoy },
    ]
  },
  {
    title: 'BUSINESS & MONETIZATION',
    items: [
      { id: 'business', label: 'AI Business & Products', icon: TrendingUp },
    ]
  },
  {
    title: 'AI & CONTENT',
    items: [
      { id: 'rag', label: 'RAG Knowledge Chunks', icon: Database },
      { id: 'sarvam_keys', label: 'Sarvam API Key Pool', icon: Key },
      { id: 'ai', label: 'AI Configuration', icon: Sparkles },
      { id: 'content', label: 'Content & CMS', icon: FileText },
      { id: 'notifications', label: 'Notifications', icon: Bell },
    ]
  },
  {
    title: 'ANALYTICS & SYSTEM',
    items: [
      { id: 'analytics', label: 'Analytics & Reports', icon: BarChart3 },
      { id: 'audit', label: 'Audit Logs', icon: ShieldCheck },
      { id: 'settings', label: 'System Settings', icon: Settings },
    ]
  }
];

export default function Sidebar({ activeTab, setActiveTab }) {
  return (
    <aside className="sidebar">
      <div className="sidebar-logo">
        <img 
          src="./logo.png" 
          alt="Sanjivani.ai Logo" 
          style={{ 
            width: 40, 
            height: 40, 
            borderRadius: 10, 
            objectFit: 'contain', 
            background: '#FFFFFF', 
            boxShadow: '0 4px 12px rgba(30, 96, 246, 0.15)',
            border: '1px solid #E2E8F0',
            flexShrink: 0
          }} 
        />
        <div className="logo-text">
          <h2>Sanjivani.ai</h2>
          <span>Admin Operations</span>
        </div>
      </div>

      <nav className="sidebar-nav">
        {NAV_SECTIONS.map((section, sIdx) => (
          <div key={sIdx} style={{ marginBottom: 16 }}>
            <div style={{
              fontSize: '0.7rem',
              fontWeight: 800,
              color: 'var(--text-muted)',
              letterSpacing: '0.8px',
              padding: '0 16px 8px 16px',
              textTransform: 'uppercase'
            }}>
              {section.title}
            </div>

            {section.items.map((item) => {
              const Icon = item.icon;
              const isActive = activeTab === item.id;
              return (
                <button
                  key={item.id}
                  className={`nav-link ${isActive ? 'active' : ''}`}
                  onClick={() => setActiveTab(item.id)}
                >
                  <Icon size={18} strokeWidth={isActive ? 2.5 : 2} />
                  <span style={{ flex: 1, textAlign: 'left' }}>{item.label}</span>
                </button>
              );
            })}
          </div>
        ))}
      </nav>

      <div className="sidebar-footer">
        <a
          href="../"
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 8,
            padding: '8px 12px',
            marginBottom: 10,
            borderRadius: 8,
            background: 'var(--primary-light)',
            color: 'var(--primary)',
            fontSize: '0.8rem',
            fontWeight: 700,
            textDecoration: 'none',
            border: '1px solid rgba(30, 96, 246, 0.2)'
          }}
        >
          📱 Open Mobile Web App
        </a>
        <div className="admin-card-mini">
          <img
            src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200"
            alt="Super Admin"
          />
          <div className="admin-mini-info" style={{ flex: 1 }}>
            <h4>Super Admin</h4>
            <p>admin@healthexpress.ai</p>
          </div>
          <ChevronRight size={14} color="var(--text-muted)" />
        </div>
      </div>
    </aside>
  );
}
