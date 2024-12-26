import Foundation

class CSVManager {
    static let shared = CSVManager()
    private let dateFormatter: ISO8601DateFormatter
    
    private init() {
        dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
    }
    
    func exportToCSV() -> String {
        let workTimes = DatabaseManager.shared.getAllWorkTimes()
        var csvString = "ID,체크인,체크아웃\n"
        
        for workTime in workTimes {
            let checkIn = dateFormatter.string(from: workTime.checkIn)
            let checkOut = workTime.checkOut.map { dateFormatter.string(from: $0) } ?? ""
            csvString += "\(workTime.id),\(checkIn),\(checkOut)\n"
        }
        
        return csvString
    }
    
    func importFromCSV(_ csvString: String) {
        let rows = csvString.components(separatedBy: .newlines)
        guard rows.count > 1 else { return } // 헤더만 있는 경우
        
        // 기존 데이터를 모두 삭제
        DatabaseManager.shared.deleteAllWorkTimes()
        
        // 첫 번째 행은 헤더이므로 건너뜀
        for row in rows.dropFirst() where !row.isEmpty {
            let columns = row.components(separatedBy: ",")
            guard columns.count >= 3,
                  let checkIn = dateFormatter.date(from: columns[1].trimmingCharacters(in: .whitespaces)) else {
                continue
            }
            
            let checkOutStr = columns[2].trimmingCharacters(in: .whitespaces)
            let checkOut = checkOutStr.isEmpty ? nil : dateFormatter.date(from: checkOutStr)
            
            // ID는 무시하고 새로운 ID를 생성
            let workTime = WorkTime(id: Int.random(in: 1...10000), checkIn: checkIn, checkOut: checkOut)
            DatabaseManager.shared.importWorkTime(workTime)
        }
    }
    
    func saveToFile() -> URL? {
        let csvString = exportToCSV()
        
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "worktime_backup_\(timestamp).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving CSV file: \(error)")
            return nil
        }
    }
}
