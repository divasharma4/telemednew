# Rural Telemedicine Portal - Deployment Guide

## Overview
This guide covers the complete deployment of the Rural Telemedicine Portal, including the Flask backend with Supabase integration and React Native mobile application.

## Prerequisites

### Backend Requirements
- Python 3.8 or higher
- Supabase account and project
- Virtual environment support

### Mobile App Requirements
- Node.js 16 or higher
- React Native CLI
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)

## Backend Deployment

### 1. Supabase Setup

#### Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Note down your project URL and anon key

#### Database Schema Setup
Run the following SQL in your Supabase SQL editor:

```sql
-- Enable Row Level Security
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- Create custom tables
CREATE TABLE users (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email VARCHAR UNIQUE NOT NULL,
    full_name VARCHAR NOT NULL,
    phone VARCHAR,
    role VARCHAR NOT NULL CHECK (role IN ('patient', 'doctor', 'admin', 'gov_official')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE doctors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    specialization VARCHAR NOT NULL,
    license_number VARCHAR UNIQUE NOT NULL,
    experience_years INTEGER DEFAULT 0,
    qualification VARCHAR,
    availability_hours VARCHAR DEFAULT '9:00-17:00',
    consultation_fee DECIMAL(10,2) DEFAULT 0.00,
    village VARCHAR,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE patients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date_of_birth DATE,
    gender VARCHAR CHECK (gender IN ('male', 'female', 'other')),
    blood_group VARCHAR,
    village VARCHAR NOT NULL,
    address TEXT,
    emergency_contact VARCHAR,
    medical_history TEXT,
    allergies TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE medicines (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR NOT NULL,
    category VARCHAR NOT NULL,
    description TEXT,
    dosage_form VARCHAR,
    strength VARCHAR,
    manufacturer VARCHAR,
    stock_quantity INTEGER DEFAULT 0,
    unit_price DECIMAL(10,2) DEFAULT 0.00,
    minimum_stock_alert INTEGER DEFAULT 10,
    expiry_date DATE,
    batch_number VARCHAR,
    outbreak_demand_flag BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
    doctor_id UUID REFERENCES doctors(id),
    symptoms TEXT NOT NULL,
    diagnosis TEXT,
    treatment TEXT,
    medications TEXT,
    notes TEXT,
    follow_up_date TIMESTAMP WITH TIME ZONE,
    record_type VARCHAR DEFAULT 'consultation',
    is_emergency BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE queues (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
    doctor_id UUID REFERENCES doctors(id),
    symptoms_brief TEXT NOT NULL,
    priority INTEGER DEFAULT 1,
    status VARCHAR DEFAULT 'waiting' CHECK (status IN ('waiting', 'in_progress', 'completed', 'cancelled')),
    consultation_type VARCHAR DEFAULT 'general',
    consultation_notes TEXT,
    consultation_started_at TIMESTAMP WITH TIME ZONE,
    consultation_completed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE emergency_alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
    alert_type VARCHAR NOT NULL,
    severity VARCHAR DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    description TEXT NOT NULL,
    location VARCHAR,
    contact_number VARCHAR,
    symptoms TEXT,
    status VARCHAR DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'cancelled')),
    created_by UUID REFERENCES users(id),
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE outbreak_alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    disease_name VARCHAR NOT NULL,
    affected_area VARCHAR NOT NULL,
    severity_level VARCHAR DEFAULT 'medium' CHECK (severity_level IN ('low', 'medium', 'high', 'critical')),
    description TEXT NOT NULL,
    prevention_measures TEXT,
    reported_cases INTEGER DEFAULT 1,
    status VARCHAR DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'monitoring')),
    created_by UUID REFERENCES users(id),
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_doctors_user_id ON doctors(user_id);
CREATE INDEX idx_patients_user_id ON patients(user_id);
CREATE INDEX idx_records_patient_id ON records(patient_id);
CREATE INDEX idx_records_doctor_id ON records(doctor_id);
CREATE INDEX idx_queues_patient_id ON queues(patient_id);
CREATE INDEX idx_queues_doctor_id ON queues(doctor_id);
CREATE INDEX idx_queues_status ON queues(status);
CREATE INDEX idx_emergency_alerts_status ON emergency_alerts(status);
CREATE INDEX idx_outbreak_alerts_status ON outbreak_alerts(status);

-- Row Level Security Policies
CREATE POLICY "Users can view their own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own data" ON users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Doctors can view their own profile" ON doctors FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Doctors can update their own profile" ON doctors FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Patients can view their own profile" ON patients FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Patients can update their own profile" ON patients FOR UPDATE USING (user_id = auth.uid());

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE medicines ENABLE ROW LEVEL SECURITY;
ALTER TABLE records ENABLE ROW LEVEL SECURITY;
ALTER TABLE queues ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE outbreak_alerts ENABLE ROW LEVEL SECURITY;
```

