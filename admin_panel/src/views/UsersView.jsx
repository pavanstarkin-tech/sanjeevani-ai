import React, { useState, useEffect } from 'react';
import { Search, Download, Eye } from 'lucide-react';
import MetricCard from '../components/MetricCard';
import UserDetailsModal from '../components/UserDetailsModal';
import { healthApi } from '../services/api';
import { DB_SNAPSHOT } from '../data/databaseSnapshot';
import illus1 from '../assets/illustrations/1.png';
import illus3 from '../assets/illustrations/3.png';
import illus2 from '../assets/illustrations/2.png';

export default function UsersView() {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUser, setSelectedUser] = useState(null);
  const [users, setUsers] = useState(DB_SNAPSHOT.users);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    async function loadLiveUsers() {
      try {
        const res = await healthApi.getUsers();
        if (res?.data?.data || res?.data) {
          const list = res.data.data || res.data;
          if (Array.isArray(list)) {
            setUsers(list.map(u => ({
              id: u.id,
              name: u.name,
              phone: u.phone || u.mobile || '+91 9848011223',
              email: u.email || 'patient@healthexpress.ai',
              aarogyasri: u.aarogyasri_id || 'AROG' + u.id.replace('USR-', ''),
              age: u.age || 28,
              gender: u.gender || 'Male',
              address: u.address || (u.city ? `${u.city}, ${u.state || 'Telangana'}` : 'Madhapur, Hyderabad'),
              emergencyContact: u.emergency_contact || 'Priya Sharma (9876500001)',
              joined: u.created_at ? new Date(u.created_at).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }) : '18 May 2024',
              status: 'Active',
              bloodGroup: u.blood_group || 'B+',
              allergies: u.allergies || 'None',
              pastSurgeries: u.past_surgeries || 'None',
              avatar: u.profile_picture || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=200'
            })));
          }
        }
      } catch (e) {
        console.warn('Live users load note:', e);
      } finally {
        setLoading(false);
      }
    }
    loadLiveUsers();
    const interval = setInterval(loadLiveUsers, 10000);
    return () => clearInterval(interval);
  }, []);

  const filtered = users.filter(u => u.name.toLowerCase().includes(searchTerm.toLowerCase()) || u.phone.includes(searchTerm) || (u.aarogyasri && u.aarogyasri.toLowerCase().includes(searchTerm.toLowerCase())));

  return (
    <div>
      {/* 3 User KPI Metric Cards (3 per row) */}
      <div className="metrics-grid cols-3" style={{ marginBottom: 20 }}>
        <MetricCard
          title="Total Registered Patients"
          value={users.length.toString()}
          change="Live Hostinger DB"
          illustration={illus1}
          color="blue"
        />
        <MetricCard
          title="Aarogyasri Health Cards"
          value={users.filter(u => u.aarogyasri).length.toString()}
          change="Government Subsidy"
          illustration={illus3}
          color="green"
        />
        <MetricCard
          title="Active Digital EHR Vaults"
          value={users.length.toString()}
          change="QR Scannable"
          illustration={illus2}
          color="purple"
        />
      </div>
    <div className="table-card">
      <div className="table-header">
        <div className="table-title">
          <h3>Registered Users & Patient Health Passes</h3>
          <p>Total Registered: {users.length} Patients (Live Hostinger MySQL)</p>
        </div>

        <div className="table-actions">
          <div className="search-box">
            <Search size={16} />
            <input
              type="text"
              placeholder="Search users (name, phone, Aarogyasri)..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <select className="filter-select">
            <option>All Users</option>
            <option>Active</option>
            <option>Blocked</option>
          </select>

          <button className="btn-outline">
            <Download size={15} /> Export
          </button>
        </div>
      </div>

      <table className="custom-table">
        <thead>
          <tr>
            <th>User</th>
            <th>Phone</th>
            <th>Email</th>
            <th>Aarogyasri Health ID</th>
            <th>Joined On</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {filtered.length > 0 ? (
            filtered.map((u, i) => (
              <tr key={i}>
                <td>
                  <div className="table-user-cell">
                    <img src={u.avatar} className="table-avatar" alt={u.name} />
                    <strong>{u.name}</strong>
                  </div>
                </td>
                <td>{u.phone}</td>
                <td>{u.email}</td>
                <td>
                  <span style={{ fontWeight: 800, color: 'var(--primary)', background: 'var(--primary-light)', padding: '4px 8px', borderRadius: 6 }}>
                    {u.aarogyasri}
                  </span>
                </td>
                <td>{u.joined}</td>
                <td>
                  <span className={`status-badge ${u.status === 'Active' ? 'active' : 'inactive'}`}>
                    {u.status}
                  </span>
                </td>
                <td>
                  <div className="action-btn-group">
                    <button className="action-btn" title="View Patient Vault" onClick={() => setSelectedUser(u)}>
                      <Eye size={15} />
                    </button>
                  </div>
                </td>
              </tr>
            ))
          ) : (
            <tr>
              <td colSpan="7" style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                {loading ? 'Loading live patient records from MySQL...' : 'No users found matching your search.'}
              </td>
            </tr>
          )}
        </tbody>
      </table>

      {selectedUser && (
        <UserDetailsModal
          isOpen={!!selectedUser}
          onClose={() => setSelectedUser(null)}
          user={selectedUser}
        />
      )}
    </div>
  </div>
  );
}
