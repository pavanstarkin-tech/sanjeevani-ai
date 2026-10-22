import React, { useState, useEffect } from 'react';
import { 
  Key, 
  Plus, 
  RefreshCw, 
  AlertTriangle, 
  CheckCircle2, 
  Trash2, 
  Copy, 
  ExternalLink,
  ShieldCheck,
  Zap,
  Info
} from 'lucide-react';
import MetricCard from '../components/MetricCard';
import { healthApi } from '../services/api';

export default function SarvamKeyPoolView() {
  const [keysData, setKeysData] = useState({
    keys: [],
    active_key_id: null,
    total_keys: 0,
    active_count: 0,
    exhausted_count: 0,
    invalid_count: 0
  });
  const [loading, setLoading] = useState(true);
  const [newKeys, setNewKeys] = useState('');
  const [newLabel, setNewLabel] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [statusMsg, setStatusMsg] = useState(null);

  const fetchKeys = async () => {
    setLoading(true);
    try {
      const res = await healthApi.getSarvamKeys();
      const payload = res?.data?.data || res?.data;
      if (payload && payload.keys) {
        setKeysData(payload);
      }
    } catch (err) {
      console.error('Error fetching Sarvam keys:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchKeys();
    const interval = setInterval(fetchKeys, 12000);
    return () => clearInterval(interval);
  }, []);

  const handleAddKeys = async (e) => {
    e.preventDefault();
    if (!newKeys.trim()) return;
    setSubmitting(true);
    try {
      const res = await healthApi.addSarvamKeys({ keys: newKeys.trim(), label: newLabel.trim() });
      const payload = res?.data?.data || res?.data;
      if (payload?.status === 'success' || res?.data?.success) {
        setStatusMsg({ type: 'success', text: payload?.message || res?.data?.message || 'Key(s) added successfully.' });
        setNewKeys('');
        setNewLabel('');
        fetchKeys();
      } else {
        setStatusMsg({ type: 'error', text: payload?.error || res?.data?.error || 'Failed to add key' });
      }
    } catch (err) {
      setStatusMsg({ type: 'error', text: 'Network error adding key' });
    } finally {
      setSubmitting(false);
      setTimeout(() => setStatusMsg(null), 4000);
    }
  };

  const handleMarkExhausted = async (id) => {
    if (!window.confirm('Mark this key as EXHAUSTED? The system will automatically promote the next active key.')) return;
    try {
      await healthApi.markSarvamKeyExhausted({ id, reason: 'Manually marked exhausted from Admin Panel' });
      fetchKeys();
    } catch (err) {
      console.error(err);
    }
  };

  const handleReactivate = async (id) => {
    try {
      await healthApi.reactivateSarvamKey({ id });
      fetchKeys();
    } catch (err) {
      console.error(err);
    }
  };

  const handleSetActive = async (id) => {
    try {
      await healthApi.setSarvamActiveKey({ id });
      fetchKeys();
    } catch (err) {
      console.error(err);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this API key from the pool?')) return;
    try {
      await healthApi.deleteSarvamKey(id);
      fetchKeys();
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* Top Banner & Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 14 }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ padding: 10, background: 'rgba(37, 99, 235, 0.15)', borderRadius: 12, color: '#3B82F6' }}>
              <Key size={24} />
            </div>
            <div>
              <h2 style={{ fontSize: '1.4rem', fontWeight: 800 }}>Sarvam AI Multi-Key Pool & Failover Manager</h2>
              <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                Non-authenticatable public admin controller • Auto-rotates to backup keys when credits are exhausted
              </p>
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', gap: 10 }}>
          <a 
            href="/sarvam-keys" 
            target="_blank" 
            rel="noopener noreferrer"
            className="btn btn-outline"
            style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: '0.8rem' }}
          >
            <ExternalLink size={15} />
            Open Standalone Public URL
          </a>
          <button 
            className="btn btn-outline"
            onClick={fetchKeys}
            style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: '0.8rem' }}
          >
            <RefreshCw size={15} className={loading ? 'spin' : ''} />
            Refresh
          </button>
        </div>
      </div>

      {statusMsg && (
        <div style={{
          padding: '12px 16px',
          borderRadius: 'var(--radius-md)',
          background: statusMsg.type === 'success' ? 'rgba(16, 185, 129, 0.15)' : 'rgba(239, 68, 68, 0.15)',
          color: statusMsg.type === 'success' ? '#10B981' : '#EF4444',
          border: `1px solid ${statusMsg.type === 'success' ? 'rgba(16, 185, 129, 0.3)' : 'rgba(239, 68, 68, 0.3)'}`,
          fontWeight: 600,
          fontSize: '0.9rem'
        }}>
          {statusMsg.text}
        </div>
      )}

      {/* Metrics Row */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))', gap: '14px' }}>
        <MetricCard 
          title="Current Active Key"
          value={keysData.active_key_masked || 'None Active'}
          subtext={`ID: ${keysData.active_key_id || 'None'}`}
          icon={Zap}
        />
        <MetricCard 
          title="Active Keys Available"
          value={keysData.active_count ?? 0}
          subtext="Ready for live calls"
          trend={`${keysData.active_count > 0 ? 'Healthy' : 'Zero Active'}`}
          icon={CheckCircle2}
        />
        <MetricCard 
          title="Exhausted / Depleted"
          value={keysData.exhausted_count ?? 0}
          subtext="Need recharge on Sarvam"
          icon={AlertTriangle}
        />
        <MetricCard 
          title="Total Keys Registered"
          value={keysData.total_keys ?? 0}
          subtext="In failover rotation"
          icon={ShieldCheck}
        />
      </div>

      {/* Add New Key Section */}
      <div className="chart-card" style={{ padding: '24px' }}>
        <h3 style={{ fontSize: '1.05rem', fontWeight: 800, marginBottom: 6, display: 'flex', alignItems: 'center', gap: 8 }}>
          <Plus size={18} color="var(--primary)" />
          Add New Sarvam API Key(s) to Failover Pool
        </h3>
        <p style={{ color: 'var(--text-muted)', fontSize: '0.82rem', marginBottom: 16 }}>
          Paste 1, 2, or multiple Sarvam API keys. You can enter them separated by newlines or commas. They will be queued automatically.
        </p>

        <form onSubmit={handleAddKeys} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div>
            <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-muted)' }}>
              Sarvam API Key(s) (format: sk_...)
            </label>
            <textarea
              rows={3}
              placeholder={`sk_5ijbsyhu_co3XmcxZMgr0Rf0HAjfWvV4x\nsk_d3mrjqmd_WCMwFkKIf6GQKxpaUIu9Ucwu`}
              value={newKeys}
              onChange={(e) => setNewKeys(e.target.value)}
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: 'var(--radius-md)',
                background: 'var(--bg-darker)',
                border: '1px solid var(--border)',
                color: 'var(--text)',
                fontFamily: 'monospace',
                fontSize: '0.88rem',
                marginTop: 6
              }}
              required
            />
          </div>

          <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
            <div style={{ flex: 1 }}>
              <input
                type="text"
                placeholder="Optional Label (e.g., Account #3 - 500 Credits)"
                value={newLabel}
                onChange={(e) => setNewLabel(e.target.value)}
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  borderRadius: 'var(--radius-md)',
                  background: 'var(--bg-darker)',
                  border: '1px solid var(--border)',
                  color: 'var(--text)',
                  fontSize: '0.88rem'
                }}
              />
            </div>
            <button
              type="submit"
              disabled={submitting || !newKeys.trim()}
              className="btn btn-primary"
              style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 22px' }}
            >
              <Plus size={16} />
              {submitting ? 'Adding...' : 'Add Keys to Pool'}
            </button>
          </div>
        </form>
      </div>

      {/* Keys Table Card */}
      <div className="chart-card" style={{ padding: '24px' }}>
        <h3 style={{ fontSize: '1.05rem', fontWeight: 800, marginBottom: 14 }}>
          Configured Keys Rotation Queue
        </h3>

        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--border)', color: 'var(--text-muted)', fontSize: '0.78rem' }}>
                <th style={{ padding: '10px 12px' }}>KEY ID</th>
                <th style={{ padding: '10px 12px' }}>API KEY</th>
                <th style={{ padding: '10px 12px' }}>LABEL</th>
                <th style={{ padding: '10px 12px' }}>STATUS</th>
                <th style={{ padding: '10px 12px' }}>ADDED AT</th>
                <th style={{ padding: '10px 12px' }}>ACTIONS</th>
              </tr>
            </thead>
            <tbody>
              {keysData.keys.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ padding: '24px', textAlign: 'center', color: 'var(--text-muted)' }}>
                    No Sarvam API keys in the pool yet. Add one above.
                  </td>
                </tr>
              ) : (
                keysData.keys.map((k) => {
                  const isActive = k.id === keysData.active_key_id;
                  return (
                    <tr key={k.id} style={{ borderBottom: '1px solid var(--border)', fontSize: '0.88rem' }}>
                      <td style={{ padding: '12px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <strong>{k.id}</strong>
                          {isActive && (
                            <span style={{
                              background: '#2563EB',
                              color: '#fff',
                              fontSize: '0.65rem',
                              fontWeight: 800,
                              padding: '2px 6px',
                              borderRadius: 4
                            }}>
                              ACTIVE
                            </span>
                          )}
                        </div>
                      </td>
                      <td style={{ padding: '12px', fontFamily: 'monospace' }}>
                        {k.masked_key}
                      </td>
                      <td style={{ padding: '12px', color: 'var(--text-muted)' }}>
                        {k.label || 'Standard Key'}
                      </td>
                      <td style={{ padding: '12px' }}>
                        <span style={{
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: 4,
                          fontSize: '0.75rem',
                          fontWeight: 700,
                          padding: '3px 8px',
                          borderRadius: 6,
                          background: k.status === 'active' 
                            ? 'rgba(16, 185, 129, 0.15)' 
                            : (k.status === 'exhausted' ? 'rgba(245, 158, 11, 0.15)' : 'rgba(239, 68, 68, 0.15)'),
                          color: k.status === 'active' 
                            ? '#10B981' 
                            : (k.status === 'exhausted' ? '#F59E0B' : '#EF4444')
                        }}>
                          ● {k.status.toUpperCase()}
                        </span>
                        {k.failure_reason && (
                          <div style={{ fontSize: '0.72rem', color: '#EF4444', marginTop: 3 }}>
                            {k.failure_reason}
                          </div>
                        )}
                      </td>
                      <td style={{ padding: '12px', fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                        {k.added_at || '-'}
                      </td>
                      <td style={{ padding: '12px' }}>
                        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                          {!isActive && k.status === 'active' && (
                            <button
                              className="btn btn-outline"
                              style={{ padding: '4px 8px', fontSize: '0.72rem' }}
                              onClick={() => handleSetActive(k.id)}
                            >
                              Make Active
                            </button>
                          )}
                          {k.status === 'active' && (
                            <button
                              className="btn btn-outline"
                              style={{ padding: '4px 8px', fontSize: '0.72rem', color: '#F59E0B', borderColor: 'rgba(245, 158, 11, 0.3)' }}
                              onClick={() => handleMarkExhausted(k.id)}
                            >
                              Exhaust
                            </button>
                          )}
                          {k.status !== 'active' && (
                            <button
                              className="btn btn-outline"
                              style={{ padding: '4px 8px', fontSize: '0.72rem', color: '#10B981', borderColor: 'rgba(16, 185, 129, 0.3)' }}
                              onClick={() => handleReactivate(k.id)}
                            >
                              Reactivate
                            </button>
                          )}
                          <button
                            className="btn btn-outline"
                            style={{ padding: '4px 8px', fontSize: '0.72rem', color: '#EF4444', borderColor: 'rgba(239, 68, 68, 0.3)' }}
                            onClick={() => handleDelete(k.id)}
                          >
                            <Trash2 size={13} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
