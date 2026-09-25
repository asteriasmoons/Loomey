//
//  LumeyWidgetsLiveActivity.swift
//  LumeyWidgets
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Attributes

struct ReadingTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startDate: Date
        var elapsedSeconds: Int
        var isPaused: Bool
        var pausedElapsedSeconds: Int // seconds accumulated before current pause
    }

    var bookTitle: String
}

// MARK: - Widget

struct LumeyWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReadingTimerAttributes.self) { context in
            // Lock screen / banner
            ReadingTimerLockScreenView(context: context)
                .activityBackgroundTint(Color(red: 0.02, green: 0.03, blue: 0.04))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        WidgetBookIcon(size: 14)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Reading")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                            
                            Text(context.attributes.bookTitle.isEmpty ? "Session" : context.attributes.bookTitle)
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: 82, alignment: .leading)
                    }
                    .padding(.leading, 2)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.isPaused ? "Paused" : "Live")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(context.state.isPaused ? .white.opacity(0.45) : Color(widgetHex: "#03DBFC"))

                        if context.state.isPaused {
                            Text(formatSeconds(context.state.pausedElapsedSeconds))
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .monospacedDigit()
                                .frame(width: 44, alignment: .trailing)
                        } else {
                            Text(adjustedStartDate(for: context.state), style: .timer)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .monospacedDigit()
                                .frame(width: 44, alignment: .trailing)
                        }
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label {
                            Text(context.state.isPaused ? "Timer paused" : "Timer running")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.65))
                        } icon: {
                            Image(systemName: context.state.isPaused ? "pause.circle.fill" : "timer")
                                .font(.system(size: 14))
                                .foregroundStyle(context.state.isPaused ? .white.opacity(0.45) : Color(widgetHex: "#03DBFC"))
                        }
                        Spacer()
                        Text("Open Lumey")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(Color(widgetHex: "#7D19F7"))
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                WidgetBookIcon(size: 12)
            } compactTrailing: {
                if context.state.isPaused {
                    Text(formatSeconds(context.state.pausedElapsedSeconds))
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .frame(width: 34, alignment: .trailing)
                } else {
                    Text(adjustedStartDate(for: context.state), style: .timer)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .frame(width: 34, alignment: .trailing)
                }
            } minimal: {
                WidgetBookIcon(size: 12)
            }
            .widgetURL(URL(string: "lumey://timer"))
            .keylineTint(Color(widgetHex: "#03DBFC"))
        }
    }

    private func adjustedStartDate(for state: ReadingTimerAttributes.ContentState) -> Date {
        state.startDate.addingTimeInterval(-Double(state.pausedElapsedSeconds))
    }

    private func formatSeconds(_ total: Int) -> String {
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Lock Screen View

struct ReadingTimerLockScreenView: View {
    let context: ActivityViewContext<ReadingTimerAttributes>

    private var adjustedStartDate: Date {
        context.state.startDate.addingTimeInterval(-Double(context.state.pausedElapsedSeconds))
    }

    private var formattedPausedElapsed: String {
        String(format: "%02d:%02d", context.state.pausedElapsedSeconds / 60, context.state.pausedElapsedSeconds % 60)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            WidgetBookIcon(size: 26)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Color.white.opacity(0.07)))

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.bookTitle.isEmpty ? "Reading Session" : context.attributes.bookTitle)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(context.state.isPaused ? "Paused" : "Reading in progress")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if context.state.isPaused {
                    Text(formattedPausedElapsed)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                } else {
                    Text(adjustedStartDate, style: .timer)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(context.state.isPaused ? Color.white.opacity(0.3) : Color(widgetHex: "#03DBFC"))
                        .frame(width: 6, height: 6)
                    Text(context.state.isPaused ? "Paused" : "Live")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(context.state.isPaused ? .white.opacity(0.45) : Color(widgetHex: "#03DBFC"))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Widget Asset Icon

private struct WidgetBookIcon: View {
    let size: CGFloat
    
    var body: some View {
        Image("book")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(widgetHex: "#7D19F7"), Color(widgetHex: "#B66CFF")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Color Helper (widget target)

private extension Color {
    init(widgetHex hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

extension ReadingTimerAttributes {
    fileprivate static var preview: ReadingTimerAttributes {
        ReadingTimerAttributes(bookTitle: "The Night Circus")
    }
}

extension ReadingTimerAttributes.ContentState {
    fileprivate static var running: ReadingTimerAttributes.ContentState {
        ReadingTimerAttributes.ContentState(
            startDate: Date(),
            elapsedSeconds: 0,
            isPaused: false,
            pausedElapsedSeconds: 742
        )
    }

    fileprivate static var paused: ReadingTimerAttributes.ContentState {
        ReadingTimerAttributes.ContentState(
            startDate: Date(),
            elapsedSeconds: 0,
            isPaused: true,
            pausedElapsedSeconds: 742
        )
    }
}

#Preview("Lock Screen", as: .content, using: ReadingTimerAttributes.preview) {
    LumeyWidgetsLiveActivity()
} contentStates: {
    ReadingTimerAttributes.ContentState.running
    ReadingTimerAttributes.ContentState.paused
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: ReadingTimerAttributes.preview) {
    LumeyWidgetsLiveActivity()
} contentStates: {
    ReadingTimerAttributes.ContentState.running
    ReadingTimerAttributes.ContentState.paused
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: ReadingTimerAttributes.preview) {
    LumeyWidgetsLiveActivity()
} contentStates: {
    ReadingTimerAttributes.ContentState.running
    ReadingTimerAttributes.ContentState.paused
}
