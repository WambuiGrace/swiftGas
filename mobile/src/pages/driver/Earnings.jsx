import { Header } from '../../components/common/Header';
import { TabNav } from '../../components/common/TabNav';
import { ROUTES } from '../../constants';

export const DriverEarnings = () => {
  const tabs = [
    { path: ROUTES.DRIVER_DASHBOARD, label: 'Dashboard', icon: '📊' },
    { path: ROUTES.DRIVER_ORDERS, label: 'Orders', icon: '📦' },
    { path: ROUTES.DRIVER_EARNINGS, label: 'Earnings', icon: '💰' },
    { path: ROUTES.DRIVER_PROFILE, label: 'Profile', icon: '👤' },
  ];

  return (
    <div className="min-h-screen bg-background pb-20">
      <Header title="Earnings" />
      <div className="p-4 max-w-md mx-auto">
        <p className="text-gray-600">Earnings page - Coming soon</p>
      </div>
      <TabNav tabs={tabs} />
    </div>
  );
};
