import React, { useState } from 'react';
import { 
  TrendingUp, 
  ShoppingBag, 
  Users, 
  Package, 
  CheckCircle2, 
  Sparkles, 
  ArrowUpRight, 
  Percent, 
  Activity, 
  HeartPulse, 
  Bone, 
  Baby, 
  ShieldCheck, 
  Plus, 
  Search, 
  Flame, 
  Zap, 
  DollarSign, 
  Settings2,
  Stethoscope,
  Filter,
  Layers,
  ArrowRight,
  ChevronRight,
  X,
  Check,
  Image as ImageIcon,
  Tag,
  AlertCircle,
  Store,
  MapPin,
  Clock,
  Phone,
  FileText
} from 'lucide-react';
import MetricCard from '../components/MetricCard';
import StoreVerificationModal from '../components/StoreVerificationModal';
import { healthApi } from '../services/api';
import { DB_SNAPSHOT } from '../data/databaseSnapshot';
import illus1 from '../assets/illustrations/1.png';
import illus2 from '../assets/illustrations/2.png';
import illus4 from '../assets/illustrations/4.png';
import illus5 from '../assets/illustrations/5.png';
import storePartnerIllus from '../assets/illustrations/store_partner.png';
import storePendingIllus from '../assets/illustrations/store_pending.png';
import storeDeliveryIllus from '../assets/illustrations/store_delivery.png';

