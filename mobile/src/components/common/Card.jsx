export const Card = ({ children, className = '', onClick, ...props }) => {
  const clickableStyles = onClick ? 'cursor-pointer hover:shadow-lg transition-shadow' : '';
  
  return (
    <div
      onClick={onClick}
      className={`bg-white rounded-xl shadow-md p-4 ${clickableStyles} ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};
