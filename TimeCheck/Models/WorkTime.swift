import Foundation

struct WorkTime: Identifiable {
    let id: Int
    let checkIn: Date
    let checkOut: Date?
    
    var duration: TimeInterval? {
        guard let checkOut = checkOut else { return nil }
        return checkOut.timeIntervalSince(checkIn)
    }
    
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return String(format: "%d시간 %d분", hours, minutes)
    }
}
