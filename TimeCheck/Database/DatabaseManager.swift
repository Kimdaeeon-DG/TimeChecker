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
        let insertStatementString = "INSERT INTO work_time (check_in) VALUES (?);"
        var insertStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            let now = Date()
            let dateString = ISO8601DateFormatter().string(from: now)
            sqlite3_bind_text(insertStatement, 1, (dateString as NSString).utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted check-in time")
            }
        }
        sqlite3_finalize(insertStatement)
    }
    
    func checkOut() {
        let updateStatementString = """
            UPDATE work_time 
            SET check_out = ? 
            WHERE id = (SELECT id FROM work_time WHERE check_out IS NULL ORDER BY check_in DESC LIMIT 1);
        """
        var updateStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            let now = Date()
            let dateString = ISO8601DateFormatter().string(from: now)
            sqlite3_bind_text(updateStatement, 1, (dateString as NSString).utf8String, -1, nil)
            
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully inserted check-out time")
            }
        }
        sqlite3_finalize(updateStatement)
    }
    
    func getMonthlyWorkTimes() -> [WorkTime] {
        var workTimes: [WorkTime] = []
        let calendar = Calendar.current
        let dateFormatter = ISO8601DateFormatter()
        
        let queryString = """
            SELECT id, check_in, check_out 
            FROM work_time 
            WHERE check_in >= date('now', 'start of month') 
            ORDER BY check_in DESC;
        """
        
        var queryStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = sqlite3_column_int(queryStatement, 0)
                
                guard let checkInStr = sqlite3_column_text(queryStatement, 1) else { continue }
                let checkIn = dateFormatter.date(from: String(cString: checkInStr))!
                
                var checkOut: Date? = nil
                if let checkOutStr = sqlite3_column_text(queryStatement, 2) {
                    checkOut = dateFormatter.date(from: String(cString: checkOutStr))
                }
                
                let workTime = WorkTime(id: Int(id), checkIn: checkIn, checkOut: checkOut)
                workTimes.append(workTime)
            }
        }
        sqlite3_finalize(queryStatement)
        
        return workTimes
    }
    
    func getTotalMonthlyHours() -> Double {
        let workTimes = getMonthlyWorkTimes()
        let totalSeconds = workTimes.compactMap { $0.duration }.reduce(0, +)
        return totalSeconds / 3600 // Convert to hours
    }
    
    func updateWorkTime(id: Int, checkIn: Date?, checkOut: Date?) {
        var updateStatementString = "UPDATE work_time SET"
        var bindings: [(Int, Any)] = []
        
        if let checkIn = checkIn {
            updateStatementString += " check_in = ?,"
            bindings.append((bindings.count + 1, ISO8601DateFormatter().string(from: checkIn)))
        }
        
        if let checkOut = checkOut {
            updateStatementString += " check_out = ?,"
            bindings.append((bindings.count + 1, ISO8601DateFormatter().string(from: checkOut)))
        }
        
        // Remove trailing comma
        updateStatementString = String(updateStatementString.dropLast())
        updateStatementString += " WHERE id = ?"
        bindings.append((bindings.count + 1, id))
        
        var updateStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            for (index, value) in bindings {
                switch value {
                case let stringValue as String:
                    sqlite3_bind_text(updateStatement, Int32(index), (stringValue as NSString).utf8String, -1, nil)
                case let intValue as Int:
                    sqlite3_bind_int(updateStatement, Int32(index), Int32(intValue))
                default:
                    break
                }
            }
            
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully updated work time")
            }
        }
        sqlite3_finalize(updateStatement)
    }
    
    func deleteWorkTime(id: Int) {
        let deleteStatementString = "DELETE FROM work_time WHERE id = ?;"
        var deleteStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(deleteStatement, 1, Int32(id))
            
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Successfully deleted work time")
            }
        }
        sqlite3_finalize(deleteStatement)
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
            WHERE date(check_in) = date(?)
            ORDER BY check_in DESC;
        """
        
        var queryStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
            let dateString = dateFormatter.string(from: date)
            sqlite3_bind_text(queryStatement, 1, (dateString as NSString).utf8String, -1, nil)
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = sqlite3_column_int(queryStatement, 0)
                
                guard let checkInStr = sqlite3_column_text(queryStatement, 1) else { continue }
                let checkIn = dateFormatter.date(from: String(cString: checkInStr))!
                
                var checkOut: Date? = nil
                if let checkOutStr = sqlite3_column_text(queryStatement, 2) {
                    checkOut = dateFormatter.date(from: String(cString: checkOutStr))
                }
                
                let workTime = WorkTime(id: Int(id), checkIn: checkIn, checkOut: checkOut)
                workTimes.append(workTime)
            }
        }
        sqlite3_finalize(queryStatement)
        
        return workTimes
    }
}
