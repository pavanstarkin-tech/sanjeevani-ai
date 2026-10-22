import React, { useState, useEffect } from 'react';
import { Search, Plus, MessageSquare, AlertCircle } from 'lucide-react';
import MetricCard from '../components/MetricCard';
import ReplyTicketModal from '../components/ReplyTicketModal';
import { healthApi } from '../services/api';
import { DB_SNAPSHOT } from '../data/databaseSnapshot';
import illus8 from '../assets/illustrations/8.png';
import illus6 from '../assets/illustrations/6.png';
import illus1 from '../assets/illustrations/1.png';

export default function TicketsView() {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [selectedTicket, setSelectedTicket] = useState(null);
  const [tickets, setTickets] = useState(DB_SNAPSHOT.tickets);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    async function loadLiveTickets() {
      try {
        const res = await healthApi.getTickets();
        if (res?.data?.data || res?.data) {
          const list = res.data.data || res.data;
          if (Array.isArray(list)) {
            setTickets(list.map(t => ({
              id: t.id,
              user: t.user_name || 'Patient User',
              phone: t.user_phone || '+91 9848011223',
              subject: t.subject,
              description: t.description,
              priority: t.priority ? t.priority.charAt(0).toUpperCase() + t.priority.slice(1) : 'Medium',
              status: t.status ? t.status.charAt(0).toUpperCase() + t.status.slice(1) : 'Open',
              time: t.created_at ? new Date(t.created_at).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }) : '18 May 2024'
            })));
          }
        }
      } catch (e) {
        console.warn('Live tickets load note:', e);
      } finally {
        setLoading(false);
      }
    }
    loadLiveTickets();
    const interval = setInterval(loadLiveTickets, 10000);
    return () => clearInterval(interval);
  }, []);

  const handleTicketResolved = (ticketId, replyText) => {
    setTickets(tickets.map(t => t.id === ticketId ? { ...t, status: 'Resolved' } : t));
  };

  const filtered = tickets.filter(t => {
    const matchSearch = t.user.toLowerCase().includes(searchTerm.toLowerCase()) || t.subject.toLowerCase().includes(searchTerm.toLowerCase()) || t.id.toLowerCase().includes(searchTerm.toLowerCase());
    const matchStatus = statusFilter === 'All' || t.status === statusFilter;
    return matchSearch && matchStatus;
  });

  const openTickets = tickets.filter(t => t.status === 'Open').length;
  const resolvedTickets = tickets.filter(t => t.status === 'Resolved').length;

  return (
    <div>
      {/* 3 Support KPI Metric Cards (3 per row) */}
      <div className="metrics-grid cols-3" style={{ marginBottom: 20 }}>
        <MetricCard
          title="Total Support Tickets"
          value={tickets.length.toString()}
          change="Live Queue"
          illustration={illus8}
          color="blue"
        />
        <MetricCard
          title="Open / Action Required"
          value={openTickets.toString()}
          change="Pending Reply"
          isPositive={openTickets === 0}
          illustration={illus6}
          color="orange"
        />
        <MetricCard
          title="Resolved Disputes"
          value={resolvedTickets.toString()}
          change="100% Satisfaction"
          illustration={illus1}
          color="green"
        />
      </div>
      <div className="table-card">
      <div className="table-header">
        <div className="table-title">
          <h3>Customer Support & Dispute Desk</h3>
          <p>Total Tickets: {tickets.length} (Live Hostinger MySQL)</p>
        </div>

        <div className="table-actions">
          <div className="search-box">
            <Search size={16} />
            <input
              type="text"
              placeholder="Search ticket ID, user, subject..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <select
            className="filter-select"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="All">All Statuses</option>
            <option value="Open">Open</option>
            <option value="Pending">Pending</option>
            <option value="Resolved">Resolved</option>
          </select>
        </div>
      </div>

      <table className="custom-table">
        <thead>
          <tr>
            <th>Ticket ID</th>
            <th>Patient User</th>
            <th>Subject</th>
            <th>Priority</th>
            <th>Status</th>
            <th>Date</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {filtered.length > 0 ? (
            filtered.map((t, i) => (
              <tr key={i}>
                <td><strong style={{ color: 'var(--primary)' }}>{t.id}</strong></td>
                <td>
                  <div>
                    <strong>{t.user}</strong>
                    <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>{t.phone}</div>
                  </div>
                </td>
                <td>{t.subject}</td>
                <td>
                  <span className={`status-badge ${t.priority === 'High' || t.priority === 'Emergency' ? 'inactive' : 'pending'}`}>
                    {t.priority}
                  </span>
                </td>
                <td>
                  <span className={`status-badge ${t.status === 'Resolved' ? 'active' : 'pending'}`}>
                    {t.status}
                  </span>
                </td>
                <td>{t.time}</td>
                <td>
                  <button className="action-btn" title="Reply & Resolve" onClick={() => setSelectedTicket(t)}>
                    <MessageSquare size={16} color="var(--primary)" />
                  </button>
                </td>
              </tr>
            ))
          ) : (
            <tr>
              <td colSpan="7" style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                {loading ? 'Loading tickets from MySQL...' : 'No support tickets found.'}
              </td>
            </tr>
          )}
        </tbody>
      </table>

      {selectedTicket && (
        <ReplyTicketModal
          isOpen={!!selectedTicket}
          onClose={() => setSelectedTicket(null)}
          ticket={selectedTicket}
          onResolved={handleTicketResolved}
        />
      )}
    </div>
  </div>
  );
}
