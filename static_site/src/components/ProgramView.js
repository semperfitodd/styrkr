import React, { useState, useEffect } from 'react';
import { api } from '../api/client';
import { loadPlanTemplate, generateProgram, calculateTrainingMaxes } from '../utils/programGenerator';
import { selectExercisesForSession } from '../utils/exerciseSelector';
import ProgramCalendar from './ProgramCalendar';
import './ProgramView.css';

function ProgramView({ onClose }) {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [program, setProgram] = useState(null);
  const [selectedWeek, setSelectedWeek] = useState(1);
  const [selectedDay, setSelectedDay] = useState(null);
  const [selectedSession, setSelectedSession] = useState(null);
  const [circuitData, setCircuitData] = useState([]);
  const [needsStrengthData, setNeedsStrengthData] = useState(false);
  const [weekDates, setWeekDates] = useState([]);
  const [completedWorkouts, setCompletedWorkouts] = useState([]);
  
  // For entering 1RMs
  const [oneRepMaxes, setOneRepMaxes] = useState({
    squat: '',
    bench: '',
    deadlift: '',
    ohp: '',
  });
  const [tmPercent, setTmPercent] = useState(85);
  const [units, setUnits] = useState('lb');

  useEffect(() => {
    loadData();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const getNextStartDay = (preferredDay) => {
    const dayMap = {
      'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6, 'sun': 0
    };
    
    const today = new Date();
    const targetDay = dayMap[preferredDay];
    const currentDay = today.getDay();
    
    let daysUntilStart = targetDay - currentDay;
    if (daysUntilStart <= 0) {
      daysUntilStart += 7;
    }
    
    const startDate = new Date(today);
    startDate.setDate(today.getDate() + daysUntilStart);
    startDate.setHours(0, 0, 0, 0);
    
    return startDate;
  };

  const generateWeekDates = (startDate, numWeeks) => {
    const weeks = [];
    for (let i = 0; i < numWeeks; i++) {
      const weekStart = new Date(startDate);
      weekStart.setDate(startDate.getDate() + (i * 7));
      
      const weekEnd = new Date(weekStart);
      weekEnd.setDate(weekStart.getDate() + 6);
      
      weeks.push({
        weekNumber: i + 1,
        startDate: weekStart,
        endDate: weekEnd
      });
    }
    return weeks;
  };

  const loadCompletedWorkouts = async () => {
    try {
      const result = await api.getWorkouts();
      setCompletedWorkouts(result.workouts || []);
    } catch (err) {
      console.error('Error loading workouts:', err);
      // Don't fail if no workouts yet
    }
  };

  const loadData = async () => {
    setLoading(true);
    setError(null);
    try {
      // Load profile for units preference
      const profile = await api.getProfile();
      setUnits(profile.preferredUnits || 'lb');
      
      // Calculate program start date
      const startDate = getNextStartDay(profile.preferredStartDay || 'mon');
      
      // Try to load strength data
      try {
        const strength = await api.getStrength();
        
        // Generate program with existing strength data
        const template = await loadPlanTemplate();
        const generatedProgram = generateProgram(
          template,
          strength.trainingMaxes,
          profile.preferredUnits || 'lb'
        );
        setProgram(generatedProgram);
        
        // Generate week dates
        const dates = generateWeekDates(startDate, template.macrocycle.cycleLengthWeeks);
        setWeekDates(dates);
        
        // Load completed workouts
        await loadCompletedWorkouts();
      } catch (err) {
        // No strength data yet - need to collect it
        if (err.statusCode === 404) {
          setNeedsStrengthData(true);
        } else {
          throw err;
        }
      }
    } catch (err) {
      console.error('Error loading data:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSaveStrengthData = async () => {
    setLoading(true);
    setError(null);
    try {
      const lifts = ['squat', 'bench', 'deadlift', 'ohp'];
      for (const lift of lifts) {
        if (!oneRepMaxes[lift] || parseFloat(oneRepMaxes[lift]) <= 0) {
          throw new Error(`Please enter a valid ${lift} 1RM`);
        }
      }

      const orms = {
        squat: parseFloat(oneRepMaxes.squat),
        bench: parseFloat(oneRepMaxes.bench),
        deadlift: parseFloat(oneRepMaxes.deadlift),
        ohp: parseFloat(oneRepMaxes.ohp),
      };

      const trainingMaxes = calculateTrainingMaxes(orms, tmPercent / 100, units);

      const strengthData = {
        oneRepMaxes: orms,
        tmPolicy: {
          percent: tmPercent / 100,
          rounding: units === 'lb' ? '5lb' : '2.5kg',
        },
        trainingMaxes,
      };

      await api.updateStrength(strengthData);
      
      // Get profile for start day
      const profile = await api.getProfile();
      const startDate = getNextStartDay(profile.preferredStartDay || 'mon');
      
      // Generate program
      const template = await loadPlanTemplate();
      const generatedProgram = generateProgram(template, trainingMaxes, units);
      setProgram(generatedProgram);
      
      // Generate week dates
      const dates = generateWeekDates(startDate, template.macrocycle.cycleLengthWeeks);
      setWeekDates(dates);
      
      setNeedsStrengthData(false);
    } catch (err) {
      console.error('Error saving strength data:', err);
      console.error('Error details:', {
        message: err.message,
        code: err.code,
        statusCode: err.statusCode,
        requestId: err.requestId
      });
      setError(err.message || 'Failed to save strength data');
    } finally {
      setLoading(false);
    }
  };

  const handleSelectDay = async (date, weekNumber, session) => {
    setSelectedDay(date);
    setSelectedWeek(weekNumber);
    setSelectedSession(session);
    
    // Select exercises for this session
    const exercises = await selectExercisesForSession(session);
    
    // Initialize circuit data with pre-populated values
    if (session.circuit?.enabled && session.supplemental) {
      const rounds = session.circuit.rounds;
      const initialCircuit = [];
      
      for (let round = 0; round < rounds; round++) {
        // FSL set
        initialCircuit.push({
          round: round + 1,
          exercise: 'A',
          exerciseName: session.label,
          weight: session.supplemental.weight,
          reps: session.supplemental.repsRange[0],
          targetReps: `${session.supplemental.repsRange[0]}-${session.supplemental.repsRange[1]}`,
        });
        
        // Assistance exercises
        exercises.assistance.forEach((ex, idx) => {
          initialCircuit.push({
            round: round + 1,
            exercise: String.fromCharCode(66 + idx),
            exerciseName: ex.name,
            weight: 0,
            reps: ex.minReps,
            targetReps: `${ex.minReps}-${ex.maxReps}`,
          });
        });
      }
      
      setCircuitData(initialCircuit);
    }
  };

  const updateCircuitSet = (index, field, value) => {
    const updated = [...circuitData];
    updated[index][field] = value;
    setCircuitData(updated);
  };

  const handleCompleteWorkout = async () => {
    if (!selectedDay || !selectedSession) return;
    
    try {
      const workoutLog = {
        workoutDate: selectedDay.toISOString().split('T')[0],
        programWeek: selectedWeek,
        sessionId: selectedSession.sessionId,
        mainLift: {
          liftId: selectedSession.mainLiftId,
          sets: selectedSession.mainSets?.map(set => ({
            weight: set.weight,
            reps: set.targetReps,
            targetReps: set.targetReps,
            pctTM: set.pctTM,
          })) || [],
        },
        circuit: circuitData.length > 0 ? {
          rounds: selectedSession.circuit.rounds,
          sets: circuitData.map(set => ({
            round: set.round,
            exercise: set.exercise,
            exerciseName: set.exerciseName,
            weight: parseFloat(set.weight) || 0,
            reps: parseInt(set.reps) || 0,
            targetReps: set.targetReps,
          }))
        } : undefined,
      };
      
      await api.logWorkout(workoutLog);
      alert('Workout logged successfully!');
      
      // Reload completed workouts to update calendar
      await loadCompletedWorkouts();
      
      setSelectedDay(null);
      setSelectedSession(null);
      setCircuitData([]);
    } catch (err) {
      console.error('Error logging workout:', err);
      setError(err.message);
    }
  };

  if (loading) {
    return (
      <div className="program-view">
        <div className="program-container">
          <div className="spinner"></div>
          <p>Loading program...</p>
        </div>
      </div>
    );
  }

  if (needsStrengthData) {
    return (
      <div className="program-view">
        <div className="program-container">
          <div className="program-header">
            <button onClick={onClose} className="close-button" aria-label="Close">
              ✕
            </button>
            <h1>Set Your Starting Maxes</h1>
            <p className="subtitle">Enter your current 1 rep maxes to generate your personalized program</p>
          </div>

          {error && <div className="alert alert-error">{error}</div>}

          <div className="strength-form">
            <div className="units-selector">
              <button
                className={`unit-btn ${units === 'lb' ? 'active' : ''}`}
                onClick={() => setUnits('lb')}
              >
                LB
              </button>
              <button
                className={`unit-btn ${units === 'kg' ? 'active' : ''}`}
                onClick={() => setUnits('kg')}
              >
                KG
              </button>
            </div>

            <div className="lifts-grid">
              <div className="lift-input-card">
                <label>Squat</label>
                <div className="input-with-unit">
                  <input
                    type="number"
                    step="5"
                    value={oneRepMaxes.squat}
                    onChange={(e) => setOneRepMaxes({ ...oneRepMaxes, squat: e.target.value })}
                    placeholder="0"
                  />
                  <span className="unit-label">{units}</span>
                </div>
              </div>

              <div className="lift-input-card">
                <label>Bench Press</label>
                <div className="input-with-unit">
                  <input
                    type="number"
                    step="5"
                    value={oneRepMaxes.bench}
                    onChange={(e) => setOneRepMaxes({ ...oneRepMaxes, bench: e.target.value })}
                    placeholder="0"
                  />
                  <span className="unit-label">{units}</span>
                </div>
              </div>

              <div className="lift-input-card">
                <label>Deadlift</label>
                <div className="input-with-unit">
                  <input
                    type="number"
                    step="5"
                    value={oneRepMaxes.deadlift}
                    onChange={(e) => setOneRepMaxes({ ...oneRepMaxes, deadlift: e.target.value })}
                    placeholder="0"
                  />
                  <span className="unit-label">{units}</span>
                </div>
              </div>

              <div className="lift-input-card">
                <label>Overhead Press</label>
                <div className="input-with-unit">
                  <input
                    type="number"
                    step="5"
                    value={oneRepMaxes.ohp}
                    onChange={(e) => setOneRepMaxes({ ...oneRepMaxes, ohp: e.target.value })}
                    placeholder="0"
                  />
                  <span className="unit-label">{units}</span>
                </div>
              </div>
            </div>

            <div className="tm-percentage-card">
              <div className="tm-header">
                <label>Training Max</label>
                <div className="tm-value">{tmPercent}%</div>
              </div>
              <input
                type="range"
                min="70"
                max="95"
                step="5"
                value={tmPercent}
                onChange={(e) => setTmPercent(parseInt(e.target.value))}
                className="tm-slider"
              />
              <p className="tm-note">Your working weights will be calculated from {tmPercent}% of your 1RM</p>
            </div>

            <button onClick={handleSaveStrengthData} className="btn-primary btn-large" disabled={loading}>
              {loading ? 'Generating Program...' : 'Generate My Program'}
            </button>
          </div>
        </div>
      </div>
    );
  }

  if (!program) {
    return (
      <div className="program-view">
        <div className="program-container">
          <div className="alert alert-error">Failed to generate program</div>
          <button onClick={onClose} className="btn-secondary">Close</button>
        </div>
      </div>
    );
  }

  const currentWeek = program.weeks.find(w => w.weekNumber === selectedWeek);

  return (
    <div className="program-view">
      <div className="program-container">
          <div className="program-header">
            <button onClick={onClose} className="close-button" aria-label="Close">
              ✕
            </button>
            <h1>{program.programName}</h1>
            <p className="program-subtitle">12-Week Training Program</p>
          
          <div className="training-maxes">
            <h3>Your Training Maxes ({program.units})</h3>
            <div className="tm-grid">
              <div className="tm-item">
                <span className="tm-label">Squat:</span>
                <span className="tm-value">{program.trainingMaxes.squat} {program.units}</span>
              </div>
              <div className="tm-item">
                <span className="tm-label">Bench:</span>
                <span className="tm-value">{program.trainingMaxes.bench} {program.units}</span>
              </div>
              <div className="tm-item">
                <span className="tm-label">Deadlift:</span>
                <span className="tm-value">{program.trainingMaxes.deadlift} {program.units}</span>
              </div>
              <div className="tm-item">
                <span className="tm-label">OHP:</span>
                <span className="tm-value">{program.trainingMaxes.ohp} {program.units}</span>
              </div>
            </div>
          </div>
        </div>

        {error && <div className="alert alert-error">{error}</div>}

        <ProgramCalendar 
          program={program}
          weekDates={weekDates}
          completedWorkouts={completedWorkouts}
          onSelectWeek={setSelectedWeek}
          onSelectDay={handleSelectDay}
        />

        {selectedDay && selectedSession && (
          <div className="workout-modal-overlay" onClick={() => { setSelectedDay(null); setSelectedSession(null); }}>
            <div className="workout-modal" onClick={(e) => e.stopPropagation()}>
              <div className="workout-header">
                <button onClick={() => { setSelectedDay(null); setSelectedSession(null); }} className="btn-close-workout">
                  ✕
                </button>
                <h2>{selectedDay.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}</h2>
                <h3>{selectedSession.label}</h3>
              </div>

            {selectedSession.mainSets && (
              <>
                <div className="set-scheme-label">{selectedSession.setScheme}</div>
                <div className="sets-table">
                  <table>
                    <thead>
                      <tr>
                        <th>Set</th>
                        <th>Weight</th>
                        <th>Reps</th>
                        <th>% TM</th>
                      </tr>
                    </thead>
                    <tbody>
                      {selectedSession.mainSets.map((set, setIdx) => (
                        <tr key={setIdx}>
                          <td>{setIdx + 1}</td>
                          <td>{set.weight} {program.units}</td>
                          <td>{set.targetReps}{selectedSession.rules?.allowPRSets && setIdx === selectedSession.mainSets.length - 1 ? '+' : ''}</td>
                          <td>{Math.round(set.pctTM * 100)}%</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {selectedSession.supplemental && selectedSession.circuit?.enabled && circuitData.length > 0 && (
                  <div className="circuit-section">
                    <h4>Circuit - {selectedSession.circuit.rounds} Rounds</h4>
                    <p className="circuit-instructions">
                      Fill in actual weight and reps for each set. Pre-populated with target values.
                    </p>
                    
                    {Array.from({ length: selectedSession.circuit.rounds }).map((_, roundIdx) => (
                      <div key={roundIdx} className="circuit-round">
                        <h5>Round {roundIdx + 1}</h5>
                        <div className="circuit-sets">
                          {circuitData
                            .filter(set => set.round === roundIdx + 1)
                            .map((set, setIdx) => {
                              const globalIdx = circuitData.findIndex(s => s.round === set.round && s.exercise === set.exercise);
                              return (
                                <div key={setIdx} className="circuit-set-row">
                                  <div className="set-exercise-label">
                                    <span className="exercise-letter">{set.exercise}</span>
                                    <span className="exercise-name-small">{set.exerciseName}</span>
                                    <span className="target-reps">Target: {set.targetReps}</span>
                                  </div>
                                  <div className="set-inputs">
                                    <div className="input-group">
                                      <label>Weight</label>
                                      <input
                                        type="number"
                                        step="5"
                                        value={set.weight}
                                        onChange={(e) => updateCircuitSet(globalIdx, 'weight', e.target.value)}
                                        placeholder="0"
                                      />
                                      <span className="unit">{program.units}</span>
                                    </div>
                                    <div className="input-group">
                                      <label>Reps</label>
                                      <input
                                        type="number"
                                        value={set.reps}
                                        onChange={(e) => updateCircuitSet(globalIdx, 'reps', e.target.value)}
                                        placeholder="0"
                                      />
                                    </div>
                                  </div>
                                </div>
                              );
                            })}
                        </div>
                      </div>
                    ))}
                  </div>
                )}

                <button 
                  className="btn-complete-workout btn-large"
                  onClick={handleCompleteWorkout}
                >
                  Complete Workout
                </button>
              </>
            )}

            {selectedSession.isTestWeek && (
              <div className="test-week-notice">
                <p>🎯 Test Week - Work up to a new 1RM</p>
                <p className="small">Take your time, no grinders!</p>
              </div>
            )}

            {selectedSession.isReset && (
              <div className="reset-notice">
                <p>🔄 Reset Week</p>
                <p className="small">Update your 1RMs and start the next cycle</p>
              </div>
            )}
            </div>
          </div>
        )}

        {currentWeek && !selectedDay && (
          <div className="week-detail">
            <h2>Week {currentWeek.weekNumber}: {currentWeek.phaseLabel}</h2>
            
            <div className="sessions-grid">
              {currentWeek.sessions.map((session, idx) => (
                <div key={idx} className="session-card">
                  <h3>{session.label}</h3>
                  
                  {session.isTestWeek && (
                    <div className="test-week-notice">
                      <p>🎯 Test Week - Work up to a new 1RM</p>
                      <p className="small">Take your time, no grinders!</p>
                    </div>
                  )}
                  
                  {session.isReset && (
                    <div className="reset-notice">
                      <p>🔄 Reset Week</p>
                      <p className="small">Update your 1RMs and start the next cycle</p>
                    </div>
                  )}
                  
                  {session.mainSets && (
                    <>
                      <div className="set-scheme-label">{session.setScheme}</div>
                      <div className="sets-table">
                        <table>
                          <thead>
                            <tr>
                              <th>Set</th>
                              <th>Weight</th>
                              <th>Reps</th>
                              <th>% TM</th>
                            </tr>
                          </thead>
                          <tbody>
                            {session.mainSets.map((set, setIdx) => (
                              <tr key={setIdx}>
                                <td>{setIdx + 1}</td>
                                <td>{set.weight} {program.units}</td>
                                <td>{set.targetReps}{session.rules?.allowPRSets && setIdx === session.mainSets.length - 1 ? '+' : ''}</td>
                                <td>{Math.round(set.pctTM * 100)}%</td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>

                      {session.supplemental && (
                        <div className="supplemental-section">
                          <h4>{session.supplemental.label}</h4>
                          <p>
                            {session.supplemental.sets} sets × {session.supplemental.repsRange[0]}-{session.supplemental.repsRange[1]} reps @ {session.supplemental.weight} {program.units}
                          </p>
                          {session.circuit?.enabled && (
                            <p className="circuit-note">
                              Circuit style: {session.circuit.rounds} rounds
                            </p>
                          )}
                        </div>
                      )}

                      {session.assistanceSlots && session.assistanceSlots.length > 0 && (
                        <div className="assistance-section">
                          <h4>Assistance Work</h4>
                          <ul>
                            {session.assistanceSlots.map((slot, slotIdx) => (
                              <li key={slotIdx}>
                                {slot.slotId.replace(/_/g, ' ')}: {slot.minReps}-{slot.maxReps} reps
                              </li>
                            ))}
                          </ul>
                        </div>
                      )}

                      <button 
                        className="btn-complete-workout"
                        onClick={() => handleCompleteWorkout(currentWeek, session)}
                      >
                        Complete Workout
                      </button>
                    </>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default ProgramView;

