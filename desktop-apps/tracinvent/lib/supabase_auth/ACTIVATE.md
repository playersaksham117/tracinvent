# TracInvent Auth System — Activation Guide

> All code is ready. Follow these steps **only when you decide to enable auth**.
> Nothing in `lib/supabase_auth/` is imported by the running app yet.

---

## Step 1 — Set up Supabase Project

1. Go to [supabase.com](https://supabase.com) → New Project.
2. Open **SQL Editor** → paste the full content of `supabase/schema.sql` → Run.
3. Go to **Authentication → Email** → enable "Confirm email".
4. Copy from **Settings → API**:
   - `Project URL` → `SUPABASE_URL`
   - `anon / public` key → `SUPABASE_ANON_KEY`
   - `JWT Secret` → for the Python backend's `.env`

---

## Step 2 — Deploy Python Licensing Backend

```bash
cd backend/licensing_server
cp .env.example .env
# Fill in SUPABASE_URL, SUPABASE_SERVICE_KEY, SUPABASE_JWT_SECRET, ADMIN_API_KEY
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8080
```

Deploy to Railway / Render / VPS. Copy the public URL — this becomes `LICENSING_API_URL`.

---

## Step 3 — Set Supabase RPC helper for device count decrement

Run this in SQL Editor (needed by `devices.py`):

```sql
CREATE OR REPLACE FUNCTION public.decrement_active_count(p_license_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.licenses
  SET active_device_count = GREATEST(0, active_device_count - 1)
  WHERE id = p_license_id;
END;
$$;
```

---

## Step 4 — Flutter: add dart-define to build commands

For dev:
```
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=eyJ... \
            --dart-define=LICENSING_API_URL=https://your-backend.com
```

For CI (update `.github/workflows/tracinvent-windows-release.yml`):
```yaml
- run: flutter build windows --release
    --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }}
    --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
    --dart-define=LICENSING_API_URL=${{ secrets.LICENSING_API_URL }}
    --dart-define=APP_VERSION=${{ steps.version.outputs.version }}
```

---

## Step 5 — Wire into main.dart (THE ACTIVATION STEP)

### 5a. Add `SupabaseConfig.initialize()` in `main()`:

```dart
import 'lib/supabase_auth/services/supabase_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... existing init code ...
  await SupabaseConfig.initialize();   // ← ADD THIS
  runApp(const MyApp());
}
```

### 5b. Add `SupabaseAuthProvider` to your MultiProvider:

```dart
import 'lib/supabase_auth/providers/supabase_auth_provider.dart';

MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => SupabaseAuthProvider()),
    // ... existing providers ...
  ],
  child: MaterialApp(...),
)
```

### 5c. Wrap `HomeScreen` with `AuthGate`:

```dart
import 'lib/supabase_auth/auth_gate.dart';

// In MaterialApp home:
home: AuthGate(child: const HomeScreen()),
```

---

## Step 6 — Create first admin user

After registering via the app:
1. Go to Supabase Dashboard → Table Editor → `profiles`.
2. Find your user row → set `is_admin = true`.

Or run:
```sql
UPDATE public.profiles SET is_admin = TRUE WHERE email = 'your@email.com';
```

---

## Security Checklist

- [ ] Never commit `.env` — it's in `.gitignore`
- [ ] `SUPABASE_SERVICE_KEY` is only in the Python backend, never in Flutter
- [ ] `SUPABASE_ANON_KEY` is safe to include in Flutter (restricted by RLS)
- [ ] All Supabase tables have RLS enabled (verified by `schema.sql`)
- [ ] Admin routes protected by `X-Admin-Key` header
- [ ] License keys are SHA-256 hashed before storage
- [ ] Hardware fingerprints are SHA-256 hashed, raw values never stored
- [ ] PIN is hashed with app-specific salt before storage

---

## Folder Structure

```
lib/supabase_auth/
├── models/
│   ├── user_profile.dart       # UserProfile data class
│   ├── device_info.dart        # DeviceInfo + RegisteredDevice
│   └── license.dart            # LicenseInfo + CachedValidation
├── services/
│   ├── supabase_init.dart      # SupabaseConfig.initialize()
│   ├── auth_service.dart       # register / login / PIN
│   ├── hardware_fingerprint_service.dart  # Windows hardware IDs → SHA-256
│   ├── license_service.dart    # activate / validate / grace period
│   └── offline_grace_service.dart  # SharedPreferences cache
├── providers/
│   └── supabase_auth_provider.dart  # ChangeNotifier — UI state machine
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── email_verification_screen.dart
│   ├── forgot_password_screen.dart
│   └── license_activation_screen.dart
└── auth_gate.dart              # Root widget — routes based on auth+license state

backend/licensing_server/
├── main.py                     # FastAPI app entry point
├── config.py                   # Pydantic settings from .env
├── models.py                   # Request/response Pydantic models
├── requirements.txt
├── .env.example
└── routes/
    ├── deps.py                 # JWT verification, admin check, Supabase client
    ├── licenses.py             # /activate /validate /generate /revoke
    ├── devices.py              # /mine  /reset
    └── admin.py                # /users /licenses /activations /stats /upgrade

supabase/
└── schema.sql                  # All tables + RLS + stored functions
```
