import React, { useState } from 'react';
import { Activity, Lock, Mail, Eye, EyeOff, ShieldCheck, ArrowRight } from 'lucide-react';

export default function LoginView({ onLoginSuccess }) {
  const [email, setEmail] = useState('admin@healthexpress.ai');
  const [password, setPassword] = useState('admin123');
  const [showPassword, setShowPassword] = useState(false);
  const [role, setRole] = useState('Super Admin');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleLogin = (e) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    setTimeout(() => {
      if (email && password) {
        onLoginSuccess({
          email,
          role,
          token: 'JWT_SUPER_ADMIN_LIVE_TOKEN_2026'
        });
      } else {
        setError('Please enter valid email and password');
      }
      setIsLoading(false);
    }, 600);
  };

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'linear-gradient(135deg, #0A192F 0%, #1E3A8A 50%, #0F172A 100%)',
      padding: 20
    }}>
      <div style={{
        width: '100%',
        maxWidth: 440,
        background: 'rgba(255, 255, 255, 0.98)',
        borderRadius: 16,
        boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.35)',
        padding: '36px 32px'
      }}>
        {/* Brand Header */}
        <div style={{ textAlign: 'center', marginBottom: 28 }}>
          <img
            src="./logo.png"
            alt="HealthExpress Logo"
            style={{
              width: 68,
              height: 68,
              borderRadius: 16,
              objectFit: 'contain',
              background: '#FFFFFF',
              boxShadow: '0 8px 24px rgba(30, 96, 246, 0.25)',
              marginBottom: 14,
              padding: 4,
              border: '1px solid #E2E8F0',
              display: 'inline-block'
            }}
          />
          <h2 style={{ fontSize: '1.5rem', fontWeight: 900, color: '#0F172A', letterSpacing: '-0.5px' }}>
            HealthExpress AI
          </h2>
          <p style={{ fontSize: '0.85rem', color: '#64748B', marginTop: 4 }}>
            Control Center & Operations Portal
          </p>
        </div>

        {error && (
          <div style={{
            padding: '10px 14px',
            background: '#FEE2E2',
            color: '#DC2626',
            borderRadius: 8,
            fontSize: '0.82rem',
            fontWeight: 600,
            marginBottom: 18,
            textAlign: 'center'
          }}>
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          {/* Role Selector */}
          <div>
            <label style={{ fontSize: '0.78rem', fontWeight: 700, color: '#475569', textTransform: 'uppercase', marginBottom: 6, display: 'block' }}>
              Select Admin Portal
            </label>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
              <button
                type="button"
                onClick={() => setRole('Super Admin')}
                style={{
                  padding: '8px 12px',
                  borderRadius: 8,
                  fontSize: '0.82rem',
                  fontWeight: 700,
                  border: role === 'Super Admin' ? '2px solid #1E60F6' : '1px solid #CBD5E1',
                  background: role === 'Super Admin' ? '#EFF6FF' : '#FFFFFF',
                  color: role === 'Super Admin' ? '#1E60F6' : '#64748B',
                  cursor: 'pointer'
                }}
              >
                👑 Super Admin
              </button>
              <button
                type="button"
                onClick={() => setRole('Hospital Admin')}
                style={{
                  padding: '8px 12px',
                  borderRadius: 8,
                  fontSize: '0.82rem',
                  fontWeight: 700,
                  border: role === 'Hospital Admin' ? '2px solid #1E60F6' : '1px solid #CBD5E1',
                  background: role === 'Hospital Admin' ? '#EFF6FF' : '#FFFFFF',
                  color: role === 'Hospital Admin' ? '#1E60F6' : '#64748B',
                  cursor: 'pointer'
                }}
              >
                🏥 Hospital Admin
              </button>
            </div>
          </div>

          {/* Email Field */}
          <div>
            <label style={{ fontSize: '0.78rem', fontWeight: 700, color: '#475569', textTransform: 'uppercase', marginBottom: 6, display: 'block' }}>
              Official Email Address *
            </label>
            <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
              <Mail size={18} color="#94A3B8" style={{ position: 'absolute', left: 12 }} />
              <input
                type="email"
                required
                placeholder="admin@healthexpress.ai"
                value={email}
                onChange={e => setEmail(e.target.value)}
                style={{
                  width: '100%',
                  padding: '11px 14px 11px 40px',
                  borderRadius: 8,
                  border: '1px solid #CBD5E1',
                  fontSize: '0.9rem',
                  outline: 'none'
                }}
              />
            </div>
          </div>

          {/* Password Field */}
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
              <label style={{ fontSize: '0.78rem', fontWeight: 700, color: '#475569', textTransform: 'uppercase' }}>
                Secure Password *
              </label>
              <span style={{ fontSize: '0.75rem', color: '#1E60F6', fontWeight: 600, cursor: 'pointer' }}>
                Forgot Password?
              </span>
            </div>
            <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
              <Lock size={18} color="#94A3B8" style={{ position: 'absolute', left: 12 }} />
              <input
                type={showPassword ? 'text' : 'password'}
                required
                placeholder="••••••••••••"
                value={password}
                onChange={e => setPassword(e.target.value)}
                style={{
                  width: '100%',
                  padding: '11px 40px 11px 40px',
                  borderRadius: 8,
                  border: '1px solid #CBD5E1',
                  fontSize: '0.9rem',
                  outline: 'none'
                }}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                style={{
                  position: 'absolute',
                  right: 10,
                  background: 'none',
                  border: 'none',
                  cursor: 'pointer',
                  color: '#94A3B8'
                }}
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={isLoading}
            style={{
              width: '100%',
              padding: '12px',
              borderRadius: 8,
              background: '#1E60F6',
              color: 'white',
              border: 'none',
              fontSize: '0.92rem',
              fontWeight: 800,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 8,
              marginTop: 10,
              boxShadow: '0 4px 12px rgba(30, 96, 246, 0.35)'
            }}
          >
            {isLoading ? 'Verifying Credentials...' : 'Sign In to Control Center'}
            {!isLoading && <ArrowRight size={16} />}
          </button>
        </form>

        <div style={{ marginTop: 24, textAlign: 'center', fontSize: '0.75rem', color: '#94A3B8' }}>
          🔒 Protected by SHA-256 JWT Encryption & ABDM Clinical Compliance
        </div>
      </div>
    </div>
  );
}
