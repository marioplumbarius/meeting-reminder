import Foundation

enum PreviewEvents {
    static let enabledKey = "previewEventsEnabled"

    static func synthesize(for now: Date, defaults: UserDefaults = .standard) -> [MeetingEvent] {
        guard defaults.bool(forKey: enabledKey) else { return [] }

        let calendar = Calendar.current
        var result: [MeetingEvent] = []

        // Event starting in 2 minutes (to test start overlay)
        if let upcoming = calendar.date(byAdding: .minute, value: 2, to: now) {
            result.append(
                MeetingEvent(
                    id: "preview-upcoming",
                    title: "Preview: Meeting in 2 min",
                    startDate: upcoming,
                    endDate: upcoming.addingTimeInterval(1800),
                    calendar: "Preview",
                    videoLink: "https://zoom.us/j/123456"
                )
            )
        }

        // Ongoing event (to test ending overlay at 2 min before end)
        if let ongoing = calendar.date(byAdding: .minute, value: -5, to: now),
           let ongoingEnd = calendar.date(byAdding: .minute, value: 7, to: now) {
            result.append(
                MeetingEvent(
                    id: "preview-ongoing",
                    title: "Preview: Ongoing meeting",
                    startDate: ongoing,
                    endDate: ongoingEnd,
                    calendar: "Preview"
                )
            )
        }

        return result
    }
}
