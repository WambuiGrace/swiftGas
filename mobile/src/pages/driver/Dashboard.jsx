import { useAuth } from '../../hooks/useAuth';
import { Header } from '../../components/common/Header';
import { TabNav } from '../../components/common/TabNav';
import { ROUTES } from '../../constants';

export const DriverDashboard = () => {
  const { userProfile } = useAuth();

  const tabs = [
    { path: ROUTES.DRIVER_DASHBOARD, label: 'Dashboard', icon: '📊' },
    { path: ROUTES.DRIVER_ORDERS, label: 'Orders', icon: '📦' },
    { path: ROUTES.DRIVER_EARNINGS, label: 'Earnings', icon: '💰' },
    { path: ROUTES.DRIVER_PROFILE, label: 'Profile', icon: '👤' },
  ];

  return (
    <div className="min-h-screen bg-background pb-20">
      <Header title="Driver Dashboard" />
      <div className="p-4 max-w-md mx-auto">
        <h2 className="text-xl font-bold">Welcome, {userProfile?.full_name || 'Driver'}!</h2>
        <p className="text-gray-600 mt-2">Dashboard coming soon</p>
      </div>
      <TabNav tabs={tabs} />
    </div>
  );
};
