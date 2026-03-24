import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query private var habits: [Habit]

    private let calendar = Calendar.current

    private var last7Days: [Date] {
        (0..<7).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: calendar.startOfDay(for: Date()))
        }
    }

    private var overallCompletionRate: Double {
        guard !habits.isEmpty else { return 0 }
        return habits.reduce(0.0) { $0 + $1.completionRate } / Double(habits.count)
    }

    private var completedTodayCount: Int {
        habits.filter { $0.isCompletedToday }.count
    }

    private var totalStreakDays: Int {
        habits.reduce(0) { $0 + $1.currentStreak }
    }

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView {
                        Label("No Data Yet", systemImage: "chart.bar")
                    } description: {
                        Text("Add habits and start tracking to see your statistics.")
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            summaryRow
                            weeklyChartCard
                            habitsList
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Statistics")
        }
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Today",
                value: "\(completedTodayCount)/\(habits.count)",
                subtitle: "completed",
                color: .green
            )
            SummaryCard(
                title: "Avg Rate",
                value: String(format: "%.0f%%", overallCompletionRate),
                subtitle: "overall",
                color: .blue
            )
            SummaryCard(
                title: "Streaks",
                value: "\(totalStreakDays)",
                subtitle: "total days",
                color: .orange
            )
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(.headline)

            Chart {
                ForEach(last7Days, id: \.self) { date in
                    BarMark(
                        x: .value("Day", date, unit: .day),
                        y: .value("Completions", completionCount(on: date))
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(6)
                }
                RuleMark(y: .value("Habits", habits.count))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Total: \(habits.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(values: .stride(by: 1)) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYScale(domain: 0...max(habits.count, 1))
            .frame(height: 180)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Habits List

    private var habitsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Per Habit")
                .font(.headline)

            ForEach(habits.sorted { $0.completionRate > $1.completionRate }) { habit in
                HabitStatRow(habit: habit)
            }
        }
    }

    private func completionCount(on date: Date) -> Int {
        habits.filter { $0.isCompleted(on: date) }.count
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Habit Stat Row

struct HabitStatRow: View {
    let habit: Habit

    private var rateColor: Color {
        habit.completionRate >= 70 ? .green : habit.completionRate >= 40 ? .orange : .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(habit.name)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(String(format: "%.0f%%", habit.completionRate))
                    .font(.subheadline.bold())
                    .foregroundStyle(rateColor)
            }

            ProgressView(value: min(habit.completionRate / 100, 1.0))
                .tint(rateColor)

            HStack(spacing: 14) {
                Label("\(habit.currentStreak)d streak", systemImage: "flame.fill")
                    .foregroundStyle(.orange)
                Label("\(habit.totalCompletions) done", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Label("Best \(habit.longestStreak)d", systemImage: "trophy.fill")
                    .foregroundStyle(.yellow)
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
