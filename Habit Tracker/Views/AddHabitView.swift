import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingHabit: Habit? = nil

    @State private var name = ""
    @State private var frequency: HabitFrequency = .daily
    @State private var isReminderEnabled = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var goal = 0
    @State private var showNameError = false

    private var isEditing: Bool { editingHabit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit Info") {
                    TextField("Habit Name", text: $name)
                        .autocorrectionDisabled()
                        .onChange(of: name) { _, _ in
                            if showNameError && !name.trimmingCharacters(in: .whitespaces).isEmpty {
                                showNameError = false
                            }
                        }

                    if showNameError {
                        Text("Please enter a habit name")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Picker("Frequency", selection: $frequency) {
                        ForEach(HabitFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Reminder") {
                    Toggle("Enable Reminder", isOn: $isReminderEnabled)

                    if isReminderEnabled {
                        DatePicker(
                            "Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                Section {
                    Stepper(value: $goal, in: 0...3650) {
                        HStack {
                            Text("Target Days")
                            Spacer()
                            Text(goal > 0 ? "\(goal) days" : "No goal")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if goal > 0 {
                        Text("Complete this habit for \(goal) consecutive days.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Goal (Optional)")
                }
            }
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if let habit = editingHabit {
                name = habit.name
                frequency = habit.frequency
                isReminderEnabled = habit.isReminderEnabled
                reminderTime = habit.reminderTime ?? (Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date())
                goal = habit.goal
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            showNameError = true
            return
        }

        if let habit = editingHabit {
            habit.name = trimmed
            habit.frequency = frequency
            habit.isReminderEnabled = isReminderEnabled
            habit.reminderTime = isReminderEnabled ? reminderTime : nil
            habit.goal = goal
            NotificationManager.shared.updateReminder(for: habit)
        } else {
            let habit = Habit(
                name: trimmed,
                frequency: frequency,
                reminderTime: isReminderEnabled ? reminderTime : nil,
                goal: goal,
                isReminderEnabled: isReminderEnabled
            )
            modelContext.insert(habit)

            if isReminderEnabled {
                NotificationManager.shared.requestAuthorization { granted in
                    if granted {
                        NotificationManager.shared.scheduleReminder(for: habit)
                    }
                }
            }
        }

        dismiss()
    }
}
