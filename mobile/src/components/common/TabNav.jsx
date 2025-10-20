import { Link, useLocation } from 'react-router-dom';

export const TabNav = ({ tabs }) => {
  const location = useLocation();

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 px-4 py-2 safe-area-bottom z-50">
      <div className="flex justify-around items-center max-w-md mx-auto">
        {tabs.map((tab) => {
          const isActive = location.pathname === tab.path;
          
          return (
            <Link
              key={tab.path}
              to={tab.path}
              className={`flex flex-col items-center justify-center p-2 transition-colors min-w-[60px]
                ${isActive ? 'text-primary' : 'text-gray-500'}
              `}
            >
              <div className={`text-2xl mb-1 ${isActive ? 'scale-110' : ''} transition-transform`}>
                {tab.icon}
              </div>
              <span className={`text-xs ${isActive ? 'font-semibold' : 'font-normal'}`}>
                {tab.label}
              </span>
            </Link>
          );
        })}
      </div>
    </div>
  );
};