export default function BusinessWingView() {
  const [activeSubTab, setActiveSubTab] = useState('segments'); // 'segments' | 'products' | 'stores' | 'leads' | 'rules'
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedSegment, setSelectedSegment] = useState('ALL');
  const [promoCode, setPromoCode] = useState('HEALTHEXPRESS20');
  const [maxProducts, setMaxProducts] = useState('2');
  const [inChatEnabled, setInChatEnabled] = useState(true);

  // Live product state initialized from DB_SNAPSHOT
  const [productsList, setProductsList] = useState(DB_SNAPSHOT.businessProducts || []);
  const [showAddModal, setShowAddModal] = useState(false);
  const [toastMessage, setToastMessage] = useState('');

  // Live medical stores state initialized from DB_SNAPSHOT
  const [medicalStoresList, setMedicalStoresList] = useState(DB_SNAPSHOT.medicalStores || []);
  const [showAddStoreModal, setShowAddStoreModal] = useState(false);
  const [selectedStoreForVerify, setSelectedStoreForVerify] = useState(null);

  const handleStoreVerified = async (storeId, newStatus, reason) => {
    try {
      await healthApi.verifyStore(storeId, newStatus, reason);
    } catch (e) {
      console.warn('API store verify note:', e);
    }
    const updated = medicalStoresList.map(s => 
      s.id === storeId 
        ? { ...s, verificationStatus: newStatus, verification_status: newStatus.toLowerCase(), rejectionReason: reason } 
        : s
    );
    setMedicalStoresList(updated);
    DB_SNAPSHOT.medicalStores = updated;
    setToastMessage(`Store ${storeId} successfully ${newStatus === 'Verified' ? 'Approved & Activated' : 'Rejected'}!`);
    setTimeout(() => setToastMessage(''), 4000);
  };

  const verifiedStorePresets = [
    { label: 'Apollo Pharmacy Store', url: 'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=400' },
    { label: 'MedPlus Modern Chemist', url: 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?auto=format&fit=crop&q=80&w=400' },
    { label: 'Wellness Forever Dark Store', url: 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?auto=format&fit=crop&q=80&w=400' },
    { label: 'Balaji Healthcare Superstore', url: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&q=80&w=400' },
  ];

  const [newStore, setNewStore] = useState({
    name: '',
    area: 'Hitech City',
    city: 'Hyderabad',
    address: '',
    phone: '',
    license: '',
    etaMinutes: '15',
    distanceKm: '1.2',
    is24x7: true,
    imageUrl: verifiedStorePresets[0].url
  });

  const handleAddStore = (e) => {
    e.preventDefault();
    if (!newStore.name.trim() || !newStore.address.trim()) {
      alert('Please fill in Store Name and Address.');
      return;
    }

    const createdStore = {
      id: `STORE-0${medicalStoresList.length + 1}`,
      name: newStore.name.trim(),
      address: newStore.address.trim(),
      area: newStore.area || 'Hyderabad',
      city: newStore.city || 'Hyderabad',
      rating: 4.8,
      reviews: 1,
      distanceKm: parseFloat(newStore.distanceKm) || 1.5,
      etaMinutes: parseInt(newStore.etaMinutes) || 15,
      is24x7: newStore.is24x7,
      isOpen: true,
      phone: newStore.phone || '+91 40 2300 0000',
      license: newStore.license || `TS-HYD-PHARM-2026-${Date.now().toString().slice(-4)}`,
      imageUrl: newStore.imageUrl || verifiedStorePresets[0].url,
      availableMedicinesCount: 200,
      monthlyFulfillments: 0
    };

    const updatedStores = [createdStore, ...medicalStoresList];
    setMedicalStoresList(updatedStores);
    DB_SNAPSHOT.medicalStores = updatedStores;

    setShowAddStoreModal(false);
    setToastMessage(`Medical Store "${createdStore.name}" registered & live for 15-min delivery!`);
    setTimeout(() => setToastMessage(''), 4000);

    setNewStore({
      name: '',
      area: 'Hitech City',
      city: 'Hyderabad',
      address: '',
      phone: '',
      license: '',
      etaMinutes: '15',
      distanceKm: '1.2',
      is24x7: true,
      imageUrl: verifiedStorePresets[0].url
    });
  };

  const verifiedImagePresets = [
    { label: 'Glucometer / Diabetes Kit', url: 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?auto=format&fit=crop&q=80&w=600' },
    { label: 'BP Monitor / Cardiac', url: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&q=80&w=600' },
    { label: 'Ortho Support / Joint Relief', url: 'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?auto=format&fit=crop&q=80&w=600' },
    { label: 'Supplements / Nutrition', url: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&q=80&w=600' },
    { label: 'Maternal & Pregnancy Care', url: 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?auto=format&fit=crop&q=80&w=600' },
    { label: 'Lab Full Body Package', url: 'https://images.unsplash.com/photo-1581594693702-fbdc51b2763b?auto=format&fit=crop&q=80&w=600' },
  ];

  const [newProduct, setNewProduct] = useState({
    title: '',
    category: 'Medical Devices & Diagnostics',
    price: '',
    originalPrice: '',
    marginPercent: '25',
    badge: 'AI Recommended',
    targetSegments: ['Diabetes & Endocrine Care'],
    targetConditions: '',
    imageUrl: 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?auto=format&fit=crop&q=80&w=600'
  });

  const availableSegments = [
    'Diabetes & Endocrine Care',
    'Cardiac & Hypertension',
    'Orthopedics & Joint Health',
    'Maternal & Child Health',
    'Respiratory & Pulmonology',
    'General Preventive Wellness'
  ];

  const handleAddProduct = (e) => {
    e.preventDefault();
    if (!newProduct.title.trim() || !newProduct.price) {
      alert('Please enter a product title and price.');
      return;
    }

    const priceNum = parseFloat(newProduct.price) || 0;
    const origPriceNum = parseFloat(newProduct.originalPrice) || priceNum;
    const discount = origPriceNum > priceNum ? Math.round(((origPriceNum - priceNum) / origPriceNum) * 100) : 0;
    
    const conditionsArray = typeof newProduct.targetConditions === 'string'
      ? newProduct.targetConditions.split(',').map(s => s.trim()).filter(Boolean)
      : newProduct.targetConditions;

    const createdProduct = {
      id: `PRD-${Date.now().toString().slice(-4)}`,
      title: newProduct.title.trim(),
      category: newProduct.category,
      price: priceNum,
      originalPrice: origPriceNum,
      discountPercent: discount,
      badge: newProduct.badge || 'AI Recommended',
      marginPercent: parseInt(newProduct.marginPercent) || 25,
      targetSegments: newProduct.targetSegments.length > 0 ? newProduct.targetSegments : ['General Preventive Wellness'],
      targetConditions: conditionsArray.length > 0 ? conditionsArray : ['Preventive Care', 'Routine Monitoring'],
      imageUrl: newProduct.imageUrl || verifiedImagePresets[0].url,
      conversionRate: '0.0%',
      salesCount: 0,
      revenueGenerated: 0
    };

    const updated = [createdProduct, ...productsList];
    setProductsList(updated);
    DB_SNAPSHOT.businessProducts = updated;

    setShowAddModal(false);
    setToastMessage(`Product "${createdProduct.title}" created & activated for AI recommendations!`);
    setTimeout(() => setToastMessage(''), 4000);

    setNewProduct({
      title: '',
      category: 'Medical Devices & Diagnostics',
      price: '',
      originalPrice: '',
      marginPercent: '25',
      badge: 'AI Recommended',
      targetSegments: ['Diabetes & Endocrine Care'],
      targetConditions: '',
      imageUrl: verifiedImagePresets[0].url
    });
  };

  const leads = DB_SNAPSHOT.userLeadSegments || [];
  const stats = DB_SNAPSHOT.businessStats || {
    total_leads_generated: 1240,
    active_monetized_users: 856,
    total_gmv: 342800.0,
    total_commission: 68560.0,
    overall_conversion_rate: 19.4,
    avg_order_value: 1280.0,
    top_converting_product: 'HealthExpress Smart Glucometer Kit'
  };
  const segmentBreakdown = DB_SNAPSHOT.segmentBreakdown || [];

  // Filtered leads
  const filteredLeads = leads.filter(l => {
    const matchesSearch = l.userName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      l.primarySegment.toLowerCase().includes(searchTerm.toLowerCase()) ||
      l.detectedProblems.some(p => p.toLowerCase().includes(searchTerm.toLowerCase()));
    const matchesSegment = selectedSegment === 'ALL' || l.primarySegment === selectedSegment;
    return matchesSearch && matchesSegment;
  });

  // Filtered products using dynamic productsList
  const filteredProducts = productsList.filter(p => {
    const matchesSearch = p.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.category.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.targetConditions.some(c => c.toLowerCase().includes(searchTerm.toLowerCase()));
    const matchesSegment = selectedSegment === 'ALL' || p.targetSegments.some(s => s === selectedSegment);
    return matchesSearch && matchesSegment;
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      {/* Hero Monetization Banner */}
      <div style={{
        background: 'linear-gradient(135deg, #0F172A 0%, #1E3A8A 50%, #0D9488 100%)',
        borderRadius: 16,
        padding: '28px 32px',
        color: 'white',
        boxShadow: '0 10px 25px rgba(15, 23, 42, 0.15)',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        flexWrap: 'wrap',
        gap: 20
      }}>
        <div style={{ maxWidth: 620 }}>
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: 6,
            padding: '4px 12px',
            background: 'rgba(255, 255, 255, 0.15)',
            backdropFilter: 'blur(8px)',
            borderRadius: 20,
            fontSize: '0.75rem',
            fontWeight: 800,
            marginBottom: 10,
            border: '1px solid rgba(255, 255, 255, 0.25)',
            letterSpacing: '0.4px',
            textTransform: 'uppercase'
          }}>
            <Sparkles size={13} color="#FACC15" /> AI Problem-to-Product Recommendation Wing
          </div>
          <h2 style={{ fontSize: '1.7rem', fontWeight: 900, letterSpacing: '-0.5px', marginBottom: 8 }}>
            AI Business & Lead Monetization
          </h2>
          <p style={{ fontSize: '0.9rem', color: '#E2E8F0', lineHeight: 1.5 }}>
            Sarvam AI segregates patient inquiries into 7 high-intent health interest segments and contextually recommends HealthExpress diagnostic packages, monitoring devices, and care passes in real-time.
          </p>
        </div>

        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <button 
            onClick={() => setActiveSubTab('rules')}
            style={{
              padding: '10px 18px',
              background: 'rgba(255, 255, 255, 0.12)',
              border: '1px solid rgba(255, 255, 255, 0.25)',
              borderRadius: 10,
              color: 'white',
              fontSize: '0.85rem',
              fontWeight: 700,
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              cursor: 'pointer'
            }}
          >
            <Settings2 size={16} /> Recommendation Rules
          </button>
          <button 
            onClick={() => setActiveSubTab('products')}
            style={{
              padding: '10px 20px',
              background: '#10B981',
              border: 'none',
              borderRadius: 10,
              color: 'white',
              fontSize: '0.85rem',
              fontWeight: 800,
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              cursor: 'pointer',
              boxShadow: '0 4px 14px rgba(16, 185, 129, 0.4)'
            }}
          >
            <ShoppingBag size={16} /> View Products ({productsList.length})
          </button>
        </div>
      </div>

      {/* Top KPI Metric Cards (3 per row) */}
      <div className="metrics-grid">
        <MetricCard
          title="Gross Merchandise Value"
          value={`₹${stats.total_gmv.toLocaleString('en-IN')}`}
          change="34.8% MoM Growth"
          illustration={illus5}
          color="green"
        />
        <MetricCard
          title="AI Qualified Leads"
          value={stats.total_leads_generated.toLocaleString('en-IN')}
          change={`${stats.active_monetized_users} Active Intent`}
          illustration={illus1}
          color="blue"
        />
        <MetricCard
          title="AI Conversion Rate"
          value={`${stats.overall_conversion_rate}%`}
          change="4.6x Industry Avg"
          illustration={illus4}
          color="orange"
        />
        <MetricCard
          title="Average Order Value"
          value={`₹${stats.avg_order_value.toLocaleString('en-IN')}`}
          change={stats.top_converting_product.split(' ')[2] || 'High Margin'}
          illustration={illus2}
          color="blue"
        />
      </div>

      {/* Navigation Sub-Tabs Bar */}
      <div style={{
        display: 'flex',
        gap: 10,
        background: 'var(--card-bg)',
        padding: '8px',
        borderRadius: 12,
        border: '1px solid var(--border)',
        boxShadow: 'var(--shadow-sm)'
      }}>
        <button
          onClick={() => setActiveSubTab('segments')}
          style={{
            flex: 1,
            padding: '10px 16px',
            fontSize: '0.85rem',
            fontWeight: 800,
            borderRadius: 8,
            border: 'none',
            color: activeSubTab === 'segments' ? '#FFFFFF' : 'var(--text-muted)',
            background: activeSubTab === 'segments' ? 'var(--primary)' : 'transparent',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 8,
            cursor: 'pointer',
            transition: 'all 0.2s'
          }}
        >
          <Activity size={16} /> User Interest Segmentation ({leads.length})
        </button>

        <button
          onClick={() => setActiveSubTab('products')}
          style={{
            flex: 1,
            padding: '10px 16px',
            fontSize: '0.85rem',
            fontWeight: 800,
            borderRadius: 8,
            border: 'none',
            color: activeSubTab === 'products' ? '#FFFFFF' : 'var(--text-muted)',
            background: activeSubTab === 'products' ? 'var(--primary)' : 'transparent',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 8,
            cursor: 'pointer',
            transition: 'all 0.2s'
          }}
        >
          <Package size={16} /> Products Catalog ({productsList.length})
        </button>

        <button
          onClick={() => setActiveSubTab('stores')}
          style={{
            flex: 1,
            padding: '10px 16px',
            fontSize: '0.85rem',
            fontWeight: 800,
            borderRadius: 8,
            border: 'none',
            color: activeSubTab === 'stores' ? '#FFFFFF' : 'var(--text-muted)',
            background: activeSubTab === 'stores' ? 'var(--primary)' : 'transparent',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 8,
            cursor: 'pointer',
            transition: 'all 0.2s'
          }}
        >
          <Store size={16} /> Nearby Medical Stores ({medicalStoresList.length})
        </button>

        <button
          onClick={() => setActiveSubTab('leads')}
          style={{
            flex: 1,
            padding: '10px 16px',
            fontSize: '0.85rem',
            fontWeight: 800,
            borderRadius: 8,
            border: 'none',
            color: activeSubTab === 'leads' ? '#FFFFFF' : 'var(--text-muted)',
            background: activeSubTab === 'leads' ? 'var(--primary)' : 'transparent',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 8,
            cursor: 'pointer',
            transition: 'all 0.2s'
          }}
        >
          <Flame size={16} /> Live AI Lead Conversion Stream
        </button>

        <button
          onClick={() => setActiveSubTab('rules')}
          style={{
            flex: 1,
            padding: '10px 16px',
            fontSize: '0.85rem',
            fontWeight: 800,
            borderRadius: 8,
            border: 'none',
            color: activeSubTab === 'rules' ? '#FFFFFF' : 'var(--text-muted)',
            background: activeSubTab === 'rules' ? 'var(--primary)' : 'transparent',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 8,
            cursor: 'pointer',
            transition: 'all 0.2s'
          }}
        >
          <Settings2 size={16} /> AI Monetization Rules
        </button>
      </div>

      {/* SUB-TAB 1: USER SEGMENTATION MATRIX */}
      {activeSubTab === 'segments' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          {/* Segment Breakdown Category Cards */}
          <div className="chart-card" style={{ padding: 22 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
              <div>
                <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--text-main)' }}>
                  Therapeutic Problem Breakdown & Lead Volume
                </h3>
                <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                  Click any segment card to filter patient leads and targeted catalog offerings.
                </p>
              </div>
              {selectedSegment !== 'ALL' && (
                <button
                  onClick={() => setSelectedSegment('ALL')}
                  style={{
                    padding: '6px 14px',
                    borderRadius: 8,
                    background: 'var(--primary-light)',
                    color: 'var(--primary)',
                    fontSize: '0.8rem',
                    fontWeight: 700,
                    cursor: 'pointer'
                  }}
                >
                  Show All Segments
                </button>
              )}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 14 }}>
              {segmentBreakdown.map((seg, idx) => {
                const isSelected = selectedSegment === seg.segment;
                return (
                  <div 
                    key={idx}
                    onClick={() => setSelectedSegment(isSelected ? 'ALL' : seg.segment)}
                    style={{
                      padding: 16,
                      borderRadius: 12,
                      border: isSelected ? `2px solid ${seg.color}` : '1px solid var(--border)',
                      background: isSelected ? `${seg.color}15` : 'var(--bg-main)',
                      cursor: 'pointer',
                      transition: 'all 0.2s',
                      display: 'flex',
                      flexDirection: 'column',
                      gap: 10
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ fontSize: '0.82rem', fontWeight: 800, color: seg.color }}>{seg.segment}</span>
                      <span style={{ fontSize: '0.9rem', fontWeight: 900, color: 'var(--text-main)' }}>{seg.percent}%</span>
                    </div>

                    <div style={{ height: 6, width: '100%', background: 'var(--border)', borderRadius: 3, overflow: 'hidden' }}>
                      <div style={{ height: '100%', width: `${seg.percent}%`, background: seg.color, borderRadius: 3 }} />
                    </div>

                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                      <span><strong>{seg.count}</strong> Leads</span>
                      <span style={{ color: '#10B981', fontWeight: 700 }}>High Intent</span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* User Segmented Leads Table */}
          <div className="table-card">
            <div className="table-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12 }}>
              <div>
                <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--text-main)' }}>
                  Segmented Patients & AI Recommended Products ({filteredLeads.length})
                </h3>
                <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                  Real-time matching based on symptom triage, vitals, chronic conditions & language questions.
                </p>
              </div>

              <div style={{ position: 'relative' }}>
                <Search size={15} color="var(--text-muted)" style={{ position: 'absolute', left: 10, top: 10 }} />
                <input
                  type="text"
                  placeholder="Search patient, problem..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  style={{
                    padding: '8px 12px 8px 32px',
                    borderRadius: 8,
                    border: '1px solid var(--border)',
                    fontSize: '0.85rem',
                    background: 'var(--bg-main)',
                    width: 240
                  }}
                />
              </div>
            </div>

            <div className="table-container">
              <table>
                <thead>
                  <tr>
                    <th>PATIENT</th>
                    <th>DETECTED HEALTH PROBLEMS</th>
                    <th>PRIMARY SEGMENT</th>
                    <th>AI RECOMMENDED PRODUCT</th>
                    <th>AFFINITY</th>
                    <th>LEAD STAGE</th>
                    <th>ORDER VALUE</th>
                    <th>LAST AI TOUCH</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredLeads.map((lead) => (
                    <tr key={lead.id}>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          <img
                            src={lead.userAvatar}
                            alt={lead.userName}
                            style={{ width: 38, height: 38, borderRadius: '50%', objectFit: 'cover' }}
                          />
                          <div>
                            <strong style={{ display: 'block', fontSize: '0.88rem' }}>{lead.userName}</strong>
                            <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>{lead.userCity} • {lead.userId}</span>
                          </div>
                        </div>
                      </td>
                      <td>
                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                          {lead.detectedProblems.map((prob, pIdx) => (
                            <span
                              key={pIdx}
                              style={{
                                padding: '3px 8px',
                                background: '#F1F5F9',
                                color: '#334155',
                                borderRadius: 6,
                                fontSize: '0.72rem',
                                fontWeight: 600
                              }}
                            >
                              {prob}
                            </span>
                          ))}
                        </div>
                      </td>
                      <td>
                        <span style={{
                          padding: '4px 10px',
                          borderRadius: 6,
                          fontSize: '0.75rem',
                          fontWeight: 700,
                          background: lead.primarySegment.includes('Diabetes') ? '#EFF6FF' :
                            lead.primarySegment.includes('Cardiac') ? '#FEE2E2' :
                            lead.primarySegment.includes('Ortho') ? '#FEF3C7' : '#F3E8FF',
                          color: lead.primarySegment.includes('Diabetes') ? '#1E60F6' :
                            lead.primarySegment.includes('Cardiac') ? '#EF4444' :
                            lead.primarySegment.includes('Ortho') ? '#D97706' : '#7C3AED',
                        }}>
                          {lead.primarySegment}
                        </span>
                      </td>
                      <td>
                        <div style={{ maxWidth: 220 }}>
                          <strong style={{ fontSize: '0.82rem', color: 'var(--text-main)', display: 'block' }}>
                            {lead.recommendedProduct}
                          </strong>
                          <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>
                            Trigger: {lead.aiTrigger}
                          </span>
                        </div>
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <div style={{ width: 44, height: 6, background: '#E2E8F0', borderRadius: 3, overflow: 'hidden' }}>
                            <div style={{ width: `${lead.affinityScore}%`, height: '100%', background: '#10B981' }} />
                          </div>
                          <span style={{ fontSize: '0.78rem', fontWeight: 800, color: '#10B981' }}>{lead.affinityScore}%</span>
                        </div>
                      </td>
                      <td>
                        <span style={{
                          padding: '4px 8px',
                          borderRadius: 6,
                          fontSize: '0.72rem',
                          fontWeight: 700,
                          background: lead.leadStage === 'Purchased' ? '#DCFCE7' : lead.leadStage === 'High Intent' ? '#FEF3C7' : '#F1F5F9',
                          color: lead.leadStage === 'Purchased' ? '#166534' : lead.leadStage === 'High Intent' ? '#92400E' : '#475569',
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: 4
                        }}>
                          {lead.leadStage === 'Purchased' && <CheckCircle2 size={12} />}
                          {lead.leadStage}
                        </span>
                      </td>
                      <td>
                        <strong style={{ fontSize: '0.88rem', color: 'var(--text-main)' }}>
                          ₹{lead.orderValue.toLocaleString('en-IN')}
                        </strong>
                      </td>
                      <td style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                        {lead.lastInteraction}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* SUB-TAB 2: PRODUCTS & PACKAGES CATALOG */}
      {activeSubTab === 'products' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          {/* Header Action Bar */}
          <div style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: 14,
            padding: '16px 20px',
            background: 'var(--bg-card)',
            borderRadius: 12,
            border: '1px solid var(--border)'
          }}>
            <div>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--text-main)', margin: 0 }}>
                Commercial Products, Devices & Health Packages ({filteredProducts.length})
              </h3>
              <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', margin: '4px 0 0 0' }}>
                AI engine automatically recommends these products during patient triage and consultation sessions.
              </p>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
              <div style={{ position: 'relative' }}>
                <Search size={15} color="var(--text-muted)" style={{ position: 'absolute', left: 10, top: 10 }} />
                <input
                  type="text"
                  placeholder="Search products, conditions..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  style={{
                    padding: '8px 12px 8px 32px',
                    borderRadius: 8,
                    border: '1px solid var(--border)',
                    fontSize: '0.85rem',
                    background: 'var(--bg-main)',
                    width: 220
                  }}
                />
              </div>

              <button
                onClick={() => setShowAddModal(true)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  padding: '9px 18px',
                  borderRadius: 8,
                  background: 'linear-gradient(135deg, #1E60F6 0%, #0D9488 100%)',
                  color: 'white',
                  fontWeight: 800,
                  fontSize: '0.85rem',
                  border: 'none',
                  cursor: 'pointer',
                  boxShadow: '0 4px 12px rgba(30, 96, 246, 0.25)',
                  transition: 'transform 0.15s'
                }}
              >
                <Plus size={16} /> Add New Product / Package
              </button>
            </div>
          </div>

          {/* Toast Notification */}
          {toastMessage && (
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: 10,
              padding: '12px 20px',
              borderRadius: 10,
              background: '#DCFCE7',
              color: '#166534',
              border: '1px solid #86EFAC',
              fontWeight: 700,
              fontSize: '0.88rem'
            }}>
              <CheckCircle2 size={18} color="#166534" />
              {toastMessage}
            </div>
          )}

          {/* Product Cards Grid */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: 20 }}>
            {filteredProducts.map((product) => (
              <div
                key={product.id}
                className="chart-card"
                style={{
                  padding: 0,
                  overflow: 'hidden',
                  display: 'flex',
                  flexDirection: 'column',
                  border: '1px solid var(--border)',
                  borderRadius: 14
                }}
              >
                <div style={{ position: 'relative', height: 160, background: '#F8FAFC' }}>
                  <img
                    src={product.imageUrl}
                    alt={product.title}
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  />
                  <span style={{
                    position: 'absolute',
                    top: 12,
                    left: 12,
                    padding: '4px 10px',
                    borderRadius: 20,
                    background: 'rgba(15, 23, 42, 0.85)',
                    backdropFilter: 'blur(4px)',
                    color: 'white',
                    fontSize: '0.72rem',
                    fontWeight: 800,
                    textTransform: 'uppercase',
                    letterSpacing: '0.5px'
                  }}>
                    {product.badge}
                  </span>
                  {product.discountPercent > 0 && (
                    <span style={{
                      position: 'absolute',
                      top: 12,
                      right: 12,
                      padding: '4px 8px',
                      borderRadius: 6,
                      background: '#10B981',
                      color: 'white',
                      fontSize: '0.72rem',
                      fontWeight: 800
                    }}>
                      {product.discountPercent}% OFF
                    </span>
                  )}
                </div>

                <div style={{ padding: 18, display: 'flex', flexDirection: 'column', flex: 1 }}>
                  <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--primary)', textTransform: 'uppercase', marginBottom: 4 }}>
                    {product.category}
                  </div>
                  <h4 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--text-main)', marginBottom: 8, lineHeight: 1.3 }}>
                    {product.title}
                  </h4>

                  {/* Target Conditions Tags */}
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4, marginBottom: 14 }}>
                    {product.targetConditions.slice(0, 3).map((cond, cIdx) => (
                      <span
                        key={cIdx}
                        style={{
                          padding: '2px 6px',
                          background: '#EFF6FF',
                          color: '#1E60F6',
                          borderRadius: 4,
                          fontSize: '0.7rem',
                          fontWeight: 600
                        }}
                      >
                        {cond}
                      </span>
                    ))}
                  </div>

                  {/* Pricing and Revenue Stats */}
                  <div style={{ marginTop: 'auto', paddingTop: 12, borderTop: '1px solid var(--border-light)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8 }}>
                      <div>
                        <span style={{ fontSize: '1.25rem', fontWeight: 900, color: 'var(--text-main)' }}>
                          ₹{product.price.toLocaleString('en-IN')}
                        </span>
                        {product.originalPrice > product.price && (
                          <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)', textDecoration: 'line-through', marginLeft: 6 }}>
                            ₹{product.originalPrice.toLocaleString('en-IN')}
                          </span>
                        )}
                      </div>
                      <span style={{ fontSize: '0.78rem', fontWeight: 700, color: '#10B981' }}>
                        {product.marginPercent}% Profit Margin
                      </span>
                    </div>

                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                      <span><strong>{product.salesCount}</strong> units sold</span>
                      <span><strong>₹{product.revenueGenerated.toLocaleString('en-IN')}</strong> GMV</span>
                      <span>Conv: <strong>{product.conversionRate}</strong></span>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* ADD PRODUCT MODAL */}
          {showAddModal && (
            <div style={{
              position: 'fixed',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              background: 'rgba(15, 23, 42, 0.65)',
              backdropFilter: 'blur(6px)',
              zIndex: 9999,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              padding: 20
            }}>
              <div style={{
                background: 'var(--bg-card)',
                borderRadius: 16,
                border: '1px solid var(--border)',
                width: '100%',
                maxWidth: 640,
                maxHeight: '90vh',
                overflowY: 'auto',
                boxShadow: '0 20px 50px rgba(0,0,0,0.3)',
                display: 'flex',
                flexDirection: 'column'
              }}>
                {/* Modal Header */}
                <div style={{
                  padding: '20px 24px',
                  borderBottom: '1px solid var(--border)',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center'
                }}>
                  <div>
                    <h3 style={{ margin: 0, fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-main)', display: 'flex', alignItems: 'center', gap: 8 }}>
                      <Package size={20} color="var(--primary)" /> Add New Commercial Product / Package
                    </h3>
                    <p style={{ margin: '4px 0 0 0', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                      Integrates automatically with AI symptom analysis & live recommendation stream.
                    </p>
                  </div>
                  <button
                    onClick={() => setShowAddModal(false)}
                    style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
                  >
                    <X size={20} />
                  </button>
                </div>

                {/* Modal Form */}
                <form onSubmit={handleAddProduct} style={{ padding: 24, display: 'flex', flexDirection: 'column', gap: 16 }}>
                  {/* Title & Category */}
                  <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 14 }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                        Product / Package Name *
                      </label>
                      <input
                        type="text"
                        placeholder="e.g. Smart ECG Monitor 6-Lead"
                        value={newProduct.title}
                        onChange={(e) => setNewProduct({ ...newProduct, title: e.target.value })}
                        required
                        style={{
                          width: '100%',
                          padding: '10px 12px',
                          borderRadius: 8,
                          border: '1px solid var(--border)',
                          background: 'var(--bg-main)',
                          fontSize: '0.88rem'
                        }}
                      />
                    </div>

                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                        Category
                      </label>
                      <select
                        value={newProduct.category}
                        onChange={(e) => setNewProduct({ ...newProduct, category: e.target.value })}
                        style={{
                          width: '100%',
                          padding: '10px 12px',
                          borderRadius: 8,
                          border: '1px solid var(--border)',
                          background: 'var(--bg-main)',
                          fontSize: '0.88rem'
                        }}
                      >
                        <option value="Medical Devices & Diagnostics">Medical Devices</option>
                        <option value="Diagnostics & Lab Tests">Lab Test Packages</option>
                        <option value="Chronic Disease Kits">Chronic Disease Kits</option>
                        <option value="Supplements & Nutrition">Supplements & Nutrition</option>
                        <option value="Orthopedics & Joint Support">Ortho & Joint Care</option>
                        <option value="Maternal & Child Health">Maternal & Child Care</option>
                      </select>
                    </div>
                  </div>

                  {/* Pricing Row */}
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 14 }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                        Special Price (₹) *
                      </label>
                      <input
                        type="number"
                        placeholder="e.g. 1499"
                        value={newProduct.price}
                        onChange={(e) => setNewProduct({ ...newProduct, price: e.target.value })}
                        required
                        style={{
                          width: '100%',
                          padding: '10px 12px',
                          borderRadius: 8,
                          border: '1px solid var(--border)',
                          background: 'var(--bg-main)',
                          fontSize: '0.88rem'
                        }}
                      />
                    </div>

                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                        MRP / Original (₹)
                      </label>
                      <input
                        type="number"
                        placeholder="e.g. 2499"
                        value={newProduct.originalPrice}
                        onChange={(e) => setNewProduct({ ...newProduct, originalPrice: e.target.value })}
                        style={{
                          width: '100%',
                          padding: '10px 12px',
                          borderRadius: 8,
                          border: '1px solid var(--border)',
                          background: 'var(--bg-main)',
                          fontSize: '0.88rem'
                        }}
                      />
                    </div>

                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                        Profit Margin %
                      </label>
                      <input
                        type="number"
                        placeholder="e.g. 30"
                        value={newProduct.marginPercent}
                        onChange={(e) => setNewProduct({ ...newProduct, marginPercent: e.target.value })}
                        style={{
                          width: '100%',
                          padding: '10px 12px',
                          borderRadius: 8,
                          border: '1px solid var(--border)',
                          background: 'var(--bg-main)',
                          fontSize: '0.88rem'
                        }}
                      />
                    </div>
                  </div>

                  {/* Badge & Target Segment */}
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                        Promo Badge
                      </label>
                      <input
                        type="text"
                        placeholder="e.g. AI Recommended / Bestseller"
                        value={newProduct.badge}
                        onChange={(e) => setNewProduct({ ...newProduct, badge: e.target.value })}
                        style={{
                          width: '100%',
                          padding: '10px 12px',
                          borderRadius: 8,
                          border: '1px solid var(--border)',
                          background: 'var(--bg-main)',
                          fontSize: '0.88rem'
                        }}
                      />
                    </div>

                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                        Primary Target Health Segment
                      </label>
                      <select
                        value={newProduct.targetSegments[0] || 'Diabetes & Endocrine Care'}
                        onChange={(e) => setNewProduct({ ...newProduct, targetSegments: [e.target.value] })}
                        style={{
                          width: '100%',
                          padding: '10px 12px',
                          borderRadius: 8,
                          border: '1px solid var(--border)',
                          background: 'var(--bg-main)',
                          fontSize: '0.88rem'
                        }}
                      >
                        {availableSegments.map((seg, sIdx) => (
                          <option key={sIdx} value={seg}>{seg}</option>
                        ))}
                      </select>
                    </div>
                  </div>

                  {/* Detected Problem Keywords */}
                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                      AI Problem Trigger Keywords (Comma separated)
                    </label>
                    <input
                      type="text"
                      placeholder="e.g. chest pain, hypertension, palpitations, high bp, irregular pulse"
                      value={newProduct.targetConditions}
                      onChange={(e) => setNewProduct({ ...newProduct, targetConditions: e.target.value })}
                      style={{
                        width: '100%',
                        padding: '10px 12px',
                        borderRadius: 8,
                        border: '1px solid var(--border)',
                        background: 'var(--bg-main)',
                        fontSize: '0.88rem'
                      }}
                    />
                    <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: 4, display: 'block' }}>
                      When AI chatbot detects these keywords in patient conversation, it highlights this product.
                    </span>
                  </div>

                  {/* Image URL & Preset Picker */}
                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                      Product Image URL (100% 200 OK Verified)
                    </label>
                    <input
                      type="url"
                      placeholder="https://images.unsplash.com/..."
                      value={newProduct.imageUrl}
                      onChange={(e) => setNewProduct({ ...newProduct, imageUrl: e.target.value })}
                      style={{
                        width: '100%',
                        padding: '10px 12px',
                        borderRadius: 8,
                        border: '1px solid var(--border)',
                        background: 'var(--bg-main)',
                        fontSize: '0.88rem',
                        marginBottom: 8
                      }}
                    />

                    {/* Quick Presets Picker */}
                    <div style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: 6 }}>
                      Or choose from verified medical asset presets:
                    </div>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
                      {verifiedImagePresets.map((preset, pIdx) => {
                        const isChosen = newProduct.imageUrl === preset.url;
                        return (
                          <div
                            key={pIdx}
                            onClick={() => setNewProduct({ ...newProduct, imageUrl: preset.url })}
                            style={{
                              padding: '6px 8px',
                              borderRadius: 6,
                              border: isChosen ? '2px solid var(--primary)' : '1px solid var(--border)',
                              background: isChosen ? 'var(--primary-light)' : 'var(--bg-main)',
                              cursor: 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                              gap: 6,
                              fontSize: '0.72rem',
                              fontWeight: isChosen ? 800 : 600,
                              color: isChosen ? 'var(--primary)' : 'var(--text-main)'
                            }}
                          >
                            <img
                              src={preset.url}
                              alt={preset.label}
                              style={{ width: 28, height: 28, borderRadius: 4, objectFit: 'cover' }}
                            />
                            <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                              {preset.label}
                            </span>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 12, marginTop: 10, paddingTop: 14, borderTop: '1px solid var(--border)' }}>
                    <button
                      type="button"
                      onClick={() => setShowAddModal(false)}
                      style={{
                        padding: '10px 18px',
                        borderRadius: 8,
                        border: '1px solid var(--border)',
                        background: 'var(--bg-main)',
                        color: 'var(--text-main)',
                        fontWeight: 700,
                        fontSize: '0.85rem',
                        cursor: 'pointer'
                      }}
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 8,
                        padding: '10px 24px',
                        borderRadius: 8,
                        background: 'linear-gradient(135deg, #1E60F6 0%, #0D9488 100%)',
                        color: 'white',
                        fontWeight: 800,
                        fontSize: '0.88rem',
                        border: 'none',
                        cursor: 'pointer',
                        boxShadow: '0 4px 12px rgba(30, 96, 246, 0.25)'
                      }}
                    >
                      <Check size={16} /> Save & Activate in AI Engine
                    </button>
                  </div>
                </form>
              </div>
            </div>
          )}
        </div>
      )}

      {/* SUB-TAB 3: NEARBY MEDICAL STORES & CHEMISTS */}
      {activeSubTab === 'stores' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          {/* Header Action Bar */}
          <div style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: 14,
            padding: '16px 20px',
            background: 'var(--bg-card)',
            borderRadius: 12,
            border: '1px solid var(--border)'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <img
                src={storePartnerIllus}
                alt="Medical Store"
                style={{ width: 56, height: 56, objectFit: 'contain' }}
              />
              <div>
                <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--text-main)', margin: 0 }}>
                  Nearby Medical Stores & Hyperlocal Dark Stores ({medicalStoresList.length})
                </h3>
                <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', margin: '4px 0 0 0' }}>
                  Powers 12-15 minute doorstep medicine delivery & live stock lookup in the patient mobile app.
                </p>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
              <button
                onClick={() => setShowAddStoreModal(true)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  padding: '9px 18px',
                  borderRadius: 8,
                  background: 'linear-gradient(135deg, #10B981 0%, #0D9488 100%)',
                  color: 'white',
                  fontWeight: 800,
                  fontSize: '0.85rem',
                  border: 'none',
                  cursor: 'pointer',
                  boxShadow: '0 4px 12px rgba(16, 185, 129, 0.25)'
                }}
              >
                <Plus size={16} /> Register New Medical Store
              </button>
            </div>
          </div>

          {/* Pending Store Approvals Banner */}
          {medicalStoresList.some(s => s.verificationStatus === 'Pending' || s.verification_status === 'pending') && (
            <div style={{
              background: '#FEF3C7',
              border: '1px solid #FCD34D',
              borderRadius: 12,
              padding: '16px 20px',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              flexWrap: 'wrap',
              gap: 12
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                <img
                  src={storePendingIllus}
                  alt="KYC Review"
                  style={{ width: 54, height: 54, objectFit: 'contain' }}
                />
                <div>
                  <h4 style={{ margin: 0, fontSize: '0.95rem', fontWeight: 800, color: '#92400E' }}>
                    Pending Store Partner KYC Verifications
                  </h4>
                  <p style={{ margin: '2px 0 0 0', fontSize: '0.8rem', color: '#B45309' }}>
                    {medicalStoresList.filter(s => s.verificationStatus === 'Pending' || s.verification_status === 'pending').length} new pharmacy applications submitted via App onboarding awaiting State Drug License audit.
                  </p>
                </div>
              </div>
              <div style={{ display: 'flex', gap: 8 }}>
                {medicalStoresList.filter(s => s.verificationStatus === 'Pending' || s.verification_status === 'pending').map(pStore => (
                  <button
                    key={pStore.id}
                    onClick={() => setSelectedStoreForVerify(pStore)}
                    style={{
                      padding: '8px 16px',
                      background: '#D97706',
                      color: 'white',
                      border: 'none',
                      borderRadius: 8,
                      fontWeight: 800,
                      fontSize: '0.82rem',
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: 6
                    }}
                  >
                    <CheckCircle2 size={14} /> Review {pStore.name.split(' ')[0]}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Stores Grid */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: 20 }}>
            {medicalStoresList.map((store) => (
              <div
                key={store.id}
                className="chart-card"
                style={{
                  padding: 0,
                  overflow: 'hidden',
                  display: 'flex',
                  flexDirection: 'column',
                  border: '1px solid var(--border)',
                  borderRadius: 14
                }}
              >
                <div style={{ position: 'relative', height: 150, background: '#F8FAFC' }}>
                  <img
                    src={store.imageUrl}
                    alt={store.name}
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  />
                  <span style={{
                    position: 'absolute',
                    top: 12,
                    left: 12,
                    padding: '4px 10px',
                    borderRadius: 20,
                    background: store.is24x7 ? 'rgba(16, 185, 129, 0.9)' : 'rgba(15, 23, 42, 0.85)',
                    color: 'white',
                    fontSize: '0.72rem',
                    fontWeight: 800,
                    letterSpacing: '0.4px'
                  }}>
                    {store.is24x7 ? '24x7 OPEN' : 'OPEN NOW'}
                  </span>
                  <span style={{
                    position: 'absolute',
                    top: 12,
                    right: 12,
                    padding: '4px 10px',
                    borderRadius: 20,
                    background: 'rgba(15, 23, 42, 0.85)',
                    backdropFilter: 'blur(4px)',
                    color: '#F59E0B',
                    fontSize: '0.72rem',
                    fontWeight: 800
                  }}>
                    ★ {store.rating} ({store.reviews})
                  </span>
                </div>

                <div style={{ padding: 18, display: 'flex', flexDirection: 'column', flex: 1 }}>
                  <div style={{ fontSize: '0.72rem', fontWeight: 800, color: 'var(--primary)', textTransform: 'uppercase', marginBottom: 4 }}>
                    {store.area} • {store.city}
                  </div>
                  <h4 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--text-main)', marginBottom: 6 }}>
                    {store.name}
                  </h4>
                  <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginBottom: 12, lineHeight: 1.4 }}>
                    {store.address}
                  </p>

                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6, fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: 14 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <Phone size={13} color="var(--primary)" /> {store.phone}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <FileText size={13} color="#10B981" /> License: <strong>{store.license}</strong>
                    </div>
                  </div>

                  {/* Metrics & KYC Footer */}
                  <div style={{ marginTop: 'auto', paddingTop: 12, borderTop: '1px solid var(--border-light)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{
                      padding: '4px 8px',
                      background: '#DCFCE7',
                      color: '#166534',
                      borderRadius: 6,
                      fontSize: '0.72rem',
                      fontWeight: 800
                    }}>
                      ⚡ {store.etaMinutes} MINS ETA
                    </span>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <span style={{
                        padding: '3px 8px',
                        borderRadius: 6,
                        fontSize: '0.72rem',
                        fontWeight: 800,
                        background: (store.verificationStatus === 'Verified' || store.verification_status === 'verified') ? '#DCFCE7' : store.verificationStatus === 'Rejected' ? '#FEE2E2' : '#FEF3C7',
                        color: (store.verificationStatus === 'Verified' || store.verification_status === 'verified') ? '#166534' : store.verificationStatus === 'Rejected' ? '#991B1B' : '#92400E'
                      }}>
                        {store.verificationStatus || store.verification_status || 'Verified'}
                      </span>
                      {(store.verificationStatus === 'Pending' || store.verification_status === 'pending') && (
                        <button
                          onClick={() => setSelectedStoreForVerify(store)}
                          style={{
                            padding: '3px 8px',
                            background: '#0D9488',
                            color: 'white',
                            border: 'none',
                            borderRadius: 6,
                            fontSize: '0.72rem',
                            fontWeight: 800,
                            cursor: 'pointer'
                          }}
                        >
                          Verify KYC
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* ADD MEDICAL STORE MODAL */}
          {showAddStoreModal && (
            <div style={{
              position: 'fixed',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              background: 'rgba(15, 23, 42, 0.65)',
              backdropFilter: 'blur(6px)',
              zIndex: 9999,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              padding: 20
            }}>
              <div style={{
                background: 'var(--bg-card)',
                borderRadius: 16,
                border: '1px solid var(--border)',
                width: '100%',
                maxWidth: 600,
                maxHeight: '90vh',
                overflowY: 'auto',
                boxShadow: '0 20px 50px rgba(0,0,0,0.3)',
                display: 'flex',
                flexDirection: 'column'
              }}>
                <div style={{
                  padding: '20px 24px',
                  borderBottom: '1px solid var(--border)',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center'
                }}>
                  <div>
                    <h3 style={{ margin: 0, fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-main)', display: 'flex', alignItems: 'center', gap: 8 }}>
                      <Store size={20} color="var(--primary)" /> Register Nearby Medical Store / Dark Store
                    </h3>
                    <p style={{ margin: '4px 0 0 0', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                      Enables 15-min delivery dispatch and store inventory synchronization in user app.
                    </p>
                  </div>
                  <button
                    onClick={() => setShowAddStoreModal(false)}
                    style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
                  >
                    <X size={20} />
                  </button>
                </div>

                <form onSubmit={handleAddStore} style={{ padding: 24, display: 'flex', flexDirection: 'column', gap: 16 }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                      Store / Pharmacy Name *
                    </label>
                    <input
                      type="text"
                      placeholder="e.g. Apollo Pharmacy 24x7"
                      value={newStore.name}
                      onChange={(e) => setNewStore({ ...newStore, name: e.target.value })}
                      required
                      style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1px solid var(--border)', background: 'var(--bg-main)', fontSize: '0.88rem' }}
                    />
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                        Area / Suburb *
                      </label>
                      <input
                        type="text"
                        placeholder="e.g. Hitech City / Jubilee Hills"
                        value={newStore.area}
                        onChange={(e) => setNewStore({ ...newStore, area: e.target.value })}
                        required
                        style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1px solid var(--border)', background: 'var(--bg-main)', fontSize: '0.88rem' }}
                      />
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                        City *
                      </label>
                      <input
                        type="text"
                        placeholder="e.g. Hyderabad"
                        value={newStore.city}
                        onChange={(e) => setNewStore({ ...newStore, city: e.target.value })}
                        required
                        style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1px solid var(--border)', background: 'var(--bg-main)', fontSize: '0.88rem' }}
                      />
                    </div>
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                      Full Street Address *
                    </label>
                    <input
                      type="text"
                      placeholder="e.g. Plot 12, Phase 2, Hitech City Main Rd, Hyderabad"
                      value={newStore.address}
                      onChange={(e) => setNewStore({ ...newStore, address: e.target.value })}
                      required
                      style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1px solid var(--border)', background: 'var(--bg-main)', fontSize: '0.88rem' }}
                    />
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                        Phone / Dispatch Contact
                      </label>
                      <input
                        type="text"
                        placeholder="+91 40 2360 8888"
                        value={newStore.phone}
                        onChange={(e) => setNewStore({ ...newStore, phone: e.target.value })}
                        style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1px solid var(--border)', background: 'var(--bg-main)', fontSize: '0.88rem' }}
                      />
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                        Drug License Number
                      </label>
                      <input
                        type="text"
                        placeholder="TS-HYD-PHARM-2024-XXXX"
                        value={newStore.license}
                        onChange={(e) => setNewStore({ ...newStore, license: e.target.value })}
                        style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1px solid var(--border)', background: 'var(--bg-main)', fontSize: '0.88rem' }}
                      />
                    </div>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                        Average Delivery ETA (Mins)
                      </label>
                      <input
                        type="number"
                        placeholder="15"
                        value={newStore.etaMinutes}
                        onChange={(e) => setNewStore({ ...newStore, etaMinutes: e.target.value })}
                        style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1px solid var(--border)', background: 'var(--bg-main)', fontSize: '0.88rem' }}
                      />
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                      <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '0.85rem', fontWeight: 700, cursor: 'pointer', marginTop: 18 }}>
                        <input
                          type="checkbox"
                          checked={newStore.is24x7}
                          onChange={(e) => setNewStore({ ...newStore, is24x7: e.target.checked })}
                          style={{ width: 18, height: 18, accentColor: 'var(--primary)' }}
                        />
                        Open 24x7 Day & Night
                      </label>
                    </div>
                  </div>

                  {/* Preset Image Picker */}
                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: 6, color: 'var(--text-main)' }}>
                      Store Front Image (100% 200 OK Verified)
                    </label>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 8 }}>
                      {verifiedStorePresets.map((preset, pIdx) => {
                        const isChosen = newStore.imageUrl === preset.url;
                        return (
                          <div
                            key={pIdx}
                            onClick={() => setNewStore({ ...newStore, imageUrl: preset.url })}
                            style={{
                              padding: '8px 10px',
                              borderRadius: 8,
                              border: isChosen ? '2px solid var(--primary)' : '1px solid var(--border)',
                              background: isChosen ? 'var(--primary-light)' : 'var(--bg-main)',
                              cursor: 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                              gap: 8,
                              fontSize: '0.78rem',
                              fontWeight: isChosen ? 800 : 600,
                              color: isChosen ? 'var(--primary)' : 'var(--text-main)'
                            }}
                          >
                            <img
                              src={preset.url}
                              alt={preset.label}
                              style={{ width: 32, height: 32, borderRadius: 6, objectFit: 'cover' }}
                            />
                            <span>{preset.label}</span>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 12, marginTop: 10, paddingTop: 14, borderTop: '1px solid var(--border)' }}>
                    <button
                      type="button"
                      onClick={() => setShowAddStoreModal(false)}
                      style={{ padding: '10px 18px', borderRadius: 8, border: '1px solid var(--border)', background: 'var(--bg-main)', fontWeight: 700, fontSize: '0.85rem', cursor: 'pointer' }}
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 24px', borderRadius: 8, background: 'linear-gradient(135deg, #10B981 0%, #0D9488 100%)', color: 'white', fontWeight: 800, fontSize: '0.88rem', border: 'none', cursor: 'pointer', boxShadow: '0 4px 12px rgba(16, 185, 129, 0.25)' }}
                    >
                      <Check size={16} /> Register & Connect Store
                    </button>
                  </div>
                </form>
              </div>
            </div>
          )}
        </div>
      )}

      {/* SUB-TAB 4: LIVE AI LEAD STREAM */}
      {activeSubTab === 'leads' && (
        <div className="chart-card" style={{ padding: 22 }}>
          <h3 style={{ fontSize: '1.05rem', fontWeight: 800, marginBottom: 16, color: 'var(--text-main)' }}>
            Real-Time AI Problem Detection & Commercial Suggestion Stream
          </h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {leads.map((lead, idx) => (
              <div
                key={idx}
                style={{
                  padding: 16,
                  borderRadius: 12,
                  background: 'var(--bg-main)',
                  border: '1px solid var(--border)',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  flexWrap: 'wrap',
                  gap: 14
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                  <img
                    src={lead.userAvatar}
                    alt={lead.userName}
                    style={{ width: 44, height: 44, borderRadius: '50%', objectFit: 'cover' }}
                  />
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <strong style={{ fontSize: '0.92rem' }}>{lead.userName}</strong>
                      <span style={{ fontSize: '0.72rem', padding: '2px 6px', background: '#DCFCE7', color: '#166534', borderRadius: 4, fontWeight: 700 }}>
                        {lead.leadStage}
                      </span>
                    </div>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', marginTop: 2 }}>
                      💬 <em>"{lead.aiTrigger}"</em>
                    </p>
                  </div>
                </div>

                <div style={{ textAlign: 'right' }}>
                  <span style={{ fontSize: '0.75rem', color: 'var(--primary)', fontWeight: 800, display: 'block' }}>
                    → {lead.recommendedProduct}
                  </span>
                  <span style={{ fontSize: '0.88rem', fontWeight: 900, color: 'var(--text-main)' }}>
                    ₹{lead.orderValue} • {lead.lastInteraction}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* SUB-TAB 4: MONETIZATION & RECOMMENDATION RULES */}
      {activeSubTab === 'rules' && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: 20 }}>
          <div className="chart-card" style={{ padding: 22 }}>
            <h3 style={{ fontSize: '1.05rem', fontWeight: 800, marginBottom: 14 }}>
              🎯 AI Product Suggestion Guardrails
            </h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 0', borderBottom: '1px solid var(--border-light)' }}>
                <div>
                  <strong style={{ fontSize: '0.88rem', display: 'block' }}>Automated In-Chat Product Cards</strong>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Display complementary care products during triage</span>
                </div>
                <input 
                  type="checkbox" 
                  checked={inChatEnabled} 
                  onChange={(e) => setInChatEnabled(e.target.checked)} 
                  style={{ width: 18, height: 18, accentColor: 'var(--primary)' }} 
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 0', borderBottom: '1px solid var(--border-light)' }}>
                <div>
                  <strong style={{ fontSize: '0.88rem', display: 'block' }}>Red-Flag Emergency Suppression</strong>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Strictly hide commercial products during acute cardiac/stroke</span>
                </div>
                <span style={{ padding: '2px 8px', background: '#DCFCE7', color: '#166534', borderRadius: 4, fontSize: '0.72rem', fontWeight: 800 }}>
                  ACTIVE (LOCKED)
                </span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 0', borderBottom: '1px solid var(--border-light)' }}>
                <div>
                  <strong style={{ fontSize: '0.88rem', display: 'block' }}>Max Products Per Consultation</strong>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Prevent cluttering clinical advice</span>
                </div>
                <select 
                  value={maxProducts} 
                  onChange={(e) => setMaxProducts(e.target.value)} 
                  style={{ padding: '6px 12px', borderRadius: 6, border: '1px solid var(--border)', fontSize: '0.82rem', background: 'var(--bg-main)' }}
                >
                  <option value="1">1 (Ultra Subtle)</option>
                  <option value="2">2 (Optimal Balance)</option>
                  <option value="3">3 (Commercial Push)</option>
                </select>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 0' }}>
                <div>
                  <strong style={{ fontSize: '0.88rem', display: 'block' }}>Active Promo Code Multiplier</strong>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Auto-applied in AI chat</span>
                </div>
                <input
                  type="text"
                  value={promoCode}
                  onChange={(e) => setPromoCode(e.target.value)}
                  style={{ width: 160, padding: '6px 10px', borderRadius: 6, border: '1px solid var(--border)', fontSize: '0.82rem', fontWeight: 700, background: 'var(--bg-main)' }}
                />
              </div>
            </div>
          </div>

          <div className="chart-card" style={{ padding: 22 }}>
            <h3 style={{ fontSize: '1.05rem', fontWeight: 800, marginBottom: 14 }}>
              📈 Revenue Attribution & Payouts
            </h3>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', marginBottom: 16 }}>
              HealthExpress shares up to 15% partner commission with empanelled diagnostic labs and device manufacturers.
            </p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <div style={{ padding: 12, borderRadius: 8, background: '#EFF6FF', display: 'flex', justifyContent: 'space-between', border: '1px solid #DBEAFE' }}>
                <span style={{ fontSize: '0.82rem', fontWeight: 600 }}>Diagnostic Lab Partners (Apollo / MedPlus):</span>
                <strong style={{ color: '#1E60F6' }}>35% Platform Margin</strong>
              </div>
              <div style={{ padding: 12, borderRadius: 8, background: '#F0FDF4', display: 'flex', justifyContent: 'space-between', border: '1px solid #DCFCE7' }}>
                <span style={{ fontSize: '0.82rem', fontWeight: 600 }}>Smart Devices (Glucometers / BP Kits):</span>
                <strong style={{ color: '#10B981' }}>28% Platform Margin</strong>
              </div>
              <div style={{ padding: 12, borderRadius: 8, background: '#FAF5FF', display: 'flex', justifyContent: 'space-between', border: '1px solid #F3E8FF' }}>
                <span style={{ fontSize: '0.82rem', fontWeight: 600 }}>Gold Family Annual Care Pass:</span>
                <strong style={{ color: '#8B5CF6' }}>45% Platform Margin</strong>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Store Verification Modal */}
      <StoreVerificationModal
        isOpen={!!selectedStoreForVerify}
        onClose={() => setSelectedStoreForVerify(null)}
        store={selectedStoreForVerify}
        onVerified={handleStoreVerified}
      />
    </div>
  );
}
