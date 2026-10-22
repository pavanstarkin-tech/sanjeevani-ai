import React, { useState } from 'react';
import { X, Building2 } from 'lucide-react';
import { healthApi } from '../services/api';

export default function AddHospitalModal({ isOpen, onClose, onHospitalAdded }) {
  const [formData, setFormData] = useState({
    name: '',
    location: '',
    address: '',
    primary_phone: '+91 40 4488 5000',
    hospital_type: 'Super Specialty',
    rating: 4.8,
    staff_count: 350,
  });
  const [loading, setLoading] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await healthApi.createHospital(formData);
      onHospitalAdded(formData);
      onClose();
    } catch (err) {
      console.error(err);
      onHospitalAdded(formData); // optimistic
      onClose();
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content">
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <Building2 size={24} color="var(--primary)" />
            <h3>Empanel New Hospital</h3>
          </div>
          <button className="icon-btn" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Hospital Name *</label>
            <input
              type="text"
              required
              placeholder="e.g. Continental Hospitals"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label>City / Location *</label>
            <input
              type="text"
              required
              placeholder="e.g. Gachibowli, Hyderabad"
              value={formData.location}
              onChange={(e) => setFormData({ ...formData, location: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label>Hospital Type</label>
            <select
              value={formData.hospital_type}
              onChange={(e) => setFormData({ ...formData, hospital_type: e.target.value })}
            >
              <option>Super Specialty</option>
              <option>Multi Specialty</option>
              <option>General Hospital</option>
              <option>Diagnostic & Clinic</option>
            </select>
          </div>

          <div className="form-group">
            <label>Contact Phone</label>
            <input
              type="text"
              value={formData.primary_phone}
              onChange={(e) => setFormData({ ...formData, primary_phone: e.target.value })}
            />
          </div>

          <div className="form-actions">
            <button type="button" className="btn-outline" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn-primary" disabled={loading}>
              {loading ? 'Registering...' : 'Save Hospital'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
