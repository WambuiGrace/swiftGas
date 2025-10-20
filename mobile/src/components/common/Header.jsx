import { useNavigate } from 'react-router-dom';

export const Header = ({ 
  title, 
  subtitle, 
  showBack = false, 
  rightAction,
  className = '' 
}) => {
  const navigate = useNavigate();

  return (
    <header className={`bg-white border-b border-gray-200 px-4 py-4 ${className}`}>
      <div className="flex items-center justify-between max-w-md mx-auto">
        <div className="flex items-center gap-3 flex-1">
          {showBack && (
            <button
              onClick={() => navigate(-1)}
              className="text-gray-600 hover:text-gray-900 transition-colors"
            >
              <svg
                className="w-6 h-6"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M15 19l-7-7 7-7"
                />
              </svg>
            </button>
          )}
          
          <div className="flex-1">
            {title && (
              <h1 className="text-xl font-bold text-gray-900">{title}</h1>
            )}
            {subtitle && (
              <p className="text-sm text-gray-600">{subtitle}</p>
            )}
          </div>
        </div>

        {rightAction && <div>{rightAction}</div>}
      </div>
    </header>
  );
};
