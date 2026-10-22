import React, { useState } from 'react';
import { X, LifeBuoy, Send } from 'lucide-react';

export default function ReplyTicketModal({ isOpen, onClose, ticket, onResolved }) {
  const [replyText, setReplyText] = useState('');

  if (!isOpen || !ticket) return null;

  const handleResolve = (e) => {
    e.preventDefault();
    onResolved(ticket.id, 'Resolved');
    onClose();
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content">
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <LifeBuoy size={24} color="var(--primary)" />
            <h3>Resolve Support Ticket #{ticket.id}</h3>
          </div>
          <button className="icon-btn" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        <div style={{ background: 'var(--bg-main)', padding: '14px', borderRadius: 'var(--radius-md)', marginBottom: 16 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
            <span style={{ fontSize: '0.85rem', fontWeight: 800 }}>{ticket.user}</span>
            <span className="status-badge active" style={{ fontSize: '0.72rem' }}>{ticket.category}</span>
          </div>
          <div style={{ fontSize: '0.9rem', color: 'var(--text-main)', fontWeight: 600 }}>{ticket.subject}</div>
        </div>

        <form onSubmit={handleResolve}>
          <div className="form-group">
            <label>Admin Response & Resolution Note</label>
            <textarea
              rows={4}
              required
              placeholder="Type resolution message sent to patient..."
              value={replyText}
              onChange={(e) => setReplyText(e.target.value)}
            />
          </div>

          <div className="form-actions">
            <button type="button" className="btn-outline" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn-primary">
              <Send size={15} /> Send Reply & Mark Resolved
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
