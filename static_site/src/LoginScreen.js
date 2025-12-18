import React from 'react';
import { useAuth } from './AuthContext';
import './LoginScreen.css';

function LoginScreen() {
  const { loginWithGoogle, loginWithApple, error } = useAuth();

  return (
    <div className="login-screen">
      <div className="login-container">
        <div className="logo-section">
          <img src="/icon.png" alt="STYRKR Logo" className="login-logo" />
          <h1>STYRKR</h1>
          <p className="tagline">Your Ultimate Strength Training Companion</p>
        </div>

        {error && <div className="error-message">{error}</div>}

        <div className="login-buttons">
          <button onClick={loginWithGoogle} className="google-signin-button">
            <svg width="20" height="20" viewBox="0 0 24 24">
              <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
              <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
            </svg>
            Continue with Google
          </button>

          <button onClick={loginWithApple} className="apple-signin-button">
            <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
              <path d="M17.05 14.85c-.45 1.01-1 1.94-1.65 2.8-.9 1.18-1.64 2-2.22 2.45-.9.82-1.86 1.24-2.89 1.27-1.03.03-1.36-.31-2.54-.31-1.18 0-1.55.29-2.52.34-1.01.05-2.05-.48-3-1.31-.96-.84-1.74-1.93-2.34-3.27-.86-1.93-1.28-3.8-1.28-5.61 0-2.08.45-3.87 1.35-5.38.71-1.19 1.65-2.13 2.82-2.81 1.17-.68 2.44-1.03 3.81-1.06 1.05-.03 1.93.36 2.64.59.71.23 1.17.36 1.38.36.16 0 .7-.16 1.62-.48.87-.29 1.61-.41 2.22-.36 1.64.13 2.87.78 3.69 1.95-1.47.89-2.19 2.14-2.17 3.74.02 1.25.47 2.29 1.34 3.12.39.39.83.69 1.32.9-.11.31-.22.61-.34.89zM13.23 1.36c0 .98-.36 1.9-1.07 2.75-.86 1.02-1.9 1.61-3.03 1.52-.01-.12-.02-.25-.02-.39 0-.94.41-1.95 1.14-2.77.36-.42.82-.77 1.37-1.05.55-.27 1.07-.43 1.57-.45.01.13.02.26.02.39z"/>
            </svg>
            Continue with Apple
          </button>
        </div>

        <p className="login-footer">
          By continuing, you agree to STYRKR's Terms of Service and Privacy Policy
        </p>
      </div>
    </div>
  );
}

export default LoginScreen;

