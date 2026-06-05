import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var syncService: SyncService

    @AppStorage("nightscoutURL") private var nightscoutURL = ""
    @AppStorage("apiSecret") private var apiSecret = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Nightscout") {
                    TextField("https://site.herokuapp.com sau domeniul tău", text: $nightscoutURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("API_SECRET", text: $apiSecret)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Permisiuni") {
                    Button("Permite citirea glicemiei din Health") {
                        Task {
                            await syncService.requestHealthPermission()
                        }
                    }
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
        }
    }
}
