import React, { useState } from 'react';
import { X, ShieldCheck, CheckCircle2, AlertCircle, FileText, Check, Ban, ExternalLink, Award, Store, Clock, MapPin, Phone } from 'lucide-react';

export default function StoreVerificationModal({ isOpen, onClose, store, onVerified }) {
  const [checklist, setChecklist] = useState({
    license: true,
    address: true,
    pharmacist: true,
    coldStorage: true,
  });
  const [rejectionReason, setRejectionReason] = useState('');
  const [showRejectBox, setShowRejectBox] = useState(false);

  if (!isOpen || !store) return null;

  const handleApprove = () => {
    onVerified(store.id, 'Verified');
    onClose();
  };

  const handleReject = () => {
    onVerified(store.id, 'Rejected', rejectionReason || 'State Drug License could not be authenticated');
    onClose();
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content" style={{ width: '680px', maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <Store size={26} color="#0D9488" />
            <div>
              <h3>Medical Store Partner Verification Workspace</h3>
              <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                Pharmacy KYC & Drug Authority Audit • ID: {store.id}
              </p>
            </div>
          </div>
          <button className="icon-btn" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        {/* Store Header */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '16px', background: 'var(--bg-main)', borderRadius: 'var(--radius-md)', marginBottom: 20 }}>
          <img
            src={store.imageUrl || store.image_url || 'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=400'}
            alt={store.name}
            style={{ width: 64, height: 64, borderRadius: 'var(--radius-md)', objectFit: 'cover' }}
          />
          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h4 style={{ fontSize: '1.15rem', fontWeight: 800 }}>{store.name}</h4>
              <span className={`status-badge ${store.verificationStatus === 'Verified' || store.verification_status === 'verified' ? 'active' : store.verificationStatus === 'Rejected' || store.verification_status === 'rejected' ? 'inactive' : 'pending'}`}>
                {store.verificationStatus || store.verification_status || 'Pending'}
              </span>
            </div>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginTop: 2, display: 'flex', alignItems: 'center', gap: 4 }}>
              <MapPin size={13} color="#0D9488" />
              {store.address || 'Hitech City, Hyderabad'}
            </p>
            <div style={{ marginTop: 6, display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              <span className="status-badge" style={{ background: '#CCFBF1', color: '#0F766E', fontSize: '0.72rem', fontWeight: 700 }}>
                Drug License: {store.licenseNumber || store.license || 'TS-HYD-PHARM-2026-9000'}
              </span>
              <span className="status-badge" style={{ background: '#F1F5F9', color: '#475569', fontSize: '0.72rem' }}>
                <Clock size={11} style={{ marginRight: 4 }} />
                {store.is24x7 ? '24x7 All-Night Delivery' : `${store.openingTime || '08:00 AM'} - ${store.closingTime || '10:00 PM'}`}
              </span>
            </div>
          </div>
        </div>

        {/* Contact & Registration Metrics */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 20 }}>
          <div style={{ padding: 12, border: '1px solid var(--border-color)', borderRadius: 'var(--radius-md)' }}>
            <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>Registered Phone</span>
            <p style={{ fontWeight: 700, fontSize: '0.9rem', marginTop: 4, display: 'flex', alignItems: 'center', gap: 6 }}>
              <Phone size={14} color="#0D9488" />
              {store.phone || '+91 98480 12345'}
            </p>
          </div>
          <div style={{ padding: 12, border: '1px solid var(--border-color)', borderRadius: 'var(--radius-md)' }}>
            <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>Fulfillment Zone</span>
            <p style={{ fontWeight: 700, fontSize: '0.9rem', marginTop: 4 }}>
              {store.area || 'Hyderabad'} (15-Min Radius)
            </p>
          </div>
        </div>

        {/* Drug Compliance Verification Checklist */}
        <div style={{ marginBottom: 24 }}>
          <h4 style={{ fontSize: '0.9rem', fontWeight: 700, marginBottom: 10, display: 'flex', alignItems: 'center', gap: 6 }}>
            <ShieldCheck size={18} color="#0D9488" />
            Telangana State Drug Control Administration Compliance
          </h4>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: '0.85rem', cursor: 'pointer' }}>
              <input
                type="checkbox"
                checked={checklist.license}
                onChange={e => setChecklist({ ...checklist, license: e.target.checked })}
              />
              State Form 20/21 Drug Retail License Valid on State Drug Portal
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: '0.85rem', cursor: 'pointer' }}>
              <input
                type="checkbox"
                checked={checklist.address}
                onChange={e => setChecklist({ ...checklist, address: e.target.checked })}
              />
              Physical premises geo-coordinates validated for 15-minute delivery radius
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: '0.85rem', cursor: 'pointer' }}>
              <input
                type="checkbox"
                checked={checklist.pharmacist}
                onChange={e => setChecklist({ ...checklist, pharmacist: e.target.checked })}
              />
              Registered Pharmacist credentials on file with State Pharmacy Council
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: '0.85rem', cursor: 'pointer' }}>
              <input
                type="checkbox"
                checked={checklist.coldStorage}
                onChange={e => setChecklist({ ...checklist, coldStorage: e.target.checked })}
              />
              Temperature-controlled refrigeration compliant for insulin & vaccines
            </label>
          </div>
        </div>

        {/* Rejection Form Box if initiated */}
        {showRejectBox && (
          <div style={{ padding: 14, background: '#FEF2F2', border: '1px solid #FCA5A5', borderRadius: 'var(--radius-md)', marginBottom: 20 }}>
            <h5 style={{ color: '#B91C1C', fontWeight: 700, fontSize: '0.85rem', marginBottom: 6 }}>
              Specify Ground for Rejection
            </h5>
            <textarea
              style={{ width: '100%', padding: 8, borderRadius: 6, border: '1px solid #F87171', fontSize: '0.82rem', fontFamily: 'inherit' }}
              rows={3}
              placeholder="e.g. State Drug License expired or address does not match registered trade certificate..."
              value={rejectionReason}
              onChange={e => setRejectionReason(e.target.value)}
            />
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginTop: 8 }}>
              <button className="btn-secondary" style={{ padding: '4px 10px', fontSize: '0.78rem' }} onClick={() => setShowRejectBox(false)}>
                Cancel
              </button>
              <button className="btn-primary" style={{ background: '#DC2626', borderColor: '#DC2626', padding: '4px 12px', fontSize: '0.78rem' }} onClick={handleReject}>
                Confirm Rejection
              </button>
            </div>
          </div>
        )}

        {/* Action Footer */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, borderTop: '1px solid var(--border-color)', paddingTop: 16 }}>
          <button className="btn-secondary" onClick={onClose}>
            Close
          </button>
          {!showRejectBox && (
            <button
              className="btn-secondary"
              style={{ color: '#DC2626', borderColor: '#FCA5A5' }}
              onClick={() => setShowRejectBox(true)}
            >
              <Ban size={15} style={{ marginRight: 6 }} />
              Reject Store
            </button>
          )}
          <button
            className="btn-primary"
            style={{ background: '#0D9488', borderColor: '#0D9488' }}
            onClick={handleApprove}
          >
            <Check size={16} style={{ marginRight: 6 }} />
            Approve & Activate Store
          </button>
        </div>
      </div>
    </div>
  );
}
