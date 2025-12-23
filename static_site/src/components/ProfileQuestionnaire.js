import React, { useState } from 'react';
import { api } from '../api/client';
import './ProfileQuestionnaire.css';

function ProfileQuestionnaire({ onComplete }) {
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Profile state (v1 contract)
  const [profile, setProfile] = useState({
    trainingDaysPerWeek: 4,
    preferredStartDay: 'mon',
    preferredUnits: 'lb',
    nonLiftingDaysEnabled: true,
    nonLiftingDayMode: 'gpp',
    conditioningLevel: 'moderate',
  });

  const handleProfileChange = (field, value) => {
    setProfile({ ...profile, [field]: value });
  };

  const handleNext = () => {
    setError(null);
    if (step < 2) {
      setStep(step + 1);
    } else {
      handleSubmit();
    }
  };

  const handleBack = () => {
    setError(null);
    if (step > 1) {
      setStep(step - 1);
    }
  };

  const handleSubmit = async () => {
    setLoading(true);
    setError(null);

    try {
      await api.updateProfile(profile);

      setLoading(false);
      onComplete();
    } catch (err) {
      console.error('Setup error:', err);
      setError(err.message || 'Failed to save profile');
      setLoading(false);
    }
  };

  const isStep1Valid = () => {
    return profile.trainingDaysPerWeek >= 4 && profile.trainingDaysPerWeek <= 7;
  };


  return (
    <div className="questionnaire">
      <div className="questionnaire-container">
        <div className="questionnaire-header">
          <h1>Welcome to STYRKR</h1>
          <p>Let's build your training profile</p>
          <div className="progress-bar">
            <div className="progress-fill" style={{ width: `${(step / 2) * 100}%` }}></div>
          </div>
          <p className="step-indicator">Step {step} of 2</p>
        </div>

        {error && <div className="alert alert-error">{error}</div>}

        {/* Step 1: Training Schedule */}
        {step === 1 && (
          <div className="questionnaire-step">
            <h2>Training Schedule</h2>

            <div className="form-group">
              <label>How many days per week will you train?</label>
              <div className="day-selector">
                {[4, 5, 6, 7].map((days) => (
                  <button
                    key={days}
                    type="button"
                    className={`day-button ${profile.trainingDaysPerWeek === days ? 'active' : ''}`}
                    onClick={() => handleProfileChange('trainingDaysPerWeek', days)}
                  >
                    {days} days
                  </button>
                ))}
              </div>
              <p className="help-text">4 days = main lifts only. 5-7 days adds GPP, mobility, or active recovery.</p>
            </div>

            <div className="form-group">
              <label>Preferred Units</label>
              <div className="radio-group">
                <label className="radio-label">
                  <input
                    type="radio"
                    value="lb"
                    checked={profile.preferredUnits === 'lb'}
                    onChange={(e) => handleProfileChange('preferredUnits', e.target.value)}
                  />
                  Pounds (lb)
                </label>
                <label className="radio-label">
                  <input
                    type="radio"
                    value="kg"
                    checked={profile.preferredUnits === 'kg'}
                    onChange={(e) => handleProfileChange('preferredUnits', e.target.value)}
                  />
                  Kilograms (kg)
                </label>
              </div>
            </div>

            <div className="form-group">
              <label>Preferred Start Day</label>
              <select
                value={profile.preferredStartDay}
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
          </div>
        )}

        {/* Step 2: Non-Lifting Days */}
        {step === 2 && (
          <div className="questionnaire-step">
            <h2>Non-Lifting Days</h2>

            <div className="form-group">
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  checked={profile.nonLiftingDaysEnabled}
                  onChange={(e) => handleProfileChange('nonLiftingDaysEnabled', e.target.checked)}
                />
                Include non-lifting day programming
              </label>
              <small>We'll program your off-days with recovery work</small>
            </div>

            {profile.nonLiftingDaysEnabled && (
              <>
                <div className="form-group">
                  <label>What should non-lifting days focus on?</label>
                  <select
                    value={profile.nonLiftingDayMode}
                    onChange={(e) => handleProfileChange('nonLiftingDayMode', e.target.value)}
                  >
                    <option value="pilates">Pilates</option>
                    <option value="conditioning">Conditioning</option>
                    <option value="gpp">GPP (General Physical Preparedness)</option>
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
                        checked={profile.conditioningLevel === 'low'}
                        onChange={(e) => handleProfileChange('conditioningLevel', e.target.value)}
                      />
                      Low
                    </label>
                    <label className="radio-label">
                      <input
                        type="radio"
                        value="moderate"
                        checked={profile.conditioningLevel === 'moderate'}
                        onChange={(e) => handleProfileChange('conditioningLevel', e.target.value)}
                      />
                      Moderate
                    </label>
                    <label className="radio-label">
                      <input
                        type="radio"
                        value="high"
                        checked={profile.conditioningLevel === 'high'}
                        onChange={(e) => handleProfileChange('conditioningLevel', e.target.value)}
                      />
                      High
                    </label>
                  </div>
                </div>
              </>
            )}
          </div>
        )}



        <div className="questionnaire-actions">
          {step > 1 && (
            <button type="button" onClick={handleBack} className="btn-secondary" disabled={loading}>
              Back
            </button>
          )}
          <button
            type="button"
            onClick={handleNext}
            className="btn-primary"
            disabled={loading || (step === 1 && !isStep1Valid())}
          >
            {loading ? 'Saving...' : step === 2 ? 'Complete Setup' : 'Next'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default ProfileQuestionnaire;

