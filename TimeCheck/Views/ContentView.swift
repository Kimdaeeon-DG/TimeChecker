import SwiftUI

struct ContentView: View {
    @State private var workTimes: [WorkTime] = []
    @State private var totalHours: Double = 0
    @State private var selectedWorkTime: WorkTime?
    @State private var showingEditSheet = false
    @State private var selectedDate = Date()
    @State private var calendarWorkTimes: [Date: [WorkTime]] = [:]
    @State private var showingDocumentPicker = false
    @State private var showingSideMenu = false
    @State private var isCheckedIn = false
    
    var filteredWorkTimes: [WorkTime] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        return DatabaseManager.shared.getWorkTimeForDate(startOfDay)
    }
    
    var selectedMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                HStack {
                    Text("42 시간 기록")
                        .font(.largeTitle)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showingSideMenu = true
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                
                CalendarView(selectedDate: $selectedDate, workTimes: calendarWorkTimes)
                    .frame(height: 300)
                
                HStack {
                    Button(action: {
                        if isCheckedIn {
                            DatabaseManager.shared.checkOut()
                        } else {
                            DatabaseManager.shared.checkIn()
                        }
                        updateData()
                        updateCheckedInStatus()
                    }) {
                        if isCheckedIn {
                            Text("퇴근하기")
                                .font(.title2)
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                        } else {
                            Text("출근하기")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
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
                        Text("\(selectedMonthString) 근무시간")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ProgressBarView(value: totalHours, total: 80.0)
                            .frame(height: 40)
                            .padding(.horizontal)
                        
                        Text("\(selectedMonthString) 총 근무시간: \(formatDuration(totalHours * 3600))")
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
            
            if showingSideMenu {
                SideMenuView(
                    isShowing: $showingSideMenu,
                    showingDocumentPicker: $showingDocumentPicker,
                    backupAction: {
                        if let fileURL = CSVManager.shared.saveToFile() {
                            let activityVC = UIActivityViewController(
                                activityItems: [fileURL],
                                applicationActivities: nil
                            )
                            
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first,
                               let rootVC = window.rootViewController {
                                activityVC.popoverPresentationController?.sourceView = rootVC.view
                                rootVC.present(activityVC, animated: true)
                            }
                        }
                        showingSideMenu = false
                    }
                )
                .transition(.move(edge: .trailing))
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
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { url in
                guard let csvString = try? String(contentsOf: url, encoding: .utf8) else { return }
                CSVManager.shared.importFromCSV(csvString)
                updateData()
            }
        }
        .onAppear {
            updateData()
            updateCheckedInStatus()
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            if oldValue != newValue {
                updateData()
            }
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
        totalHours = DatabaseManager.shared.getTotalHoursForMonth(selectedDate)
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
    
    private func updateCheckedInStatus() {
        if let lastWorkTime = DatabaseManager.shared.getLatestWorkTime() {
            isCheckedIn = lastWorkTime.checkOut == nil
        } else {
            isCheckedIn = false
        }
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
