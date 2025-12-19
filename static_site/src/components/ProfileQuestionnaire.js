import React, { useState } from 'react';
import { api } from '../api/client';
import './ProfileQuestionnaire.css';

const COMMON_CONSTRAINTS = [
  'no_lunges',
  'no_deep_knee_flexion',
  'no_overhead',
  'no_barbell_back_squat',
  'no_jumping',
  'no_running',
  'low_back_issues',
  'shoulder_issues',
  'knee_issues',
];

function ProfileQuestionnaire({ onComplete }) {
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Profile state
  const [profile, setProfile] = useState({
    trainingDaysPerWeek: 4,
    preferredUnits: 'lb',
    includeNonLiftingDays: true,
    nonLiftingDayMode: 'pilates',
    constraints: [],
    conditioningLevel: 'moderate',
    preferredStartDay: 'mon',
    movementCapabilities: {
      pullups: false,
      ringDips: false,
      muscleUps: 'none',
    },
  });


  const [customConstraint, setCustomConstraint] = useState('');

  const handleProfileChange = (field, value) => {
    setProfile({ ...profile, [field]: value });
  };

  const handleMovementCapabilityChange = (field, value) => {
    setProfile({
      ...profile,
      movementCapabilities: {
        ...profile.movementCapabilities,
        [field]: value,
      },
    });
  };


  const toggleConstraint = (constraint) => {
    if (profile.constraints.includes(constraint)) {
      setProfile({
        ...profile,
        constraints: profile.constraints.filter((c) => c !== constraint),
      });
    } else {
      setProfile({
        ...profile,
        constraints: [...profile.constraints, constraint],
      });
    }
  };

  const addCustomConstraint = () => {
    if (customConstraint.trim() && !profile.constraints.includes(customConstraint.trim())) {
      setProfile({
        ...profile,
        constraints: [...profile.constraints, customConstraint.trim()],
      });
      setCustomConstraint('');
    }
  };

  const removeConstraint = (constraint) => {
    setProfile({
      ...profile,
      constraints: profile.constraints.filter((c) => c !== constraint),
    });
  };

  const handleNext = () => {
    setError(null);
    if (step < 3) {
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
    return profile.trainingDaysPerWeek >= 3 && profile.trainingDaysPerWeek <= 6;
  };


  return (
    <div className="questionnaire">
      <div className="questionnaire-container">
        <div className="questionnaire-header">
          <h1>Welcome to STYRKR</h1>
          <p>Let's build your training profile</p>
          <div className="progress-bar">
            <div className="progress-fill" style={{ width: `${(step / 3) * 100}%` }}></div>
          </div>
          <p className="step-indicator">Step {step} of 3</p>
        </div>

        {error && <div className="alert alert-error">{error}</div>}

        {/* Step 1: Training Schedule */}
        {step === 1 && (
          <div className="questionnaire-step">
            <h2>Training Schedule</h2>

            <div className="form-group">
              <label>How many days per week will you train?</label>
              <div className="day-selector">
                {[3, 4, 5, 6].map((days) => (
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
                  checked={profile.includeNonLiftingDays}
                  onChange={(e) => handleProfileChange('includeNonLiftingDays', e.target.checked)}
                />
                Include non-lifting day programming
              </label>
              <small>We'll program your off-days with recovery work</small>
            </div>

            {profile.includeNonLiftingDays && (
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

        {/* Step 3: Movement Capabilities & Constraints */}
        {step === 3 && (
          <div className="questionnaire-step">
            <h2>Movement Capabilities & Constraints</h2>

            <div className="form-group">
              <label>What can you do?</label>
              <div className="capability-checks">
                <label className="checkbox-label">
                  <input
                    type="checkbox"
                    checked={profile.movementCapabilities.pullups}
                    onChange={(e) => handleMovementCapabilityChange('pullups', e.target.checked)}
                  />
                  Pull-ups
                </label>
                <label className="checkbox-label">
                  <input
                    type="checkbox"
                    checked={profile.movementCapabilities.ringDips}
                    onChange={(e) => handleMovementCapabilityChange('ringDips', e.target.checked)}
                  />
                  Ring Dips
                </label>
              </div>
            </div>

            <div className="form-group">
              <label>Muscle-ups</label>
              <select
                value={profile.movementCapabilities.muscleUps}
                onChange={(e) => handleMovementCapabilityChange('muscleUps', e.target.value)}
              >
                <option value="none">None</option>
                <option value="bar">Bar Muscle-ups</option>
                <option value="rings">Ring Muscle-ups</option>
              </select>
            </div>

            <div className="form-group">
              <label>Any injuries or movement constraints?</label>
              <small>Select all that apply</small>
              <div className="chip-list mt-2">
                {COMMON_CONSTRAINTS.map((constraint) => (
                  <button
                    key={constraint}
                    type="button"
                    className={`chip ${profile.constraints.includes(constraint) ? 'active' : ''}`}
                    onClick={() => toggleConstraint(constraint)}
                  >
                    {constraint.replace(/_/g, ' ')}
                  </button>
                ))}
              </div>
              <div className="custom-constraint mt-2">
                <input
                  type="text"
                  placeholder="Add custom constraint"
                  value={customConstraint}
                  onChange={(e) => setCustomConstraint(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addCustomConstraint())}
                />
                <button type="button" onClick={addCustomConstraint} className="btn-ghost">
                  Add
                </button>
              </div>
              {profile.constraints.length > 0 && (
                <div className="chip-list mt-2">
                  {profile.constraints.map((constraint) => (
                    <span key={constraint} className="badge badge-removable">
                      {constraint.replace(/_/g, ' ')}
                      <button type="button" className="badge-remove" onClick={() => removeConstraint(constraint)}>
                        ×
                      </button>
                    </span>
                  ))}
                </div>
              )}
            </div>
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
            {loading ? 'Saving...' : step === 3 ? 'Complete Setup' : 'Next'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default ProfileQuestionnaire;

