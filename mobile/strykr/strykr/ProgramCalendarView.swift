import SwiftUI

struct ProgramCalendarView: View {
    let program: GeneratedProgram
    let completedWorkouts: Set<String>
    let onDaySelected: (Date, ProgramSession?) -> Void
    
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date?
    
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
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            session: sessionForDate(date),
                            isCompleted: isDateCompleted(date),
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                        )
                        .onTapGesture {
                            selectedDate = date
                            onDaySelected(date, sessionForDate(date))
                        }
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
        for week in program.weeks {
            if let session = week.sessions.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                return session
            }
        }
        return nil
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
        .opacity(isCompleted ? 0.8 : 1.0)
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

