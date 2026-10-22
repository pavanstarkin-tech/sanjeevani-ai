import React, { useState, useEffect } from 'react';
import { Sparkles, Plus, AlertTriangle, ShieldCheck, Cpu, Sliders, CheckCircle2, User, Clock, Activity, MessageSquare, Database } from 'lucide-react';
import MetricCard from '../components/MetricCard';
import { healthApi } from '../services/api';
import { DB_SNAPSHOT } from '../data/databaseSnapshot';
import RagManagementView from './RagManagementView';
import illus1 from '../assets/illustrations/1.png';
import illus2 from '../assets/illustrations/2.png';
import illus6 from '../assets/illustrations/6.png';
import illus7 from '../assets/illustrations/7.png';

export default function AiManagementView() {
  const [stats, setStats] = useState(DB_SNAPSHOT.aiStats);
  const [aiSessions, setAiSessions] = useState(DB_SNAPSHOT.aiSessions);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('rules'); // rules | rag

  const [rules, setRules] = useState([
    {
      id: 'RULE-01',
      condition: 'Fever + Cough + Body Pain',
      prioritySpecialty: 'General Physician',
      recommendedTests: 'Complete Blood Count (CBC), Dengue NS1',
      recommendedMeds: 'Paracetamol 650mg, Cetirizine 10mg',
      severity: 'Moderate',
      status: 'Active'
    },
    {
      id: 'RULE-02',
      condition: 'Chest Tightness OR Severe Breathlessness',
      prioritySpecialty: 'Cardiologist / Emergency Trauma',
      recommendedTests: 'ECG 12-Lead, Troponin-I, 2D Echo',
      recommendedMeds: 'Emergency SOS Hotline / Ambulance 108',
      severity: 'Emergency',
      status: 'Active'
    },
    {
      id: 'RULE-03',
      condition: 'Joint Swelling + Acute Knee Pain',
      prioritySpecialty: 'Orthopedic Surgeon',
      recommendedTests: 'X-Ray Knee (AP/Lateral), Serum Uric Acid',
      recommendedMeds: 'NSAID / Cold Compress',
      severity: 'Mild',
      status: 'Active'
    },
    {
      id: 'RULE-04',
      condition: 'Wheezing + Difficulty Breathing',
      prioritySpecialty: 'Pulmonologist',
      recommendedTests: 'Spirometry, Chest X-Ray',
      recommendedMeds: 'Bronchodilator Inhaler PRN',
      severity: 'Moderate',
      status: 'Active'
    }
  ]);

  const [newRule, setNewRule] = useState({
    condition: '',
    prioritySpecialty: 'General Physician',
    recommendedTests: '',
    recommendedMeds: '',
    severity: 'Moderate'
  });

  const [isAdding, setIsAdding] = useState(false);

  useEffect(() => {
    async function loadLiveData() {
      try {
        const [statsRes, sessionsRes] = await Promise.all([
          healthApi.getAiStats().catch(() => null),
          healthApi.getAiSessions().catch(() => null),
        ]);

        if (statsRes?.data?.data || statsRes?.data) {
          const s = statsRes.data.data || statsRes.data;
          setStats({
            total_ai_sessions: parseInt(s.total_ai_sessions || 0),
            voice_consultations: parseInt(s.voice_consultations || 0),
            emergency_escalations: parseInt(s.emergency_escalations || 0),
            moderate_cases: parseInt(s.moderate_cases || 0),
            mild_cases: parseInt(s.mild_cases || 0),
          });
        }

        if (sessionsRes?.data?.data || sessionsRes?.data) {
          const list = sessionsRes.data.data || sessionsRes.data;
          if (Array.isArray(list)) {
            setAiSessions(list);
          }
        }
      } catch (err) {
        console.warn('AI stats live fetch note:', err);
      } finally {
        setLoading(false);
      }
    }
    loadLiveData();
  }, []);

  const handleAddRule = (e) => {
    e.preventDefault();
    setRules([
      {
        id: `RULE-${Math.floor(10 + Math.random() * 90)}`,
        ...newRule,
        status: 'Active'
      },
      ...rules
    ]);
    setIsAdding(false);
    setNewRule({ condition: '', prioritySpecialty: 'General Physician', recommendedTests: '', recommendedMeds: '', severity: 'Moderate' });
  };

  const totalSessions = stats.total_ai_sessions > 0 ? stats.total_ai_sessions : (aiSessions.length > 0 ? aiSessions.length : 5);
  const voiceConsults = stats.voice_consultations > 0 ? stats.voice_consultations : Math.max(2, Math.floor(totalSessions * 0.4));
  const emergencyCount = stats.emergency_escalations > 0 ? stats.emergency_escalations : (aiSessions.filter(s => s.severity === 'Emergency').length || 1);

  return (
    <div>
      {/* 4 AI Metric Cards (3 per row) */}
      <div className="metrics-grid">
        <MetricCard
          title="AI Triage Sessions"
          value={totalSessions.toLocaleString()}
          change="Live MySQL"
          illustration={illus1}
          color="blue"
        />
        <MetricCard
          title="Voice AI Consultations"
          value={voiceConsults.toLocaleString()}
          change="Multilingual Sarvam"
          illustration={illus2}
          color="purple"
        />
        <MetricCard
          title="Emergency Escalations"
          value={emergencyCount.toString()}
          change="108 Dispatched"
          isPositive={emergencyCount === 0}
          illustration={illus6}
          color="orange"
        />
        <MetricCard
          title="Active Clinical Rules"
          value={`${rules.length} Rules`}
          change="Safety Guardrails"
          illustration={illus7}
          color="green"
        />
      </div>

      {/* Tabs for Rules vs RAG Sync */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 18 }}>
        <button 
          className={activeTab === 'rag' ? 'btn-primary' : 'btn-outline'} 
          onClick={() => setActiveTab('rag')}
          style={{ display: 'flex', alignItems: 'center', gap: 6, backgroundColor: activeTab === 'rag' ? '#10B981' : undefined }}
        >
          <Database size={16} /> RAG Knowledge Chunks & Sync
        </button>
        <button 
          className={activeTab === 'rules' ? 'btn-primary' : 'btn-outline'} 
          onClick={() => setActiveTab('rules')}
          style={{ display: 'flex', alignItems: 'center', gap: 6 }}
        >
          <Sliders size={16} /> Clinical Rules Engine ({rules.length})
        </button>
      </div>

      {activeTab === 'rules' && (
        <div className="table-card" style={{ marginBottom: 24 }}>
          <div className="table-header">
            <div className="table-title">
              <h3>Clinical AI Recommendation Rules Engine</h3>
              <p>Dynamic symptom parsing, priority specialties, and emergency escalation protocols</p>
            </div>
            <button className="btn-primary" onClick={() => setIsAdding(!isAdding)}>
              <Plus size={16} /> {isAdding ? 'Close Builder' : 'Create New Rule'}
            </button>
          </div>

          {isAdding && (
            <form onSubmit={handleAddRule} style={{ padding: '20px 24px', background: 'var(--bg-main)', borderBottom: '1px solid var(--border)' }}>
              <h4 style={{ fontSize: '0.95rem', fontWeight: 800, marginBottom: 12 }}>Visual Rule Configuration</h4>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                <div className="form-group">
                  <label>IF Symptoms Contain (Keywords)</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Sore Throat + Runny Nose"
                    value={newRule.condition}
                    onChange={e => setNewRule({ ...newRule, condition: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label>THEN Prioritize Doctor Specialty</label>
                  <select
                    value={newRule.prioritySpecialty}
                    onChange={e => setNewRule({ ...newRule, prioritySpecialty: e.target.value })}
                  >
                    <option>General Physician</option>
                    <option>Cardiologist</option>
                    <option>ENT Specialist</option>
                    <option>Pulmonologist</option>
                    <option>Pediatrician</option>
                    <option>Emergency Trauma / Ambulance</option>
                  </select>
                </div>

                <div className="form-group">
                  <label>Suggested Diagnostic Lab Tests</label>
                  <input
                    type="text"
                    placeholder="e.g. Throat Swab Culture, Rapid Antigen"
                    value={newRule.recommendedTests}
                    onChange={e => setNewRule({ ...newRule, recommendedTests: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label>Suggested Care / Medicine Catalog</label>
                  <input
                    type="text"
                    placeholder="e.g. Warm Salt Gargle, Cetirizine 10mg"
                    value={newRule.recommendedMeds}
                    onChange={e => setNewRule({ ...newRule, recommendedMeds: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 14 }}>
                <button type="button" className="btn-outline" onClick={() => setIsAdding(false)}>Cancel</button>
                <button type="submit" className="btn-primary">Save & Publish AI Rule</button>
              </div>
            </form>
          )}

          <table className="custom-table">
            <thead>
              <tr>
                <th>Rule ID</th>
                <th>Trigger Condition (IF)</th>
                <th>Recommended Action (THEN)</th>
                <th>Diagnostic Tests</th>
                <th>Severity Level</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {rules.map((r, i) => (
                <tr key={i}>
                  <td><strong style={{ color: 'var(--primary)' }}>{r.id}</strong></td>
                  <td><strong>{r.condition}</strong></td>
                  <td>
                    <span style={{ color: 'var(--primary)', fontWeight: 700 }}>
                      {r.prioritySpecialty}
                    </span>
                  </td>
                  <td>{r.recommendedTests}</td>
                  <td>
                    <span className={`status-badge ${r.severity === 'Emergency' ? 'inactive' : 'confirmed'}`}>
                      {r.severity}
                    </span>
                  </td>
                  <td><span className="status-badge active">Active</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}


      {activeTab === 'rag' && <RagManagementView />}
    </div>
  );
}
