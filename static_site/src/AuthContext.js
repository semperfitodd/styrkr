import React, { createContext, useContext, useState, useEffect } from 'react';

const AuthContext = createContext(null);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const decodeIdToken = (idToken) => {
    const payload = JSON.parse(atob(idToken.split('.')[1]));
    return {
      name: payload.name || payload.email || 'User',
      email: payload.email || '',
      provider: payload.identities?.[0]?.providerName || 'cognito'
    };
  };

  const checkAuthStatus = async () => {
    try {
      const idToken = sessionStorage.getItem('id_token');
      
      if (idToken) {
        setUser(decodeIdToken(idToken));
      } else {
        const urlParams = new URLSearchParams(window.location.search);
        const code = urlParams.get('code');
        
        if (code) {
          await exchangeCodeForTokens(code);
          window.history.replaceState({}, document.title, window.location.pathname);
        } else {
          setUser(null);
        }
      }
    } catch (err) {
      console.error('Auth check error:', err);
      setUser(null);
    } finally {
      setLoading(false);
    }
  };

  const exchangeCodeForTokens = async (code) => {
    try {
      const tokenUrl = `https://${process.env.REACT_APP_COGNITO_DOMAIN}/oauth2/token`;
      
      const body = new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: process.env.REACT_APP_COGNITO_CLIENT_ID,
        code: code,
        redirect_uri: process.env.REACT_APP_REDIRECT_URI
      });

      const response = await fetch(tokenUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body.toString()
      });

      if (!response.ok) {
        throw new Error('Token exchange failed');
      }

      const tokens = await response.json();
      
      sessionStorage.setItem('access_token', tokens.access_token);
      sessionStorage.setItem('id_token', tokens.id_token);
      if (tokens.refresh_token) {
        sessionStorage.setItem('refresh_token', tokens.refresh_token);
      }

      setUser(decodeIdToken(tokens.id_token));
    } catch (err) {
      console.error('Token exchange error:', err);
      setError('Authentication failed');
    }
  };

  const buildAuthUrl = (provider) => {
    const params = new URLSearchParams({
      identity_provider: provider,
      redirect_uri: process.env.REACT_APP_REDIRECT_URI,
      response_type: 'code',
      client_id: process.env.REACT_APP_COGNITO_CLIENT_ID,
      scope: 'email openid profile'
    });
    return `https://${process.env.REACT_APP_COGNITO_DOMAIN}/oauth2/authorize?${params}`;
  };

  const loginWithGoogle = () => {
    window.location.href = buildAuthUrl('Google');
  };

  const loginWithApple = () => {
    window.location.href = buildAuthUrl('SignInWithApple');
  };

  const logout = () => {
    sessionStorage.removeItem('access_token');
    sessionStorage.removeItem('id_token');
    sessionStorage.removeItem('refresh_token');
    
    const params = new URLSearchParams({
      client_id: process.env.REACT_APP_COGNITO_CLIENT_ID,
      logout_uri: process.env.REACT_APP_LOGOUT_URI
    });
    window.location.href = `https://${process.env.REACT_APP_COGNITO_DOMAIN}/logout?${params}`;
  };

  useEffect(() => {
    checkAuthStatus();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const value = {
    user,
    loginWithGoogle,
    loginWithApple,
    logout,
    isAuthenticated: !!user,
    loading,
    error
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

