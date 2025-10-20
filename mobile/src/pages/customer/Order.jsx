import { Header } from '../../components/common/Header';
import { TabNav } from '../../components/common/TabNav';
import { ROUTES } from '../../constants';

export const CustomerOrder = () => {
  const tabs = [
    { path: ROUTES.CUSTOMER_HOME, label: 'Home', icon: '🏠' },
    { path: ROUTES.CUSTOMER_ORDER, label: 'Order', icon: '🛒' },
    { path: ROUTES.CUSTOMER_TRACK, label: 'Track', icon: '📍' },
    { path: ROUTES.CUSTOMER_PROFILE, label: 'Profile', icon: '👤' },
  ];

  return (
    <div className="min-h-screen bg-background pb-20">
      <Header title="Order Gas" showBack />
      <div className="p-4 max-w-md mx-auto">
        <p className="text-gray-600">Order page - Coming soon</p>
      </div>
      <TabNav tabs={tabs} />
    </div>
  );
};
