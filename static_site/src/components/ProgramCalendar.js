import React, { useState, useEffect } from 'react';
import { api } from '../api/client';
import { getDefaultDayAssignments, generateWorkoutForType, DAY_TYPES } from '../utils/nonLiftingDays';
import './ProgramCalendar.css';

function ProgramCalendar({ program, weekDates, completedWorkouts, onSelectWeek, onSelectDay, userProfile }) {
  const [currentMonth, setCurrentMonth] = useState(new Date());
  const [selectedDate, setSelectedDate] = useState(null);
  const [draggedDay, setDraggedDay] = useState(null);
  const [dragOverDay, setDragOverDay] = useState(null);
  const [daySwaps, setDaySwaps] = useState({});
  const [dayAssignments, setDayAssignments] = useState({});
  const [isLoadingSwaps, setIsLoadingSwaps] = useState(true);
  const [showDayTypeMenu, setShowDayTypeMenu] = useState(null);
  const [generatedWorkouts, setGeneratedWorkouts] = useState({});

  useEffect(() => {
    loadScheduleCustomizations();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const loadScheduleCustomizations = async () => {
    try {
      setIsLoadingSwaps(true);
      const profile = await api.getProfile();
      
      const result = await api.getScheduleCustomizations();
      if (result.daySwaps) {
        setDaySwaps(result.daySwaps);
      }
      if (result.dayAssignments) {
        setDayAssignments(result.dayAssignments);
      } else {
        const defaultAssignments = getDefaultDayAssignments(
          profile.trainingDaysPerWeek || 4,
          profile.nonLiftingDayMode || 'gpp'
        );
        setDayAssignments(defaultAssignments);
      }
    } catch (err) {
      if (err.statusCode !== 404) {
        console.error('Error loading schedule customizations:', err);
      }
      try {
        const profile = await api.getProfile();
        const defaultAssignments = getDefaultDayAssignments(
          profile.trainingDaysPerWeek || 4,
          profile.nonLiftingDayMode || 'gpp'
        );
        setDayAssignments(defaultAssignments);
      } catch (profileErr) {
        console.error('Error loading profile:', profileErr);
      }
    } finally {
      setIsLoadingSwaps(false);
    }
  };

  const saveScheduleCustomizations = async (swaps, assignments) => {
    try {
      await api.updateScheduleCustomizations({ 
        daySwaps: swaps,
        dayAssignments: assignments || dayAssignments
      });
    } catch (err) {
      console.error('Error saving schedule customizations:', err);
      alert('Failed to save schedule changes. Please try again.');
    }
  };

  const getDaysInMonth = (date) => {
    const year = date.getFullYear();
    const month = date.getMonth();
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const daysInMonth = lastDay.getDate();
    const startingDayOfWeek = firstDay.getDay();

    return { daysInMonth, startingDayOfWeek, year, month };
  };

  const getWeekForDate = (date) => {
    const dateStr = date.toISOString().split('T')[0];
    for (let i = 0; i < weekDates.length; i++) {
      const weekDate = weekDates[i];
      const startStr = weekDate.startDate.toISOString().split('T')[0];
      const endStr = weekDate.endDate.toISOString().split('T')[0];
      if (dateStr >= startStr && dateStr <= endStr) {
        return { 
          ...weekDate, 
          phase: program.weeks[i].phase, 
          phaseLabel: program.weeks[i].phaseLabel,
          sessions: program.weeks[i].sessions
        };
      }
    }
    return null;
  };

  useEffect(() => {
    const generateWorkouts = async () => {
      const workouts = {};
      for (const assignment of Object.values(dayAssignments)) {
        if (assignment.type !== DAY_TYPES.MAIN) {
          const key = `${assignment.type}`;
          if (!workouts[key]) {
            const programContext = {
              weekPhase: program?.weeks?.[0]?.phase || 'LEADER',
              nextSession: null,
            };
            workouts[key] = await generateWorkoutForType(assignment.type, userProfile, programContext);
          }
        }
      }
      setGeneratedWorkouts(workouts);
    };
    
    if (Object.keys(dayAssignments).length > 0) {
      generateWorkouts();
    }
  }, [dayAssignments, userProfile, program]);

  const getOriginalSessionForDay = (date, weekInfo) => {
    if (!weekInfo || !weekInfo.sessions) return null;
    
    const dayOfWeek = date.getDay();
    const assignment = dayAssignments[dayOfWeek];
    
    if (!assignment) return null;
    
    if (assignment.type === DAY_TYPES.MAIN) {
      return weekInfo.sessions[assignment.index];
    }
    
    return generatedWorkouts[assignment.type] || null;
  };
  
  const getSessionForDay = (date, weekInfo) => {
    if (!weekInfo) return null;
    
    const dateStr = date.toISOString().split('T')[0];
    
    if (daySwaps[dateStr]) {
      return daySwaps[dateStr];
    }
    
    return getOriginalSessionForDay(date, weekInfo);
  };

  const isWorkoutCompleted = (date) => {
    const dateStr = date.toISOString().split('T')[0];
    return completedWorkouts.some(workout => workout.workoutDate === dateStr);
  };

  const handleDayClick = (date, weekInfo) => {
    if (!weekInfo) return;
    const session = getSessionForDay(date, weekInfo);
    if (session) {
      setSelectedDate(date);
      onSelectDay(date, weekInfo.weekNumber, session);
    }
  };

  const changeMonth = (delta) => {
    const newDate = new Date(currentMonth);
    newDate.setMonth(currentMonth.getMonth() + delta);
    setCurrentMonth(newDate);
  };

  const handleDragStart = (e, date, weekInfo, session) => {
    if (!session || isWorkoutCompleted(date)) return;
    
    setDraggedDay({ date, weekInfo, session });
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/html', e.currentTarget);
    
    const element = e.currentTarget;
    setTimeout(() => {
      if (element) {
        element.style.opacity = '0.4';
      }
    }, 0);
  };

  const handleDragEnd = (e) => {
    if (e.currentTarget) {
      e.currentTarget.style.opacity = '1';
    }
    setDraggedDay(null);
    setDragOverDay(null);
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    return false;
  };

  const handleDragEnter = (e, date, weekInfo, session) => {
    if (!draggedDay || !session || isWorkoutCompleted(date)) return;
    
    if (draggedDay.weekInfo.weekNumber === weekInfo.weekNumber) {
      setDragOverDay(date);
    }
  };

  const handleDragLeave = (e) => {
    if (e.currentTarget === e.target) {
      setDragOverDay(null);
    }
  };

  const handleDrop = (e, targetDate, targetWeekInfo, targetSession) => {
    e.stopPropagation();
    e.preventDefault();
    
    if (!draggedDay || !targetSession || isWorkoutCompleted(targetDate)) {
      setDraggedDay(null);
      setDragOverDay(null);
      return;
    }
    
    if (draggedDay.weekInfo.weekNumber !== targetWeekInfo.weekNumber) {
      setDraggedDay(null);
      setDragOverDay(null);
      return;
    }
    
    const draggedDateStr = draggedDay.date.toISOString().split('T')[0];
    const targetDateStr = targetDate.toISOString().split('T')[0];
    
    if (draggedDateStr === targetDateStr) {
      setDraggedDay(null);
      setDragOverDay(null);
      return;
    }
    
    const draggedCurrentSession = draggedDay.session;
    const targetCurrentSession = targetSession;
    
    const newSwaps = { ...daySwaps };
    newSwaps[draggedDateStr] = targetCurrentSession;
    newSwaps[targetDateStr] = draggedCurrentSession;
    
    setDaySwaps(newSwaps);
    setDraggedDay(null);
    setDragOverDay(null);
    
    saveScheduleCustomizations(newSwaps);
  };

  const renderCalendar = () => {
    const { daysInMonth, startingDayOfWeek, year, month } = getDaysInMonth(currentMonth);
    const days = [];

    for (let i = 0; i < startingDayOfWeek; i++) {
      days.push(<div key={`empty-${i}`} className="calendar-day empty"></div>);
    }

    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(year, month, day);
      const weekInfo = getWeekForDate(date);
      const session = weekInfo ? getSessionForDay(date, weekInfo) : null;
      const isSelected = selectedDate && date.toDateString() === selectedDate.toDateString();
      const isCompleted = isWorkoutCompleted(date);
      const isDragging = draggedDay && draggedDay.date.toDateString() === date.toDateString();
      const isDragOver = dragOverDay && dragOverDay.toDateString() === date.toDateString();
      const canDrop = session && !isCompleted && draggedDay && 
                      draggedDay.weekInfo.weekNumber === weekInfo?.weekNumber &&
                      draggedDay.date.toDateString() !== date.toDateString();
      const dayOfWeek = date.getDay();
      const assignment = dayAssignments[dayOfWeek];
      const isNonMainDay = assignment && assignment.type !== DAY_TYPES.MAIN;
      
      days.push(
        <div
          key={day}
          className={`calendar-day ${weekInfo ? 'has-workout' : ''} ${session ? 'has-session' : ''} ${isSelected ? 'selected' : ''} ${isCompleted ? 'completed' : ''} ${weekInfo ? `phase-${weekInfo.phase.toLowerCase()}` : ''} ${isDragging ? 'dragging' : ''} ${isDragOver ? 'drag-over' : ''} ${canDrop ? 'can-drop' : ''} ${isNonMainDay ? 'non-main-day' : ''}`}
          onClick={() => handleDayClick(date, weekInfo)}
          draggable={session && !isCompleted}
          onDragStart={(e) => handleDragStart(e, date, weekInfo, session)}
          onDragEnd={handleDragEnd}
          onDragOver={handleDragOver}
          onDragEnter={(e) => handleDragEnter(e, date, weekInfo, session)}
          onDragLeave={handleDragLeave}
          onDrop={(e) => handleDrop(e, date, weekInfo, session)}
          onContextMenu={(e) => {
            if (isNonMainDay && weekInfo) {
              e.preventDefault();
              setShowDayTypeMenu({ date, dayOfWeek, x: e.clientX, y: e.clientY });
            }
          }}
        >
          <div className="day-number">
            {day}
            {isCompleted && <span className="completed-badge">✓</span>}
          </div>
          {weekInfo && (
            <div className="day-info">
              <div className="week-label">W{weekInfo.weekNumber}</div>
              {session && <div className="session-label">{session.label}</div>}
            </div>
          )}
          {session && !isCompleted && (
            <div className="drag-handle" title="Drag to swap days">⋮⋮</div>
          )}
          {isNonMainDay && !isCompleted && (
            <button 
              className="change-day-btn"
              onClick={(e) => {
                e.stopPropagation();
                setShowDayTypeMenu({ date, dayOfWeek, x: e.clientX, y: e.clientY });
              }}
              title="Change day type"
            >
              ⚙️
            </button>
          )}
        </div>
      );
    }

    return days;
  };

  const handleResetSchedule = async () => {
    if (!window.confirm('Reset all workout day swaps? This will restore the original schedule.')) {
      return;
    }
    
    setDaySwaps({});
    await saveScheduleCustomizations({}, dayAssignments);
  };

  const handleChangeDayType = async (dayOfWeek, newType) => {
    const newAssignments = { ...dayAssignments };
    
    if (newType === DAY_TYPES.MAIN) {
      alert('Cannot change to main lift day. Use drag and drop to swap main lifts.');
      return;
    }
    
    newAssignments[dayOfWeek] = { type: newType };
    setDayAssignments(newAssignments);
    await saveScheduleCustomizations(daySwaps, newAssignments);
    setShowDayTypeMenu(null);
  };

  const monthName = currentMonth.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
  const hasSwaps = Object.keys(daySwaps).length > 0;

  return (
    <div className="program-calendar">
      <div className="calendar-header">
        <button onClick={() => changeMonth(-1)} className="month-nav">←</button>
        <h3>{monthName}</h3>
        <button onClick={() => changeMonth(1)} className="month-nav">→</button>
      </div>
      
      {isLoadingSwaps && (
        <div className="calendar-loading">Loading schedule...</div>
      )}
      
      {hasSwaps && !isLoadingSwaps && (
        <div className="schedule-customization-notice">
          <span>📅 You have customized workout days</span>
          <button onClick={handleResetSchedule} className="btn-reset-schedule">
            Reset Schedule
          </button>
        </div>
      )}
      
      <div className="calendar-weekdays">
        <div>Sun</div>
        <div>Mon</div>
        <div>Tue</div>
        <div>Wed</div>
        <div>Thu</div>
        <div>Fri</div>
        <div>Sat</div>
      </div>
      
      <div className="calendar-grid">
        {renderCalendar()}
      </div>

      <div className="calendar-legend">
        <div className="legend-item">
          <div className="legend-color phase-leader"></div>
          <span>Leader</span>
        </div>
        <div className="legend-item">
          <div className="legend-color phase-anchor"></div>
          <span>Anchor</span>
        </div>
        <div className="legend-item">
          <div className="legend-color phase-deload_1"></div>
          <span>Deload</span>
        </div>
        <div className="legend-item">
          <div className="legend-color phase-test"></div>
          <span>Test</span>
        </div>
        <div className="legend-item">
          <div className="legend-color phase-reset"></div>
          <span>Reset</span>
        </div>
      </div>

      {showDayTypeMenu && (
        <>
          <div className="day-type-menu-overlay" onClick={() => setShowDayTypeMenu(null)} />
          <div 
            className="day-type-menu"
            style={{ 
              position: 'fixed',
              left: `${showDayTypeMenu.x}px`,
              top: `${showDayTypeMenu.y}px`,
            }}
          >
            <div className="day-type-menu-header">Change Day Type</div>
            <button onClick={() => handleChangeDayType(showDayTypeMenu.dayOfWeek, DAY_TYPES.GPP)}>
              GPP / Krypteia
            </button>
            <button onClick={() => handleChangeDayType(showDayTypeMenu.dayOfWeek, DAY_TYPES.MOBILITY)}>
              Mobility
            </button>
            <button onClick={() => handleChangeDayType(showDayTypeMenu.dayOfWeek, DAY_TYPES.PILATES)}>
              Pilates
            </button>
            <button onClick={() => handleChangeDayType(showDayTypeMenu.dayOfWeek, DAY_TYPES.REST)}>
              Active Recovery
            </button>
          </div>
        </>
      )}
    </div>
  );
}

export default ProgramCalendar;

