# CLIProxyAPI Dashboard (sirwhy fork) — Railway Deployment

Deploy dashboard dari repo **https://github.com/sirwhy/cliproxyapi-dashboard** ke Railway.

Dashboard Next.js + PostgreSQL lengkap untuk CLIProxyAPI.  
Fitur: multi-user, custom providers, OAuth (Claude/Gemini/Kiro/Copilot), usage stats, backup, sync.

---

## 🚀 Cara Deploy ke Railway

### Step 1 — Buat PostgreSQL di Railway

1. Railway → project kamu → **New Service → Database → PostgreSQL**
2. Setelah dibuat klik PostgreSQL → tab **Variables** → copy `DATABASE_URL`

### Step 2 — Push repo ini ke GitHub

```bash
git remote add origin https://github.com/USERNAME/sirwhy-dashboard-railway.git
git push -u origin main
```

### Step 3 — Buat Service Dashboard

1. Railway → **New Service → GitHub Repo** → pilih repo ini
2. Railway otomatis detect Dockerfile dan mulai build
3. Build time: ~3-5 menit (clone + Next.js build)

### Step 4 — Set Variables di Railway

Service Dashboard → **Variables**:

| Variable | Isi | Keterangan |
|----------|-----|------------|
| `DATABASE_URL` | Dari PostgreSQL service | **WAJIB** |
| `JWT_SECRET` | String random 32+ karakter | **WAJIB** — enkripsi session |
| `MANAGEMENT_API_KEY` | String random bebas | **WAJIB** — komunikasi ke CLIProxyAPI |
| `CLIPROXYAPI_MANAGEMENT_URL` | `https://<cli-proxy-url>/v0/management` | **WAJIB** — URL CLIProxyAPI kamu |
| `LOG_LEVEL` | `info` | Opsional |
| `TZ` | `Asia/Jakarta` | Opsional — timezone |
| `ALLOW_LOCAL_PROVIDER_URLS` | `false` | Opsional |

> **`PORT`** tidak perlu diisi — Railway set otomatis.

### Step 5 — Set `MANAGEMENT_API_KEY` di CLIProxyAPI juga

Di service CLIProxyAPI Railway → Variables:
```
MANAGEMENT_API_KEY = nilai yang SAMA dengan di dashboard
```

### Step 6 — Akses Dashboard

```
https://<dashboard-railway-url>/
```

User pertama yang register otomatis jadi **admin**.

---

## ⚙️ Build & Start Commands

### Backend (Next.js Dashboard)

| | Command |
|--|---------|
| **Build Command** | `npm run build` (via Dockerfile) |
| **Start Command** | `./entrypoint.sh` (migrate DB + start server) |

> Tidak perlu isi manual di Railway — Dockerfile handle semuanya.

### Dev Lokal

```bash
git clone https://github.com/sirwhy/cliproxyapi-dashboard.git
cd cliproxyapi-dashboard
cp .env.example .env
# Edit .env — isi DATABASE_URL, JWT_SECRET, MANAGEMENT_API_KEY, CLIPROXYAPI_MANAGEMENT_URL
npm install
npm run dev
# Buka http://localhost:3000
```

---

## 🗄️ Database

Butuh **PostgreSQL**. Di Railway: **New Service → Database → PostgreSQL** (gratis di hobby plan).  
Schema dibuat otomatis saat container pertama kali start via `entrypoint.sh`.

---

## 🔗 Hubungkan ke CLIProxyAPI

```
Dashboard Variables:
  CLIPROXYAPI_MANAGEMENT_URL = https://<cli-proxy-url>/v0/management
  MANAGEMENT_API_KEY = secret-key-sama

CLIProxyAPI Variables:
  MANAGEMENT_API_KEY = secret-key-sama
```

---

## 🤖 Fitur

- Multi-user (Admin/User roles)
- AI Providers — Gemini, Claude, OpenAI, Custom (Cline, Fireworks, dll)
- OAuth — Claude Code, Gemini CLI, Codex, Kiro, GitHub Copilot, Cursor
- Usage Statistics & Quota Tracking
- Backup & Restore
- Cloud Sync via OpenCode plugin
- Custom Providers (endpoint OpenAI-compatible apapun)
