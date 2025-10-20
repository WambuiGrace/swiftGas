import { createClient } from '@supabase/supabase-js';

// Supabase configuration
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Supabase environment variables are not set. Using mock mode.');
}

// Create Supabase client
export const supabase = createClient(
  supabaseUrl || 'https://mock-project.supabase.co',
  supabaseAnonKey || 'mock-anon-key',
  {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: true,
    },
  }
);

// Auth helpers
export const authService = {
  // Sign up new user
  signUp: async (email, password, userData) => {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: userData, // Store role and other metadata
      },
    });
    return { data, error };
  },

  // Sign in existing user
  signIn: async (email, password) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    return { data, error };
  },

  // Sign out
  signOut: async () => {
    const { error } = await supabase.auth.signOut();
    return { error };
  },

  // Get current session
  getSession: async () => {
    const { data, error } = await supabase.auth.getSession();
    return { data, error };
  },

  // Get current user
  getUser: async () => {
    const { data, error } = await supabase.auth.getUser();
    return { data, error };
  },

  // Update user metadata
  updateUser: async (updates) => {
    const { data, error } = await supabase.auth.updateUser(updates);
    return { data, error };
  },

  // Listen to auth state changes
  onAuthStateChange: (callback) => {
    return supabase.auth.onAuthStateChange(callback);
  },
};

// Database helpers
export const dbService = {
  // Fetch user profile
  getUserProfile: async (userId) => {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();
    return { data, error };
  },

  // Update user profile
  updateUserProfile: async (userId, updates) => {
    const { data, error } = await supabase
      .from('users')
      .update(updates)
      .eq('id', userId)
      .select()
      .single();
    return { data, error };
  },

  // Get orders for customer
  getCustomerOrders: async (userId) => {
    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .eq('customer_id', userId)
      .order('created_at', { ascending: false });
    return { data, error };
  },

  // Get available orders for driver
  getAvailableOrders: async () => {
    const { data, error } = await supabase
      .from('orders')
      .select('*, users!customer_id(*)')
      .eq('status', 'pending')
      .is('driver_id', null)
      .order('created_at', { ascending: false });
    return { data, error };
  },

  // Get active delivery for driver
  getActiveDelivery: async (driverId) => {
    const { data, error } = await supabase
      .from('orders')
      .select('*, users!customer_id(*)')
      .eq('driver_id', driverId)
      .in('status', ['accepted', 'picked_up', 'on_the_way'])
      .single();
    return { data, error };
  },

  // Create order
  createOrder: async (orderData) => {
    const { data, error } = await supabase
      .from('orders')
      .insert(orderData)
      .select()
      .single();
    return { data, error };
  },

  // Update order status
  updateOrderStatus: async (orderId, status) => {
    const { data, error } = await supabase
      .from('orders')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', orderId)
      .select()
      .single();
    return { data, error };
  },

  // Accept order (driver)
  acceptOrder: async (orderId, driverId) => {
    const { data, error } = await supabase
      .from('orders')
      .update({
        driver_id: driverId,
        status: 'accepted',
        updated_at: new Date().toISOString(),
      })
      .eq('id', orderId)
      .select()
      .single();
    return { data, error };
  },

  // Get driver earnings
  getDriverEarnings: async (driverId, period = 'week') => {
    const { data, error } = await supabase
      .from('driver_earnings')
      .select('*')
      .eq('driver_id', driverId)
      .eq('period', period)
      .order('created_at', { ascending: false });
    return { data, error };
  },

  // Get safety tips
  getSafetyTips: async () => {
    const { data, error } = await supabase
      .from('safety_tips')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(5);
    return { data, error };
  },

  // Get loyalty points
  getLoyaltyPoints: async (userId) => {
    const { data, error } = await supabase
      .from('loyalty_points')
      .select('*')
      .eq('user_id', userId)
      .single();
    return { data, error };
  },
};

export default supabase;
