import React from 'react';
import { AuthProvider, useAuth } from './AuthContext';
import LoginScreen from './LoginScreen';
import HomeScreen from './HomeScreen';
import './App.css';

function AppContent() {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return (
      <div className="App">
        <div className="loading-screen">
          <img src="/icon.png" alt="STYRKR Logo" className="loading-logo" />
          <p>Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="App">
      {isAuthenticated ? <HomeScreen /> : <LoginScreen />}
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
