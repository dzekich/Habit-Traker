import SwiftData
import Foundation

enum HabitFrequency: String, Codable, CaseIterable {
    case daily = "Every Day"
    case severalTimesPerWeek = "Several Times a Week"
}

@Model
final class Habit {
    var id: UUID
    var name: String
    var frequencyRaw: String
    var reminderTime: Date?
    var goal: Int
    var createdAt: Date
    var isReminderEnabled: Bool

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []

    var frequency: HabitFrequency {
        get { HabitFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    init(
        name: String,
        frequency: HabitFrequency = .daily,
        reminderTime: Date? = nil,
        goal: Int = 0,
        isReminderEnabled: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.frequencyRaw = frequency.rawValue
        self.reminderTime = reminderTime
        self.goal = goal
        self.createdAt = Date()
        self.isReminderEnabled = isReminderEnabled
    }

    // MARK: - Computed Properties

    var isCompletedToday: Bool {
        isCompleted(on: Date())
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let completionDates = Set(completions.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var checkDate = today
        while completionDates.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streak
    }

    var longestStreak: Int {
        let calendar = Calendar.current
        let sortedDates = completions
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()
        guard !sortedDates.isEmpty else { return 0 }
        var longest = 1
        var current = 1
        for i in 1..<sortedDates.count {
            let diff = calendar.dateComponents([.day], from: sortedDates[i - 1], to: sortedDates[i]).day ?? 0
            if diff == 0 { continue }
            else if diff == 1 { current += 1; longest = max(longest, current) }
            else { current = 1 }
        }
        return longest
    }

    var completionRate: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: createdAt)
        let totalDays = (calendar.dateComponents([.day], from: start, to: today).day ?? 0) + 1
        guard totalDays > 0 else { return 0 }
        return min(Double(completions.count) / Double(totalDays) * 100, 100)
    }

    var totalCompletions: Int {
        completions.count
    }

    func isCompleted(on date: Date) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        return completions.contains { Calendar.current.startOfDay(for: $0.date) == day }
    }
}
