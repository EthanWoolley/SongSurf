-- Drop existing policies
DROP POLICY IF EXISTS users_select_own ON users;
DROP POLICY IF EXISTS users_update_own ON users;
DROP POLICY IF EXISTS recommendations_insert_own ON recommendations;
DROP POLICY IF EXISTS recommendations_select_involved ON recommendations;
DROP POLICY IF EXISTS recommendations_update_involved ON recommendations;

-- Create new policies that don't require authentication
CREATE POLICY users_select ON users
    FOR SELECT
    USING (true);

CREATE POLICY users_insert ON users
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY users_update ON users
    FOR UPDATE
    USING (true);

CREATE POLICY recommendations_select ON recommendations
    FOR SELECT
    USING (true);

CREATE POLICY recommendations_insert ON recommendations
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY recommendations_update ON recommendations
    FOR UPDATE
    USING (true); 