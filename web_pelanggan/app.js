import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js';
import {
  getFirestore,
  collection,
  doc,
  setDoc,
  query,
  where,
  limit,
  getDocs,
  serverTimestamp,
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js';

// GANTI dengan konfigurasi Firebase Project Anda dari Firebase Console
const firebaseConfig = {
  apiKey: 'YOUR_API_KEY',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  messagingSenderId: 'YOUR_SENDER_ID',
  appId: 'YOUR_APP_ID',
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const customersCol = collection(db, 'customers');

// Tab Switching
const tabDaftar = document.getElementById('tabDaftar');
const tabCek = document.getElementById('tabCek');
const panelDaftar = document.getElementById('panelDaftar');
const panelCek = document.getElementById('panelCek');

tabDaftar.addEventListener('click', () => {
  tabDaftar.classList.add('active');
  tabCek.classList.remove('active');
  panelDaftar.classList.remove('hidden');
  panelCek.classList.add('hidden');
});

tabCek.addEventListener('click', () => {
  tabCek.classList.add('active');
  tabDaftar.classList.remove('active');
  panelCek.classList.remove('hidden');
  panelDaftar.classList.add('hidden');
});

// Ambil Lokasi GPS Browser
document.getElementById('btnGeo').addEventListener('click', () => {
  if (!navigator.geolocation) {
    alert('Browser Anda tidak mendukung GPS.');
    return;
  }
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      document.getElementById('latitude').value = pos.coords.latitude.toFixed(6);
      document.getElementById('longitude').value = pos.coords.longitude.toFixed(6);
    },
    () => alert('Gagal mengambil lokasi GPS. Pastikan izin lokasi aktif.')
  );
});

function generateRegistrationCode() {
  const now = new Date();
  const ym = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}`;
  const rand = String(Math.floor(100 + Math.random() * 900));
  return `MMD-${ym}-${rand}`;
}

function formatTanggal(timestampOrDate) {
  if (!timestampOrDate) return '-';
  const date = typeof timestampOrDate.toDate === 'function'
    ? timestampOrDate.toDate()
    : new Date(timestampOrDate);
  return date.toLocaleDateString('id-ID', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
}

// 1. Kirim Pendaftaran Baru dari Web ke Firestore
const registerForm = document.getElementById('registerForm');
const registerResult = document.getElementById('registerResult');

registerForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  registerResult.classList.add('hidden');
  registerResult.classList.remove('error');

  const [selectedPackage, priceStr] = document.getElementById('packageSelect').value.split('|');
  const id = `cust_${Date.now()}`;
  const registrationCode = generateRegistrationCode();

  const payload = {
    id,
    registrationCode,
    fullName: document.getElementById('fullName').value.trim(),
    phoneNumber: document.getElementById('phoneNumber').value.trim(),
    address: document.getElementById('address').value.trim(),
    selectedPackage,
    packagePrice: Number(priceStr),
    latitude: Number(document.getElementById('latitude').value),
    longitude: Number(document.getElementById('longitude').value),
    createdAt: serverTimestamp(),
    status: 'menungguJadwal',
    nearestOdpCode: 'ODP-MANUAL-CHECK',
    distanceToOdpMeter: 0,
    isPackageVerified: false,
    paymentStatus: 'belumBayar',
    needsRevision: false,
  };

  try {
    await setDoc(doc(customersCol, id), payload);
    registerResult.innerHTML = `
      <strong>Pendaftaran Berhasil Dikirim!</strong><br/>
      Simpan kode registrasi Anda untuk mengecek jadwal pemasangan:<br/>
      <div style="margin-top:8px; font-size:16px; font-weight:800; color:#1E227A;">
        ${registrationCode}
      </div>
    `;
    registerResult.classList.remove('hidden');
    registerForm.reset();
  } catch (err) {
    registerResult.textContent = `Gagal mengirim pendaftaran: ${err.message}`;
    registerResult.classList.add('error');
    registerResult.classList.remove('hidden');
  }
});

// 2. Cek Jadwal Pemasangan (Hanya 2 Status: Menunggu Jadwal / Dijadwalkan, tanpa nama teknisi)
const checkForm = document.getElementById('checkForm');
const checkResult = document.getElementById('checkResult');

checkForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  checkResult.classList.add('hidden');
  checkResult.classList.remove('error');

  const code = document.getElementById('checkCode').value.trim().toUpperCase();
  const phone = document.getElementById('checkPhone').value.trim();

  try {
    const q = query(
      customersCol,
      where('registrationCode', '==', code),
      where('phoneNumber', '==', phone),
      limit(1)
    );
    const snap = await getDocs(q);

    if (snap.empty) {
      checkResult.textContent = 'Data tidak ditemukan. Periksa kembali Kode Registrasi dan Nomor HP Anda.';
      checkResult.classList.add('error');
      checkResult.classList.remove('hidden');
      return;
    }

    const data = snap.docs[0].data();
    const isScheduled = data.status && data.status !== 'menungguJadwal';

    if (!isScheduled) {
      checkResult.innerHTML = `
        <span class="badge badge-waiting">Menunggu Jadwal</span>
        <div style="margin-top:8px;">
          <strong>${data.fullName}</strong> (${data.registrationCode})<br/>
          Paket: ${data.selectedPackage}<br/>
          Status Pembayaran: <strong>${data.paymentStatus === 'sudahBayar' ? 'Lunas' : 'Belum Bayar'}</strong><br/>
          <span style="color:#64748B;">Jadwal pemasangan Anda sedang diproses oleh Admin.</span>
        </div>
      `;
    } else {
      checkResult.innerHTML = `
        <span class="badge badge-scheduled">Dijadwalkan</span>
        <div style="margin-top:8px;">
          <strong>${data.fullName}</strong> (${data.registrationCode})<br/>
          Paket: ${data.selectedPackage}<br/>
          Tanggal Pemasangan: <strong>${formatTanggal(data.scheduledDate)}</strong><br/>
          Jam Pemasangan: <strong>${data.scheduledTimeSlot || '-'}</strong>
        </div>
      `;
    }

    checkResult.classList.remove('hidden');
  } catch (err) {
    checkResult.textContent = `Gagal memeriksa jadwal: ${err.message}`;
    checkResult.classList.add('error');
    checkResult.classList.remove('hidden');
  }
});
