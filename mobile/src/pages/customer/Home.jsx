import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { Header } from '../../components/common/Header';
import { TabNav } from '../../components/common/TabNav';
import { Card } from '../../components/common/Card';
import { Button } from '../../components/common/Button';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { ROUTES } from '../../constants';
import { getGreeting, formatDateTime, formatCurrency } from '../../utils/helpers';
import { dbService } from '../../services/supabase';

export const CustomerHome = () => {
  const { userProfile } = useAuth();
  const navigate = useNavigate();
  const [orders, setOrders] = useState([]);
  const [safetyTip, setSafetyTip] = useState(null);
  const [loading, setLoading] = useState(true);

  const loadData = useCallback(async () => {
    try {
      // Fetch recent orders
      const { data: ordersData } = await dbService.getCustomerOrders(userProfile?.id);
      if (ordersData) {
        setOrders(ordersData.slice(0, 3)); // Show only recent 3 orders
      }

      // Fetch safety tip
      const { data: tipsData } = await dbService.getSafetyTips();
      if (tipsData && tipsData.length > 0) {
        setSafetyTip(tipsData[0]);
      }
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  }, [userProfile?.id]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const tabs = [
    { path: ROUTES.CUSTOMER_HOME, label: 'Home', icon: '🏠' },
    { path: ROUTES.CUSTOMER_ORDER, label: 'Order', icon: '🛒' },
    { path: ROUTES.CUSTOMER_TRACK, label: 'Track', icon: '📍' },
    { path: ROUTES.CUSTOMER_PROFILE, label: 'Profile', icon: '👤' },
  ];

  if (loading) {
    return <LoadingSpinner />;
  }

  return (
    <div className="min-h-screen bg-background pb-20">
      <Header title="SwiftGas" />

      <div className="p-4 max-w-md mx-auto space-y-6">
        {/* Greeting */}
        <div>
          <h2 className="text-2xl font-bold text-gray-900">
            {getGreeting()}, {userProfile?.full_name || 'there'}! 👋
          </h2>
          <p className="text-gray-600 mt-1">Ready to order gas?</p>
        </div>

        {/* Order Button */}
        <Button
          fullWidth
          size="lg"
          onClick={() => navigate(ROUTES.CUSTOMER_ORDER)}
          className="shadow-lg"
        >
          🔥 Order Gas Now
        </Button>

        {/* Safety Tip */}
        {safetyTip && (
          <Card className="bg-gradient-to-r from-primary/10 to-secondary/10 border border-primary/20">
            <div className="flex items-start gap-3">
              <span className="text-2xl">💡</span>
              <div>
                <h3 className="font-semibold text-gray-900 mb-1">
                  Safety Tip of the Day
                </h3>
                <p className="text-sm text-gray-700">
                  {safetyTip.tip || 'Always check for gas leaks before connecting your cylinder.'}
                </p>
              </div>
            </div>
          </Card>
        )}

        {/* Recent Orders */}
        <div>
          <div className="flex justify-between items-center mb-3">
            <h3 className="text-lg font-bold text-gray-900">Recent Orders</h3>
            {orders.length > 0 && (
              <button
                onClick={() => navigate(ROUTES.CUSTOMER_TRACK)}
                className="text-primary text-sm font-semibold"
              >
                View All
              </button>
            )}
          </div>

          {orders.length === 0 ? (
            <Card className="text-center py-8">
              <div className="text-5xl mb-3">📦</div>
              <p className="text-gray-600 mb-4">No orders yet</p>
              <Button onClick={() => navigate(ROUTES.CUSTOMER_ORDER)}>
                Place Your First Order
              </Button>
            </Card>
          ) : (
            <div className="space-y-3">
              {orders.map((order) => (
                <Card
                  key={order.id}
                  onClick={() => navigate(`${ROUTES.CUSTOMER_TRACK}/${order.id}`)}
                  className="cursor-pointer"
                >
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <p className="font-semibold text-gray-900">
                        {order.cylinder_size}kg Cylinder
                      </p>
                      <p className="text-sm text-gray-600">
                        {formatDateTime(order.created_at)}
                      </p>
                    </div>
                    <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                      order.status === 'delivered' ? 'bg-success/10 text-success' :
                      order.status === 'on_the_way' ? 'bg-primary/10 text-primary' :
                      'bg-warning/10 text-warning'
                    }`}>
                      {order.status}
                    </span>
                  </div>
                  <p className="text-primary font-bold">
                    {formatCurrency(order.total_amount)}
                  </p>
                </Card>
              ))}
            </div>
          )}
        </div>
      </div>

      <TabNav tabs={tabs} />
    </div>
  );
};
