import SwiftUI

struct ContentView: View {
    @State private var workTimes: [WorkTime] = []
    @State private var totalHours: Double = 0
    @State private var selectedWorkTime: WorkTime?
    @State private var showingEditSheet = false
    @State private var selectedDate = Date()
    @State private var calendarWorkTimes: [Date: [WorkTime]] = [:]
    
    var filteredWorkTimes: [WorkTime] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        return DatabaseManager.shared.getWorkTimeForDate(startOfDay)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Work Time Tracker")
                .font(.largeTitle)
                .padding()
            
            CalendarView(selectedDate: $selectedDate, workTimes: calendarWorkTimes)
                .frame(height: 300)
            
            HStack(spacing: 20) {
                Button(action: {
                    DatabaseManager.shared.checkIn()
                    updateData()
                }) {
                    Text("출근")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 100, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    DatabaseManager.shared.checkOut()
                    updateData()
                }) {
                    Text("퇴근")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 100, height: 50)
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text(formatDate(selectedDate))
                    .font(.headline)
                    .padding(.horizontal)
                
                if let dayTotal = calculateDayTotal(for: selectedDate) {
                    Text("오늘 총 근무시간: \(formatDuration(dayTotal))")
                        .font(.subheadline)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("이번 달 근무시간")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ProgressBarView(value: totalHours, total: 80.0)
                        .frame(height: 40)
                        .padding(.horizontal)
                    
                    Text("이번 달 총 근무시간: \(formatDuration(totalHours * 3600))")
                        .font(.subheadline)
                        .padding(.horizontal)
                }
            }
            
            List {
                ForEach(filteredWorkTimes) { workTime in
                    WorkTimeRow(workTime: workTime)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedWorkTime = workTime
                            showingEditSheet = true
                        }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        DatabaseManager.shared.deleteWorkTime(id: filteredWorkTimes[index].id)
                    }
                    updateData()
                }
            }
        }
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            selectedWorkTime = nil
        }) {
            if let workTime = selectedWorkTime {
                EditWorkTimeView(
                    workTime: workTime,
                    isPresented: $showingEditSheet,
                    onSave: updateData
                )
            }
        }
        .onAppear {
            updateData()
        }
        .onChange(of: selectedDate) { _ in
            updateData()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        return String(format: "%d시간 %d분", hours, minutes)
    }
    
    private func calculateDayTotal(for date: Date) -> TimeInterval? {
        let dayWorkTimes = DatabaseManager.shared.getWorkTimeForDate(date)
        let totalSeconds = dayWorkTimes.compactMap { $0.duration }.reduce(0, +)
        return totalSeconds > 0 ? totalSeconds : nil
    }
    
    private func updateData() {
        workTimes = DatabaseManager.shared.getMonthlyWorkTimes()
        totalHours = DatabaseManager.shared.getTotalMonthlyHours()
        updateCalendarData()
    }
    
    private func updateCalendarData() {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: selectedDate)!
        let startOfMonth = monthInterval.start
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        var newWorkTimes: [Date: [WorkTime]] = [:]
        var currentDate = startOfMonth
        
        while currentDate <= endOfMonth {
            let dayStart = calendar.startOfDay(for: currentDate)
            newWorkTimes[dayStart] = DatabaseManager.shared.getWorkTimeForDate(dayStart)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        calendarWorkTimes = newWorkTimes
    }
}

struct WorkTimeRow: View {
    let workTime: WorkTime
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("출근: \(formatDate(workTime.checkIn))")
            if let checkOut = workTime.checkOut {
                Text("퇴근: \(formatDate(checkOut))")
            }
            if let duration = workTime.formattedDuration {
                Text("근무시간: \(duration)")
            }
        }
        .padding(.vertical, 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

struct ProgressBarView: View {
    let value: Double
    let total: Double
    
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .frame(height: 10)
                .foregroundColor(.gray)
                .opacity(0.3)
            
            Rectangle()
                .frame(width: UIScreen.main.bounds.width * CGFloat(value / total), height: 10)
                .foregroundColor(.blue)
        }
        .cornerRadius(5)
    }
}

#Preview {
    ContentView()
}
