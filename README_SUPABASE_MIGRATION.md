# Rural Telemedicine Portal - Supabase Migration Guide

## Overview
This guide covers the complete migration from PostgreSQL/SQLAlchemy to Supabase for the Rural Telemedicine Portal.

## What's Been Completed

### 1. Backend Migration ✅
- **Supabase Client Setup**: Created `supabase_client.py` with connection configuration
- **Database Wrapper**: Implemented `SupabaseDB` class in `database.py` for CRUD operations
- **Pydantic Models**: Created `supabase_models.py` with all data models
- **Authentication**: Updated `routes/auth.py` to use Supabase Auth
- **Doctors Routes**: Partially updated `routes/doctors.py` to use Supabase

### 2. Database Schema ✅
- **SQL Schema**: Created `supabase_schema.sql` with complete database structure
- **Tables**: Users, Doctors, Patients, Records, Pharmacy, Queues, Emergency Alerts, Outbreak Alerts
- **Row Level Security**: Implemented RLS policies for data protection
- **Indexes**: Added performance indexes
- **Triggers**: Auto-update timestamps and user creation

### 3. Seed Data ✅
- **Seed Script**: Created `supabase_seed.py` to populate database with sample data
- **Sample Users**: Admin, doctors, patients with realistic data
- **Medical Records**: Sample consultations and treatments
- **Pharmacy**: Medicine inventory with stock levels
- **Alerts**: Emergency and outbreak scenarios

### 4. Frontend Updates ✅
- **Supabase Client**: Added `@supabase/supabase-js` dependency
- **Auth Context**: Created React context for Supabase authentication
- **Login Component**: Updated authentication flow
- **Utility Functions**: Database helper functions in `utils/supabase.js`

## Setup Instructions

### 1. Supabase Project Setup
1. Create a new Supabase project at https://supabase.com
2. Copy your project URL and anon key
3. Run the SQL schema in Supabase SQL Editor:
   ```sql
   -- Copy and paste contents of supabase_schema.sql
   ```

### 2. Environment Configuration
**Backend (.env):**
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
SECRET_KEY=your_secret_key_here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
ENVIRONMENT=development
```

**Frontend (.env):**
```env
REACT_APP_SUPABASE_URL=your_supabase_project_url
REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key
REACT_APP_API_URL=http://localhost:8000
```

### 3. Install Dependencies
**Backend:**
```bash
cd backend
pip install -r requirements.txt
```

**Frontend:**
```bash
cd frontend
npm install
```

### 4. Seed Database
```bash
cd backend
python supabase_seed.py
```

### 5. Run Application
**Backend:**
```bash
cd backend
uvicorn main:app --reload
```

**Frontend:**
```bash
cd frontend
npm start
```

## Key Changes Made

### Authentication Flow
- **Before**: Custom JWT with SQLAlchemy user management
- **After**: Supabase Auth with automatic user creation via triggers

### Database Operations
- **Before**: SQLAlchemy ORM queries
- **After**: Supabase client with direct table operations

### Real-time Features
- **New**: Real-time subscriptions for queues, emergency alerts, and outbreak notifications
- **Benefit**: Instant updates across all connected clients

### Security
- **Enhanced**: Row Level Security policies ensure users only access their own data
- **Automatic**: Supabase handles authentication tokens and session management

## Remaining Tasks

### Backend Routes to Update:
- [ ] `routes/patients.py` - Patient management
- [ ] `routes/pharmacy.py` - Medicine inventory
- [ ] `routes/records.py` - Medical records
- [ ] `routes/queues.py` - Queue management
- [ ] `routes/emergency.py` - Emergency alerts
- [ ] `routes/ai.py` - AI features

### Testing Required:
- [ ] Authentication flow
- [ ] CRUD operations for all entities
- [ ] Real-time subscriptions
- [ ] Row Level Security policies
- [ ] Mobile app compatibility

## Benefits of Supabase Migration

1. **Scalability**: Automatic scaling and performance optimization
2. **Real-time**: Built-in real-time subscriptions
3. **Security**: Row Level Security and built-in authentication
4. **Reduced Complexity**: No need to manage database infrastructure
5. **Mobile Ready**: Perfect for React Native mobile app development
6. **Offline Support**: Built-in offline capabilities
7. **Edge Functions**: Serverless functions for complex operations

## Mobile App Considerations

Since this is being developed as a mobile app, the Supabase migration provides:
- **Offline-first**: Automatic data synchronization
- **Push Notifications**: Integration with mobile push services
- **File Storage**: Easy image/document upload for medical records
- **Geolocation**: Built-in location services for emergency features
- **Camera Integration**: Direct image capture for medical documentation

## Next Steps for Mobile Development

1. **React Native Setup**: Initialize React Native project
2. **Supabase Mobile SDK**: Install React Native Supabase client
3. **Navigation**: Implement React Navigation
4. **UI Components**: Create mobile-optimized components
5. **Camera Features**: Add medical photo capture
6. **Location Services**: Emergency location tracking
7. **Push Notifications**: Real-time alert system
8. **Offline Sync**: Implement offline-first data management

## Support

For issues with the Supabase migration:
1. Check Supabase dashboard for errors
2. Verify environment variables
3. Ensure RLS policies are correctly configured
4. Test authentication flow first
5. Check network connectivity for real-time features
