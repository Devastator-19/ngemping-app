# Ngemping App

Aplikasi mobile komunitas camping Indonesia — temukan komunitas, ikuti event, dan kelola keanggotaan dalam satu platform.

## Tech Stack

- **Flutter** 3.x (Dart SDK ^3.5.0)
- **Firebase** — Auth, Cloud Messaging (FCM)
- **Provider** — state management
- **Dio** — HTTP client
- **Google Fonts** — Comfortaa & Nunito

## Fitur

### Autentikasi
- Login via Google
- Login via Nomor HP (OTP)
- Multi-provider: satu akun bisa terhubung ke Google dan HP sekaligus
- Soft delete akun dengan grace period 30 hari

### Profil
- Lihat & edit informasi profil: nama, jenis kelamin, provinsi, kota/kabupaten, alamat
- Kartu anggota dengan Member ID unik (`Campers_YYYY_MM_XXXX`)
- Manajemen metode login (link / unlink Google & HP)

### Komunitas
- Daftar komunitas dengan pencarian
- Join komunitas dengan form motivasi & pengalaman
- Tab "Komunitasku" untuk melihat keanggotaan aktif & pending
- Detail komunitas: anggota, event, info lengkap

### Home
- Kartu keanggotaan (jika sudah login) atau hero banner (guest)
- Upcoming events (horizontal scroll)
- Daftar komunitas horizontal scroll dengan data live dari backend
- Navigasi langsung ke tab Komunitas

### Notifikasi
- Push notification via Firebase Cloud Messaging
- Local notification untuk pesan foreground
- Token FCM otomatis terdaftar ke backend saat login

## Struktur Proyek

```
lib/
├── core/
│   ├── constants/      # AppStrings, dll
│   ├── models/         # UserModel, CommunityModel
│   ├── services/       # ApiClient, NotificationService
│   └── theme/          # AppColors, AppTheme
└── features/
    ├── auth/           # Login, Register, Phone OTP
    ├── community/      # Community screen, detail, join sheet
    ├── home/           # Home screen, membership card
    ├── onboarding/     # Onboarding flow
    ├── profile/        # Profile screen, edit profile
    └── splash/         # Splash & routing screen
```

## Koneksi Backend

Base URL dikonfigurasi di `lib/core/services/api_client.dart`:

```dart
static const _baseUrl = 'http://localhost:3000/api/v1';
```

Ganti ke IP lokal atau URL produksi sesuai environment. Semua request otomatis menyertakan Firebase ID token sebagai Bearer token.

### Endpoint yang digunakan

| Method | Endpoint | Fungsi |
|--------|----------|--------|
| POST | `/users/sync` | Sync user setelah Firebase auth |
| GET | `/users/me` | Ambil profil & status akun |
| PATCH | `/users/me` | Update profil (nama, gender, alamat, dll) |
| PATCH | `/users/me/fcm-token` | Daftarkan FCM token |
| POST | `/users/me/deletion-request` | Minta penghapusan akun |
| DELETE | `/users/me/deletion-request` | Batalkan penghapusan akun |
| GET | `/communities` | Daftar komunitas (support `?search=`) |
| GET | `/communities/me` | Komunitas yang diikuti user |
| GET | `/communities/:id` | Detail komunitas |
| POST | `/communities/:id/join` | Join komunitas |
| DELETE | `/communities/:id/join` | Keluar dari komunitas |

## Menjalankan Proyek

```bash
flutter pub get
flutter run
```

> Pastikan `google-services.json` (Android) dan `GoogleService-Info.plist` (iOS) sudah ada di direktori masing-masing.

## Terkait

- **Backend API**: `ngemping-api` (Node.js + Prisma + PostgreSQL)
- **Web Admin**: `administrator-ngemping`
