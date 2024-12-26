import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    private init() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("WorkTime.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
            return
        }
        
        createTable()
    }
    
    private func createTable() {
        let createTableString = """
            CREATE TABLE IF NOT EXISTS work_time(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                check_in DATETIME NOT NULL,
                check_out DATETIME
            );
        """
        
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Work time table created.")
            }
        }
        sqlite3_finalize(createTableStatement)
    }
    
    func checkIn() {
        let queryString = "INSERT INTO work_time (check_in) VALUES (?);"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            let now = Date()
            let dateString = ISO8601DateFormatter().string(from: now)
            sqlite3_bind_text(statement, 1, (dateString as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error inserting new check-in")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    func checkOut() {
        let queryString = """
            UPDATE work_time 
            SET check_out = ? 
            WHERE id = (
                SELECT id FROM work_time 
                WHERE check_out IS NULL 
                ORDER BY check_in DESC 
                LIMIT 1
            );
        """
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            let now = Date()
            let dateString = ISO8601DateFormatter().string(from: now)
            sqlite3_bind_text(statement, 1, (dateString as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error updating check-out")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    func getAllWorkTimes() -> [WorkTime] {
        var workTimes: [WorkTime] = []
        let dateFormatter = ISO8601DateFormatter()
        
        let queryString = """
            SELECT id, check_in, check_out 
            FROM work_time 
            ORDER BY check_in DESC;
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                
                if let checkInStr = sqlite3_column_text(statement, 1) {
                    let checkInString = String(cString: checkInStr)
                    if let checkIn = dateFormatter.date(from: checkInString) {
                        var checkOut: Date? = nil
                        
                        if let checkOutStr = sqlite3_column_text(statement, 2) {
                            let checkOutString = String(cString: checkOutStr)
                            checkOut = dateFormatter.date(from: checkOutString)
                        }
                        
                        let workTime = WorkTime(id: id, checkIn: checkIn, checkOut: checkOut)
                        workTimes.append(workTime)
                    }
                }
            }
        }
        
        sqlite3_finalize(statement)
        return workTimes
    }
    
    func getMonthlyWorkTimes() -> [WorkTime] {
        var workTimes: [WorkTime] = []
        let dateFormatter = ISO8601DateFormatter()
        
        let queryString = """
            SELECT id, check_in, check_out 
            FROM work_time 
            WHERE check_in >= date('now', 'start of month') 
            ORDER BY check_in DESC;
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                
                if let checkInStr = sqlite3_column_text(statement, 1) {
                    let checkInString = String(cString: checkInStr)
                    if let checkIn = dateFormatter.date(from: checkInString) {
                        var checkOut: Date? = nil
                        
                        if let checkOutStr = sqlite3_column_text(statement, 2) {
                            let checkOutString = String(cString: checkOutStr)
                            checkOut = dateFormatter.date(from: checkOutString)
                        }
                        
                        let workTime = WorkTime(id: id, checkIn: checkIn, checkOut: checkOut)
                        workTimes.append(workTime)
                    }
                }
            }
        }
        
        sqlite3_finalize(statement)
        return workTimes
    }
    
    func getWorkTimeForDate(_ date: Date) -> [WorkTime] {
        var workTimes: [WorkTime] = []
        let calendar = Calendar.current
        let dateFormatter = ISO8601DateFormatter()
        
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let queryString = """
            SELECT id, check_in, check_out 
            FROM work_time 
            WHERE check_in >= ? AND check_in < ? 
            ORDER BY check_in DESC;
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            let startStr = dateFormatter.string(from: startOfDay)
            let endStr = dateFormatter.string(from: endOfDay)
            
            sqlite3_bind_text(statement, 1, (startStr as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (endStr as NSString).utf8String, -1, nil)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                
                if let checkInStr = sqlite3_column_text(statement, 1) {
                    let checkInString = String(cString: checkInStr)
                    if let checkIn = dateFormatter.date(from: checkInString) {
                        var checkOut: Date? = nil
                        
                        if let checkOutStr = sqlite3_column_text(statement, 2) {
                            let checkOutString = String(cString: checkOutStr)
                            checkOut = dateFormatter.date(from: checkOutString)
                        }
                        
                        let workTime = WorkTime(id: id, checkIn: checkIn, checkOut: checkOut)
                        workTimes.append(workTime)
                    }
                }
            }
        }
        
        sqlite3_finalize(statement)
        return workTimes
    }
    
    func deleteWorkTime(id: Int) {
        let queryString = "DELETE FROM work_time WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error deleting work time")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    func updateWorkTime(_ workTime: WorkTime) {
        let queryString = """
            UPDATE work_time 
            SET check_in = ?, check_out = ? 
            WHERE id = ?;
        """
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            let dateFormatter = ISO8601DateFormatter()
            let checkInStr = dateFormatter.string(from: workTime.checkIn)
            
            sqlite3_bind_text(statement, 1, (checkInStr as NSString).utf8String, -1, nil)
            
            if let checkOut = workTime.checkOut {
                let checkOutStr = dateFormatter.string(from: checkOut)
                sqlite3_bind_text(statement, 2, (checkOutStr as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 2)
            }
            
            sqlite3_bind_int(statement, 3, Int32(workTime.id))
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error updating work time")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    func importWorkTime(_ workTime: WorkTime) {
        let queryString = """
            INSERT INTO work_time (id, check_in, check_out) 
            VALUES (?, ?, ?);
        """
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            let dateFormatter = ISO8601DateFormatter()
            let checkInStr = dateFormatter.string(from: workTime.checkIn)
            
            sqlite3_bind_int(statement, 1, Int32(workTime.id))
            sqlite3_bind_text(statement, 2, (checkInStr as NSString).utf8String, -1, nil)
            
            if let checkOut = workTime.checkOut {
                let checkOutStr = dateFormatter.string(from: checkOut)
                sqlite3_bind_text(statement, 3, (checkOutStr as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error importing work time")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    func deleteAllWorkTimes() {
        let queryString = "DELETE FROM work_time;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error deleting all work times")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    func getTotalHoursForMonth(_ date: Date) -> Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        let workTimes = getWorkTimesBetween(start: startOfMonth, end: nextMonth)
        let totalSeconds = workTimes.compactMap { $0.duration }.reduce(0, +)
        return totalSeconds / 3600.0
    }
    
    func getWorkTimesBetween(start: Date, end: Date) -> [WorkTime] {
        var workTimes: [WorkTime] = []
        let dateFormatter = ISO8601DateFormatter()
        
        let queryString = """
            SELECT id, check_in, check_out
            FROM work_time
            WHERE check_in >= ? AND check_in < ?
            ORDER BY check_in DESC
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            let startStr = dateFormatter.string(from: start)
            let endStr = dateFormatter.string(from: end)
            
            sqlite3_bind_text(statement, 1, (startStr as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (endStr as NSString).utf8String, -1, nil)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                
                if let checkInStr = sqlite3_column_text(statement, 1) {
                    let checkInString = String(cString: checkInStr)
                    if let checkIn = dateFormatter.date(from: checkInString) {
                        var checkOut: Date? = nil
                        
                        if let checkOutStr = sqlite3_column_text(statement, 2) {
                            let checkOutString = String(cString: checkOutStr)
                            checkOut = dateFormatter.date(from: checkOutString)
                        }
                        
                        let workTime = WorkTime(id: id, checkIn: checkIn, checkOut: checkOut)
                        workTimes.append(workTime)
                    }
                }
            }
        }
        
        sqlite3_finalize(statement)
        return workTimes
    }
    
    func getLatestWorkTime() -> WorkTime? {
        let queryString = """
            SELECT id, check_in, check_out 
            FROM work_time 
            ORDER BY check_in DESC 
            LIMIT 1;
        """
        
        var statement: OpaquePointer?
        var workTime: WorkTime? = nil
        let dateFormatter = ISO8601DateFormatter()
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                
                if let checkInStr = sqlite3_column_text(statement, 1) {
                    let checkInString = String(cString: checkInStr)
                    if let checkIn = dateFormatter.date(from: checkInString) {
                        var checkOut: Date? = nil
                        
                        if let checkOutStr = sqlite3_column_text(statement, 2) {
                            let checkOutString = String(cString: checkOutStr)
                            checkOut = dateFormatter.date(from: checkOutString)
                        }
                        
                        workTime = WorkTime(id: id, checkIn: checkIn, checkOut: checkOut)
                    }
                }
            }
        }
        
        sqlite3_finalize(statement)
        return workTime
    }
}
