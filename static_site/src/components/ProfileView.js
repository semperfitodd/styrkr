import React, { useState, useEffect } from 'react';
import { api } from '../api/client';
import './ProfileView.css';

function ProfileView({ onClose }) {
  const [mode, setMode] = useState('view'); // view or edit
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  
  const [profile, setProfile] = useState(null);
  const [editedProfile, setEditedProfile] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    setError(null);
    try {
      const profileData = await api.getProfile();
      setProfile(profileData);
      setEditedProfile(JSON.parse(JSON.stringify(profileData)));
    } catch (err) {
      console.error('Error loading profile:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = () => {
    setMode('edit');
    setEditedProfile(JSON.parse(JSON.stringify(profile)));
  };

  const handleCancel = () => {
    setMode('view');
    setEditedProfile(JSON.parse(JSON.stringify(profile)));
    setError(null);
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      await api.updateProfile(editedProfile);
      await loadData();
      setMode('view');
    } catch (err) {
      console.error('Error saving:', err);
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleProfileChange = (field, value) => {
    setEditedProfile({ ...editedProfile, [field]: value });
  };

  if (loading) {
    return (
      <div className="profile-view">
        <div className="profile-container">
          <div className="spinner"></div>
          <p>Loading profile...</p>
        </div>
      </div>
    );
  }

  if (error && !profile) {
    return (
      <div className="profile-view">
        <div className="profile-container">
          <div className="alert alert-error">{error}</div>
          <button onClick={onClose} className="btn-secondary">Close</button>
        </div>
      </div>
    );
  }

  const currentProfile = mode === 'edit' ? editedProfile : profile;

  return (
    <div className="profile-view">
      <div className="profile-container">
        <div className="profile-header">
          <button onClick={onClose} className="close-button" aria-label="Close">
            ✕
          </button>
          <h1>Your Profile</h1>
          <div className="profile-actions">
            {mode === 'view' ? (
              <button onClick={handleEdit} className="btn-edit">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                </svg>
                Edit Profile
              </button>
            ) : (
              <div className="edit-actions">
                <button onClick={handleCancel} className="btn-cancel" disabled={saving}>
                  Cancel
                </button>
                <button onClick={handleSave} className="btn-save" disabled={saving}>
                  {saving ? 'Saving...' : 'Save Changes'}
                </button>
              </div>
            )}
          </div>
        </div>

        {error && <div className="alert alert-error">{error}</div>}

        <div className="profile-content">
          {/* Training Schedule */}
          <div className="section">
            <h2>Training Schedule</h2>
            {mode === 'view' ? (
              <div className="info-grid">
                <div className="info-item">
                  <span className="label">Training Days:</span>
                  <span className="value">{currentProfile.trainingDaysPerWeek} days/week</span>
                </div>
                <div className="info-item">
                  <span className="label">Start Day:</span>
                  <span className="value">{currentProfile.preferredStartDay?.toUpperCase()}</span>
                </div>
                <div className="info-item">
                  <span className="label">Units:</span>
                  <span className="value">{currentProfile.preferredUnits?.toUpperCase()}</span>
                </div>
              </div>
            ) : (
              <>
                <div className="form-group">
                  <label>Training Days Per Week</label>
                  <input
                    type="number"
                    min="3"
                    max="6"
                    value={currentProfile.trainingDaysPerWeek}
                    onChange={(e) => handleProfileChange('trainingDaysPerWeek', parseInt(e.target.value))}
                  />
                </div>
                <div className="form-group">
                  <label>Preferred Start Day</label>
                  <select
                    value={currentProfile.preferredStartDay}
                    onChange={(e) => handleProfileChange('preferredStartDay', e.target.value)}
                  >
                    <option value="mon">Monday</option>
                    <option value="tue">Tuesday</option>
                    <option value="wed">Wednesday</option>
                    <option value="thu">Thursday</option>
                    <option value="fri">Friday</option>
                    <option value="sat">Saturday</option>
                    <option value="sun">Sunday</option>
                  </select>
                </div>
                <div className="form-group">
                  <label>Preferred Units</label>
                  <div className="radio-group">
                    <label className="radio-label">
                      <input
                        type="radio"
                        value="lb"
                        checked={currentProfile.preferredUnits === 'lb'}
                        onChange={(e) => handleProfileChange('preferredUnits', e.target.value)}
                      />
                      Pounds (lb)
                    </label>
                    <label className="radio-label">
                      <input
                        type="radio"
                        value="kg"
                        checked={currentProfile.preferredUnits === 'kg'}
                        onChange={(e) => handleProfileChange('preferredUnits', e.target.value)}
                      />
                      Kilograms (kg)
                    </label>
                  </div>
                </div>
              </>
            )}
          </div>

          {/* Non-Lifting Days */}
          <div className="section">
            <h2>Non-Lifting Days</h2>
            {mode === 'view' ? (
              <div className="info-grid">
                <div className="info-item">
                  <span className="label">Programming:</span>
                  <span className="value">{currentProfile.nonLiftingDaysEnabled ? 'Enabled' : 'Disabled'}</span>
                </div>
                {currentProfile.nonLiftingDaysEnabled && (
                  <>
                    <div className="info-item">
                      <span className="label">Mode:</span>
                      <span className="value">{currentProfile.nonLiftingDayMode}</span>
                    </div>
                    <div className="info-item">
                      <span className="label">Conditioning Level:</span>
                      <span className="value">{currentProfile.conditioningLevel}</span>
                    </div>
                  </>
                )}
              </div>
            ) : (
              <>
                <div className="form-group">
                  <label className="checkbox-label">
                    <input
                      type="checkbox"
                      checked={currentProfile.nonLiftingDaysEnabled}
                      onChange={(e) => handleProfileChange('nonLiftingDaysEnabled', e.target.checked)}
                    />
                    Include non-lifting day programming
                  </label>
                </div>
                {currentProfile.nonLiftingDaysEnabled && (
                  <>
                    <div className="form-group">
                      <label>Non-Lifting Day Mode</label>
                      <select
                        value={currentProfile.nonLiftingDayMode}
                        onChange={(e) => handleProfileChange('nonLiftingDayMode', e.target.value)}
                      >
                        <option value="pilates">Pilates</option>
                        <option value="conditioning">Conditioning</option>
                        <option value="gpp">GPP</option>
                        <option value="mobility">Mobility</option>
                        <option value="rest">Rest</option>
                      </select>
                    </div>
                    <div className="form-group">
                      <label>Conditioning Level</label>
                      <div className="radio-group">
                        <label className="radio-label">
                          <input
                            type="radio"
                            value="low"
                            checked={currentProfile.conditioningLevel === 'low'}
                            onChange={(e) => handleProfileChange('conditioningLevel', e.target.value)}
                          />
                          Low
                        </label>
                        <label className="radio-label">
                          <input
                            type="radio"
                            value="moderate"
                            checked={currentProfile.conditioningLevel === 'moderate'}
                            onChange={(e) => handleProfileChange('conditioningLevel', e.target.value)}
                          />
                          Moderate
                        </label>
                        <label className="radio-label">
                          <input
                            type="radio"
                            value="high"
                            checked={currentProfile.conditioningLevel === 'high'}
                            onChange={(e) => handleProfileChange('conditioningLevel', e.target.value)}
                          />
                          High
                        </label>
                      </div>
                    </div>
                  </>
                )}
              </>
            )}
          </div>

        </div>
      </div>
    </div>
  );
}

export default ProfileView;

