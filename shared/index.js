import { createClient } from '@supabase/supabase-js';

function createSupabaseClient(url, key, options = {}) {
  return createClient(url, key, {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: true,
    },
    ...options,
  });
}

function createAuthService(supabase) {
  return {
    signUp: async (email, password, userData) => {
      return supabase.auth.signUp({
        email,
        password,
        options: {
          data: userData,
        },
      });
    },
    signIn: async (email, password) => {
      return supabase.auth.signInWithPassword({ email, password });
    },
    signOut: async () => {
      return supabase.auth.signOut();
    },
    getSession: async () => {
      return supabase.auth.getSession();
    },
    getUser: async () => {
      return supabase.auth.getUser();
    },
    updateUser: async (updates) => {
      return supabase.auth.updateUser(updates);
    },
    onAuthStateChange: (callback) => {
      return supabase.auth.onAuthStateChange(callback);
    },
  };
}

function createDbService(supabase) {
  return {
    getUserProfile: async (userId) => {
      return supabase.from('users').select('*').eq('id', userId).single();
    },
    updateUserProfile: async (userId, updates) => {
      return supabase.from('users').update(updates).eq('id', userId).select().single();
    },
    getCustomerOrders: async (userId) => {
      return supabase.from('orders').select('*').eq('customer_id', userId).order('created_at', { ascending: false });
    },
    getAvailableOrders: async () => {
      return supabase
        .from('orders')
        .select('*, users!customer_id(*)')
        .eq('status', 'pending')
        .is('driver_id', null)
        .order('created_at', { ascending: false });
    },
    getActiveDelivery: async (driverId) => {
      return supabase
        .from('orders')
        .select('*, users!customer_id(*)')
        .eq('driver_id', driverId)
        .in('status', ['accepted', 'picked_up', 'on_the_way'])
        .single();
    },
    createOrder: async (orderData) => {
      return supabase.from('orders').insert(orderData).select().single();
    },
    updateOrderStatus: async (orderId, status) => {
      return supabase
        .from('orders')
        .update({ status, updated_at: new Date().toISOString() })
        .eq('id', orderId)
        .select()
        .single();
    },
    acceptOrder: async (orderId, driverId) => {
      return supabase
        .from('orders')
        .update({
          driver_id: driverId,
          status: 'accepted',
          updated_at: new Date().toISOString(),
        })
        .eq('id', orderId)
        .select()
        .single();
    },
    getDriverEarnings: async (driverId, period = 'week') => {
      return supabase
        .from('driver_earnings')
        .select('*')
        .eq('driver_id', driverId)
        .eq('period', period)
        .order('created_at', { ascending: false });
    },
    getSafetyTips: async () => {
      return supabase.from('safety_tips').select('*').order('created_at', { ascending: false }).limit(5);
    },
    getLoyaltyPoints: async (userId) => {
      return supabase.from('loyalty_points').select('*').eq('user_id', userId).single();
    },
  };
}

export { createSupabaseClient, createAuthService, createDbService };
export default { createSupabaseClient, createAuthService, createDbService };