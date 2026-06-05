import SwiftUI
import BackgroundTasks

@main
struct LinxNightscoutBridgeApp: App {
    @StateObject private var syncService = SyncService()

    init() {
        BackgroundSync.register()

        if UserDefaults.standard.bool(forKey: "keepAliveEnabled") {
            SilentTuneManager.shared.start()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(syncService)
                .onAppear {
                    BackgroundSync.schedule()

                    if UserDefaults.standard.bool(forKey: "keepAliveEnabled") {
                        SilentTuneManager.shared.start()
                    }
                }
        }
    }
}
