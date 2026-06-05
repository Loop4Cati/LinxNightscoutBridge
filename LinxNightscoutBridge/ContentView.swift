import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var syncService: SyncService

    @AppStorage("nightscoutURL") private var nightscoutURL = ""
    @AppStorage("apiSecret") private var apiSecret = ""
    @AppStorage("keepAliveEnabled") private var keepAliveEnabled = false

    private let syncTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Form {
                Section("Nightscout") {
                    TextField("https://heygluco.ro sau domeniul tău", text: $nightscoutURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("API_SECRET", text: $apiSecret)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Permisiuni") {
                    Button("Permite citirea glicemiei") {
                        Task {
                            await syncService.requestHealthPermission()
                        }
                    }
                }

                Section("Keep Alive") {
                    Toggle("Silent Tune", isOn: $keepAliveEnabled)
                        .onChange(of: keepAliveEnabled) { enabled in
                            if enabled {
                                SilentTuneManager.shared.start()
                            } else {
                                SilentTuneManager.shared.stop()
                            }
                        }

                    Text("Menține aplicația activă în fundal folosind redare audio silențioasă și sincronizare periodică.")
                        .font(.footnote)
                }

                Section("Sincronizare") {
                    Button("Sincronizează valorile noi") {
                        Task {
                            await syncService.syncLatestGlucose()
                        }
                    }
                    .disabled(nightscoutURL.isEmpty || apiSecret.isEmpty)

                    Button("Resetează istoricul sync") {
                        syncService.resetSyncHistory()
                    }
                    .foregroundStyle(.red)

                    if let last = syncService.lastMessage {
                        Text(last)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Linx → Nightscout")
            .onReceive(syncTimer) { _ in
                guard keepAliveEnabled else { return }
                guard !nightscoutURL.isEmpty, !apiSecret.isEmpty else { return }

                Task {
                    await syncService.syncLatestGlucose()
                }
            }
        }
    }
}
