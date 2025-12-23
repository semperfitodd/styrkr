import SwiftUI
import UniformTypeIdentifiers

struct ProgramCalendarView: View {
    let program: GeneratedProgram
    let completedWorkouts: Set<String>
    let onDaySelected: (Date, ProgramSession?) -> Void
    @Binding var daySwaps: [String: [String: Any]]
    let onSwapUpdate: ([String: [String: Any]]) -> Void
    
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date?
    @State private var draggedDate: Date?
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color(hex: "2d2d2d"))
            
            // Day headers
            HStack(spacing: 0) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
            .background(Color(hex: "1a1a1a"))
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            session: sessionForDate(date),
                            isCompleted: isDateCompleted(date),
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            isDragging: draggedDate != nil && calendar.isDate(date, inSameDayAs: draggedDate!)
                        )
                        .onTapGesture {
                            selectedDate = date
                            onDaySelected(date, sessionForDate(date))
                        }
                        .onDrag {
                            if sessionForDate(date) != nil && isInCurrentWeek(date) {
                                draggedDate = date
                                return NSItemProvider(object: dateFormatter.string(from: date) as NSString)
                            }
                            return NSItemProvider()
                        }
                        .onDrop(of: [.text], delegate: DayDropDelegate(
                            targetDate: date,
                            draggedDate: $draggedDate,
                            program: program,
                            daySwaps: $daySwaps,
                            calendar: calendar,
                            dateFormatter: dateFormatter,
                            isInCurrentWeek: isInCurrentWeek,
                            sessionForDate: sessionForDate,
                            onSwapUpdate: onSwapUpdate
                        ))
                    } else {
                        Color.clear
                            .frame(height: 70)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(hex: "1a1a1a"))
        .cornerRadius(15)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var date = monthFirstWeek.start
        
        while days.count < 42 {
            if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                days.append(date)
            } else if days.isEmpty || days.last != nil {
                days.append(nil)
            } else {
                break
            }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        return days
    }
    
    private func sessionForDate(_ date: Date) -> ProgramSession? {
        let dateString = dateFormatter.string(from: date)
        
        if let swappedSessionData = daySwaps[dateString],
           let sessionId = swappedSessionData["sessionId"] as? String {
            for week in program.weeks {
                for session in week.sessions {
                    if session.mainLift.liftName == sessionId || 
                       session.mainLift.liftName.lowercased() == sessionId.lowercased() {
                        return session
                    }
                }
            }
        }
        
        for week in program.weeks {
            if let session = week.sessions.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                return session
            }
        }
        return nil
    }
    
    private func isInCurrentWeek(_ date: Date) -> Bool {
        guard let selectedWeekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate ?? Date())?.start,
              let dateWeekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
            return false
        }
        return calendar.isDate(selectedWeekStart, inSameDayAs: dateWeekStart)
    }
    
    private func isDateCompleted(_ date: Date) -> Bool {
        let dateString = dateFormatter.string(from: date)
        return completedWorkouts.contains(dateString)
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}

struct DayCell: View {
    let date: Date
    let session: ProgramSession?
    let isCompleted: Bool
    let isSelected: Bool
    let isCurrentMonth: Bool
    let isDragging: Bool
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(dayNumber)
                    .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                    .foregroundColor(textColor)
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            if let session = session {
                VStack(spacing: 2) {
                    Text(session.mainLift.liftName)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
                .background(sessionColor)
                .cornerRadius(4)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color(hex: "667eea") : Color.clear, lineWidth: 2)
        )
        .opacity(isDragging ? 0.5 : (isCompleted ? 0.8 : 1.0))
        .padding(2)
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .gray.opacity(0.3)
        }
        return .white
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color(hex: "667eea").opacity(0.2)
        }
        if session != nil {
            return Color(hex: "2d2d2d")
        }
        return Color(hex: "1a1a1a")
    }
    
    private var sessionColor: Color {
        if isCompleted {
            return .green.opacity(0.6)
        }
        return Color(hex: "667eea").opacity(0.8)
    }
}

struct DayDropDelegate: DropDelegate {
    let targetDate: Date
    @Binding var draggedDate: Date?
    let program: GeneratedProgram
    @Binding var daySwaps: [String: [String: Any]]
    let calendar: Calendar
    let dateFormatter: DateFormatter
    let isInCurrentWeek: (Date) -> Bool
    let sessionForDate: (Date) -> ProgramSession?
    let onSwapUpdate: ([String: [String: Any]]) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedDate = draggedDate else { return false }
        
        guard !calendar.isDate(draggedDate, inSameDayAs: targetDate) else {
            self.draggedDate = nil
            return false
        }
        
        guard isInCurrentWeek(draggedDate) && isInCurrentWeek(targetDate) else {
            self.draggedDate = nil
            return false
        }
        
        guard let draggedSession = sessionForDate(draggedDate),
              let targetSession = sessionForDate(targetDate) else {
            self.draggedDate = nil
            return false
        }
        
        let draggedDateString = dateFormatter.string(from: draggedDate)
        let targetDateString = dateFormatter.string(from: targetDate)
        
        var newSwaps = daySwaps
        
        let draggedSessionData: [String: Any] = [
            "sessionId": draggedSession.mainLift.liftName,
            "label": draggedSession.mainLift.liftName,
            "mainLiftId": draggedSession.mainLift.liftName.lowercased()
        ]
        
        let targetSessionData: [String: Any] = [
            "sessionId": targetSession.mainLift.liftName,
            "label": targetSession.mainLift.liftName,
            "mainLiftId": targetSession.mainLift.liftName.lowercased()
        ]
        
        newSwaps[draggedDateString] = targetSessionData
        newSwaps[targetDateString] = draggedSessionData
        
        daySwaps = newSwaps
        onSwapUpdate(newSwaps)
        
        self.draggedDate = nil
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

