# 🔥 MediQ — Complete Firebase Setup Guide

> **Project:** `doctor-appointment--booking`  
> **Flutter package:** `doctor_booking_system`  
> **Database:** Firebase Realtime Database  
> **Auth:** Firebase Authentication (Email/Password + Phone OTP)

---

## Step 1 — Create the Firebase Project

1. Open [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **"Add project"**
3. Enter project name: `doctor-appointment--booking`
4. Disable Google Analytics (optional for dev) → **Create project**

---

## Step 2 — Enable Required Firebase Services

### 2a. Authentication
1. In Firebase Console → **Build → Authentication**
2. Click **"Get started"**
3. Under **Sign-in method** tab, enable:
   - ✅ **Email/Password**
   - ✅ **Phone** (required for OTP in `SignupScreen`)
4. Click **Save**

### 2b. Realtime Database
1. In Firebase Console → **Build → Realtime Database**
2. Click **"Create database"**
3. Choose region: **asia-south1 (Mumbai)** for Pakistan users
4. Start in **test mode** initially (we'll deploy real rules in Step 7)
5. Your database URL will be:
   ```
   https://doctor-appointment--booking-default-rtdb.firebaseio.com
   ```

### 2c. Storage (Not currently used)
Storage is listed in `pubspec.yaml` but not used in code. You can skip this for now.

---

## Step 3 — Register Your Android App

1. In Firebase Console → Project Overview → **Add app → Android**
2. Android package name: `com.example.doctor_booking_system`
   - To verify, open: `android/app/src/main/AndroidManifest.xml` → look for `package=`
3. Download `google-services.json`
4. Place it here:
   ```
   doctor_booking_system/
   └── android/
       └── app/
           └── google-services.json   ← place here
   ```
5. **Do NOT commit this file to public Git**. Add to `.gitignore`:
   ```
   android/app/google-services.json
   ```

---

## Step 4 — Configure Web/Windows App

The web and Windows configuration is already embedded in:
```
lib/firebase_options.dart
```

Real values for **Web** and **Windows** are already filled in:
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyBSi-G6JfcsA6U8cHgJJAmdFuLLtkYXAyw',
  appId: '1:771232081967:web:11f1cc3e855eaab4a0beda',
  ...
  databaseURL: 'https://doctor-appointment--booking-default-rtdb.firebaseio.com/',
);
```
✅ No further action needed for Web/Windows.

---

## Step 5 — Configure iOS App (If Needed)

1. In Firebase Console → **Add app → iOS**
2. iOS bundle ID: `com.example.doctorBookingSystem`
3. Download `GoogleService-Info.plist`
4. Open Xcode: drag and drop `GoogleService-Info.plist` into `ios/Runner/`
5. Update `lib/firebase_options.dart` → `ios` section:
   ```dart
   static const FirebaseOptions ios = FirebaseOptions(
     apiKey: 'YOUR_REAL_IOS_API_KEY',
     appId: '1:771232081967:ios:YOUR_REAL_IOS_APP_ID',
     messagingSenderId: '771232081967',
     projectId: 'doctor-appointment--booking',
     databaseURL: 'https://doctor-appointment--booking-default-rtdb.firebaseio.com/',
     storageBucket: 'doctor-appointment--booking.firebasestorage.app',
     iosBundleId: 'com.example.doctorBookingSystem',
   );
   ```

---

## Step 6 — Install Firebase Dependencies

All required packages are already in `pubspec.yaml`:
```yaml
firebase_core: ^3.8.1
firebase_database: ^11.3.10
firebase_auth: ^5.3.4
```

To install:
```bash
flutter pub get
```

---

## Step 7 — Deploy Firebase Security Rules

The security rules file is at: `database.rules.json`

### Option A — Deploy via Firebase CLI (Recommended)
```bash
# Install Firebase CLI (once)
npm install -g firebase-tools

# Login
firebase login

# In the project root
firebase use doctor-appointment--booking

# Deploy rules
firebase database:deploy --rules database.rules.json
```

### Option B — Paste Rules Manually in Console
1. Firebase Console → Realtime Database → **Rules** tab
2. Replace the content with what's in `database.rules.json`
3. Click **Publish**

**What the rules do:**
| Path | Read | Write |
|---|---|---|
| `/users/<uid>/**` | Owner only (auth.uid === uid) | Owner only |
| `/doctors/<uid>/**` | Owner only | Owner only |
| `/catalog/doctors` | Any authenticated user | Server/admin only |

---

## Step 8 — Run the App Locally

### Android (Emulator or Physical Device)
```bash
flutter run
```

### Windows Desktop
```bash
flutter run -d windows
```

### Web
```bash
flutter run -d chrome
```

---

## Step 9 — Verify Firebase is Connected

When the app starts, the `FirebaseBootstrap.initializeIfNeeded()` in `main.dart` will:

1. ✅ Call `Firebase.initializeApp()` with the platform-specific config
2. ✅ Enable offline persistence (`setPersistenceEnabled(true)`)
3. ✅ Set `FirebaseBootstrap.enabled = true`

You can verify in **Debug Console** — you should see **no** log line containing:
```
FirebaseBootstrap: disabled
```

If you see it, Firebase failed to initialise. Check the error in the same log line.

---

## Step 10 — Seed the Doctor Catalog to Firebase

The app reads doctors from `/catalog/doctors` in Firebase. On first run with an empty database, it falls back to `MockData.doctors()`.

To seed real doctors, run this from a Dart script or Firebase Console → **Database → + (Add data)**:

```
catalog/
└── doctors/
    └── d1/
        ├── id: "d1"
        ├── name: "Dr. Sara Ali"
        ├── specialty: "General Physician"
        ├── hospital: "City Hospital Lahore"
        ├── location: "Johar Town, Lahore"
        ├── experienceYears: 8
        ├── qualifications: "MBBS, FCPS"
        ├── rating: 4.8
        ├── consultationFee: 1000
        ├── nextAvailableSlot: "Today 3:00 PM"
        ├── gender: "Female"
        ├── distanceKm: 1.2
        └── isAvailableToday: true
```

Repeat for `d2`, `d3`, `d4` (see `lib/data/mock/mock_data.dart` for all values).

---

## Step 11 — Test Read/Write Operations

### Test Authentication
1. Open the app → tap **Create Account**
2. Fill in Name, Phone, Email, Password
3. After signup, check Firebase Console → **Authentication → Users**
4. ✅ Your user should appear with a UID

### Test Database Write
1. After signing up and completing profile:
2. Firebase Console → **Realtime Database**
3. Navigate to `/users/<your-uid>/profile`
4. ✅ Should contain `encryptedData` (an opaque AES-256 blob), `nameHash`, `age`, `gender`

### Test Database Read
1. Book an appointment in the app
2. Firebase Console → `/users/<your-uid>/appointments/`
3. ✅ Should contain the new appointment entry

### Test Queue Sync
1. After booking, navigate to **Track Queue**
2. Firebase Console → `/users/<your-uid>/queueSnapshot`
3. ✅ Should show `yourToken`, `currentToken`, `patientsAhead`

---

## Step 12 — Common Errors & Fixes

| Error | Cause | Fix |
|---|---|---|
| `FirebaseBootstrap: disabled` | Firebase not initialised | Check `google-services.json` exists in `android/app/` |
| `[firebase_database/permission-denied]` | Security rules blocking access | Check user is authenticated; verify rules in console |
| `PlatformException: sign_in_failed` | Email/Password auth not enabled | Enable in Firebase Console → Auth → Sign-in method |
| `FirebaseAuthException: invalid-phone-number` | Wrong phone format | Use E.164 format: `+923001234567` |
| `FirebaseAuthException: too-many-requests` | OTP rate limit | Wait 1 hour or use a test phone number in Firebase Console |
| `MissingPluginException` | Package not installed | Run `flutter pub get` and **rebuild** (not hot reload) |
| App stuck on splash | `AppState.initialize()` throwing silently | Check debug console for errors in mock data loading |
| `[firebase_database/index-not-defined]` | Query needs an index | Add `.indexOn` rule for the queried field in database rules |

---

## Step 13 — Enable Phone Auth Test Numbers (Development)

To avoid using real SMS during development:

1. Firebase Console → **Authentication → Sign-in method → Phone**
2. Scroll to **Phone numbers for testing**
3. Add: `+923001234567` → OTP: `123456`
4. Use these in the app during testing

---

## Step 14 — Important Files Reference

| File | Purpose |
|---|---|
| `lib/main.dart` | Entry point — boots Firebase then `MediQApp` |
| `lib/firebase_options.dart` | Platform-specific Firebase config keys |
| `lib/core/firebase/firebase_bootstrap.dart` | Safe Firebase init with offline fallback |
| `lib/core/firebase/firebase_paths.dart` | All RTDB path constants |
| `lib/data/firebase/patient_cloud_sync.dart` | All Firebase read/write repositories |
| `lib/data/firebase/app_rtdb_codecs.dart` | Encode/decode RTDB ↔ Dart entities |
| `lib/data/firebase/appointment_rtdb_codec.dart` | Appointment-specific codec |
| `lib/presentation/state/app_state.dart` | Central state — orchestrates all Firebase calls |
| `lib/presentation/state/app_scope.dart` | `InheritedNotifier` — exposes state to widget tree |
| `database.rules.json` | Firebase Realtime Database security rules |

---

## Step 15 — Deployment Considerations

### Android APK
```bash
flutter build apk --release
```
Ensure `google-services.json` is present before building.

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
```

### Key Security Checklist Before Deploying
- [ ] Remove `// ignore_for_file` suppressions in firebase_options.dart
- [ ] Never commit `google-services.json` or `GoogleService-Info.plist` to public repos
- [ ] Deploy the `database.rules.json` rules (Step 7)
- [ ] Change catalog write rules from `false` to proper admin check
- [ ] Enable **App Check** in Firebase Console (prevents API abuse)
- [ ] Set billing alerts in Google Cloud Console
- [ ] Review Firebase Auth sign-in methods — disable unused ones

---

*Generated for MediQ Doctor Appointment Booking System — Firebase project: `doctor-appointment--booking`*
