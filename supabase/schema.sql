-- Drop existing tables if they exist (in correct order)
DROP TABLE IF EXISTS newsletter_contacts;
DROP TABLE IF EXISTS image_generation_history;
DROP TABLE IF EXISTS newsletter_sections;
DROP TABLE IF EXISTS compiled_newsletters;
DROP TABLE IF EXISTS newsletters;
DROP TABLE IF EXISTS industry_insights;
DROP TABLE IF EXISTS contacts;
DROP TABLE IF EXISTS csv_uploads;
DROP TABLE IF EXISTS companies;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Companies table
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name TEXT NOT NULL,
    website_url TEXT,
    contact_email TEXT UNIQUE NOT NULL,
    phone_number TEXT,
    industry TEXT NOT NULL,
    target_audience TEXT NOT NULL,
    audience_description TEXT,
    logo_url TEXT,
    status TEXT CHECK (status IN ('active', 'inactive')) NOT NULL DEFAULT 'active',
    version INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Industry Insights table
CREATE TABLE industry_insights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    industry TEXT NOT NULL,
    insights JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Contacts table
CREATE TABLE contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
    email TEXT NOT NULL,
    first_name TEXT,
    last_name TEXT,
    is_active BOOLEAN DEFAULT true,
    status TEXT DEFAULT 'active',
    csv_batch_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(company_id, email)
);

-- CSV uploads tracking table
CREATE TABLE csv_uploads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    filename TEXT NOT NULL,
    processed_count INTEGER DEFAULT 0,
    total_count INTEGER DEFAULT 0,
    status TEXT CHECK (status IN ('pending', 'processing', 'completed', 'failed')) NOT NULL DEFAULT 'pending',
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Newsletters table
CREATE TABLE newsletters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    industry_insight_id UUID REFERENCES industry_insights(id) ON DELETE SET NULL,
    status TEXT CHECK (status IN ('draft', 'published')) NOT NULL DEFAULT 'draft',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Newsletter Sections table
CREATE TABLE newsletter_sections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    newsletter_id UUID REFERENCES newsletters(id) ON DELETE CASCADE,
    section_number INTEGER NOT NULL CHECK (section_number BETWEEN 1 AND 3),
    heading TEXT NOT NULL,
    body TEXT NOT NULL,
    image_prompt TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(newsletter_id, section_number)
);

-- Image Generation History table
CREATE TABLE image_generation_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    newsletter_section_id UUID REFERENCES newsletter_sections(id) ON DELETE CASCADE,
    original_prompt TEXT NOT NULL,
    enhanced_prompt TEXT NOT NULL,
    replicate_prediction_id TEXT,
    replicate_status TEXT NOT NULL DEFAULT 'pending',
    replicate_image_url TEXT,
    model_version TEXT NOT NULL,
    generation_params JSONB NOT NULL DEFAULT '{}',
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Compiled Newsletters table
CREATE TABLE compiled_newsletters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    newsletter_id UUID REFERENCES newsletters(id) ON DELETE CASCADE UNIQUE,
    html_content TEXT NOT NULL,
    email_subject TEXT NOT NULL,
    preview_text TEXT,
    compiled_status TEXT CHECK (compiled_status IN ('pending', 'processing', 'completed', 'failed')) NOT NULL DEFAULT 'draft',
    error_message TEXT,
    sent_count INTEGER DEFAULT 0,
    last_sent_at TIMESTAMP WITH TIME ZONE,
    public_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Newsletter Contacts junction table
CREATE TABLE newsletter_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    newsletter_id UUID REFERENCES newsletters(id) ON DELETE CASCADE,
    contact_id UUID REFERENCES contacts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(newsletter_id, contact_id)
);

-- Create indexes for performance
CREATE INDEX idx_compiled_newsletters_status ON compiled_newsletters(compiled_status);
CREATE INDEX idx_image_generation_newsletter_section ON image_generation_history(newsletter_section_id);
CREATE INDEX newsletter_contacts_newsletter_id_idx ON newsletter_contacts(newsletter_id);
CREATE INDEX newsletter_contacts_contact_id_idx ON newsletter_contacts(contact_id);

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for timestamp updates
CREATE TRIGGER update_companies_updated_at
    BEFORE UPDATE ON companies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_contacts_updated_at
    BEFORE UPDATE ON contacts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_csv_uploads_updated_at
    BEFORE UPDATE ON csv_uploads
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_industry_insights_updated_at
    BEFORE UPDATE ON industry_insights
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_newsletters_updated_at
    BEFORE UPDATE ON newsletters
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_newsletter_sections_updated_at
    BEFORE UPDATE ON newsletter_sections
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_compiled_newsletters_updated_at
    BEFORE UPDATE ON compiled_newsletters
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_image_generation_history_updated_at
    BEFORE UPDATE ON image_generation_history
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_newsletter_contacts_updated_at
    BEFORE UPDATE ON newsletter_contacts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
