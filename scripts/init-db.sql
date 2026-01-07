-- Horse Tempo - Database initialization script
-- This script runs when PostgreSQL container is first created

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For fuzzy text search

-- Create additional indexes for performance (Prisma will create the tables)
-- These are supplementary indexes for common queries

-- Log initialization
DO $$
BEGIN
  RAISE NOTICE 'Horse Tempo database initialized successfully';
END $$;
