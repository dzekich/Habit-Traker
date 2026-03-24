import SwiftData
import Foundation

@Model
final class HabitCompletion {
    var id: UUID
    var date: Date
    var habit: Habit?

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
    }
}
