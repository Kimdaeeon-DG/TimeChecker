import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    let workTimes: [Date: [WorkTime]]
    
    private let calendar = Calendar.current
    private let daysInWeek = 7
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        return formatter
    }()
    
    private var weeks: [[DateItem]] {
        let monthInterval = calendar.dateInterval(of: .month, for: selectedDate)!
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)!.count
        
        var dates: [DateItem] = Array(repeating: DateItem(id: UUID(), date: nil), count: firstWeekday - 1)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                dates.append(DateItem(id: UUID(), date: date))
            }
        }
        
        while dates.count % daysInWeek != 0 {
            dates.append(DateItem(id: UUID(), date: nil))
        }
        
        return dates.chunked(into: daysInWeek)
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { moveMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                
                Text(monthFormatter.string(from: selectedDate))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                
                Button(action: { moveMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            
            HStack {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(day == "일" ? .red : day == "토" ? .blue : .primary)
                }
            }
            
            ForEach(weeks, id: \.self) { week in
                HStack {
                    ForEach(week, id: \.id) { item in
                        if let date = item.date {
                            DayCell(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                workTimes: workTimes[calendar.startOfDay(for: date)] ?? []
                            )
                            .onTapGesture {
                                selectedDate = date
                            }
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func moveMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

struct DateItem: Identifiable, Hashable {
    let id: UUID
    let date: Date?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DateItem, rhs: DateItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let workTimes: [WorkTime]
    
    private let calendar = Calendar.current
    
    private var totalHours: Double {
        workTimes.compactMap { $0.duration }.reduce(0, +) / 3600
    }
    
    var body: some View {
        VStack {
            Text("\(calendar.component(.day, from: date))")
                .foregroundColor(isWeekend(date) ? (calendar.component(.weekday, from: date) == 1 ? .red : .blue) : .primary)
            
            if !workTimes.isEmpty {
                Text(String(format: "%.1f시간", totalHours))
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(5)
        .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }
    
    private func isWeekend(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension Array: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        for element in self {
            hasher.combine(element)
        }
    }
}

extension Date: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(timeIntervalSince1970)
    }
}
