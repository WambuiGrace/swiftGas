import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { ProtectedRoute } from './components/common/ProtectedRoute';
import { ROUTES, ROLES } from './constants';

// Common Pages
import { Splash } from './pages/common/Splash';
import { Onboarding } from './pages/common/Onboarding';
import { Login } from './pages/common/Login';
import { Signup } from './pages/common/Signup';

// Customer Pages
import { CustomerHome } from './pages/customer/Home';
import { CustomerOrder } from './pages/customer/Order';
import { CustomerTrack } from './pages/customer/Track';
import { CustomerProfile } from './pages/customer/Profile';

// Driver Pages
import { DriverDashboard } from './pages/driver/Dashboard';
import { DriverOrders } from './pages/driver/Orders';
import { DriverEarnings } from './pages/driver/Earnings';
import { DriverProfile } from './pages/driver/Profile';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          {/* Common Routes */}
          <Route path={ROUTES.SPLASH} element={<Splash />} />
          <Route path={ROUTES.ONBOARDING} element={<Onboarding />} />
          <Route path={ROUTES.LOGIN} element={<Login />} />
          <Route path={ROUTES.SIGNUP} element={<Signup />} />

          {/* Customer Routes */}
          <Route
            path={ROUTES.CUSTOMER_HOME}
            element={
              <ProtectedRoute requiredRole={ROLES.CUSTOMER}>
                <CustomerHome />
              </ProtectedRoute>
            }
          />
          <Route
            path={ROUTES.CUSTOMER_ORDER}
            element={
              <ProtectedRoute requiredRole={ROLES.CUSTOMER}>
                <CustomerOrder />
              </ProtectedRoute>
            }
          />
          <Route
            path={ROUTES.CUSTOMER_TRACK}
            element={
              <ProtectedRoute requiredRole={ROLES.CUSTOMER}>
                <CustomerTrack />
              </ProtectedRoute>
            }
          />
          <Route
            path={ROUTES.CUSTOMER_PROFILE}
            element={
              <ProtectedRoute requiredRole={ROLES.CUSTOMER}>
                <CustomerProfile />
              </ProtectedRoute>
            }
          />

          {/* Driver Routes */}
          <Route
            path={ROUTES.DRIVER_DASHBOARD}
            element={
              <ProtectedRoute requiredRole={ROLES.DRIVER}>
                <DriverDashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path={ROUTES.DRIVER_ORDERS}
            element={
              <ProtectedRoute requiredRole={ROLES.DRIVER}>
                <DriverOrders />
              </ProtectedRoute>
            }
          />
          <Route
            path={ROUTES.DRIVER_EARNINGS}
            element={
              <ProtectedRoute requiredRole={ROLES.DRIVER}>
                <DriverEarnings />
              </ProtectedRoute>
            }
          />
          <Route
            path={ROUTES.DRIVER_PROFILE}
            element={
              <ProtectedRoute requiredRole={ROLES.DRIVER}>
                <DriverProfile />
              </ProtectedRoute>
            }
          />

          {/* Default Route */}
          <Route path={ROUTES.HOME} element={<Navigate to={ROUTES.SPLASH} replace />} />
          
          {/* 404 Fallback */}
          <Route path="*" element={<Navigate to={ROUTES.SPLASH} replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;

