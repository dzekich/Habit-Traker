import SwiftUI

struct HabitMonthCalendar: View {
    let habit: Habit
    let month: Date

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 6) {
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(calendar.veryShortWeekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        HabitDayCell(
                            date: date,
                            isCompleted: habit.isCompleted(on: date)
                        )
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }
        }
    }

    private var daysInMonth: [Date?] {
        guard
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
            let range = calendar.range(of: .day, in: .month, for: month)
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let offset = firstWeekday - calendar.firstWeekday
        let paddingDays = ((offset % 7) + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: paddingDays)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        return days
    }
}

private struct HabitDayCell: View {
    let date: Date
    let isCompleted: Bool

    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var isFuture: Bool { date > Calendar.current.startOfDay(for: Date()) }

    var body: some View {
        ZStack {
            Circle()
                .fill(isCompleted ? Color.green : Color.clear)
                .overlay {
                    if isToday && !isCompleted {
                        Circle().stroke(Color.accentColor, lineWidth: 2)
                    }
                }

            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 13, weight: isToday ? .bold : .regular))
                .foregroundStyle(
                    isCompleted ? Color.white :
                    isFuture ? Color.secondary.opacity(0.4) : Color.primary
                )
        }
        .frame(width: 34, height: 34)
    }
}
