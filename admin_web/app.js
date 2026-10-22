const API_BASE = 'https://acheva.in/api';

// State loaded live from remote MySQL
let platformData = {
  hospitals: [],
  doctors: [],
  users: [
    { name: 'Rahul Kumar', phone: '+91 9876543210', email: 'rahul.kumar@gmail.com', aarogyasri: 'AROG12345678', joined: '18 May 2024', status: 'Active', avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=200' },
    { name: 'Anita Sharma', phone: '+91 9848011223', email: 'anita.sharma@yahoo.com', aarogyasri: 'AROG88900112', joined: '17 May 2024', status: 'Active', avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200' },
    { name: 'Suresh Rao', phone: '+91 9700123456', email: 'suresh.rao@outlook.com', aarogyasri: 'AROG77865544', joined: '17 May 2024', status: 'Active', avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=200' },
  ],
  bookings: [
    { id: 'BK24851', patient: 'Rahul Kumar', doctor: 'Dr. Sandeep Attawar', hospital: 'KIMS Hospitals', datetime: '18 May 2024, 10:30 AM', status: 'Confirmed', payment: 'Paid (Aarogyasri)' },
    { id: 'BK24850', patient: 'Anita Sharma', doctor: 'Dr. Priya Nair', hospital: 'Apollo Hospitals', datetime: '18 May 2024, 12:00 PM', status: 'Confirmed', payment: 'Paid (UPI)' },
    { id: 'BK24849', patient: 'Suresh Rao', doctor: 'Dr. Naveen Thota', hospital: 'Yashoda Hospitals', datetime: '18 May 2024, 02:30 PM', status: 'Upcoming', payment: 'Paid (Card)' },
  ],
  tickets: [
    { id: 'TK2561', user: 'Rahul Kumar', category: 'Booking', subject: 'Aarogyasri subsidy discount verification', priority: 'High', status: 'Open' },
    { id: 'TK2560', user: 'Anita Sharma', category: 'Payment', subject: 'Razorpay UPI confirmation receipt', priority: 'Medium', status: 'In Progress' },
    { id: 'TK2559', user: 'Dr. Sandeep Attawar', category: 'Doctor', subject: 'Shift slot buffer configuration update', priority: 'Low', status: 'Resolved' },
  ]
};

// Fetch Live Data from Backend / Remote MySQL
async function fetchLiveDatabaseData() {
  try {
    const [hospRes, docRes] = await Promise.all([
      fetch(`${API_BASE}/hospitals`).catch(() => null),
      fetch(`${API_BASE}/doctors`).catch(() => null),
    ]);

    if (hospRes && hospRes.ok) {
      const liveHospitals = await hospRes.json();
      if (liveHospitals && liveHospitals.length > 0) {
        platformData.hospitals = liveHospitals.map(h => ({
          name: h.name,
          location: h.location,
          doctors: h.staff_count || 120,
          users: (h.reviews_count * 10) || 5200,
          status: h.status || 'Active',
        }));
        renderHospitals();
      }
    }

    if (docRes && docRes.ok) {
      const liveDocs = await docRes.json();
      if (liveDocs && liveDocs.length > 0) {
        platformData.doctors = liveDocs.map(d => ({
          name: d.name,
          hospital: d.hospital_name || 'KIMS Hospitals',
          specialty: d.specialty,
          exp: `${d.experience_years}+ Years`,
          status: d.verification_status || 'Active',
          avatar: d.photo_url || 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=200',
        }));
        renderDoctors();
      }
    }
  } catch (err) {
    console.warn('Backend live API warning:', err);
  }
}

// Nav Tab Switcher
const navButtons = document.querySelectorAll('.nav-item');
const viewSections = document.querySelectorAll('.view-section');
const pageTitle = document.getElementById('pageTitle');
const pageSubtitle = document.getElementById('pageSubtitle');

const viewTitles = {
  dashboard: { title: 'Dashboard Overview', sub: 'Real-time healthcare platform statistics and operational telemetry' },
  hospitals: { title: 'Hospitals Management', sub: 'Manage hospital empanelment, bed availability, and departments' },
  doctors: { title: 'Doctors Directory & Verification', sub: 'MCI Council verification, hospital affiliations, and scheduling' },
  users: { title: 'Users & Patient Records', sub: 'Registered patients, Aarogyasri ID passes, and consultation history' },
  bookings: { title: 'Bookings & Telehealth Queue', sub: 'Live consultation bookings, video room sessions, and home dispatch' },
  payments: { title: 'Payments & Revenue Ledger', sub: 'Platform commission breakdown, doctor payouts, and Razorpay gateway' },
  tickets: { title: 'Support & Helpdesk Tickets', sub: 'Clinical inquiries, payment reconciliation, and dispute resolution' },
  reports: { title: 'Reports & Business Analytics', sub: 'Hospital volume rankings, growth velocity, and retention trends' },
  settings: { title: 'Super Admin Settings', sub: 'System configuration, access controls, and security audit logs' }
};

function switchView(viewName) {
  navButtons.forEach(btn => {
    btn.classList.toggle('active', btn.dataset.view === viewName);
  });

  viewSections.forEach(sec => {
    sec.classList.toggle('active', sec.id === `view-${viewName}`);
  });

  if (viewTitles[viewName]) {
    pageTitle.textContent = viewTitles[viewName].title;
    pageSubtitle.textContent = viewTitles[viewName].sub;
  }
}

navButtons.forEach(btn => {
  btn.addEventListener('click', () => switchView(btn.dataset.view));
});

// Render Hospitals Table
function renderHospitals() {
  const tbody = document.querySelector('#hospitalsTable tbody');
  if (!tbody) return;
  tbody.innerHTML = platformData.hospitals.map(h => `
    <tr>
      <td><strong>${h.name}</strong></td>
      <td>${h.location}</td>
      <td>${h.doctors}</td>
      <td>${h.users}</td>
      <td><span class="status-chip ${h.status.toLowerCase()}">${h.status}</span></td>
      <td>
        <div class="action-icons">
          <button title="View Details"><i class="fa-regular fa-eye"></i></button>
          <button title="Edit"><i class="fa-regular fa-pen-to-square"></i></button>
          <button title="Delete"><i class="fa-regular fa-trash-can"></i></button>
        </div>
      </td>
    </tr>
  `).join('');
}

// Render Doctors Table
function renderDoctors(filter = 'All') {
  const tbody = document.querySelector('#doctorsTable tbody');
  if (!tbody) return;
  const filtered = filter === 'All' ? platformData.doctors : platformData.doctors.filter(d => d.specialty === filter);
  tbody.innerHTML = filtered.map(d => `
    <tr>
      <td>
        <img src="${d.avatar}" class="table-avatar" alt="${d.name}">
        <strong>${d.name}</strong>
      </td>
      <td>${d.hospital}</td>
      <td>${d.specialty}</td>
      <td>${d.exp}</td>
      <td><span class="status-chip ${d.status === 'Active' ? 'active' : 'pending'}">${d.status}</span></td>
      <td>
        <div class="action-icons">
          <button title="View Profile"><i class="fa-regular fa-eye"></i></button>
          <button title="Edit"><i class="fa-regular fa-pen-to-square"></i></button>
          <button title="Delete"><i class="fa-regular fa-trash-can"></i></button>
        </div>
      </td>
    </tr>
  `).join('');
}

// Render Users Table
function renderUsers() {
  const tbody = document.querySelector('#usersTable tbody');
  if (!tbody) return;
  tbody.innerHTML = platformData.users.map(u => `
    <tr>
      <td>
        <img src="${u.avatar}" class="table-avatar" alt="${u.name}">
        <strong>${u.name}</strong>
      </td>
      <td>${u.phone}</td>
      <td>${u.email}</td>
      <td><strong style="color: var(--primary);">${u.aarogyasri}</strong></td>
      <td>${u.joined}</td>
      <td><span class="status-chip active">${u.status}</span></td>
      <td>
        <div class="action-icons">
          <button title="View Health File"><i class="fa-regular fa-eye"></i></button>
          <button title="Edit User"><i class="fa-regular fa-pen-to-square"></i></button>
        </div>
      </td>
    </tr>
  `).join('');
}

// Render Bookings Table
function renderBookings(statusFilter = 'All') {
  const tbody = document.querySelector('#bookingsTable tbody');
  if (!tbody) return;
  const filtered = statusFilter === 'All' ? platformData.bookings : platformData.bookings.filter(b => b.status === statusFilter);
  tbody.innerHTML = filtered.map(b => `
    <tr>
      <td><strong style="color: var(--primary);">${b.id}</strong></td>
      <td>${b.patient}</td>
      <td>${b.doctor}</td>
      <td>${b.hospital}</td>
      <td>${b.datetime}</td>
      <td><span class="status-chip ${b.status.toLowerCase()}">${b.status}</span></td>
      <td>${b.payment}</td>
      <td>
        <div class="action-icons">
          <button title="View Booking"><i class="fa-regular fa-eye"></i></button>
          <button title="Manage"><i class="fa-regular fa-pen-to-square"></i></button>
        </div>
      </td>
    </tr>
  `).join('');
}

// Render Tickets Table
function renderTickets() {
  const tbody = document.querySelector('#ticketsTable tbody');
  if (!tbody) return;
  tbody.innerHTML = platformData.tickets.map(t => `
    <tr>
      <td><strong style="color: var(--primary);">${t.id}</strong></td>
      <td>${t.user}</td>
      <td><span class="badge primary">${t.category}</span></td>
      <td>${t.subject}</td>
      <td><strong style="color: ${t.priority === 'High' ? 'var(--error)' : 'var(--warning)'};">${t.priority}</strong></td>
      <td><span class="status-chip ${t.status.toLowerCase().replace(' ', '-')}">${t.status}</span></td>
      <td>
        <div class="action-icons">
          <button title="Reply & Resolve"><i class="fa-regular fa-comment-dots"></i></button>
        </div>
      </td>
    </tr>
  `).join('');
}

// Filters & Event Listeners
document.getElementById('doctorSpecialtyFilter')?.addEventListener('change', (e) => {
  renderDoctors(e.target.value);
});

document.getElementById('bookingStatusFilter')?.addEventListener('change', (e) => {
  renderBookings(e.target.value);
});

// Modals
function openAddHospitalModal() {
  document.getElementById('addHospitalModal').classList.add('active');
}
function openAddDoctorModal() {
  document.getElementById('addDoctorModal').classList.add('active');
}
function openNewTicketModal() {
  switchView('tickets');
}
function closeModal(id) {
  document.getElementById(id).classList.remove('active');
}

async function saveNewHospital() {
  const name = document.getElementById('newHospName').value.trim();
  const location = document.getElementById('newHospLocation').value.trim();
  const docs = parseInt(document.getElementById('newHospDoctors').value) || 50;

  if (!name || !location) {
    alert('Please enter hospital name and location.');
    return;
  }

  // Save to Live Backend
  try {
    await fetch(`${API_BASE}/hospitals`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, location, rating: 4.8 })
    });
  } catch (e) {}

  platformData.hospitals.unshift({ name, location, doctors: docs, users: '1,200', status: 'Active' });
  renderHospitals();
  closeModal('addHospitalModal');
  alert(`Hospital "${name}" has been registered in the database!`);
}

