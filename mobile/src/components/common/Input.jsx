export const Input = ({
  label,
  type = 'text',
  placeholder,
  value,
  onChange,
  error,
  required = false,
  disabled = false,
  icon,
  className = '',
  ...props
}) => {
  return (
    <div className={`w-full ${className}`}>
      {label && (
        <label className="block text-sm font-medium text-gray-700 mb-1.5">
          {label}
          {required && <span className="text-error ml-1">*</span>}
        </label>
      )}
      <div className="relative">
        {icon && (
          <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
            {icon}
          </div>
        )}
        <input
          type={type}
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          disabled={disabled}
          required={required}
          className={`
            w-full px-4 py-2.5 rounded-lg border
            ${icon ? 'pl-10' : ''}
            ${error ? 'border-error focus:ring-error' : 'border-gray-300 focus:ring-primary'}
            focus:outline-none focus:ring-2 focus:border-transparent
            disabled:bg-gray-100 disabled:cursor-not-allowed
            transition-all duration-200
          `}
          {...props}
        />
      </div>
      {error && (
        <p className="text-error text-sm mt-1">{error}</p>
      )}
    </div>
  );
};
