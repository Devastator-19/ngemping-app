# Dokumentasi Progress - Ngemping App
**Aplikasi Super Komunitas Camping Indonesia**

---

## 📋 Informasi Proyek

| | Flutter (App) | Backend (API) |
|---|---|---|
| **Lokasi** | `/Documents/Projects/ngemping-app` | `/Documents/Projects/ngemping-api` |
| **Stack** | Flutter + Provider + Firebase Auth | Node.js + Express + PostgreSQL (Prisma) |
| **Versi** | 1.0.0+1 | — |
| **SDK/Runtime** | Flutter ^3.5.0 | Node.js (ESM `"type":"module"`) |

---

## 🎯 Status Proyek: **Dalam Pengembangan Aktif**

---

## 🗄️ Backend (ngemping-api)

### Stack
- **Express.js** — HTTP server
- **Prisma ORM** — Database access layer
- **PostgreSQL** — Database (`ngemping_db`)
- **Firebase Admin SDK** — Verifikasi JWT dari Flutter

### Database Schema (Prisma)

#### Tabel
| Model | Keterangan |
|---|---|
| `users` | Profil user, memberId, status, role, deletionRequestedAt |
| `communities` | Komunitas camping (publik/privat) |
| `community_members` | Membership user ke komunitas (role + status) |
| `events` | Event/trip, opsional terkait ke komunitas via `communityId` |
| `event_registrations` | Pendaftaran user ke event |

#### Migrations yang sudah dijalankan
| Migrasi | Perubahan |
|---|---|
| `init` | Schema awal (users, events, event_registrations) |
| `add_communities` | Tambah model Community + CommunityMember |
| `add_deletion_request` | Tambah `deletionRequestedAt DateTime?` ke User |
| `add_community_events` | Tambah `communityId String?` ke Event, relasi Community → events[] |

### API Endpoints (prefix: `/api/v1`)

#### Users
| Method | Endpoint | Auth | Keterangan |
|---|---|---|---|
| POST | `/users/sync` | Required | Upsert profil setelap login Flutter |
| GET | `/users/me` | Required | Profil + deletionRequestedAt |
| PATCH | `/users/me` | Required | Update displayName / photoUrl |
| GET | `/users/me/membership` | Required | Data kartu anggota |
| POST | `/users/me/deletion-request` | Required | Minta hapus akun (30 hari grace period) |
| DELETE | `/users/me/deletion-request` | Required | Batalkan permintaan hapus akun |

#### Communities
| Method | Endpoint | Auth | Keterangan |
|---|---|---|---|
| GET | `/communities` | Optional | List komunitas publik (search + pagination) |
| GET | `/communities/me` | Required | Komunitas yang diikuti user |
| GET | `/communities/:id` | Optional | Detail komunitas + status membership |
| POST | `/communities` | Admin | Buat komunitas baru |
| PATCH | `/communities/:id` | Admin | Update komunitas |
| POST | `/communities/:id/join` | Required | Gabung komunitas |
| DELETE | `/communities/:id/join` | Required | Keluar komunitas |
| GET | `/communities/:id/members` | Optional | List anggota (pagination + filter role) |
| GET | `/communities/:id/events` | Optional | List event komunitas |

#### Events (planned)
| Method | Endpoint | Auth | Keterangan |
|---|---|---|---|
| GET | `/events` | Optional | List event publik |
| GET | `/events/:id` | Optional | Detail event |
| POST | `/events` | Admin | Buat event |
| PATCH | `/events/:id` | Admin | Update event |
| DELETE | `/events/:id` | Admin | Soft-delete (→ CANCELLED) |
| POST | `/events/:id/register` | Required | Daftar event |
| DELETE | `/events/:id/register` | Required | Batalkan pendaftaran |

### Format memberId
```
Campers_{Year}_{Month}_{4DigitIncrement}
Contoh: Campers_2026_03_0001
```
- Increment berdasarkan jumlah user yang terdaftar di bulan yang sama
- Di-generate server-side saat user baru pertama kali sync

### Fitur Khusus Backend
- **optionalAuth middleware** — inject `req.user` jika ada token, null jika tidak
- **requireAdmin** — query DB user, cek `role === 'ADMIN'`
- **membershipStatus injection** — `/communities` list inject status membership per komunitas ke setiap item
- **Soft delete akun** — `deletionRequestedAt`, hard delete otomatis setelah 30 hari saat `syncUser` dipanggil (hapus DB + Firebase Auth)

---

## 📱 Flutter (ngemping-app)

### ✅ 1. Splash Screen
- File: `lib/features/splash/splash_screen.dart`

### ✅ 2. Onboarding
- Files:
  - `lib/features/onboarding/onboarding_screen.dart`
  - `lib/features/onboarding/models/onboarding_item.dart`
  - `lib/features/onboarding/providers/onboarding_provider.dart`

### ✅ 3. Autentikasi
- Firebase Auth: Google Sign-In + Phone OTP
- Account linking (Google ↔ Phone pada satu akun)
- Auto-sync ke backend setiap login (`POST /users/sync`)
- Files:
  - `lib/features/auth/login_screen.dart`
  - `lib/features/auth/phone_auth_screen.dart`
  - `lib/features/auth/providers/auth_provider.dart`
- `AppAuthProvider` juga menyimpan `deletionRequestedAt` dari backend

### ✅ 4. Home Screen
- Membership card generik (nama platform "ngemping", bukan nama komunitas)
- Files:
  - `lib/features/home/home_screen.dart`
  - `lib/features/home/widgets/membership_card.dart`

