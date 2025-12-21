import React, { useState, useEffect } from 'react';
import { 
  fetchExerciseLibrary, 
  filterByCategory, 
  filterByConstraints,
  searchExercises,
  groupByCategory 
} from '../api/exerciseLibrary';
import './ExerciseLibrary.css';

function ExerciseLibrary({ onClose, userProfile }) {
  const [library, setLibrary] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [showSafeOnly, setShowSafeOnly] = useState(true);
  const [selectedExercise, setSelectedExercise] = useState(null);

  useEffect(() => {
    loadLibrary();
  }, []);

  const loadLibrary = async () => {
    try {
      setLoading(true);
      const lib = await fetchExerciseLibrary();
      setLibrary(lib);
      setError(null);
    } catch (err) {
      console.error('Failed to load exercise library:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const getFilteredExercises = () => {
    if (!library) return [];

    let exercises = library.exercises;

    // Filter by category
    if (selectedCategory !== 'all') {
      exercises = filterByCategory(exercises, selectedCategory);
    }

    // Filter by constraints if enabled
    if (showSafeOnly && userProfile?.constraints) {
      exercises = filterByConstraints(exercises, userProfile.constraints);
    }

    // Search
    if (searchQuery.trim()) {
      exercises = searchExercises(exercises, searchQuery);
    }

    return exercises;
  };

  const filteredExercises = getFilteredExercises();
  const exercisesByCategory = groupByCategory(filteredExercises);

  const categories = [
    { value: 'all', label: 'All', icon: '📚' },
    { value: 'main', label: 'Main Lifts', icon: '💪' },
    { value: 'supplemental', label: 'Supplemental', icon: '🏋️' },
    { value: 'accessory', label: 'Accessories', icon: '🎯' },
    { value: 'conditioning', label: 'Conditioning', icon: '🏃' },
    { value: 'mobility', label: 'Mobility', icon: '🧘' },
  ];

  const getCategoryColor = (category) => {
    const colors = {
      main: '#667eea',
      supplemental: '#764ba2',
      accessory: '#11998e',
      conditioning: '#f093fb',
      mobility: '#4facfe',
    };
    return colors[category] || '#999';
  };

  const getFatigueColor = (score) => {
    if (score >= 4) return '#ff6b6b';
    if (score >= 3) return '#ffa500';
    return '#4caf50';
  };

  if (loading) {
    return (
      <div className="exercise-library-modal">
        <div className="exercise-library-content">
          <div className="loading-state">
            <div className="spinner"></div>
            <p>Loading exercise library...</p>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="exercise-library-modal">
        <div className="exercise-library-content">
          <div className="error-state">
            <h2>❌ Error Loading Library</h2>
            <p>{error}</p>
            <button onClick={loadLibrary} className="retry-button">Retry</button>
            <button onClick={onClose} className="close-button">Close</button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="exercise-library-modal" onClick={onClose}>
      <div className="exercise-library-content" onClick={(e) => e.stopPropagation()}>
        <div className="library-header">
          <div className="header-top">
            <h2>📚 Exercise Library</h2>
            <button onClick={onClose} className="close-btn" aria-label="Close">×</button>
          </div>
          
          <div className="library-info">
            <span>Version {library.version}</span>
            <span>•</span>
            <span>{library.exercises.length} exercises</span>
            {showSafeOnly && userProfile?.constraints?.length > 0 && (
              <>
                <span>•</span>
                <span className="safe-badge">Safe for your constraints</span>
              </>
            )}
          </div>

          <div className="search-bar">
            <input
              type="text"
              placeholder="Search exercises..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="search-input"
            />
          </div>

          <div className="category-tabs">
            {categories.map(cat => (
              <button
                key={cat.value}
                onClick={() => setSelectedCategory(cat.value)}
                className={`category-tab ${selectedCategory === cat.value ? 'active' : ''}`}
              >
                <span className="category-icon">{cat.icon}</span>
                <span className="category-label">{cat.label}</span>
              </button>
            ))}
          </div>

          {userProfile?.constraints?.length > 0 && (
            <div className="filter-options">
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  checked={showSafeOnly}
                  onChange={(e) => setShowSafeOnly(e.target.checked)}
                />
                <span>Show only safe exercises for my constraints</span>
              </label>
            </div>
          )}
        </div>

        <div className="library-body">
          {filteredExercises.length === 0 ? (
            <div className="empty-state">
              <p>No exercises found</p>
              {searchQuery && (
                <button onClick={() => setSearchQuery('')} className="clear-search-btn">
                  Clear search
                </button>
              )}
            </div>
          ) : (
            <div className="exercises-list">
              {selectedCategory === 'all' ? (
                // Group by category when showing all
                Object.entries(exercisesByCategory).map(([category, exercises]) => (
                  <div key={category} className="category-group">
                    <h3 className="category-heading" style={{ color: getCategoryColor(category) }}>
                      {category.charAt(0).toUpperCase() + category.slice(1)} ({exercises.length})
                    </h3>
                    <div className="exercises-grid">
                      {exercises.map(exercise => (
                        <ExerciseCard
                          key={exercise.exerciseId}
                          exercise={exercise}
                          onClick={() => setSelectedExercise(exercise)}
                          getCategoryColor={getCategoryColor}
                          getFatigueColor={getFatigueColor}
                        />
                      ))}
                    </div>
                  </div>
                ))
              ) : (
                // Simple grid when filtered by category
                <div className="exercises-grid">
                  {filteredExercises.map(exercise => (
                    <ExerciseCard
                      key={exercise.exerciseId}
                      exercise={exercise}
                      onClick={() => setSelectedExercise(exercise)}
                      getCategoryColor={getCategoryColor}
                      getFatigueColor={getFatigueColor}
                    />
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        {selectedExercise && (
          <ExerciseDetail
            exercise={selectedExercise}
            onClose={() => setSelectedExercise(null)}
            getCategoryColor={getCategoryColor}
            getFatigueColor={getFatigueColor}
          />
        )}
      </div>
    </div>
  );
}

function ExerciseCard({ exercise, onClick, getCategoryColor, getFatigueColor }) {
  return (
    <div className="exercise-card" onClick={onClick}>
      <div className="exercise-card-header">
        <h4 className="exercise-name">{exercise.name}</h4>
        <span 
          className="category-badge" 
          style={{ backgroundColor: getCategoryColor(exercise.category) }}
        >
          {exercise.category}
        </span>
      </div>
      
      <div className="exercise-card-body">
        <div className="exercise-equipment">
          {exercise.equipment.slice(0, 3).map(eq => (
            <span key={eq} className="equipment-tag">{eq}</span>
          ))}
          {exercise.equipment.length > 3 && (
            <span className="equipment-tag">+{exercise.equipment.length - 3}</span>
          )}
        </div>
        
        <div className="exercise-meta">
          <span 
            className="fatigue-badge" 
            style={{ backgroundColor: getFatigueColor(exercise.fatigueScore) }}
          >
            Fatigue: {exercise.fatigueScore}/5
          </span>
        </div>
      </div>
    </div>
  );
}

function ExerciseDetail({ exercise, onClose, getCategoryColor, getFatigueColor }) {
  return (
    <div className="exercise-detail-modal" onClick={onClose}>
      <div className="exercise-detail-content" onClick={(e) => e.stopPropagation()}>
        <div className="detail-header">
          <div>
            <h2>{exercise.name}</h2>
            <span 
              className="category-badge large" 
              style={{ backgroundColor: getCategoryColor(exercise.category) }}
            >
              {exercise.category}
            </span>
          </div>
          <button onClick={onClose} className="close-btn" aria-label="Close">×</button>
        </div>

        <div className="detail-body">
          <div className="detail-section">
            <h3>📝 Notes</h3>
            <p>{exercise.notes || 'No notes available'}</p>
          </div>

          <div className="detail-section">
            <h3>🏋️ Equipment</h3>
            <div className="tags-list">
              {exercise.equipment.map(eq => (
                <span key={eq} className="tag equipment-tag">{eq}</span>
              ))}
            </div>
          </div>

          <div className="detail-section">
            <h3>🎯 Slot Tags</h3>
            <div className="tags-list">
              {exercise.slotTags.map(tag => (
                <span key={tag} className="tag slot-tag">{tag}</span>
              ))}
            </div>
          </div>

          <div className="detail-section">
            <h3>💪 Movement Patterns</h3>
            <div className="tags-list">
              {exercise.movementPatterns.map(pattern => (
                <span key={pattern} className="tag pattern-tag">{pattern}</span>
              ))}
            </div>
          </div>

          {exercise.constraintsBlocked.length > 0 && (
            <div className="detail-section">
              <h3>⚠️ Blocked by Constraints</h3>
              <div className="tags-list">
                {exercise.constraintsBlocked.map(constraint => (
                  <span key={constraint} className="tag constraint-tag">{constraint}</span>
                ))}
              </div>
            </div>
          )}

          <div className="detail-section">
            <h3>📊 Fatigue Score</h3>
            <div className="fatigue-display">
              <span 
                className="fatigue-score" 
                style={{ backgroundColor: getFatigueColor(exercise.fatigueScore) }}
              >
                {exercise.fatigueScore}/5
              </span>
              <span className="fatigue-description">
                {exercise.fatigueScore >= 4 ? 'High fatigue' : 
                 exercise.fatigueScore >= 3 ? 'Moderate fatigue' : 'Low fatigue'}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default ExerciseLibrary;


