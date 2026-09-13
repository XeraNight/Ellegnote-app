import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://iukblwlttvrcdclmlyxu.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1a2Jsd2x0dHZyY2RjbG1seXh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQyMTc5MjYsImV4cCI6MjA5OTc5MzkyNn0.Xq8BKQliVLT7rS2xHn8n_I84tD_rwPSz15AdHp1hcNo';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
