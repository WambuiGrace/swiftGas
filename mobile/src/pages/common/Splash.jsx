import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { ROUTES, STORAGE_KEYS } from '../../constants';

export const Splash = () => {
  const navigate = useNavigate();
  const { isAuthenticated, isCustomer, isDriver, loading } = useAuth();

  useEffect(() => {
    const timer = setTimeout(() => {
      if (loading) return;

      const onboardingComplete = localStorage.getItem(STORAGE_KEYS.ONBOARDING_COMPLETE);

      if (isAuthenticated) {
        // Redirect to appropriate dashboard based on role
        if (isCustomer) {
          navigate(ROUTES.CUSTOMER_HOME);
        } else if (isDriver) {
          navigate(ROUTES.DRIVER_DASHBOARD);
        } else {
          navigate(ROUTES.LOGIN);
        }
      } else if (onboardingComplete) {
        navigate(ROUTES.LOGIN);
      } else {
        navigate(ROUTES.ONBOARDING);
      }
    }, 2000);

    return () => clearTimeout(timer);
  }, [navigate, isAuthenticated, isCustomer, isDriver, loading]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary to-secondary flex items-center justify-center px-4">
      <div className="text-center">
        {/* Logo/Icon */}
        <div className="mb-6 flex justify-center">
          <div className="w-24 h-24 bg-white rounded-full flex items-center justify-center shadow-2xl">
            <span className="text-5xl">🔥</span>
          </div>
        </div>

        {/* App Name */}
        <h1 className="text-4xl md:text-5xl font-bold text-white mb-2">
          SwiftGas
        </h1>
        <p className="text-white/90 text-lg">
          Fast & Reliable Gas Delivery
        </p>

        {/* Loading Spinner */}
        <div className="mt-12 flex justify-center">
          <svg
            className="animate-spin h-10 w-10 text-white"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
            ></circle>
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            ></path>
          </svg>
        </div>
      </div>
    </div>
  );
};
