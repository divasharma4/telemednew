# 🚀 Quick Start Guide - Rural Telemedicine Portal

## Prerequisites
- Python 3.8+ 
- Node.js 16+
- React Native CLI
- Android Studio (for Android) or Xcode (for iOS)
- Supabase account

## 🏥 Step 1: Supabase Setup (5 minutes)

### Create Supabase Project
1. Go to [supabase.com](https://supabase.com) and create account
2. Create new project
3. Go to Settings → API → Copy your:
   - Project URL
   - Anon public key
   - Service role key (keep secret)

### Setup Database
1. Go to SQL Editor in Supabase dashboard
2. Copy and run the SQL from `DEPLOYMENT_GUIDE.md` (creates all tables)

## 🔧 Step 2: Backend Setup (2 minutes)

```bash
# Navigate to backend
cd backend

# Run automated setup
python setup.py

# This will:
# - Create virtual environment
# - Install dependencies
# - Create .env file from example
```

### Configure Environment
Edit `backend/.env` with your Supabase credentials:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_KEY=your-supabase-service-key
SECRET_KEY=your-super-secret-jwt-key-here
```

### Start Backend Server
```bash
# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Start Flask server
python main.py
```

Backend will run at: `http://localhost:8000`

## 📱 Step 3: Mobile App Setup (3 minutes)

```bash
# Navigate to mobile app
cd mobile

# Install dependencies
npm install

# For iOS (macOS only):
cd ios && pod install && cd ..
```

### Configure Environment
Edit `mobile/.env`:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
API_BASE_URL=http://localhost:8000
```

### Start Mobile App
```bash
# Start Metro bundler
npx react-native start

# In another terminal, run on device:
# Android:
npx react-native run-android

# iOS (macOS only):
npx react-native run-ios
```

## 🧪 Step 4: Test Everything Works

### Test Backend API
```bash
cd backend
python test_integration.py
```

### Test Mobile App
1. Open app on device/emulator
2. Try registering a new user
3. Login and navigate through screens
4. Test creating a consultation queue entry

## 🎯 Quick Demo Flow

### Create Test Users
1. **Register Doctor**:
   - Email: `doctor@test.com`
   - Role: `doctor`
   - Create doctor profile in Supabase dashboard

2. **Register Patient**:
   - Email: `patient@test.com` 
   - Role: `patient`
   - Create patient profile in Supabase dashboard

### Test Core Features
1. **Patient Flow**:
   - Login as patient
   - View available doctors
   - Join consultation queue
   - Check queue status

2. **Doctor Flow**:
   - Login as doctor
   - View patient queue
   - Start consultation
   - Complete consultation with notes

## 🔧 Troubleshooting

### Backend Issues
```bash
# Check if server is running
curl http://localhost:8000/health

# Check logs
python main.py  # Look for error messages
```

### Mobile App Issues
```bash
# Clear Metro cache
npx react-native start --reset-cache

# Clean Android build
cd android && ./gradlew clean && cd ..

# Rebuild
npx react-native run-android
```

### Common Fixes
- **CORS errors**: Check `CORS_ORIGINS` in backend `.env`
- **Supabase errors**: Verify URL and keys in both `.env` files
- **Metro bundler issues**: Restart with `--reset-cache`
- **Android build errors**: Clean and rebuild

## 📊 Verify Everything Works

### ✅ Backend Checklist
- [ ] Flask server starts without errors
- [ ] Health endpoint returns 200: `http://localhost:8000/health`
- [ ] Can register new user via API
- [ ] Can login and get JWT token
- [ ] Protected endpoints work with token

### ✅ Mobile App Checklist  
- [ ] App builds and runs on device/emulator
- [ ] Registration screen works
- [ ] Login screen works
- [ ] Navigation between screens works
- [ ] Can view doctors list
- [ ] Can join consultation queue

### ✅ Integration Checklist
- [ ] Mobile app can register users (calls Flask API)
- [ ] Mobile app can login (gets JWT from Flask)
- [ ] Real-time updates work (Supabase direct connection)
- [ ] Queue updates appear instantly across devices

## 🎉 You're Ready!

Once all checks pass, you have a fully functional rural telemedicine portal with:
- **Flask backend** with Supabase integration
- **React Native mobile app** with real-time features
- **Complete authentication** and role-based access
- **Queue management** for consultations
- **Emergency alerts** and pharmacy management
- **Offline support** and mobile-optimized UI

## 📚 Next Steps
- Customize UI themes and branding
- Add push notifications
- Deploy to production (see `DEPLOYMENT_GUIDE.md`)
- Add more medical features as needed
