import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var showingAddHabit = false

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(habits) { habit in
                            HabitRowView(habit: habit)
                        }
                        .onDelete(perform: deleteHabits)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Habits")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Habits Yet", systemImage: "checkmark.seal.fill")
        } description: {
            Text("Add your first habit to start building better routines.")
        } actions: {
            Button("Add Habit") {
                showingAddHabit = true
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView()
        }
    }

    private func deleteHabits(at offsets: IndexSet) {
        for index in offsets {
            let habit = habits[index]
            NotificationManager.shared.cancelReminder(for: habit)
            modelContext.delete(habit)
        }
    }
}
