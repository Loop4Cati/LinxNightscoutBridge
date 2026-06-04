import SwiftUI
import BackgroundTasks

@main
struct LinxNightscoutBridgeApp: App {
    @StateObject private var syncService = SyncService()

    init() {
        BackgroundSync.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(syncService)
                .onAppear {
                    BackgroundSync.schedule()
                }
        }
    }
}
