import SwiftUI
import SwiftData

struct HabitRowView: View {
    @Environment(\.modelContext) private var modelContext
    let habit: Habit
    @State private var showDetail = false

    var body: some View {
        HStack(spacing: 14) {
            Button {
                toggleCompletion()
            } label: {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundStyle(habit.isCompletedToday ? Color.green : Color.secondary)
                    .animation(.spring(duration: 0.25), value: habit.isCompletedToday)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundStyle(habit.isCompletedToday ? .secondary : .primary)

                HStack(spacing: 10) {
                    if habit.currentStreak > 0 {
                        Label("\(habit.currentStreak) day streak", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Text("Start your streak today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if habit.goal > 0 {
                        Text("Goal: \(habit.goal)d")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(habit.frequency == .daily ? "Daily" : "Weekly")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())

                if habit.isReminderEnabled, let time = habit.reminderTime {
                    Label {
                        Text(time, format: .dateTime.hour().minute())
                    } icon: {
                        Image(systemName: "bell.fill")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            HabitDetailView(habit: habit)
        }
    }

    private func toggleCompletion() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if habit.isCompletedToday {
            if let completion = habit.completions.first(where: {
                calendar.startOfDay(for: $0.date) == today
            }) {
                modelContext.delete(completion)
            }
        } else {
            let completion = HabitCompletion(date: Date())
            modelContext.insert(completion)
            habit.completions.append(completion)
        }
    }
}
