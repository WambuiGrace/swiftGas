import { createSupabaseClient, createAuthService, createDbService } from 'shared';

// Supabase configuration (from Vite env)
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Supabase environment variables are not set. Using mock mode.');
}

// Create Supabase client using shared module
export const supabase = createSupabaseClient(
  supabaseUrl || 'https://mock-project.supabase.co',
  supabaseAnonKey || 'mock-anon-key'
);

// Shared-auth and DB services
export const authService = createAuthService(supabase);
export const dbService = createDbService(supabase);

export default supabase;
