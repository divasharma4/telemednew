-- Supabase Schema for Rural Telemedicine Portal
-- Run this in your Supabase SQL Editor

-- Enable Row Level Security
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

-- Create custom types
CREATE TYPE user_role AS ENUM ('patient', 'doctor', 'admin', 'gov_official');
CREATE TYPE queue_status AS ENUM ('waiting', 'in_progress', 'completed', 'cancelled');

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role user_role NOT NULL,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- Doctors table
CREATE TABLE public.doctors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) UNIQUE NOT NULL,
    specialization TEXT NOT NULL,
    license_number TEXT UNIQUE,
    is_available BOOLEAN DEFAULT TRUE,
    emergency_status BOOLEAN DEFAULT FALSE,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    location TEXT,
    experience_years INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Patients table
CREATE TABLE public.patients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) UNIQUE NOT NULL,
    age INTEGER,
    gender TEXT,
    village TEXT,
    medical_history TEXT,
    emergency_contact TEXT,
    blood_group TEXT,
    allergies TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Medical records table
CREATE TABLE public.records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID REFERENCES public.patients(id) NOT NULL,
    doctor_id UUID REFERENCES public.doctors(id) NOT NULL,
    symptoms TEXT NOT NULL,
    diagnosis TEXT,
    prescriptions TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    follow_up_date TIMESTAMP WITH TIME ZONE,
    is_emergency BOOLEAN DEFAULT FALSE
);

-- Pharmacy/Medicine inventory table
CREATE TABLE public.pharmacy (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    generic_name TEXT,
    category TEXT,
    stock_quantity INTEGER DEFAULT 0,
    price DECIMAL(10,2),
    expiry_date TIMESTAMP WITH TIME ZONE,
    outbreak_demand_flag BOOLEAN DEFAULT FALSE,
    minimum_stock_alert INTEGER DEFAULT 10,
    supplier TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Queue management table
CREATE TABLE public.queues (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID REFERENCES public.patients(id) NOT NULL,
    doctor_id UUID REFERENCES public.doctors(id),
    status queue_status DEFAULT 'waiting',
    priority INTEGER DEFAULT 1, -- 1=low, 2=medium, 3=high, 4=emergency
    symptoms_brief TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    estimated_wait_time INTEGER -- in minutes
);

-- Emergency alerts table
CREATE TABLE public.emergency_alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID REFERENCES public.patients(id) NOT NULL,
    doctor_id UUID REFERENCES public.doctors(id),
    alert_type TEXT, -- cardiac, trauma, respiratory, etc.
    location TEXT,
    description TEXT,
    status TEXT DEFAULT 'active', -- active, assigned, resolved
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Outbreak alerts table
CREATE TABLE public.outbreak_alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    disease_name TEXT NOT NULL,
    location TEXT NOT NULL,
    affected_count INTEGER DEFAULT 1,
    severity_level INTEGER DEFAULT 1, -- 1-5 scale
    description TEXT,
    medicines_needed JSONB, -- JSON object of medicine requirements
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_doctors_user_id ON public.doctors(user_id);
CREATE INDEX idx_doctors_available ON public.doctors(is_available);
CREATE INDEX idx_patients_user_id ON public.patients(user_id);
CREATE INDEX idx_records_patient_id ON public.records(patient_id);
CREATE INDEX idx_records_doctor_id ON public.records(doctor_id);
CREATE INDEX idx_records_created_at ON public.records(created_at);
CREATE INDEX idx_queues_patient_id ON public.queues(patient_id);
CREATE INDEX idx_queues_doctor_id ON public.queues(doctor_id);
CREATE INDEX idx_queues_status ON public.queues(status);
CREATE INDEX idx_emergency_alerts_status ON public.emergency_alerts(status);
CREATE INDEX idx_outbreak_alerts_status ON public.outbreak_alerts(status);

-- Row Level Security Policies

-- Users table policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON public.users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role IN ('admin', 'gov_official')
        )
    );

-- Doctors table policies
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Doctors can view their own profile" ON public.doctors
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Doctors can update their own profile" ON public.doctors
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "All authenticated users can view doctors" ON public.doctors
    FOR SELECT USING (auth.role() = 'authenticated');

-- Patients table policies
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients can view their own profile" ON public.patients
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Patients can update their own profile" ON public.patients
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Doctors can view patient profiles" ON public.patients
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'doctor'
        )
    );

-- Records table policies
ALTER TABLE public.records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients can view their own records" ON public.records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.patients 
            WHERE id = patient_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Doctors can view records for their patients" ON public.records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.doctors 
            WHERE id = doctor_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Doctors can create records" ON public.records
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.doctors 
            WHERE id = doctor_id AND user_id = auth.uid()
        )
    );

-- Pharmacy table policies
ALTER TABLE public.pharmacy ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated users can view pharmacy" ON public.pharmacy
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage pharmacy" ON public.pharmacy
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role IN ('admin', 'gov_official')
        )
    );

-- Queues table policies
ALTER TABLE public.queues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients can view their own queue entries" ON public.queues
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.patients 
            WHERE id = patient_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Doctors can view their assigned queues" ON public.queues
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.doctors 
            WHERE id = doctor_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Patients can create queue entries" ON public.queues
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.patients 
            WHERE id = patient_id AND user_id = auth.uid()
        )
    );

-- Emergency alerts policies
ALTER TABLE public.emergency_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated users can view emergency alerts" ON public.emergency_alerts
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Patients can create emergency alerts" ON public.emergency_alerts
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.patients 
            WHERE id = patient_id AND user_id = auth.uid()
        )
    );

-- Outbreak alerts policies
ALTER TABLE public.outbreak_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated users can view outbreak alerts" ON public.outbreak_alerts
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage outbreak alerts" ON public.outbreak_alerts
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role IN ('admin', 'gov_official')
        )
    );

-- Functions for automatic user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, name, email, role)
    VALUES (NEW.id, NEW.raw_user_meta_data->>'name', NEW.email, 'patient');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for automatic user creation
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_pharmacy_updated_at
    BEFORE UPDATE ON public.pharmacy
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_outbreak_alerts_updated_at
    BEFORE UPDATE ON public.outbreak_alerts
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
