import React from 'react';
import { X, ShieldCheck, FileText, Heart, Activity } from 'lucide-react';

export default function UserDetailsModal({ isOpen, onClose, user }) {
  if (!isOpen || !user) return null;

  return (
    <div className="modal-overlay">
      <div className="modal-content" style={{ width: '600px' }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <ShieldCheck size={26} color="var(--primary)" />
            <div>
              <h3>Verified Patient Health Vault</h3>
              <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>ABDM & Aarogyasri Empaneled ID</p>
            </div>
          </div>
          <button className="icon-btn" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '16px', background: 'var(--bg-main)', borderRadius: 'var(--radius-md)', marginBottom: 20 }}>
          <img src={user.avatar} alt={user.name} style={{ width: 54, height: 54, borderRadius: '50%', objectFit: 'cover' }} />
          <div>
            <h4 style={{ fontSize: '1.1rem', fontWeight: 800 }}>{user.name}</h4>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>{user.phone} • {user.email}</p>
            <div style={{ marginTop: 4, display: 'flex', gap: 8, alignItems: 'center' }}>
              <span className="status-badge active" style={{ fontSize: '0.75rem' }}>
                Aarogyasri ID: {user.aarogyasri}
              </span>
              <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', background: 'rgba(0,0,0,0.05)', padding: '2px 8px', borderRadius: 4 }}>
                {user.age} yrs • {user.gender}
              </span>
            </div>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, marginBottom: 16 }}>
          <div style={{ background: 'var(--bg-main)', padding: '12px', borderRadius: 'var(--radius-md)', textAlign: 'center' }}>
            <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>Blood Group</span>
            <div style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--error)' }}>{user.bloodGroup || 'B+'}</div>
          </div>
          <div style={{ background: 'var(--bg-main)', padding: '12px', borderRadius: 'var(--radius-md)', textAlign: 'center' }}>
            <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>Past Surgeries</span>
            <div style={{ fontSize: '0.85rem', fontWeight: 700 }}>{user.pastSurgeries || 'Appendectomy (2020)'}</div>
          </div>
          <div style={{ background: 'var(--bg-main)', padding: '12px', borderRadius: 'var(--radius-md)', textAlign: 'center' }}>
            <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>Allergies</span>
            <div style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--warning-text)' }}>{user.allergies || 'Penicillin Safe'}</div>
          </div>
        </div>

        <div style={{ background: 'var(--bg-main)', padding: '14px', borderRadius: 'var(--radius-md)', marginBottom: 20 }}>
          <div style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: 4 }}>Delivery & GPS Location</div>
          <div style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-primary)', marginBottom: 10 }}>📍 {user.address || 'Madhapur, Hyderabad, Telangana'}</div>
          <div style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: 4 }}>Emergency SOS Contact</div>
          <div style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--error)' }}>🚨 {user.emergencyContact || 'Priya Sharma (9876500001) • Family'}</div>
        </div>

        <div>
          <h4 style={{ fontSize: '0.92rem', fontWeight: 800, marginBottom: 10 }}>Recent Medical Records & Prescriptions</h4>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <FileText size={18} color="var(--primary)" />
                <div>
                  <div style={{ fontSize: '0.88rem', fontWeight: 700 }}>Complete Blood Count (CBC)</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>18 May 2024 • KIMS Pathology Lab</div>
                </div>
              </div>
              <span className="status-badge active">Verified</span>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <Activity size={18} color="var(--primary)" />
                <div>
                  <div style={{ fontSize: '0.88rem', fontWeight: 700 }}>Digital Rx: Dr. Sandeep Attawar</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>18 May 2024 • Cardiology OP</div>
                </div>
              </div>
              <span className="status-badge active">Active Rx</span>
            </div>
          </div>
        </div>

        <div className="form-actions" style={{ marginTop: 24 }}>
          <button type="button" className="btn-primary" onClick={onClose} style={{ width: '100%', justifyContent: 'center' }}>
            Close Vault
          </button>
        </div>
      </div>
    </div>
  );
}
