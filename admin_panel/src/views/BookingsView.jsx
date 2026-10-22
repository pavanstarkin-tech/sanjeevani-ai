import React, { useState, useEffect } from 'react';
import { Search, Download, Eye, Edit3, Video } from 'lucide-react';
import MetricCard from '../components/MetricCard';
import { healthApi } from '../services/api';
import illus4 from '../assets/illustrations/4.png';
import illus1 from '../assets/illustrations/1.png';
import illus5 from '../assets/illustrations/5.png';

const DEFAULT_BOOKINGS = [
  { id: 'BK24851', patient: 'Rahul Kumar', doctor: 'Dr. Sandeep Attawar', hospital: 'KIMS Hospitals', datetime: '18 May 2024, 10:30 AM', status: 'Confirmed', payment: 'Paid' },
  { id: 'BK24850', patient: 'Sita Reddy', doctor: 'Dr. Priya Nair', hospital: 'Apollo Hospitals', datetime: '18 May 2024, 11:00 AM', status: 'Completed', payment: 'Paid' },
  { id: 'BK24849', patient: 'Vikram Singh', doctor: 'Dr. Naveen Thota', hospital: 'CARE Hospitals', datetime: '18 May 2024, 12:00 PM', status: 'Upcoming', payment: 'Paid' },
  { id: 'BK24848', patient: 'Anita Sharma', doctor: 'Dr. Madhavi Latha', hospital: 'Yashoda Hospitals', datetime: '19 May 2024, 09:30 AM', status: 'Upcoming', payment: 'Pending' },
  { id: 'BK24847', patient: 'Rakesh Patel', doctor: 'Dr. Sunil Kumar N', hospital: 'KIMS Hospitals', datetime: '19 May 2024, 10:00 AM', status: 'Cancelled', payment: 'Refunded' },
  { id: 'BK24846', patient: 'Neha Verma', doctor: 'Dr. Anil Kumar', hospital: 'Apollo Hospitals', datetime: '19 May 2024, 11:30 AM', status: 'Confirmed', payment: 'Paid' },
  { id: 'BK24845', patient: 'Pooja Mehta', doctor: 'Dr. Kavya S', hospital: 'CARE Hospitals', datetime: '20 May 2024, 02:00 PM', status: 'Upcoming', payment: 'Paid' },
];

export default function BookingsView() {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);

  async function loadAppointments() {
    try {
      const res = await healthApi.getAllAppointments();
      const list = res?.data?.data || res?.data;
      if (Array.isArray(list)) {
        setBookings(list.map(b => ({
          id: b.id,
          patient: b.patient_name || 'Patient ' + (b.user_id || ''),
          doctor: b.doctor_name || 'Dr. Assigned',
          hospital: b.hospital_name || 'Empaneled Hospital',
          datetime: `${b.appointment_date || ''}, ${b.time_slot || ''}`,
          status: b.booking_status ? (b.booking_status.charAt(0).toUpperCase() + b.booking_status.slice(1)) : 'Confirmed',
          payment: b.payment_status ? (b.payment_status.charAt(0).toUpperCase() + b.payment_status.slice(1)) : 'Paid',
        })));
      }
    } catch (err) {
      console.warn('Could not load live appointments:', err);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadAppointments();
    const timer = setInterval(loadAppointments, 10000); // 10s auto-refresh
    return () => clearInterval(timer);
  }, []);

  const filtered = bookings.filter(b => {
    const matchSearch = (b.patient || '').toLowerCase().includes(searchTerm.toLowerCase()) || (b.doctor || '').toLowerCase().includes(searchTerm.toLowerCase()) || (b.id || '').toLowerCase().includes(searchTerm.toLowerCase());
    const matchStatus = statusFilter === 'All' || b.status === statusFilter;
    return matchSearch && matchStatus;
  });

  return (
    <div>
      {/* 3 Booking Metric Cards (3 per row) */}
      <div className="metrics-grid cols-3" style={{ marginBottom: 20 }}>
        <MetricCard
          title="Total Bookings"
          value={bookings.length.toString()}
          change="Live Database"
          illustration={illus4}
          color="blue"
        />
        <MetricCard
          title="Confirmed Bookings"
          value={bookings.filter(b => b.status === 'Confirmed').length.toString()}
          change="Attended & Active"
          illustration={illus1}
          color="green"
        />
        <MetricCard
          title="Completed Consultations"
          value={bookings.filter(b => b.status === 'Completed').length.toString()}
          change="Completed"
          illustration={illus5}
          color="purple"
        />
      </div>
    <div className="table-card">
      <div className="table-header">
        <div className="table-title">
          <h3>Bookings Management</h3>
          <p>Total Bookings: {bookings.length} Consultations</p>
        </div>

        <div className="table-actions">
          <div className="search-box">
            <Search size={16} />
            <input
              type="text"
              placeholder="Search bookings..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <select
            className="filter-select"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="All">All Status</option>
            <option value="Confirmed">Confirmed</option>
            <option value="Upcoming">Upcoming</option>
            <option value="Completed">Completed</option>
            <option value="Cancelled">Cancelled</option>
          </select>

          <input type="date" className="filter-select" defaultValue="2024-05-18" />

          <button className="btn-outline">
            <Download size={15} /> Export
          </button>
        </div>
      </div>

      <table className="custom-table">
        <thead>
          <tr>
            <th>Booking ID</th>
            <th>Patient</th>
            <th>Doctor</th>
            <th>Hospital</th>
            <th>Date & Time</th>
            <th>Status</th>
            <th>Payment</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {filtered.map((b, i) => (
            <tr key={i}>
              <td><strong style={{ color: 'var(--primary)' }}>{b.id}</strong></td>
              <td><strong>{b.patient}</strong></td>
              <td>{b.doctor}</td>
              <td>{b.hospital}</td>
              <td>{b.datetime}</td>
              <td>
                <span className={`status-badge ${b.status.toLowerCase()}`}>
                  {b.status}
                </span>
              </td>
              <td>
                <span style={{ fontWeight: 700, color: b.payment === 'Paid' ? 'var(--success-text)' : b.payment === 'Pending' ? 'var(--warning-text)' : 'var(--error-text)' }}>
                  {b.payment}
                </span>
              </td>
              <td>
                <div className="action-btn-group">
                  <button className="action-btn" title="View Telehealth Room"><Video size={15} /></button>
                  <button className="action-btn" title="View Details"><Eye size={15} /></button>
                  <button className="action-btn" title="Edit"><Edit3 size={15} /></button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px 24px', borderTop: '1px solid var(--border-light)', fontSize: '0.84rem', color: 'var(--text-muted)' }}>
        <span>Showing {filtered.length} of {bookings.length} live bookings (Hostinger MySQL)</span>
        <div style={{ display: 'flex', gap: 6 }}>
          <button className="btn-primary" style={{ padding: '4px 12px' }}>1</button>
        </div>
      </div>
    </div>
  </div>
  );
}
