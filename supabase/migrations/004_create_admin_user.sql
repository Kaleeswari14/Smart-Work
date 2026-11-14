-- ============================================================================
-- 004_create_admin_user.sql
-- Work Management System - Seed Master Owner Account
-- Email: admin@smart.com | Password: admin@1407
-- ============================================================================

INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'admin@smart.com',
    crypt('admin@1407', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Business Owner","role":"owner"}',
    NOW(),
    NOW()
)
ON CONFLICT (email) DO UPDATE
SET encrypted_password = crypt('admin@1407', gen_salt('bf')),
    email_confirmed_at = NOW(),
    raw_user_meta_data = '{"full_name":"Business Owner","role":"owner"}';
