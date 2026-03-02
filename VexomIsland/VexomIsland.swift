import WidgetKit
import SwiftUI
import ActivityKit

struct VexomActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var statusText: String
        var statusIcon: String
        var urgentCount: Int
        var nextEvent: String
        var nextEventTime: String
        var isActive: Bool
    }
    var userName: String
}

struct VexomIslandLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VexomActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Text("⚡")
                            .font(.system(size: 16))
                        Text("Vexom")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.urgentCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                            Text("\(context.state.urgentCount)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.statusText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if !context.state.nextEvent.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                                .foregroundColor(.blue)
                            Text(context.state.nextEvent)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(context.state.nextEventTime)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 4)
                    }
                }
            } compactLeading: {
                Text("⚡")
                    .font(.system(size: 14))
            } compactTrailing: {
                if context.state.urgentCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.red)
                        Text("\(context.state.urgentCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red)
                    }
                } else {
                    Image(systemName: context.state.statusIcon)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                }
            } minimal: {
                Text("⚡")
                    .font(.system(size: 12))
            }
            .widgetURL(URL(string: "vexom://open"))
            .keylineTint(.white)
        }
    }
}

struct LockScreenView: View {
    let context: ActivityViewContext<VexomActivityAttributes>
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)
                Text("⚡")
                    .font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(context.state.statusText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                if !context.state.nextEvent.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                        Text("\(context.state.nextEvent) at \(context.state.nextEventTime)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            Spacer()
            if context.state.urgentCount > 0 {
                VStack(spacing: 2) {
                    Text("\(context.state.urgentCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.red)
                    Text("urgent")
                        .font(.system(size: 10))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), statusText: "All clear ⚡", urgentCount: 0, nextEvent: "No events")
    }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry(date: Date(), statusText: "All clear ⚡", urgentCount: 0, nextEvent: "No events"))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date(), statusText: "All clear ⚡", urgentCount: 0, nextEvent: "No events")
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let statusText: String
    let urgentCount: Int
    let nextEvent: String
}

struct VexomIslandEntryView: View {
    var entry: Provider.Entry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("⚡")
                    .font(.system(size: 16))
                Text("Vexom")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                if entry.urgentCount > 0 {
                    Text("\(entry.urgentCount) urgent")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(6)
                }
            }
            Text(entry.statusText)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(entry.nextEvent)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(12)
        .containerBackground(Color.black, for: .widget)
    }
}

struct VexomIsland: Widget {
    let kind: String = "VexomIsland"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VexomIslandEntryView(entry: entry)
        }
        .configurationDisplayName("Vexom")
        .description("Your personal AI status at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
