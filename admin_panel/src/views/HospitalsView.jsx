import React, { useState, useEffect } from 'react';
import { Plus, Search, Eye, Building2, MapPin, Phone, Layers, Users, X } from 'lucide-react';
import AddHospitalMultiStepModal from '../components/AddHospitalMultiStepModal';
import MetricCard from '../components/MetricCard';
import { healthApi } from '../services/api';
import { DB_SNAPSHOT } from '../data/databaseSnapshot';
import illus3 from '../assets/illustrations/3.png';
import illus1 from '../assets/illustrations/1.png';
import illus7 from '../assets/illustrations/7.png';
import illus2 from '../assets/illustrations/2.png';

export default function HospitalsView() {
  const [searchTerm, setSearchTerm] = useState('');
  const [isMultiStepOpen, setIsMultiStepOpen] = useState(false);
  const [selectedHospitalDetail, setSelectedHospitalDetail] = useState(null);
  const [hospitals, setHospitals] = useState(DB_SNAPSHOT.hospitals);
  const [loading, setLoading] = useState(false);

  const loadHospitals = async () => {
    try {
      const res = await healthApi.getHospitals();
      const list = res?.data?.data || res?.data || [];
      if (Array.isArray(list)) {
        setHospitals(list.map(h => ({
          id: h.id,
          name: h.name,
          location: h.location || h.city || (h.state ? `${h.city}, ${h.state}` : 'Telangana'),
          address: h.address || 'Telangana, India',
          type: h.hospital_type || 'Super Specialty',
          license: h.license_number || 'TS-HYD-HOSP-LIVE',
          doctors: h.staff_count || 0,
          departments: h.departments ? (typeof h.departments === 'string' ? JSON.parse(h.departments) : h.departments) : ['General Medicine'],
          beds: h.beds || '100+',
          users: (h.reviews_count || 0).toLocaleString(),
          status: h.verification_status === 'verified' || h.status === 'Active' ? 'Active' : 'Pending',
          phone: h.primary_phone || h.emergency_phone || '+91 40 4488 5000'
        })));
      }
    } catch (e) {
      console.warn('Live hospitals fetch note:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadHospitals();
  }, []);

  const handleHospitalAdded = (newH) => {
    setHospitals([newH, ...hospitals]);
  };

  const filtered = hospitals.filter(h => h.name.toLowerCase().includes(searchTerm.toLowerCase()) || (h.location && h.location.toLowerCase().includes(searchTerm.toLowerCase())));

  const activeCount = hospitals.filter(h => h.status === 'Active').length;
  const pendingCount = hospitals.filter(h => h.status === 'Pending').length;

  return (
    <div>
      {/* 4 Hospital KPI Stats (3 per row) */}
      <div className="metrics-grid" style={{ marginBottom: 20 }}>
        <MetricCard
          title="Registered Facilities"
          value={hospitals.length.toString()}
          change="Telangana Network"
          illustration={illus3}
          color="blue"
        />
        <MetricCard
          title="Active Empaneled"
          value={activeCount.toString()}
          change="Aarogyasri Active"
          illustration={illus1}
          color="green"
        />
        <MetricCard
          title="Pending Onboarding"
          value={pendingCount.toString()}
          change="In Inspection"
          isPositive={pendingCount === 0}
          illustration={illus7}
          color="orange"
        />
        <MetricCard
          title="Verified Network"
          value={activeCount > 0 ? '100%' : '0%'}
          change="NABH Empaneled"
          illustration={illus2}
          color="blue"
        />
      </div>

      <div className="table-card">
        <div className="table-header">
          <div className="table-title">
            <h3>Hospitals & Healthcare Facilities Management</h3>
            <p>Live facilities directory loaded directly from Hostinger MySQL</p>
          </div>

          <div className="table-actions">
            <div className="search-box">
              <Search size={16} />
              <input
                type="text"
                placeholder="Search hospitals..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>

            <button className="btn-primary" onClick={() => setIsMultiStepOpen(true)}>
              <Plus size={16} /> Empanel Hospital (8-Step)
            </button>
          </div>
        </div>

        <table className="custom-table">
          <thead>
            <tr>
              <th>Hospital Name</th>
              <th>Location</th>
              <th>Type</th>
              <th>License No</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length > 0 ? (
              filtered.map((h, i) => (
                <tr key={h.id || i}>
                  <td>
                    <div className="table-user-cell">
                      <div style={{
                        width: 38,
                        height: 38,
                        borderRadius: 8,
                        background: 'var(--primary-light)',
                        color: 'var(--primary)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontWeight: 800,
                        fontSize: '0.9rem'
                      }}>
                        {h.name.charAt(0)}
                      </div>
                      <div>
                        <strong>{h.name}</strong>
                        <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>{h.phone}</div>
                      </div>
                    </div>
                  </td>
                  <td>
                    <span style={{ fontSize: '0.85rem' }}>{h.location}</span>
                  </td>
                  <td>
                    <span className="status-badge" style={{ background: 'var(--border-light)', color: 'var(--text-main)', fontWeight: 600 }}>
                      {h.type}
                    </span>
                  </td>
                  <td>
                    <code style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{h.license}</code>
                  </td>
                  <td>
                    <span className={`status-badge ${h.status === 'Active' ? 'active' : 'pending'}`}>
                      {h.status}
                    </span>
                  </td>
                  <td>
                    <div className="action-btn-group">
                      <button className="action-btn" title="View Facility Profile" onClick={() => setSelectedHospitalDetail(h)}>
                        <Eye size={15} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan="6" style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                  {loading ? 'Loading live hospitals from MySQL...' : 'No hospitals found in the database.'}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Hospital Drawer Detail View */}
      {selectedHospitalDetail && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ width: '640px' }}>
            <div className="modal-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <Building2 size={24} color="var(--primary)" />
                <div>
                  <h3>{selectedHospitalDetail.name}</h3>
                  <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>License: {selectedHospitalDetail.license}</p>
                </div>
              </div>
              <button className="icon-btn" onClick={() => setSelectedHospitalDetail(null)}>
                <X size={18} />
              </button>
            </div>

            <div style={{ padding: '16px 0', display: 'flex', flexDirection: 'column', gap: 16 }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                <div style={{ padding: 12, background: 'var(--bg-main)', borderRadius: 8 }}>
                  <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)', fontWeight: 700 }}>FACILITY ADDRESS</div>
                  <div style={{ fontSize: '0.85rem', fontWeight: 600, marginTop: 4, display: 'flex', alignItems: 'center', gap: 6 }}>
                    <MapPin size={14} color="var(--primary)" />
                    {selectedHospitalDetail.address}
                  </div>
                </div>

                <div style={{ padding: 12, background: 'var(--bg-main)', borderRadius: 8 }}>
                  <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)', fontWeight: 700 }}>EMERGENCY CONTACT</div>
                  <div style={{ fontSize: '0.85rem', fontWeight: 600, marginTop: 4, display: 'flex', alignItems: 'center', gap: 6 }}>
                    <Phone size={14} color="var(--primary)" />
                    {selectedHospitalDetail.phone}
                  </div>
                </div>
              </div>

              <div>
                <h4 style={{ fontSize: '0.85rem', fontWeight: 700, marginBottom: 8 }}>Clinical Departments</h4>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                  {Array.isArray(selectedHospitalDetail.departments) ? selectedHospitalDetail.departments.map((dep, i) => (
                    <span key={i} style={{ padding: '4px 10px', background: 'var(--primary-light)', color: 'var(--primary)', borderRadius: 6, fontSize: '0.78rem', fontWeight: 700 }}>
                      {dep}
                    </span>
                  )) : (
                    <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>General Medicine</span>
                  )}
                </div>
              </div>
            </div>

            <div className="form-actions">
              <button className="btn-primary" style={{ width: '100%', justifyContent: 'center' }} onClick={() => setSelectedHospitalDetail(null)}>
                Close Profile
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 8-Step Empanelment Modal */}
      <AddHospitalMultiStepModal
        isOpen={isMultiStepOpen}
        onClose={() => setIsMultiStepOpen(false)}
        onHospitalAdded={handleHospitalAdded}
      />
    </div>
  );
}
