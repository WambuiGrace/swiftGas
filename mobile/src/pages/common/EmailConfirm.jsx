import { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { ROUTES } from '../../constants';

/**
 * EmailConfirm Page
 * 
 * Handles email confirmation callback from Supabase.
 * When users click the confirmation link in their email, Supabase redirects them here.
 * 
 * Supabase automatically verifies the token in the URL hash and updates the session.
 * We just need to detect the session and redirect the user appropriately.
 */
export function EmailConfirm() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [status, setStatus] = useState('verifying'); // verifying, success, error
  const [message, setMessage] = useState('Verifying your email...');

  useEffect(() => {
    const handleEmailConfirmation = async () => {
      try {
        // Check for error in URL params (Supabase passes errors via query params)
        const error = searchParams.get('error');
        const errorDescription = searchParams.get('error_description');

        if (error) {
          setStatus('error');
          setMessage(errorDescription || 'Failed to verify email. Please try again.');
          return;
        }

        // Check URL hash for tokens (Supabase uses hash-based tokens)
        const hashParams = new URLSearchParams(window.location.hash.substring(1));
        const accessToken = hashParams.get('access_token');
        const type = hashParams.get('type');

        // If we have an access token and it's an email confirmation
        if (accessToken && type === 'signup') {
          setStatus('success');
          setMessage('Email verified successfully! Redirecting to login...');
          
          // Redirect to login after 2 seconds
          setTimeout(() => {
            navigate(ROUTES.LOGIN, { 
              state: { 
                message: 'Email verified! Please log in to continue.',
                verified: true 
              } 
            });
          }, 2000);
        } else {
          // No token found, might be already verified or invalid link
          setStatus('error');
          setMessage('Invalid or expired confirmation link.');
          
          // Redirect to login after 3 seconds
          setTimeout(() => {
            navigate(ROUTES.LOGIN);
          }, 3000);
        }
      } catch (error) {
        console.error('Email confirmation error:', error);
        setStatus('error');
        setMessage('An error occurred while verifying your email.');
      }
    };

    handleEmailConfirmation();
  }, [navigate, searchParams]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4">
      <div className="max-w-md w-full bg-white rounded-lg shadow-xl p-8">
        <div className="text-center">
          {/* Status Icon */}
          <div className="mb-6">
            {status === 'verifying' && (
              <div className="flex justify-center">
                <LoadingSpinner size="large" />
              </div>
            )}
            {status === 'success' && (
              <div className="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-green-100">
                <svg
                  className="h-8 w-8 text-green-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    d="M5 13l4 4L19 7"
                  />
                </svg>
              </div>
            )}
            {status === 'error' && (
              <div className="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-red-100">
                <svg
                  className="h-8 w-8 text-red-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </div>
            )}
          </div>

          {/* Title */}
          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            {status === 'verifying' && 'Verifying Email'}
            {status === 'success' && 'Email Verified!'}
            {status === 'error' && 'Verification Failed'}
          </h2>

          {/* Message */}
          <p className="text-gray-600 mb-6">{message}</p>

          {/* Manual Navigation Button (for error case) */}
          {status === 'error' && (
            <button
              onClick={() => navigate(ROUTES.LOGIN)}
              className="w-full bg-indigo-600 text-white py-3 px-4 rounded-lg hover:bg-indigo-700 transition-colors font-medium"
            >
              Go to Login
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

export default EmailConfirm;