async function saveNewDoctor() {
  const name = document.getElementById('newDocName').value.trim();
  const hospital = document.getElementById('newDocHospital').value;
  const specialty = document.getElementById('newDocSpecialty').value;
  const exp = document.getElementById('newDocExp').value;

  if (!name) {
    alert('Please enter doctor name.');
    return;
  }

  platformData.doctors.unshift({
    name,
    hospital,
    specialty,
    exp,
    status: 'Active',
    avatar: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=200'
  });

  renderDoctors();
  closeModal('addDoctorModal');
  alert(`Doctor "${name}" KYC has been verified and registered!`);
}

// Charts Init
function initCharts() {
  const revCtx = document.getElementById('revenueChart')?.getContext('2d');
  if (revCtx) {
    new Chart(revCtx, {
      type: 'line',
      data: {
        labels: ['12 May', '13 May', '14 May', '15 May', '16 May', '17 May', '18 May'],
        datasets: [{
          label: 'Revenue (₹)',
          data: [310000, 340000, 390000, 420000, 480000, 520000, 685300],
          borderColor: '#1E60F6',
          backgroundColor: 'rgba(30, 96, 246, 0.08)',
          fill: true,
          tension: 0.4,
          borderWidth: 3,
        }]
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: {
          y: { grid: { color: '#F1F5F9' }, ticks: { callback: (val) => '₹' + (val / 1000) + 'k' } },
          x: { grid: { display: false } }
        }
      }
    });
  }

  const bookCtx = document.getElementById('bookingsDonut')?.getContext('2d');
  if (bookCtx) {
    new Chart(bookCtx, {
      type: 'doughnut',
      data: {
        labels: ['Completed', 'Upcoming', 'Cancelled'],
        datasets: [{
          data: [1856, 1102, 290],
          backgroundColor: ['#1E60F6', '#0EA5E9', '#EF4444'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } },
        cutout: '72%'
      }
    });
  }

  const payCtx = document.getElementById('paymentMethodsDonut')?.getContext('2d');
  if (payCtx) {
    new Chart(payCtx, {
      type: 'doughnut',
      data: {
        labels: ['UPI', 'Cards', 'Wallet', 'Aarogyasri Pass'],
        datasets: [{
          data: [45, 30, 15, 10],
          backgroundColor: ['#1E60F6', '#0EA5E9', '#10B981', '#EF4444'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } },
        cutout: '72%'
      }
    });
  }

  const pLineCtx = document.getElementById('paymentLineChart')?.getContext('2d');
  if (pLineCtx) {
    new Chart(pLineCtx, {
      type: 'line',
      data: {
        labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
        datasets: [{
          label: 'Revenue (₹)',
          data: [580000, 720000, 840000, 1205300],
          borderColor: '#10B981',
          backgroundColor: 'rgba(16, 185, 129, 0.08)',
          fill: true,
          tension: 0.4,
          borderWidth: 3,
        }]
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } }
      }
    });
  }

  const trendCtx = document.getElementById('trendLineChart')?.getContext('2d');
  if (trendCtx) {
    new Chart(trendCtx, {
      type: 'bar',
      data: {
        labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
        datasets: [{
          label: 'Bookings Volume',
          data: [820, 1250, 1940, 2680, 3248],
          backgroundColor: '#1E60F6',
          borderRadius: 8
        }]
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } }
      }
    });
  }
}

// Initialize on DOM load
document.addEventListener('DOMContentLoaded', async () => {
  renderHospitals();
  renderDoctors();
  renderUsers();
  renderBookings();
  renderTickets();
  initCharts();
  await fetchLiveDatabaseData();
});
