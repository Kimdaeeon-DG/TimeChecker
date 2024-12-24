import SwiftUI

struct ContentView: View {
    @State private var workTimes: [WorkTime] = []
    @State private var totalHours: Double = 0
    @State private var selectedWorkTime: WorkTime?
    @State private var showingEditSheet = false
    @State private var selectedDate = Date()
    @State private var calendarWorkTimes: [Date: [WorkTime]] = [:]
    
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
            
            Text("이번 달 총 근무시간: \(String(format: "%.1f", totalHours))시간")
                .font(.headline)
                .padding()
            
            List {
                ForEach(workTimes.indices, id: \.self) { index in
                    WorkTimeRow(workTime: workTimes[index])
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedWorkTime = workTimes[index]
                            showingEditSheet = true
                        }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        DatabaseManager.shared.deleteWorkTime(id: workTimes[index].id)
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
            updateCalendarData()
        }
    }
    
    private func updateData() {
        workTimes = DatabaseManager.shared.getMonthlyWorkTimes()
        totalHours = DatabaseManager.shared.getTotalMonthlyHours()
        updateCalendarData()
    }
    
    private func updateCalendarData() {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: selectedDate)!
        
        var newWorkTimes: [Date: [WorkTime]] = [:]
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)!.count
        
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: monthInterval.start) {
                let dayStart = calendar.startOfDay(for: date)
                newWorkTimes[dayStart] = DatabaseManager.shared.getWorkTimeForDate(dayStart)
            }
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

#Preview {
    ContentView()
}
