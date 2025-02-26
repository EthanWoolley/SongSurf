-- Create Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    last_recommendation_time TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Create Recommendations Table
CREATE TABLE recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES users(id),
    receiver_id UUID REFERENCES users(id),
    song_id TEXT NOT NULL,
    song_name TEXT NOT NULL,
    artist_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'matched')) DEFAULT 'pending'
);

-- Create indexes for better query performance
CREATE INDEX idx_recommendations_sender ON recommendations(sender_id);
CREATE INDEX idx_recommendations_receiver ON recommendations(receiver_id);
CREATE INDEX idx_recommendations_status ON recommendations(status);
CREATE INDEX idx_recommendations_created_at ON recommendations(created_at);

-- Create Row Level Security (RLS) policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendations ENABLE ROW LEVEL SECURITY;

-- Users can only read and update their own data
CREATE POLICY users_select_own ON users
    FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY users_update_own ON users
    FOR UPDATE
    USING (auth.uid() = id);

-- Recommendations policies
CREATE POLICY recommendations_insert_own ON recommendations
    FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

CREATE POLICY recommendations_select_involved ON recommendations
    FOR SELECT
    USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY recommendations_update_involved ON recommendations
    FOR UPDATE
    USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Functions
CREATE OR REPLACE FUNCTION get_random_pending_recommendation(user_id UUID)
RETURNS TABLE (
    id UUID,
    sender_id UUID,
    receiver_id UUID,
    song_id TEXT,
    song_name TEXT,
    artist_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM recommendations
    WHERE status = 'pending'
    AND sender_id != user_id
    AND receiver_id IS NULL
    ORDER BY RANDOM()
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 