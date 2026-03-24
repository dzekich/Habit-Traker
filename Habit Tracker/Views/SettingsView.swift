import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("use24HourFormat") private var use24HourFormat = false

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showSettingsAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle(isOn: $isDarkMode) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }

                    Toggle(isOn: $use24HourFormat) {
                        Label("24-Hour Time", systemImage: "clock.fill")
                    }
                }

                Section {
                    HStack {
                        Label("Status", systemImage: "bell.fill")
                        Spacer()
                        Text(notificationStatusLabel)
                            .foregroundStyle(notificationStatusColor)
                    }

                    if notificationStatus == .denied {
                        Button {
                            showSettingsAlert = true
                        } label: {
                            Label("Open System Settings", systemImage: "arrow.up.right.square")
                        }
                    } else if notificationStatus == .notDetermined {
                        Button {
                            requestNotifications()
                        } label: {
                            Label("Enable Notifications", systemImage: "bell.badge.fill")
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Set reminder times on individual habits from the Home screen.")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                checkNotificationStatus()
            }
            .alert("Notifications Disabled", isPresented: $showSettingsAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable notifications in iOS Settings to receive habit reminders.")
            }
        }
    }

    // MARK: - Helpers

    private var notificationStatusLabel: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: return "Enabled"
        case .denied: return "Denied"
        case .notDetermined: return "Not Set"
        @unknown default: return "Unknown"
        }
    }

    private var notificationStatusColor: Color {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        default: return .secondary
        }
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }

    private func requestNotifications() {
        NotificationManager.shared.requestAuthorization { granted in
            checkNotificationStatus()
        }
    }
}
