import React, { useState } from 'react';
import { X, ShieldCheck, CheckCircle2, AlertCircle, FileText, Check, Ban, ExternalLink, Award, Building2 } from 'lucide-react';

export default function DoctorVerificationModal({ isOpen, onClose, doctor, onVerified }) {
  const [checklist, setChecklist] = useState({
    identity: true,
    mci: true,
    qualification: true,
    affiliation: true,
  });
  const [rejectionReason, setRejectionReason] = useState('');
  const [showRejectBox, setShowRejectBox] = useState(false);

  if (!isOpen || !doctor) return null;

  const handleApprove = () => {
    onVerified(doctor.id, 'Verified');
    onClose();
  };

  const handleReject = () => {
    onVerified(doctor.id, 'Rejected');
    onClose();
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content" style={{ width: '680px', maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <ShieldCheck size={26} color="var(--primary)" />
            <div>
              <h3>Doctor Credentialing & Verification Workspace</h3>
              <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                App Registration Audit • ID: {doctor.id}
              </p>
            </div>
          </div>
          <button className="icon-btn" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        {/* Doctor Identity Header */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '16px', background: 'var(--bg-main)', borderRadius: 'var(--radius-md)', marginBottom: 20 }}>
          <img src={doctor.avatar} alt={doctor.name} style={{ width: 60, height: 60, borderRadius: '50%', objectFit: 'cover' }} />
          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h4 style={{ fontSize: '1.15rem', fontWeight: 800 }}>{doctor.name}</h4>
              <span className={`status-badge ${doctor.status === 'Verified' ? 'active' : doctor.status === 'Rejected' ? 'inactive' : 'pending'}`}>
                {doctor.status}
              </span>
            </div>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginTop: 2 }}>
              {doctor.specialty} • {doctor.hospital || 'Independent Practice'}
            </p>
            <div style={{ marginTop: 6, display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              <span className="status-badge" style={{ background: 'var(--primary-light)', color: 'var(--primary)', fontSize: '0.72rem', fontWeight: 700 }}>
                MCI Reg: {doctor.registrationNumber}
              </span>
              <span className="status-badge" style={{ background: 'var(--bg-card)', border: '1px solid var(--border)', fontSize: '0.72rem' }}>
                Phone: {doctor.phone}
              </span>
              <span className="status-badge" style={{ background: 'var(--bg-card)', border: '1px solid var(--border)', fontSize: '0.72rem' }}>
                Exp: {doctor.exp}
              </span>
            </div>
          </div>
        </div>

        {/* Uploaded Verification Documents Preview */}
        <div style={{ marginBottom: 20 }}>
          <h4 style={{ fontSize: '0.88rem', fontWeight: 800, marginBottom: 10 }}>Uploaded Documents for Audit</h4>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div style={{ padding: 12, border: '1px solid var(--border)', borderRadius: 8, background: 'var(--bg-card)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <FileText size={18} color="var(--primary)" />
                <div>
                  <div style={{ fontSize: '0.82rem', fontWeight: 700 }}>MCI Registration Certificate</div>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>PDF • Verified via TSMC</div>
                </div>
              </div>
              <button className="icon-btn" title="View Document">
                <ExternalLink size={14} />
              </button>
            </div>

            <div style={{ padding: 12, border: '1px solid var(--border)', borderRadius: 8, background: 'var(--bg-card)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <Award size={18} color="var(--primary)" />
                <div>
                  <div style={{ fontSize: '0.82rem', fontWeight: 700 }}>Post-Graduate Degree (MD)</div>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>PDF • NBE Certified</div>
                </div>
              </div>
              <button className="icon-btn" title="View Document">
                <ExternalLink size={14} />
              </button>
            </div>
          </div>
        </div>

        {/* Verification Checklist */}
        <div style={{ marginBottom: 20 }}>
          <h4 style={{ fontSize: '0.88rem', fontWeight: 800, marginBottom: 10 }}>Super Admin Credentialing Checklist</h4>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <label style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)', cursor: 'pointer' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <CheckCircle2 size={18} color={checklist.identity ? 'var(--success)' : 'var(--text-muted)'} />
                <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>Government Photo Identity & Mobile Verification</span>
              </div>
              <input type="checkbox" checked={checklist.identity} onChange={e => setChecklist({ ...checklist, identity: e.target.checked })} />
            </label>

            <label style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)', cursor: 'pointer' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <CheckCircle2 size={18} color={checklist.mci ? 'var(--success)' : 'var(--text-muted)'} />
                <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>Medical Council of India (MCI) / State Council Active License Check</span>
              </div>
              <input type="checkbox" checked={checklist.mci} onChange={e => setChecklist({ ...checklist, mci: e.target.checked })} />
            </label>

            <label style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)', cursor: 'pointer' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <CheckCircle2 size={18} color={checklist.qualification ? 'var(--success)' : 'var(--text-muted)'} />
                <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>Medical Degrees (MBBS, MD/MS, DM) Authenticity Verified</span>
              </div>
              <input type="checkbox" checked={checklist.qualification} onChange={e => setChecklist({ ...checklist, qualification: e.target.checked })} />
            </label>

            <label style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)', cursor: 'pointer' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <CheckCircle2 size={18} color={checklist.affiliation ? 'var(--success)' : 'var(--text-muted)'} />
                <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>Hospital Practice Affiliation / Independent Clinic Compliance</span>
              </div>
              <input type="checkbox" checked={checklist.affiliation} onChange={e => setChecklist({ ...checklist, affiliation: e.target.checked })} />
            </label>
          </div>
        </div>

        {/* Optional Rejection Reason Box */}
        {showRejectBox && (
          <div style={{ padding: 14, background: 'var(--error-bg)', borderRadius: 8, border: '1px solid var(--error-border)', marginBottom: 20 }}>
            <label style={{ fontSize: '0.82rem', fontWeight: 700, color: 'var(--error)', display: 'block', marginBottom: 6 }}>
              Reason for Rejection / Document Re-upload Request:
            </label>
            <textarea
              style={{ width: '100%', padding: 8, borderRadius: 6, border: '1px solid var(--border)', fontSize: '0.82rem' }}
              rows={3}
              placeholder="e.g. MCI certificate expired or blurred. Please re-upload current council registration..."
              value={rejectionReason}
              onChange={e => setRejectionReason(e.target.value)}
            />
            <button
              type="button"
              className="btn-outline"
              style={{ marginTop: 8, color: 'var(--error)', borderColor: 'var(--error)', width: '100%', justifyContent: 'center' }}
              onClick={handleReject}
            >
              Confirm Rejection & Notify Doctor
            </button>
          </div>
        )}

        {/* Action Decision */}
        <div className="form-actions" style={{ display: 'flex', justifyContent: 'space-between' }}>
          {!showRejectBox ? (
            <button
              type="button"
              className="btn-outline"
              style={{ color: 'var(--error)', borderColor: 'var(--error)' }}
              onClick={() => setShowRejectBox(true)}
            >
              <Ban size={15} /> Reject / Request Changes
            </button>
          ) : (
            <button
              type="button"
              className="btn-outline"
              onClick={() => setShowRejectBox(false)}
            >
              Cancel Rejection
            </button>
          )}

          <div style={{ display: 'flex', gap: 10 }}>
            <button type="button" className="btn-outline" onClick={onClose}>
              Close
            </button>
            <button
              type="button"
              className="btn-primary"
              style={{ background: 'var(--success)', borderColor: 'var(--success)' }}
              onClick={handleApprove}
            >
              <Check size={16} /> Approve & Activate Doctor
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
