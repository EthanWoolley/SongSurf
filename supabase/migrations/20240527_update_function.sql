-- Update the get_random_pending_recommendation function to include album_art
CREATE OR REPLACE FUNCTION get_random_pending_recommendation(user_id UUID)
RETURNS TABLE (
    id UUID,
    sender_id UUID,
    receiver_id UUID,
    song_id TEXT,
    song_name TEXT,
    artist_name TEXT,
    album_art TEXT,
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