import SwiftUI
import SwiftData

extension Date {
    var isInFuture: Bool {
        self > Calendar.current.startOfDay(for: Date())
    }
}

struct CalendarView: View {
    @Query private var habits: [Habit]

    @State private var currentMonth = Date()
    @State private var selectedDate: Date? = nil

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    monthNavigator
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        weekdayHeaders
                        monthGrid
                    }
                    .padding(.horizontal)

                    if let selected = selectedDate {
                        dayDetailCard(for: selected)
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Calendar")
            .animation(.spring(duration: 0.3), value: selectedDate)
        }
    }

    // MARK: - Month Navigator

    private var monthNavigator: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                    selectedDate = nil
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(currentMonth, format: .dateTime.month(.wide).year())
                .font(.title3.bold())

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                    selectedDate = nil
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .disabled(calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month))
        }
    }

    // MARK: - Weekday Headers

    private var weekdayHeaders: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(calendar.veryShortWeekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Month Grid

    private var monthGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                if let date = date {
                    let count = completionCount(on: date)
                    let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false

                    CalendarDayCell(
                        date: date,
                        completionCount: count,
                        totalHabits: habits.count,
                        isSelected: isSelected
                    )
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.25)) {
                            if let sel = selectedDate, calendar.isDate(sel, inSameDayAs: date) {
                                selectedDate = nil
                            } else {
                                selectedDate = date
                            }
                        }
                    }
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
    }

    // MARK: - Day Detail Card

    @ViewBuilder
    private func dayDetailCard(for date: Date) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(date, format: .dateTime.day(.defaultDigits).month(.wide).year())
                .font(.headline)

            if habits.isEmpty {
                Text("No habits created yet.")
                    .foregroundStyle(.secondary)
            } else if date.isInFuture {
                Label("This day hasn't happened yet.", systemImage: "clock")
                    .foregroundStyle(.secondary)
            } else {
                let done = habits.filter { $0.isCompleted(on: date) }
                let missed = habits.filter { !$0.isCompleted(on: date) }

                if !done.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Completed (\(done.count))")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.green)

                        ForEach(done) { habit in
                            Label(habit.name, systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                    }
                }

                if !missed.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Missed (\(missed.count))")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.red)

                        ForEach(missed) { habit in
                            Label(habit.name, systemImage: "xmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func completionCount(on date: Date) -> Int {
        habits.filter { $0.isCompleted(on: date) }.count
    }

    private var daysInMonth: [Date?] {
        guard
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
            let range = calendar.range(of: .day, in: .month, for: currentMonth)
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

// MARK: - Calendar Day Cell

private struct CalendarDayCell: View {
    let date: Date
    let completionCount: Int
    let totalHabits: Int
    let isSelected: Bool

    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var isFuture: Bool { date.isInFuture }

    private var fillColor: Color {
        if isSelected { return .accentColor }
        guard totalHabits > 0, completionCount > 0 else { return .clear }
        let ratio = Double(completionCount) / Double(totalHabits)
        return ratio >= 1 ? .green : .green.opacity(0.25 + ratio * 0.5)
    }

    private var textColor: Color {
        if isSelected { return .white }
        if completionCount == totalHabits && totalHabits > 0 { return .white }
        if isFuture { return Color.secondary.opacity(0.4) }
        return .primary
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .overlay {
                    if isToday {
                        Circle()
                            .stroke(isSelected ? Color.white : Color.accentColor, lineWidth: 2)
                    }
                }

            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundStyle(textColor)
        }
        .frame(width: 40, height: 40)
    }
}