### ✅ 5. Komunitas
#### community_screen.dart
- Tab "Semua Komunitas" + "Komunitas Saya" (dengan badge counter)
- Search bar dengan debounce 400ms
- Tap kartu → navigate ke `CommunityDetailScreen`
- Join / Leave langsung dari list

#### community_detail_screen.dart *(baru)*
- 4 tab: **Tentang** | **Organisasi** | **Event** | **Anggota**
- **Tentang** — deskripsi, info tile (anggota, lokasi, publik/privat)
- **Organisasi** — stat card (total anggota, pengurus) + list Ketua (OWNER) + Pengurus (ADMIN) dengan role badge
- **Event** — list event komunitas (accent color strip, status badge, harga, peserta, load-more)
- **Anggota** — semua member aktif (avatar, memberId, role badge, load-more)
- SliverAppBar dengan parallax banner, tombol join/leave/pending di header

#### Providers
- `CommunityProvider` — list komunitas, search, join/leave
- `CommunityDetailProvider` *(baru)* — detail, members, events, pagination, join/leave

#### Files
- `lib/features/community/community_screen.dart`
- `lib/features/community/community_detail_screen.dart`
- `lib/features/community/providers/community_provider.dart`
- `lib/features/community/providers/community_detail_provider.dart`

### ✅ 6. Profile
- Info akun (email, phone, memberId, bergabung)
- Metode login terhubung (Google + Phone, bisa link/unlink)
- **Hapus Akun** (soft delete 30 hari):
  - Belum request → tombol "Minta Penghapusan Akun" + dialog konfirmasi
  - Sudah request → banner merah dengan countdown + tombol "Batalkan Penghapusan"
- File: `lib/features/profile/profile_screen.dart`

### ✅ 7. Core

#### Models
| File | Isi |
|---|---|
| `lib/core/models/user_model.dart` | UserModel dari Firebase user |
| `lib/core/models/community_model.dart` | CommunityModel, CommunityMemberModel, CommunityEventModel, MyCommunityModel |

#### Services
| File | Isi |
|---|---|
| `lib/core/services/api_client.dart` | Dio client, auto-inject Firebase JWT token di setiap request |

#### Theme
- Forest Green + Earthy Amber
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_theme.dart`

---

## 📦 Dependencies

### Flutter
| Package | Versi | Kegunaan |
|---|---|---|
| `provider` | ^6.1.2 | State management |
| `google_fonts` | ^6.2.1 | Font Comfortaa + Nunito |
| `dio` | ^5.7.0 | HTTP client |
| `firebase_core` | ^3.6.0 | Firebase init |
| `firebase_auth` | ^5.3.1 | Auth |
| `google_sign_in` | ^6.2.1 | Google Sign-In |
| `smooth_page_indicator` | ^1.1.0 | Onboarding indicator |
| `shared_preferences` | ^2.3.2 | Local storage |

### Backend
```json
{
  "express": "^4.21.2",
  "cors": "^2.8.5",
  "dotenv": "^16.4.7",
  "helmet": "^8.0.0",
  "firebase-admin": "^13.0.2",
  "@prisma/client": "^6.3.1",
  "prisma": "^6.3.1" (dev)
}
```

---

## 🏗️ Arsitektur

```
ngemping-app/                     ngemping-api/
├── lib/                          ├── prisma/
│   ├── core/                     │   ├── schema.prisma
│   │   ├── models/               │   └── migrations/
│   │   ├── services/             ├── src/
│   │   └── theme/                │   ├── config/firebase.js
│   ├── features/                 │   ├── middleware/
│   │   ├── auth/                 │   │   ├── auth.js
│   │   ├── community/            │   │   └── errorHandler.js
│   │   ├── home/                 │   ├── routes/
│   │   ├── onboarding/           │   ├── controllers/
│   │   ├── profile/              │   ├── services/
│   │   └── splash/               │   └── utils/response.js
│   └── main.dart                 └── server.js
```

---

## 📊 Progress Overview

**Estimasi Progress:** ~75% ✅

| Kategori | Status | Progress |
|---|---|---|
| UI/UX (Flutter) | ✅ Done | 100% |
| Authentication (Firebase) | ✅ Done | 100% |
| Backend — Users | ✅ Done | 100% |
| Backend — Communities | ✅ Done | 100% |
| Backend — Events (CRUD) | ⏳ Pending | 0% |
| Flutter — Community Detail | ✅ Done | 100% |
| Flutter — Events | ⏳ Pending | 0% |
| Chat / Komentar | ⏳ Pending | 0% |
| Testing | ⏳ Pending | 0% |
| Deployment | ⏳ Pending | 0% |

---

## 📝 TODO Selanjutnya

### Backend
- [ ] Events CRUD endpoint lengkap
- [ ] POST/DELETE `/events/:id/register` (daftar event)
- [ ] Notifikasi (FCM via Firebase Admin)
- [ ] Chat room (WebSocket / polling)

### Flutter
- [ ] Event list & detail screen
- [ ] Daftar event dari dalam komunitas detail
- [ ] Notifikasi push
- [ ] Map integration untuk lokasi camping

### DevOps
- [ ] Setup CI/CD
- [ ] Deploy backend (Railway / Render / VPS)
- [ ] App Store & Play Store

---

## 📅 Update Terakhir
**Tanggal:** 8 Maret 2026
**Sesi ini:** Auth sync backend, Communities full-stack (list, search, join/leave, detail 4-tab), Account deletion 30-day soft delete, memberId format `Campers_YYYY_MM_XXXX`
