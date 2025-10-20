// App constants
export const APP_NAME = 'SwiftGas';

// API Configuration
export const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api';

// User Roles
export const ROLES = {
  CUSTOMER: 'customer',
  DRIVER: 'driver',
};

// Order Status
export const ORDER_STATUS = {
  PENDING: 'pending',
  ACCEPTED: 'accepted',
  PICKED_UP: 'picked_up',
  ON_THE_WAY: 'on_the_way',
  DELIVERED: 'delivered',
  CANCELLED: 'cancelled',
};

// Cylinder Sizes (in kg)
export const CYLINDER_SIZES = [
  { id: 1, size: 6, label: '6 kg', price: 1500 },
  { id: 2, size: 13, label: '13 kg', price: 2800 },
  { id: 3, size: 25, label: '25 kg', price: 5000 },
  { id: 4, size: 50, label: '50 kg', price: 9500 },
];

// Routes
export const ROUTES = {
  // Common routes
  HOME: '/',
  SPLASH: '/splash',
  ONBOARDING: '/onboarding',
  LOGIN: '/login',
  SIGNUP: '/signup',
  
  // Customer routes
  CUSTOMER_HOME: '/customer/home',
  CUSTOMER_ORDER: '/customer/order',
  CUSTOMER_TRACK: '/customer/track',
  CUSTOMER_PROFILE: '/customer/profile',
  
  // Driver routes
  DRIVER_DASHBOARD: '/driver/dashboard',
  DRIVER_ORDERS: '/driver/orders',
  DRIVER_ACTIVE: '/driver/active',
  DRIVER_EARNINGS: '/driver/earnings',
  DRIVER_PROFILE: '/driver/profile',
};

// Mapbox Configuration
export const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_TOKEN || '';
export const DEFAULT_CENTER = [36.8219, -1.2921]; // Nairobi, Kenya
export const DEFAULT_ZOOM = 12;

// Local Storage Keys
export const STORAGE_KEYS = {
  AUTH_TOKEN: 'swiftgas_auth_token',
  USER_ROLE: 'swiftgas_user_role',
  ONBOARDING_COMPLETE: 'swiftgas_onboarding_complete',
};
