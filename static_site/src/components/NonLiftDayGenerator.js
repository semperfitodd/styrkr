import React, { useState } from 'react';
import { api } from '../api/client';
import './NonLiftDayGenerator.css';

function NonLiftDayGenerator({ dayType, weekIndex, onWorkoutGenerated, onClose }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [workout, setWorkout] = useState(null);

  const generateWorkout = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const generated = await api.generateNonLiftDay(dayType, weekIndex);
      setWorkout(generated);
      if (onWorkoutGenerated) {
        onWorkoutGenerated(generated);
      }
    } catch (err) {
      setError(err.message || 'Failed to generate workout');
    } finally {
      setLoading(false);
    }
  };

  const getDayTypeLabel = () => {
    switch (dayType) {
      case 'gpp_krypteia':
        return 'GPP / Krypteia';
      case 'mobility':
        return 'Mobility';
      case 'active_recovery':
        return 'Active Recovery';
      default:
        return dayType;
    }
  };

  return (
    <div className="nonlift-generator">
      <div className="nonlift-header">
        <h3>{getDayTypeLabel()}</h3>
        {onClose && (
          <button className="close-button" onClick={onClose}>×</button>
        )}
      </div>

      {!workout && (
        <div className="nonlift-prompt">
          <p>Generate a {getDayTypeLabel()} workout for this day</p>
          <button 
            className="generate-button"
            onClick={generateWorkout}
            disabled={loading}
          >
            {loading ? 'Generating...' : 'Generate Workout'}
          </button>
          {error && <div className="error-message">{error}</div>}
        </div>
      )}

      {workout && (
        <div className="nonlift-workout">
          <h4>{workout.label}</h4>
          
          {workout.conditioning && (
            <div className="conditioning-block">
              <h5>Conditioning</h5>
              <p><strong>Modality:</strong> {workout.conditioning.modality}</p>
              <p><strong>Prescription:</strong> {workout.conditioning.prescription}</p>
              <p><strong>Target RPE:</strong> {workout.conditioning.targetRPE}</p>
            </div>
          )}

          {workout.circuit && (
            <div className="circuit-block">
              <h5>Circuit ({workout.circuit.rounds} rounds)</h5>
              {workout.circuit.slots.map((slot, idx) => (
                <div key={idx} className="circuit-slot">
                  <p><strong>{slot.label}:</strong> {slot.targetReps}</p>
                  <select className="exercise-select">
                    <option value="">Select exercise...</option>
                    {slot.exercises.map(ex => (
                      <option key={ex.id} value={ex.id}>{ex.name}</option>
                    ))}
                  </select>
                </div>
              ))}
            </div>
          )}

          {workout.exercises && (
            <div className="exercises-block">
              <h5>Exercises</h5>
              {workout.exercises.map((ex, idx) => (
                <div key={idx} className="exercise-item">
                  <p><strong>{ex.name}</strong></p>
                  <p className="prescription">{ex.prescription}</p>
                  {ex.notes && <p className="notes">{ex.notes}</p>}
                </div>
              ))}
            </div>
          )}

          {workout.notes && (
            <div className="workout-notes">
              <h5>Notes</h5>
              <ul>
                {workout.notes.map((note, idx) => (
                  <li key={idx}>{note}</li>
                ))}
              </ul>
            </div>
          )}

          <button className="complete-button" onClick={() => {
            // TODO: Implement workout logging
            console.log('Complete workout:', workout);
            if (onClose) onClose();
          }}>
            Complete Workout
          </button>
        </div>
      )}
    </div>
  );
}

export default NonLiftDayGenerator;