### 2. Backend Setup

#### Clone and Setup
```bash
cd backend
python setup.py
```

#### Environment Configuration
1. Copy `.env.example` to `.env`
2. Update the following variables:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_KEY=your-supabase-service-key
SECRET_KEY=your-super-secret-jwt-key-here
```

#### Run Development Server
```bash
# Activate virtual environment
# Windows
venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# Run Flask app
python main.py
```

#### Production Deployment
```bash
# Using Gunicorn
gunicorn -w 4 -b 0.0.0.0:8000 main:app

# Using Docker
docker build -t rural-telemedicine-backend .
docker run -p 8000:8000 --env-file .env rural-telemedicine-backend
```

## Mobile App Deployment

### 1. Setup
```bash
cd mobile
npm install
```

### 2. Environment Configuration
1. Copy `.env.example` to `.env`
2. Update configuration:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
API_BASE_URL=http://your-backend-url:8000
```

### 3. Development
```bash
# Start Metro bundler
npx react-native start

# Run on Android
npx react-native run-android

# Run on iOS (macOS only)
npx react-native run-ios
```

### 4. Production Build

#### Android
```bash
cd android
./gradlew assembleRelease
# APK will be in android/app/build/outputs/apk/release/
```

#### iOS
```bash
# Open in Xcode
open ios/RuralTelemedicinePortal.xcworkspace
# Build for release in Xcode
```

## Cloud Deployment Options

### Backend Deployment

#### Heroku
```bash
# Install Heroku CLI
heroku create rural-telemedicine-api
heroku config:set SUPABASE_URL=your-url
heroku config:set SUPABASE_ANON_KEY=your-key
git push heroku main
```

#### Railway
```bash
# Connect to Railway
railway login
railway init
railway add
railway deploy
```

#### DigitalOcean App Platform
1. Connect your repository
2. Set environment variables
3. Deploy with auto-scaling

### Mobile App Distribution

#### Android - Google Play Store
1. Generate signed APK
2. Create Play Console account
3. Upload APK and complete store listing
4. Submit for review

#### iOS - Apple App Store
1. Build with Xcode
2. Create App Store Connect account
3. Upload build via Xcode or Application Loader
4. Complete app metadata and submit for review

## Monitoring and Maintenance

### Backend Monitoring
- Use Supabase dashboard for database monitoring
- Implement logging with Python logging module
- Set up error tracking (Sentry recommended)
- Monitor API performance and response times

### Mobile App Analytics
- Implement crash reporting (Crashlytics)
- Add user analytics (Firebase Analytics)
- Monitor app performance metrics

### Security Considerations
- Enable Row Level Security in Supabase
- Use HTTPS for all API endpoints
- Implement rate limiting
- Regular security updates
- Secure API keys and environment variables

### Backup Strategy
- Supabase provides automated backups
- Export critical data regularly
- Test restore procedures
- Document recovery processes

## Troubleshooting

### Common Backend Issues
- **Supabase connection errors**: Check URL and keys
- **CORS issues**: Verify CORS_ORIGINS in .env
- **JWT errors**: Ensure SECRET_KEY is set correctly

### Common Mobile App Issues
- **Metro bundler issues**: Clear cache with `npx react-native start --reset-cache`
- **Android build errors**: Clean with `cd android && ./gradlew clean`
- **iOS build errors**: Clean build folder in Xcode

### Performance Optimization
- Enable Supabase connection pooling
- Implement API response caching
- Optimize database queries with indexes
- Use image compression for mobile uploads
- Implement offline data synchronization

## Support and Documentation
- Backend API documentation: `/docs` endpoint
- Mobile app documentation: `mobile/README.md`
- Supabase documentation: [docs.supabase.com](https://docs.supabase.com)
- React Native documentation: [reactnative.dev](https://reactnative.dev)
