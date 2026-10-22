import React, { useState, useEffect } from 'react';
import { X, UserRound, Award, Building2, Clock, DollarSign, ShieldCheck } from 'lucide-react';
import { healthApi } from '../services/api';

export default function AddDoctorModal({ isOpen, onClose, onDoctorAdded }) {
  const [activeStep, setActiveStep] = useState(1);
  const [hospitalsList, setHospitalsList] = useState([]);

  const [formData, setFormData] = useState({
    // 1. Basic Info
    name: '',
    phone: '',
    email: '',
    gender: 'Male',
    languages: 'English, Telugu, Hindi',

    // 2. Qualifications & Credentials
    specialty: 'General Physician',
    qualifications: 'MBBS, MD',
    registrationNumber: '',
    council: 'Telangana State Medical Council',
    experience: 8,

    // 3. Affiliation & Department
    hospitalId: '',
    hospitalName: 'KIMS Hospitals',
    department: 'General Medicine',
    chamberNo: 'Room 204, Block B',

    // 4. Consultation Modes & Fees
    inClinicFee: 800,
    videoFee: 600,
    homeVisitFee: 1000,
    offersInClinic: true,
    offersVideo: true,
    offersHomeVisit: false,
    isAarogyasriEmpaneled: true,

    // 5. Schedule & Payout
    workingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    morningShift: '09:00 AM - 01:00 PM',
    eveningShift: '05:00 PM - 09:00 PM',
    payoutUpi: '',
    verificationStatus: 'Verified'
  });

  useEffect(() => {
    async function loadHospitals() {
      try {
        const res = await healthApi.getHospitals();
        const list = res?.data?.data || res?.data || [];
        if (Array.isArray(list) && list.length > 0) {
          setHospitalsList(list);
          setFormData(prev => ({
            ...prev,
            hospitalId: list[0].id,
            hospitalName: list[0].name
          }));
        }
      } catch (e) {
        console.warn('Could not load hospitals for doctor modal', e);
      }
    }
    if (isOpen) {
      loadHospitals();
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const toggleDay = (day) => {
    if (formData.workingDays.includes(day)) {
      setFormData({ ...formData, workingDays: formData.workingDays.filter(d => d !== day) });
    } else {
      setFormData({ ...formData, workingDays: [...formData.workingDays, day] });
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onDoctorAdded({
      id: `DOC-${Math.floor(1000 + Math.random() * 9000)}`,
      name: formData.name,
      hospital: formData.hospitalName,
      specialty: formData.specialty,
      exp: `${formData.experience}+ Years`,
      registrationNumber: formData.registrationNumber,
      status: formData.verificationStatus,
      clinicFee: formData.inClinicFee,
      avatar: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=200',
    });
    onClose();
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content" style={{ width: '680px', maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <UserRound size={24} color="var(--primary)" />
            <div>
              <h3>Add & Credential New Doctor</h3>
              <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>MCI verification, hospital affiliation & consultation pricing</p>
            </div>
          </div>
          <button className="icon-btn" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        {/* Step Tabs */}
        <div style={{ display: 'flex', gap: 8, borderBottom: '1px solid var(--border)', paddingBottom: 12, marginBottom: 16 }}>
          <button
            type="button"
            className={`btn-outline ${activeStep === 1 ? 'active' : ''}`}
            style={{ flex: 1, padding: '8px', fontSize: '0.8rem', borderColor: activeStep === 1 ? 'var(--primary)' : 'var(--border)' }}
            onClick={() => setActiveStep(1)}
          >
            1. Basic & Bio
          </button>
          <button
            type="button"
            className={`btn-outline ${activeStep === 2 ? 'active' : ''}`}
            style={{ flex: 1, padding: '8px', fontSize: '0.8rem', borderColor: activeStep === 2 ? 'var(--primary)' : 'var(--border)' }}
            onClick={() => setActiveStep(2)}
          >
            2. Qualifications & MCI
          </button>
          <button
            type="button"
            className={`btn-outline ${activeStep === 3 ? 'active' : ''}`}
            style={{ flex: 1, padding: '8px', fontSize: '0.8rem', borderColor: activeStep === 3 ? 'var(--primary)' : 'var(--border)' }}
            onClick={() => setActiveStep(3)}
          >
            3. Hospital & Fees
          </button>
          <button
            type="button"
            className={`btn-outline ${activeStep === 4 ? 'active' : ''}`}
            style={{ flex: 1, padding: '8px', fontSize: '0.8rem', borderColor: activeStep === 4 ? 'var(--primary)' : 'var(--border)' }}
            onClick={() => setActiveStep(4)}
          >
            4. Schedule & Payout
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          {/* STEP 1: Basic & Bio */}
          {activeStep === 1 && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div className="form-group">
                <label>Doctor Full Name *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Dr. Anil Kumar, MD"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Mobile Number *</label>
                  <input
                    type="tel"
                    required
                    placeholder="+91 98480 12345"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label>Official Email</label>
                  <input
                    type="email"
                    placeholder="doctor@hospital.com"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Gender</label>
                  <select
                    value={formData.gender}
                    onChange={(e) => setFormData({ ...formData, gender: e.target.value })}
                  >
                    <option>Male</option>
                    <option>Female</option>
                    <option>Other</option>
                  </select>
                </div>
                <div className="form-group">
                  <label>Languages Spoken</label>
                  <input
                    type="text"
                    placeholder="English, Telugu, Hindi"
                    value={formData.languages}
                    onChange={(e) => setFormData({ ...formData, languages: e.target.value })}
                  />
                </div>
              </div>
            </div>
          )}

          {/* STEP 2: Qualifications & Credentials */}
          {activeStep === 2 && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Primary Specialization *</label>
                  <select
                    value={formData.specialty}
                    onChange={(e) => setFormData({ ...formData, specialty: e.target.value })}
                  >
                    <option>General Physician</option>
                    <option>Cardiologist</option>
                    <option>Orthopedic Surgeon</option>
                    <option>Gynecologist</option>
                    <option>Neurologist</option>
                    <option>Pediatrician</option>
                    <option>Dermatologist</option>
                    <option>Gastroenterologist</option>
                    <option>RMP Doctor (Home Visit)</option>
                  </select>
                </div>
                <div className="form-group">
                  <label>Degrees & Qualifications *</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. MBBS, MD (General Medicine), DM"
                    value={formData.qualifications}
                    onChange={(e) => setFormData({ ...formData, qualifications: e.target.value })}
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Medical Council Registration Number (MCI / State) *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. MCI-TS-2016-5512"
                  value={formData.registrationNumber}
                  onChange={(e) => setFormData({ ...formData, registrationNumber: e.target.value })}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 0.8fr', gap: 12 }}>
                <div className="form-group">
                  <label>State Medical Council Name</label>
                  <input
                    type="text"
                    value={formData.council}
                    onChange={(e) => setFormData({ ...formData, council: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label>Total Experience (Years)</label>
                  <input
                    type="number"
                    min="1"
                    max="60"
                    value={formData.experience}
                    onChange={(e) => setFormData({ ...formData, experience: parseInt(e.target.value || 0) })}
                  />
                </div>
              </div>
            </div>
          )}

          {/* STEP 3: Hospital Affiliation & Pricing */}
          {activeStep === 3 && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div className="form-group">
                <label>Primary Hospital Affiliation *</label>
                <select
                  value={formData.hospitalName}
                  onChange={(e) => {
                    const selName = e.target.value;
                    const found = hospitalsList.find(h => h.name === selName);
                    setFormData({
                      ...formData,
                      hospitalName: selName,
                      hospitalId: found ? found.id : ''
                    });
                  }}
                >
                  {hospitalsList.length > 0 ? (
                    hospitalsList.map(h => (
                      <option key={h.id} value={h.name}>{h.name} ({h.city || 'Hyderabad'})</option>
                    ))
                  ) : (
                    <>
                      <option>KIMS Hospitals</option>
                      <option>Apollo Hospitals</option>
                      <option>Yashoda Hospitals</option>
                      <option>CARE Hospitals</option>
                    </>
                  )}
                  <option value="Independent Practice">Independent Private Practice</option>
                </select>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Assigned Department</label>
                  <input
                    type="text"
                    placeholder="e.g. Cardiology"
                    value={formData.department}
                    onChange={(e) => setFormData({ ...formData, department: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label>Chamber / Room No.</label>
                  <input
                    type="text"
                    placeholder="e.g. OPD Block B, Room 204"
                    value={formData.chamberNo}
                    onChange={(e) => setFormData({ ...formData, chamberNo: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ background: 'var(--bg-main)', padding: 14, borderRadius: 8 }}>
                <div style={{ fontSize: '0.82rem', fontWeight: 800, marginBottom: 8, color: 'var(--text-main)' }}>
                  Consultation Modes & Patient Fees (₹)
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10 }}>
                  <div className="form-group">
                    <label style={{ fontSize: '0.75rem' }}>In-Clinic Visit (₹)</label>
                    <input
                      type="number"
                      value={formData.inClinicFee}
                      onChange={(e) => setFormData({ ...formData, inClinicFee: parseFloat(e.target.value || 0) })}
                    />
                  </div>
                  <div className="form-group">
                    <label style={{ fontSize: '0.75rem' }}>Video Telehealth (₹)</label>
                    <input
                      type="number"
                      value={formData.videoFee}
                      onChange={(e) => setFormData({ ...formData, videoFee: parseFloat(e.target.value || 0) })}
                    />
                  </div>
                  <div className="form-group">
                    <label style={{ fontSize: '0.75rem' }}>Home Visit RMP (₹)</label>
                    <input
                      type="number"
                      value={formData.homeVisitFee}
                      onChange={(e) => setFormData({ ...formData, homeVisitFee: parseFloat(e.target.value || 0) })}
                    />
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* STEP 4: Schedule & Payout */}
          {activeStep === 4 && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div>
                <label style={{ fontSize: '0.82rem', fontWeight: 700, marginBottom: 6, display: 'block' }}>
                  Available Working Days
                </label>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                  {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map(day => (
                    <button
                      key={day}
                      type="button"
                      onClick={() => toggleDay(day)}
                      style={{
                        padding: '6px 12px',
                        borderRadius: 6,
                        border: '1px solid',
                        borderColor: formData.workingDays.includes(day) ? 'var(--primary)' : 'var(--border)',
                        background: formData.workingDays.includes(day) ? 'var(--primary)' : 'transparent',
                        color: formData.workingDays.includes(day) ? 'white' : 'var(--text-main)',
                        fontWeight: 700,
                        fontSize: '0.8rem',
                        cursor: 'pointer'
                      }}
                    >
                      {day}
                    </button>
                  ))}
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Morning Shift Hours</label>
                  <input
                    type="text"
                    value={formData.morningShift}
                    onChange={(e) => setFormData({ ...formData, morningShift: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label>Evening Shift Hours</label>
                  <input
                    type="text"
                    value={formData.eveningShift}
                    onChange={(e) => setFormData({ ...formData, eveningShift: e.target.value })}
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Doctor Payout UPI ID / Account (80% Settlement)</label>
                <input
                  type="text"
                  placeholder="doctor.name@okaxis or Bank A/C"
                  value={formData.payoutUpi}
                  onChange={(e) => setFormData({ ...formData, payoutUpi: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label>Initial Verification Status</label>
                <select
                  value={formData.verificationStatus}
                  onChange={(e) => setFormData({ ...formData, verificationStatus: e.target.value })}
                >
                  <option value="Verified">Verified & Active</option>
                  <option value="Pending">Pending Document Audit</option>
                </select>
              </div>
            </div>
          )}

          {/* Modal Actions */}
          <div className="form-actions" style={{ marginTop: 20, display: 'flex', justifyContent: 'space-between' }}>
            <div>
              {activeStep > 1 && (
                <button type="button" className="btn-outline" onClick={() => setActiveStep(activeStep - 1)}>
                  Back
                </button>
              )}
            </div>

            <div style={{ display: 'flex', gap: 8 }}>
              <button type="button" className="btn-outline" onClick={onClose}>
                Cancel
              </button>
              {activeStep < 4 ? (
                <button type="button" className="btn-primary" onClick={() => setActiveStep(activeStep + 1)}>
                  Next Step →
                </button>
              ) : (
                <button type="submit" className="btn-primary" style={{ background: 'var(--success)', borderColor: 'var(--success)' }}>
                  <ShieldCheck size={16} /> Verify & Add Doctor
                </button>
              )}
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}
