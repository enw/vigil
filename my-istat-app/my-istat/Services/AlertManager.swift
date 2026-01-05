import Foundation
import UserNotifications

@MainActor
class AlertManager: ObservableObject {
    @Published var alerts: [Alert] = []
    private var alertTimestamps: [String: Date] = [:]
    private let cooldownDuration: TimeInterval = 60 // Don't repeat same alert within 60s

    struct Alert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let type: AlertType
        let timestamp: Date

        enum AlertType {
            case cpu
            case memory
            case disk
            case network
            case battery
        }
    }

    struct AlertRule {
        let id: String
        let enabled: Bool
        let name: String
        let condition: AlertCondition
        let action: AlertAction

        enum AlertCondition {
            case cpuAbove(percentage: Double, duration: TimeInterval)
            case memoryAbove(percentage: Double, duration: TimeInterval)
            case diskSpaceLow(percentage: Double)
            case batteryLow(percentage: Int)
            case networkDisconnected
        }

        enum AlertAction {
            case notification(sound: Bool)
            case script(path: String)
        }
    }

    private var activeRules: [AlertRule] = []

    init() {
        requestNotificationPermission()
        loadDefaultRules()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    private func loadDefaultRules() {
        activeRules = [
            AlertRule(
                id: "cpu_80",
                enabled: true,
                name: "CPU Alert (80%)",
                condition: .cpuAbove(percentage: 80, duration: 5),
                action: .notification(sound: true)
            ),
            AlertRule(
                id: "memory_85",
                enabled: true,
                name: "Memory Alert (85%)",
                condition: .memoryAbove(percentage: 85, duration: 5),
                action: .notification(sound: false)
            ),
            AlertRule(
                id: "disk_low",
                enabled: true,
                name: "Disk Space Low (10%)",
                condition: .diskSpaceLow(percentage: 10),
                action: .notification(sound: true)
            ),
            AlertRule(
                id: "battery_low",
                enabled: true,
                name: "Battery Low (20%)",
                condition: .batteryLow(percentage: 20),
                action: .notification(sound: true)
            ),
        ]
    }

    func checkCPUAlert(usage: Double) {
        checkThresholdAlert(
            id: "cpu_alert",
            type: .cpu,
            threshold: 80,
            currentValue: usage,
            title: "High CPU Usage",
            message: "CPU usage is \(String(format: "%.1f", usage))%"
        )
    }

    func checkMemoryAlert(usage: Double) {
        checkThresholdAlert(
            id: "memory_alert",
            type: .memory,
            threshold: 85,
            currentValue: usage,
            title: "High Memory Usage",
            message: "Memory usage is \(String(format: "%.1f", usage))%"
        )
    }

    func checkDiskAlert(usage: Double) {
        checkThresholdAlert(
            id: "disk_alert",
            type: .disk,
            threshold: 10, // Low free space
            currentValue: 100 - usage, // Invert for free space
            title: "Low Disk Space",
            message: "Only \(String(format: "%.1f", 100 - usage))% free"
        )
    }

    func checkBatteryAlert(percentage: Int, isCharging: Bool) {
        guard !isCharging else { return }

        if percentage <= 20 {
            checkThresholdAlert(
                id: "battery_alert",
                type: .battery,
                threshold: 20,
                currentValue: Double(percentage),
                title: "Low Battery",
                message: "Battery is \(percentage)%"
            )
        }
    }

    private func checkThresholdAlert(
        id: String,
        type: Alert.AlertType,
        threshold: Double,
        currentValue: Double,
        title: String,
        message: String
    ) {
        guard currentValue >= threshold else { return }

        // Check cooldown
        if let lastAlert = alertTimestamps[id],
           Date().timeIntervalSince(lastAlert) < cooldownDuration {
            return
        }

        // Create and send alert
        let alert = Alert(
            title: title,
            message: message,
            type: type,
            timestamp: Date()
        )

        sendNotification(alert)
        alertTimestamps[id] = Date()

        // Add to history (keep last 100)
        alerts.insert(alert, at: 0)
        if alerts.count > 100 {
            alerts.removeLast()
        }
    }

    private func sendNotification(_ alert: Alert) {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    func clearAlerts() {
        alerts.removeAll()
    }

    func getAlertHistory(limit: Int = 50) -> [Alert] {
        Array(alerts.prefix(limit))
    }

    func setRule(id: String, enabled: Bool) {
        if let index = activeRules.firstIndex(where: { $0.id == id }) {
            activeRules[index] = AlertRule(
                id: activeRules[index].id,
                enabled: enabled,
                name: activeRules[index].name,
                condition: activeRules[index].condition,
                action: activeRules[index].action
            )
        }
    }

    func getRules() -> [AlertRule] {
        activeRules
    }
}
