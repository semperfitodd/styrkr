import React from 'react';
import { useAuth } from './AuthContext';
import './HomeScreen.css';

function HomeScreen() {
  const { user, logout } = useAuth();

  return (
    <div className="home-screen">
      <header className="home-header">
        <div className="welcome-section">
          <h1 className="welcome-message">Hello, {user?.name}! 👋</h1>
          <p className="user-email">{user?.email}</p>
          <div className="provider-badge">
            Signed in with {user?.provider === 'Google' ? 'Google' : user?.provider === 'SignInWithApple' ? 'Apple' : 'Cognito'}
          </div>
        </div>

        <div className="features">
          <div className="feature">
            <h3>💪 Track Your Progress</h3>
            <p>Log workouts and monitor your strength gains over time</p>
          </div>
          <div className="feature">
            <h3>🎯 Set Goals</h3>
            <p>Define and achieve your fitness objectives</p>
          </div>
          <div className="feature">
            <h3>📊 Analyze Performance</h3>
            <p>Get insights into your training patterns and improvements</p>
          </div>
        </div>

        <button onClick={logout} className="logout-button">
          Sign Out
        </button>

        <footer className="home-footer">
          <p>Built with dedication by Todd</p>
          <p className="copyright">© {new Date().getFullYear()} STYRKR. All rights reserved.</p>
        </footer>
      </header>
    </div>
  );
}

export default HomeScreen;

