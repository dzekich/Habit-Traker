import SwiftUI

struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let habit: Habit

    @State private var showingEdit = false
    @State private var currentMonth = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statsGrid
                    calendarCard
                    if habit.goal > 0 {
                        goalProgressCard
                    }
                }
                .padding()
            }
            .navigationTitle(habit.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showingEdit = true }
                }
            }
            .sheet(isPresented: $showingEdit) {
                AddHabitView(editingHabit: habit)
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            StatCard(
                value: "\(habit.currentStreak)",
                label: "Current\nStreak",
                icon: "flame.fill",
                color: .orange
            )
            StatCard(
                value: "\(habit.longestStreak)",
                label: "Longest\nStreak",
                icon: "trophy.fill",
                color: .yellow
            )
            StatCard(
                value: String(format: "%.0f%%", habit.completionRate),
                label: "Completion\nRate",
                icon: "chart.pie.fill",
                color: .blue
            )
        }
    }

    // MARK: - Calendar Card

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("History")
                    .font(.headline)
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.weight(.semibold))
                    }

                    Text(currentMonth, format: .dateTime.month(.wide).year())
                        .font(.subheadline.weight(.medium))
                        .frame(minWidth: 120)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)!
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                    }
                    .disabled(
                        Calendar.current.isDate(currentMonth, equalTo: Date(), toGranularity: .month)
                    )
                }
            }

            HabitMonthCalendar(habit: habit, month: currentMonth)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Goal Progress Card

    private var goalProgressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Goal Progress")
                    .font(.headline)
                Spacer()
                Text("\(habit.totalCompletions) / \(habit.goal) days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: min(Double(habit.totalCompletions) / Double(habit.goal), 1.0))
                .tint(habit.totalCompletions >= habit.goal ? .green : .accentColor)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)

            if habit.totalCompletions >= habit.goal {
                Label("Goal achieved!", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
