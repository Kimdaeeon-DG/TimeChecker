import SwiftUI

struct EditWorkTimeView: View {
    let workTime: WorkTime
    @Binding var isPresented: Bool
    @State private var checkInDate: Date
    @State private var checkOutDate: Date 
    var onSave: () -> Void
    
    init(workTime: WorkTime, isPresented: Binding<Bool>, onSave: @escaping () -> Void) {
        self.workTime = workTime
        self._isPresented = isPresented
        self._checkInDate = State(initialValue: workTime.checkIn)
        self._checkOutDate = State(initialValue: workTime.checkOut ?? Date())
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("출근 시간")) {
                    DatePicker("", selection: $checkInDate)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                }
                
                Section(header: Text("퇴근 시간")) {
                    DatePicker("", selection: $checkOutDate)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                }
            }
            .navigationTitle("근무 시간 수정")
            .navigationBarItems(
                leading: Button("취소") {
                    isPresented = false
                },
                trailing: Button("저장") {
                    // 새로운 WorkTime 객체 생성
                    let updatedWorkTime = WorkTime(
                        id: workTime.id,
                        checkIn: checkInDate,
                        checkOut: checkOutDate
                    )
                    // 업데이트 메서드 호출
                    DatabaseManager.shared.updateWorkTime(updatedWorkTime)
                    onSave()
                    isPresented = false
                }
            )
        }
    }
}
