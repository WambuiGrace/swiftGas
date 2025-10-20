import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { ROUTES, ROLES } from '../../constants';
import { isValidEmail, isValidPhone } from '../../utils/helpers';

export const Signup = () => {
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phone: '',
    password: '',
    confirmPassword: '',
    role: ROLES.CUSTOMER, // Default to customer
  });
  const [errors, setErrors] = useState({});
  const [loading, setLoading] = useState(false);
  const { signUp } = useAuth();
  const navigate = useNavigate();

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    // Clear error for this field when user starts typing
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: '' }));
    }
  };

  const validate = () => {
    const newErrors = {};

    if (!formData.fullName.trim()) {
      newErrors.fullName = 'Full name is required';
    }

    if (!formData.email) {
      newErrors.email = 'Email is required';
    } else if (!isValidEmail(formData.email)) {
      newErrors.email = 'Please enter a valid email';
    }

    if (!formData.phone) {
      newErrors.phone = 'Phone number is required';
    } else if (!isValidPhone(formData.phone)) {
      newErrors.phone = 'Please enter a valid Kenyan phone number';
    }

    if (!formData.password) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 6) {
      newErrors.password = 'Password must be at least 6 characters';
    }

    if (!formData.confirmPassword) {
      newErrors.confirmPassword = 'Please confirm your password';
    } else if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!validate()) return;

    setLoading(true);
    setErrors({});

    try {
      const userData = {
        full_name: formData.fullName,
        phone: formData.phone,
        role: ROLES.CUSTOMER, // Force role to customer
      };

      const { error } = await signUp(formData.email, formData.password, userData);

      if (error) {
        setErrors({ general: error.message || 'Failed to create account. Please try again.' });
        return;
      }

      // Show success message and redirect to login
      alert('Account created successfully! Please check your email to verify your account.');
      navigate(ROUTES.LOGIN);
    } catch (err) {
      console.error('Signup error:', err);
      setErrors({ general: 'An unexpected error occurred. Please try again.' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background flex items-center justify-center px-4 py-8">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-primary rounded-full mb-3">
            <span className="text-3xl">🔥</span>
          </div>
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Create Account</h1>
          <p className="text-gray-600">Join SwiftGas today</p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="bg-white rounded-2xl shadow-lg p-6 space-y-4">
          {errors.general && (
            <div className="p-3 bg-error/10 border border-error rounded-lg">
              <p className="text-error text-sm">{errors.general}</p>
            </div>
          )}

          <Input
            label="Full Name"
            name="fullName"
            type="text"
            placeholder="Enter your full name"
            value={formData.fullName}
            onChange={handleChange}
            error={errors.fullName}
            required
          />

          <Input
            label="Email"
            name="email"
            type="email"
            placeholder="Enter your email"
            value={formData.email}
            onChange={handleChange}
            error={errors.email}
            required
          />

          <Input
            label="Phone Number"
            name="phone"
            type="tel"
            placeholder="+254 or 07XX XXX XXX"
            value={formData.phone}
            onChange={handleChange}
            error={errors.phone}
            required
          />

          {/* Role notice: drivers cannot sign up */}
          <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg">
            <p className="text-sm text-blue-800">
              Account type is <span className="font-semibold">Customer</span>. Drivers cannot create accounts — please use <span className="font-semibold">Sign In</span>.
            </p>
          </div>

          <Input
            label="Password"
            name="password"
            type="password"
            placeholder="At least 6 characters"
            value={formData.password}
            onChange={handleChange}
            error={errors.password}
            required
          />

          <Input
            label="Confirm Password"
            name="confirmPassword"
            type="password"
            placeholder="Re-enter your password"
            value={formData.confirmPassword}
            onChange={handleChange}
            error={errors.confirmPassword}
            required
          />

          <Button
            type="submit"
            fullWidth
            size="lg"
            loading={loading}
            disabled={loading}
          >
            Create Account
          </Button>

          <p className="text-center text-sm text-gray-600 mt-4">
            Already have an account?{' '}
            <Link to={ROUTES.LOGIN} className="text-primary font-semibold hover:underline">
              Sign In
            </Link>
          </p>
        </form>
      </div>
    </div>
  );
};
