import { Navigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { LoadingSpinner } from '../common/LoadingSpinner';
import { ROUTES } from '../../constants';

export const ProtectedRoute = ({ children, requiredRole }) => {
  const { isAuthenticated, role, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <LoadingSpinner text="Loading..." />
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to={ROUTES.LOGIN} replace />;
  }

  if (requiredRole && role !== requiredRole) {
    // Redirect to appropriate dashboard if role doesn't match
    if (role === 'customer') {
      return <Navigate to={ROUTES.CUSTOMER_HOME} replace />;
    } else if (role === 'driver') {
      return <Navigate to={ROUTES.DRIVER_DASHBOARD} replace />;
    }
    return <Navigate to={ROUTES.LOGIN} replace />;
  }

  return children;
};
