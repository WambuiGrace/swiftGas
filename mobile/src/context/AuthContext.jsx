import { createContext, useEffect, useState, useCallback } from 'react';
import { authService, dbService } from '../services/supabase';
import { STORAGE_KEYS, ROLES } from '../constants';

export const AuthContext = createContext({});

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [userProfile, setUserProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [role, setRole] = useState(null);

  // Load user data
  const loadUser = useCallback(async (authUser) => {
    try {
      setUser(authUser);
      
      // Extract role from user metadata
      const userRole = authUser.user_metadata?.role || null;
      setRole(userRole);
      
      if (userRole) {
        localStorage.setItem(STORAGE_KEYS.USER_ROLE, userRole);
      }

      // Fetch additional profile data from database
      const { data: profile } = await dbService.getUserProfile(authUser.id);
      if (profile) {
        setUserProfile(profile);
      }
    } catch (error) {
      console.error('Error loading user:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  // Handle sign out cleanup
  const handleSignOut = useCallback(() => {
    setUser(null);
    setUserProfile(null);
    setRole(null);
    localStorage.removeItem(STORAGE_KEYS.USER_ROLE);
    localStorage.removeItem(STORAGE_KEYS.AUTH_TOKEN);
  }, []);

  // Initialize authentication
  const initializeAuth = useCallback(async () => {
    try {
      const { data: sessionData } = await authService.getSession();
      
      if (sessionData?.session?.user) {
        await loadUser(sessionData.session.user);
      } else {
        setLoading(false);
      }
    } catch (error) {
      console.error('Error initializing auth:', error);
      setLoading(false);
    }
  }, [loadUser]);

  // Initialize auth state
  useEffect(() => {
    initializeAuth();

    // Listen to auth changes
    const { data: authListener } = authService.onAuthStateChange(
      async (event, session) => {
        if (event === 'SIGNED_IN' && session) {
          await loadUser(session.user);
        } else if (event === 'SIGNED_OUT') {
          handleSignOut();
        }
      }
    );

    return () => {
      authListener?.subscription?.unsubscribe();
    };
  }, [initializeAuth, loadUser, handleSignOut]);

  // Sign up
  const signUp = async (email, password, userData) => {
    setLoading(true);
    try {
      // Enforce business rule: drivers cannot create accounts
      const desiredRole = userData?.role;
      if (desiredRole === ROLES.DRIVER || desiredRole === 'driver') {
        const error = new Error('Drivers cannot create accounts. Please sign in.');
        error.code = 'DRIVER_SIGNUP_FORBIDDEN';
        throw error;
      }

      const { data, error } = await authService.signUp(email, password, userData);
      
      if (error) throw error;
      
      return { data, error: null };
    } catch (error) {
      console.error('Sign up error:', error);
      return { data: null, error };
    } finally {
      setLoading(false);
    }
  };

  // Sign in
  const signIn = async (email, password) => {
    setLoading(true);
    try {
      const { data, error } = await authService.signIn(email, password);
      
      if (error) throw error;
      
      if (data?.user) {
        await loadUser(data.user);
      }
      
      return { data, error: null };
    } catch (error) {
      console.error('Sign in error:', error);
      return { data: null, error };
    } finally {
      setLoading(false);
    }
  };

  // Sign out
  const signOut = async () => {
    try {
      const { error } = await authService.signOut();
      if (error) throw error;
      
      handleSignOut();
      return { error: null };
    } catch (error) {
      console.error('Sign out error:', error);
      return { error };
    }
  };

  // Update profile
  const updateProfile = async (updates) => {
    try {
      if (!user) return { error: new Error('No user logged in') };

      const { data, error } = await dbService.updateUserProfile(user.id, updates);
      
      if (error) throw error;
      
      if (data) {
        setUserProfile(data);
      }
      
      return { data, error: null };
    } catch (error) {
      console.error('Update profile error:', error);
      return { data: null, error };
    }
  };

  const value = {
    user,
    userProfile,
    role,
    loading,
    signUp,
    signIn,
    signOut,
    updateProfile,
    isAuthenticated: !!user,
    isCustomer: role === 'customer',
    isDriver: role === 'driver',
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
