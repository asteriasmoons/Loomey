//
//  ContentView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var themeController = LumeyThemeController.shared

    var body: some View {
        MainTabView()
            .environmentObject(appState)
            .environmentObject(themeController)
            .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
