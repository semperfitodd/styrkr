import SwiftUI

struct ExerciseLibraryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var libraryService = ExerciseLibraryService.shared
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var showSafeOnly = true
    @State private var selectedExercise: Exercise? = nil
    
    let userProfile: Profile?
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "1a1a1a"), Color(hex: "2d2d2d")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if libraryService.isLoading {
                    loadingView
                } else if let error = libraryService.error {
                    errorView(error)
                } else if let library = libraryService.library {
                    libraryContent(library)
                } else {
                    emptyView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("📚 Exercise Library")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await libraryService.fetchLibrary(forceRefresh: true) } }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            await libraryService.fetchLibrary()
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }
    
    // MARK: - Library Content
    
    @ViewBuilder
    private func libraryContent(_ library: ExerciseLibrary) -> some View {
        VStack(spacing: 0) {
            // Library Info
            libraryInfoBar(library)
            
            // Search Bar
            searchBar
            
            // Category Filter
            categoryFilter
            
            
            // Exercise List
            exerciseList(library)
        }
    }
    
    private func libraryInfoBar(_ library: ExerciseLibrary) -> some View {
        HStack {
            Text("Version \(library.version)")
                .font(.caption)
                .foregroundColor(.gray)
            Text("•")
                .foregroundColor(.gray)
            Text("\(library.exercises.count) exercises")
                .font(.caption)
                .foregroundColor(.gray)
            
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search exercises...", text: $searchText)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryButton(
                    title: "All",
                    icon: "📚",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 10)
    }
    
    private var safeOnlyToggle: some View {
        Toggle("Show only safe exercises", isOn: $showSafeOnly)
            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "667eea")))
            .foregroundColor(.white)
            .padding(.horizontal)
            .padding(.bottom, 10)
    }
    
    private func exerciseList(_ library: ExerciseLibrary) -> some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                let filtered = filteredExercises(library)
                
                if filtered.isEmpty {
                    emptyResultsView
                } else if selectedCategory == nil {
                    // Group by category when showing all
                    ForEach(ExerciseCategory.allCases, id: \.self) { category in
                        let categoryExercises = filtered.filter { $0.category == category }
                        if !categoryExercises.isEmpty {
                            CategorySection(
                                category: category,
                                exercises: categoryExercises,
                                onSelect: { selectedExercise = $0 }
                            )
                        }
                    }
                } else {
                    // Simple list when filtered
                    ForEach(filtered) { exercise in
                        ExerciseCard(exercise: exercise)
                            .onTapGesture {
                                selectedExercise = exercise
                            }
                    }
                }
            }
            .padding()
        }
    }
    
    private func filteredExercises(_ library: ExerciseLibrary) -> [Exercise] {
        var exercises = library.exercises
        
        // Filter by category
        if let category = selectedCategory {
            exercises = exercises.filterByCategory(category)
        }
        
        
        // Search
        if !searchText.isEmpty {
            exercises = exercises.search(searchText)
        }
        
        return exercises
    }
    
    // MARK: - Loading & Error States
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            Text("Loading exercise library...")
                .foregroundColor(.white)
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            Text("Error Loading Library")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(error)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: { Task { await libraryService.fetchLibrary(forceRefresh: true) } }) {
                Text("Retry")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(hex: "667eea"))
                    .cornerRadius(12)
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Library Loaded")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Button(action: { Task { await libraryService.fetchLibrary() } }) {
                Text("Load Library")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(hex: "667eea"))
                    .cornerRadius(12)
            }
        }
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No exercises found")
                .font(.title3)
                .foregroundColor(.white)
            if !searchText.isEmpty {
                Button("Clear search") {
                    searchText = ""
                }
                .foregroundColor(Color(hex: "667eea"))
            }
        }
        .padding(.top, 60)
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ?
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.05)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let category: ExerciseCategory
    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(category.icon)
                    .font(.title2)
                Text(category.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: category.color))
                Text("(\(exercises.count))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            ForEach(exercises) { exercise in
                ExerciseCard(exercise: exercise)
                    .onTapGesture {
                        onSelect(exercise)
                    }
            }
        }
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        ForEach(exercise.equipment.prefix(3), id: \.self) { equipment in
                            Text(equipment)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.gray)
                                .cornerRadius(6)
                        }
                        if exercise.equipment.count > 3 {
                            Text("+\(exercise.equipment.count - 3)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.gray)
                                .cornerRadius(6)
                        }
                    }
                }
                
                Spacer()
                
                Text(exercise.category.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: exercise.category.color))
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            
            HStack {
                Text("Fatigue: \(exercise.fatigueScore)/5")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: exercise.fatigueColor))
                    .foregroundColor(.white)
                    .cornerRadius(6)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Exercise Detail View
struct ExerciseDetailView: View {
    @Environment(\.dismiss) var dismiss
    let exercise: Exercise
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "1a1a1a"), Color(hex: "2d2d2d")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        // Header
                        VStack(alignment: .leading, spacing: 10) {
                            Text(exercise.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(exercise.category.rawValue.uppercased())
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(hex: exercise.category.color))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        // Notes
                        DetailSection(title: "📝 Notes") {
                            Text(exercise.notes)
                                .foregroundColor(.gray)
                        }
                        
                        // Equipment
                        DetailSection(title: "🏋️ Equipment") {
                            TagList(tags: exercise.equipment, color: "667eea")
                        }
                        
                        // Slot Tags
                        DetailSection(title: "🎯 Slot Tags") {
                            TagList(tags: exercise.slotTags, color: "11998e")
                        }
                        
                        // Movement Patterns
                        DetailSection(title: "💪 Movement Patterns") {
                            TagList(tags: exercise.movementPatterns, color: "764ba2")
                        }
                        
                        // Constraints
                        if !exercise.constraintsBlocked.isEmpty {
                            DetailSection(title: "⚠️ Blocked by Constraints") {
                                TagList(tags: exercise.constraintsBlocked, color: "ff6b6b")
                            }
                        }
                        
                        // Fatigue Score
                        DetailSection(title: "📊 Fatigue Score") {
                            HStack {
                                Text("\(exercise.fatigueScore)/5")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(hex: exercise.fatigueColor))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                
                                Text(exercise.fatigueLevel + " fatigue")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            content()
        }
    }
}

struct TagList: View {
    let tags: [String]
    let color: String
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: color).opacity(0.2))
                    .foregroundColor(Color(hex: color))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: color).opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    ExerciseLibraryView(userProfile: nil)
}


