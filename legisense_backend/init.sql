-- Database initialization script for Legisense
-- This script sets up the initial database structure and sample data

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create custom types
DO $$ BEGIN
    CREATE TYPE document_status AS ENUM ('uploaded', 'processing', 'analyzed', 'failed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE analysis_type AS ENUM ('basic', 'standard', 'detailed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON api_parseddocument(created_at);
CREATE INDEX IF NOT EXISTS idx_documents_status ON api_parseddocument(status);
CREATE INDEX IF NOT EXISTS idx_analysis_document_id ON api_documentanalysis(document_id);

-- Insert sample data for development
INSERT INTO api_parseddocument (id, title, content, status, created_at, updated_at) VALUES
    (uuid_generate_v4(), 'Sample Rental Agreement', 'This is a sample rental agreement for demonstration purposes...', 'analyzed', NOW(), NOW()),
    (uuid_generate_v4(), 'Sample Loan Document', 'This is a sample loan document for demonstration purposes...', 'analyzed', NOW(), NOW()),
    (uuid_generate_v4(), 'Sample Insurance Policy', 'This is a sample insurance policy for demonstration purposes...', 'processing', NOW(), NOW())
ON CONFLICT DO NOTHING;

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_parseddocument_updated_at BEFORE UPDATE ON api_parseddocument FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_documentanalysis_updated_at BEFORE UPDATE ON api_documentanalysis FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
