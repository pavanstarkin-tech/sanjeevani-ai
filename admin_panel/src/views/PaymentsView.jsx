import React, { useState, useEffect } from 'react';
import { DollarSign, ArrowUpRight, ArrowDownLeft, Search, Download, CreditCard, RefreshCw } from 'lucide-react';
import MetricCard from '../components/MetricCard';
import { healthApi } from '../services/api';
import { DB_SNAPSHOT } from '../data/databaseSnapshot';
import illus5 from '../assets/illustrations/5.png';
import illus1 from '../assets/illustrations/1.png';
import illus2 from '../assets/illustrations/2.png';
import illus6 from '../assets/illustrations/6.png';

export default function PaymentsView() {
  const [searchTerm, setSearchTerm] = useState('');
  const [payments, setPayments] = useState(DB_SNAPSHOT.payments);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    async function loadLivePayments() {
      try {
        const res = await healthApi.getPayments();
        if (res?.data?.data || res?.data) {
          const list = res.data.data || res.data;
          if (Array.isArray(list)) {
            setPayments(list.map(p => ({
              id: p.id,
              user: p.user_name || 'Patient User',
              doctor: p.doctor_name || 'Dr. Specialist',
              amount: `₹${parseFloat(p.amount || 800).toLocaleString('en-IN')}`,
              numericAmount: parseFloat(p.amount || 0),
              method: p.payment_method ? (p.payment_method.includes('razorpay') ? 'Razorpay Live' : 'UPI') : 'UPI',
              status: p.status ? p.status.charAt(0).toUpperCase() + p.status.slice(1) : 'Paid',
              date: p.created_at ? new Date(p.created_at).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }) : '18 May 2024'
            })));
          }
        }
      } catch (e) {
        console.warn('Live payments load note:', e);
      } finally {
        setLoading(false);
      }
    }
    loadLivePayments();
    const interval = setInterval(loadLivePayments, 10000);
    return () => clearInterval(interval);
  }, []);

  const totalGross = payments.reduce((acc, curr) => acc + curr.numericAmount, 0);
  const platformEarnings = totalGross * 0.20;
  const doctorPayouts = totalGross * 0.80;

  const filtered = payments.filter(p => p.user.toLowerCase().includes(searchTerm.toLowerCase()) || p.id.toLowerCase().includes(searchTerm.toLowerCase()) || p.doctor.toLowerCase().includes(searchTerm.toLowerCase()));

  return (
    <div>
      {/* 4 Financial KPI Cards (3 per row) */}
      <div className="metrics-grid">
        <MetricCard
          title="Total Gross Revenue"
          value={`₹${totalGross.toLocaleString('en-IN')}`}
          change="Live Razorpay"
          illustration={illus5}
          color="green"
        />
        <MetricCard
          title="Platform Earnings (20%)"
          value={`₹${platformEarnings.toLocaleString('en-IN')}`}
          change="+ 18%"
          illustration={illus1}
          color="blue"
        />
        <MetricCard
          title="Doctor Payouts (80%)"
          value={`₹${doctorPayouts.toLocaleString('en-IN')}`}
          change="+ 14%"
          illustration={illus2}
          color="purple"
        />
        <MetricCard
          title="Dispute Holds / Refunds"
          value="₹0"
          change="0.0% Clean"
          isPositive={true}
          illustration={illus6}
          color="orange"
        />
      </div>

      <div className="table-card">
        <div className="table-header">
          <div className="table-title">
            <h3>Payment Transactions Ledger</h3>
            <p>Live Razorpay Transactions & Aarogyasri Subsidies ({payments.length} Transactions)</p>
          </div>

          <div className="table-actions">
            <div className="search-box">
              <Search size={16} />
              <input
                type="text"
                placeholder="Search transaction ID, user, doctor..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>

            <select className="filter-select">
              <option>All Methods</option>
              <option>Razorpay Live</option>
              <option>UPI</option>
              <option>Aarogyasri Health Pass</option>
            </select>

            <button className="btn-outline">
              <Download size={15} /> Export Ledger
            </button>
          </div>
        </div>

        <table className="custom-table">
          <thead>
            <tr>
              <th>Transaction ID</th>
              <th>Patient</th>
              <th>Doctor / Service</th>
              <th>Amount</th>
              <th>Payment Gateway</th>
              <th>Date</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length > 0 ? (
              filtered.map((p, i) => (
                <tr key={i}>
                  <td><strong style={{ color: 'var(--primary)' }}>{p.id}</strong></td>
                  <td><strong>{p.user}</strong></td>
                  <td>{p.doctor}</td>
                  <td><strong style={{ color: 'var(--success-text)' }}>{p.amount}</strong></td>
                  <td>
                    <span style={{ fontSize: '0.82rem', fontWeight: 600 }}>{p.method}</span>
                  </td>
                  <td>{p.date}</td>
                  <td>
                    <span className={`status-badge ${p.status.toLowerCase()}`}>
                      {p.status}
                    </span>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan="7" style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                  {loading ? 'Loading payment transactions from MySQL...' : 'No transactions found.'}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
