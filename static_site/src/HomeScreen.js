import React, { useState, useEffect } from 'react';
import { useAuth } from './AuthContext';
import ProfileView from './components/ProfileView';
import ExerciseLibrary from './components/ExerciseLibrary';
import ProgramView from './components/ProgramView';
import { api } from './api/client';
import './HomeScreen.css';

function HomeScreen() {
  const { user, logout } = useAuth();
  const [showProfile, setShowProfile] = useState(false);
  const [showExerciseLibrary, setShowExerciseLibrary] = useState(false);
  const [showProgram, setShowProgram] = useState(false);
  const [userProfile, setUserProfile] = useState(null);

  useEffect(() => {
    loadProfile();
  }, []);

  const loadProfile = async () => {
    try {
      const profile = await api.getProfile();
      setUserProfile(profile);
    } catch (error) {
      console.error('Failed to load profile:', error);
    }
  };

  return (
    <div className="home-screen">
      <header className="home-header">
        <div className="header-top">
          <button onClick={() => setShowProfile(true)} className="settings-button" aria-label="Settings">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/>
              <circle cx="12" cy="12" r="3"/>
            </svg>
          </button>
        </div>
        <div className="welcome-section">
          <h1 className="welcome-message">Hello, {user?.name}! 👋</h1>
          <p className="user-email">{user?.email}</p>
          <div className="provider-badge">
            Signed in with {user?.provider === 'Google' ? 'Google' : user?.provider === 'SignInWithApple' ? 'Apple' : 'Cognito'}
          </div>
        </div>

        <div className="features">
          <div className="feature clickable" onClick={() => setShowProgram(true)}>
            <h3>📅 Training Program</h3>
            <p>View your personalized 13-week 5/3/1 Krypteia program</p>
            <span className="feature-link">View Program →</span>
          </div>
          <div className="feature clickable" onClick={() => setShowExerciseLibrary(true)}>
            <h3>📚 Exercise Library</h3>
            <p>Browse 120+ exercises for 5/3/1 Krypteia + longevity</p>
            <span className="feature-link">View Library →</span>
          </div>
          <div className="feature">
            <h3>💪 Track Your Progress</h3>
            <p>Log workouts and monitor your strength gains over time</p>
          </div>
        </div>

        <div className="action-buttons">
          <button onClick={logout} className="logout-button">
            Sign Out
          </button>
        </div>

        <footer className="home-footer">
          <p>Built with dedication by Todd</p>
          <p className="copyright">© {new Date().getFullYear()} STYRKR. All rights reserved.</p>
        </footer>
      </header>

      {showProfile && <ProfileView onClose={() => setShowProfile(false)} />}
      {showExerciseLibrary && (
        <ExerciseLibrary 
          onClose={() => setShowExerciseLibrary(false)} 
          userProfile={userProfile}
        />
      )}
      {showProgram && <ProgramView onClose={() => setShowProgram(false)} />}
    </div>
  );
}

export default HomeScreen;

