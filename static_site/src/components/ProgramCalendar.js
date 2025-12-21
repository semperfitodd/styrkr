import React, { useState } from 'react';
import './ProgramCalendar.css';

function ProgramCalendar({ program, weekDates, completedWorkouts, onSelectWeek, onSelectDay }) {
  const [currentMonth, setCurrentMonth] = useState(new Date());
  const [selectedDate, setSelectedDate] = useState(null);

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

  const getSessionForDay = (date, weekInfo) => {
    if (!weekInfo || !weekInfo.sessions) return null;
    const dayOfWeek = date.getDay();
    // Map day of week to session index (0-3 for 4 sessions)
    // Assuming Mon/Tue/Thu/Fri pattern
    const sessionMap = {
      1: 0, // Monday - Squat
      2: 1, // Tuesday - Bench
      4: 2, // Thursday - Deadlift
      5: 3, // Friday - OHP
    };
    const sessionIndex = sessionMap[dayOfWeek];
    return sessionIndex !== undefined ? weekInfo.sessions[sessionIndex] : null;
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

  const renderCalendar = () => {
    const { daysInMonth, startingDayOfWeek, year, month } = getDaysInMonth(currentMonth);
    const days = [];

    // Empty cells for days before month starts
    for (let i = 0; i < startingDayOfWeek; i++) {
      days.push(<div key={`empty-${i}`} className="calendar-day empty"></div>);
    }

    // Days of the month
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(year, month, day);
      const weekInfo = getWeekForDate(date);
      const session = weekInfo ? getSessionForDay(date, weekInfo) : null;
      const isSelected = selectedDate && date.toDateString() === selectedDate.toDateString();
      const isCompleted = isWorkoutCompleted(date);
      
      days.push(
        <div
          key={day}
          className={`calendar-day ${weekInfo ? 'has-workout' : ''} ${session ? 'has-session' : ''} ${isSelected ? 'selected' : ''} ${isCompleted ? 'completed' : ''} ${weekInfo ? `phase-${weekInfo.phase.toLowerCase()}` : ''}`}
          onClick={() => handleDayClick(date, weekInfo)}
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
        </div>
      );
    }

    return days;
  };

  const monthName = currentMonth.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });

  return (
    <div className="program-calendar">
      <div className="calendar-header">
        <button onClick={() => changeMonth(-1)} className="month-nav">←</button>
        <h3>{monthName}</h3>
        <button onClick={() => changeMonth(1)} className="month-nav">→</button>
      </div>
      
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
    </div>
  );
}

export default ProgramCalendar;

