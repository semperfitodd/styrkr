import React, { useState, useEffect } from 'react';
import { AuthProvider, useAuth } from './AuthContext';
import LoginScreen from './LoginScreen';
import HomeScreen from './HomeScreen';
import ProfileQuestionnaire from './components/ProfileQuestionnaire';
import { api, ApiError } from './api/client';
import './App.css';

function AppContent() {
  const { isAuthenticated, loading: authLoading } = useAuth();
  const [appState, setAppState] = useState('loading'); // loading, login, questionnaire, home
  const [error, setError] = useState(null);

  useEffect(() => {
    if (isAuthenticated) {
      checkProfileStatus();
    } else {
      setAppState('login');
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthenticated]);

  const checkProfileStatus = async () => {
    try {
      await api.getProfile();
      // Profile exists, go to home
      setAppState('home');
    } catch (err) {
      if (err instanceof ApiError && err.code === 'NOT_FOUND') {
        // Profile doesn't exist, show questionnaire
        setAppState('questionnaire');
      } else {
        // Other error
        console.error('Error checking profile:', err);
        setError(err.message);
        setAppState('error');
      }
    }
  };

  const handleQuestionnaireComplete = () => {
    setAppState('home');
  };

  if (authLoading || appState === 'loading') {
    return (
      <div className="App">
        <div className="loading-screen">
          <img src="/icon.png" alt="STYRKR Logo" className="loading-logo" />
          <p>Loading...</p>
        </div>
      </div>
    );
  }

  if (appState === 'error') {
    return (
      <div className="App">
        <div className="error-screen">
          <img src="/icon.png" alt="STYRKR Logo" className="error-logo" />
          <h2>Something went wrong</h2>
          <p>{error}</p>
          <button onClick={() => window.location.reload()}>Reload</button>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return (
      <div className="App">
        <LoginScreen />
      </div>
    );
  }

  if (appState === 'questionnaire') {
    return (
      <div className="App">
        <ProfileQuestionnaire onComplete={handleQuestionnaireComplete} />
      </div>
    );
  }

  return (
    <div className="App">
      <HomeScreen />
    </div>
  );
}

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;
