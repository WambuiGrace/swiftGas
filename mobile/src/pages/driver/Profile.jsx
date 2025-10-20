import { useAuth } from '../../hooks/useAuth';
import { useNavigate } from 'react-router-dom';
import { Header } from '../../components/common/Header';
import { TabNav } from '../../components/common/TabNav';
import { Button } from '../../components/common/Button';
import { ROUTES } from '../../constants';

export const DriverProfile = () => {
  const { userProfile, signOut } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await signOut();
    navigate(ROUTES.LOGIN);
  };

  const tabs = [
    { path: ROUTES.DRIVER_DASHBOARD, label: 'Dashboard', icon: '📊' },
    { path: ROUTES.DRIVER_ORDERS, label: 'Orders', icon: '📦' },
    { path: ROUTES.DRIVER_EARNINGS, label: 'Earnings', icon: '💰' },
    { path: ROUTES.DRIVER_PROFILE, label: 'Profile', icon: '👤' },
  ];

  return (
    <div className="min-h-screen bg-background pb-20">
      <Header title="Profile" />
      <div className="p-4 max-w-md mx-auto space-y-4">
        <div className="bg-white rounded-xl p-6 text-center">
          <div className="w-20 h-20 bg-secondary/10 rounded-full flex items-center justify-center mx-auto mb-4">
            <span className="text-4xl">🚚</span>
          </div>
          <h2 className="text-xl font-bold text-gray-900">{userProfile?.full_name || 'Driver'}</h2>
          <p className="text-gray-600">{userProfile?.email || 'driver@example.com'}</p>
        </div>

        <Button variant="danger" fullWidth onClick={handleLogout}>
          Logout
        </Button>
      </div>
      <TabNav tabs={tabs} />
    </div>
  );
};
