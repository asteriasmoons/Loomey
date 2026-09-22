//
//  ContentView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var themeController = LumeyThemeController.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        MainTabView()
            .environmentObject(appState)
            .environmentObject(themeController)
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                appState.handleReportConversationURL(url)
            }
            .onReceive(NotificationCenter.default.publisher(
                for: LumeyReportConversationNotificationManager.conversationNotificationOpened
            )) { notification in
                guard let reportID = notification.object as? String else { return }
                appState.handleReportConversationID(reportID)
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await LumeyReportConversationNotificationManager.scanForNewMessages() }
            }
    }
}

#Preview {
    ContentView()
}
