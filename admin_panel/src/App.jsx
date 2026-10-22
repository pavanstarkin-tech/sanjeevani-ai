import React, { useState } from 'react';
import Sidebar from './components/Sidebar';
import Header from './components/Header';
import AddDoctorModal from './components/AddDoctorModal';
import LoginView from './views/LoginView';

// Views
import DashboardView from './views/DashboardView';
import HospitalsView from './views/HospitalsView';
import DoctorsView from './views/DoctorsView';
import UsersView from './views/UsersView';
import AppointmentsView from './views/AppointmentsView';
import PaymentsView from './views/PaymentsView';
import TicketsView from './views/TicketsView';
import BusinessWingView from './views/BusinessWingView';
import AiManagementView from './views/AiManagementView';
import RagManagementView from './views/RagManagementView';
import SarvamKeyPoolView from './views/SarvamKeyPoolView';
import NotificationsView from './views/NotificationsView';
import ReportsView from './views/ReportsView';
import AuditLogsView from './views/AuditLogsView';
import SettingsView from './views/SettingsView';

export default function App() {
  const getInitialTab = () => {
    const path = window.location.pathname.toLowerCase();
    const hash = window.location.hash.toLowerCase();
    if (path.includes('sarvam') || hash.includes('sarvam')) return 'sarvam_keys';
    if (path.includes('rag') || hash.includes('rag')) return 'rag';
    if (path.includes('hospitals') || hash.includes('hospitals')) return 'hospitals';
    if (path.includes('doctors') || hash.includes('doctors')) return 'doctors';
    return 'dashboard';
  };

  const [activeTab, setActiveTab] = useState(getInitialTab);
  const [isAddDoctorOpen, setIsAddDoctorOpen] = useState(false);
  const [currentUser, setCurrentUser] = useState({
    email: 'admin@healthexpress.ai',
    role: 'Super Admin',
  });
  const [isAuthenticated, setIsAuthenticated] = useState(true);

  if (!isAuthenticated) {
    return (
      <LoginView
        onLoginSuccess={(user) => {
          setCurrentUser(user);
          setIsAuthenticated(true);
        }}
      />
    );
  }

  return (
    <div className="app-container">
      {/* Left Navigation Sidebar */}
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />

      {/* Main Content Area */}
      <div className="main-wrapper">
        <Header
          activeTab={activeTab}
          user={currentUser}
          onLogout={() => setIsAuthenticated(false)}
        />

        <main className="content-body">
          {activeTab === 'dashboard' && (
            <DashboardView
              onNavigate={setActiveTab}
              onOpenAddHospital={() => setActiveTab('hospitals')}
              onOpenAddDoctor={() => setIsAddDoctorOpen(true)}
            />
          )}

          {activeTab === 'hospitals' && <HospitalsView />}

          {activeTab === 'doctors' && (
            <DoctorsView onOpenAddDoctor={() => setIsAddDoctorOpen(true)} />
          )}

          {activeTab === 'users' && <UsersView />}

          {activeTab === 'appointments' && <AppointmentsView />}

          {activeTab === 'payments' && <PaymentsView />}

          {(activeTab === 'business' || activeTab === 'products') && <BusinessWingView />}

          {activeTab === 'tickets' && <TicketsView />}

          {activeTab === 'rag' && <RagManagementView />}
          {activeTab === 'sarvam_keys' && <SarvamKeyPoolView />}

          {activeTab === 'ai' && <AiManagementView />}

          {activeTab === 'content' && (
            <div className="chart-card" style={{ padding: '40px 24px' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: 8 }}>Content & CMS Center</h3>
              <p style={{ color: 'var(--text-muted)', marginBottom: 20 }}>
                Manage patient health education articles, symptom categories, seasonal outbreak banners, and emergency advisories.
              </p>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 14 }}>
                <div style={{ padding: '16px', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)' }}>
                  <strong style={{ fontSize: '0.95rem' }}>Seasonal Viral Flu Protocol</strong>
                  <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginTop: 4 }}>Updated 01 Sep 2026 • 24.5k Views</p>
                </div>
                <div style={{ padding: '16px', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)' }}>
                  <strong style={{ fontSize: '0.95rem' }}>Aarogyasri Subsidized Procedures</strong>
                  <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginTop: 4 }}>Updated 28 Aug 2026 • 18.2k Views</p>
                </div>
                <div style={{ padding: '16px', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)' }}>
                  <strong style={{ fontSize: '0.95rem' }}>Doorstep RMP Nursing Guide</strong>
                  <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginTop: 4 }}>Updated 24 Aug 2026 • 12.1k Views</p>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'notifications' && <NotificationsView />}

          {activeTab === 'analytics' && <ReportsView />}

          {activeTab === 'audit' && <AuditLogsView />}

          {activeTab === 'settings' && <SettingsView />}
        </main>
      </div>

      {/* Verify Doctor Modal */}
      <AddDoctorModal
        isOpen={isAddDoctorOpen}
        onClose={() => setIsAddDoctorOpen(false)}
      />
    </div>
  );
}
