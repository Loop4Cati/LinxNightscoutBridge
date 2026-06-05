import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var syncService: SyncService

    @AppStorage("nightscoutURL") private var nightscoutURL = ""
    @AppStorage("apiSecret") private var apiSecret = ""
    @AppStorage("keepAliveEnabled") private var keepAliveEnabled = false

    private let syncTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                statusCard

                nightscoutCard

                healthCard

                keepAliveCard

                syncCard
            }
            .padding(20)
        }
        .background(Color(hex: "0F1115").ignoresSafeArea())
        .onReceive(syncTimer) { _ in
            guard keepAliveEnabled else { return }
            guard !nightscoutURL.isEmpty, !apiSecret.isEmpty else { return }

            Task {
                await syncService.syncLatestGlucose()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image("HeyGlucoLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 90)

            Text("Linx → iOS → Nightscout")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("heygluco.ro")
                .font(.footnote)
                .foregroundStyle(Color(hex: "A8ADB7"))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
    }

    private var statusCard: some View {
    card {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .sectionTitle()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)

                    Text(syncService.lastMessage ?? "Pregătit pentru sincronizare")
                        .foregroundStyle(.white)
                        .font(.body)
                }

                if let lastSyncDate = syncService.lastSyncDate {
                    Text("Ultima sincronizare: \(lastSyncDate.formatted(date: .omitted, time: .shortened))")
                        .foregroundStyle(Color(hex: "A8ADB7"))
                        .font(.footnote)

                    Text("Valori trimise la ultimul sync: \(syncService.lastSyncCount)")
                        .foregroundStyle(Color(hex: "A8ADB7"))
                        .font(.footnote)
                }
            }
        }
    }
}

    private var nightscoutCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Nightscout")
                    .sectionTitle()

                TextField("https://numele-tău.nsromania.info", text: $nightscoutURL)
                    .textFieldStyleHeyGluco()
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("API Secret", text: $apiSecret)
                    .textFieldStyleHeyGluco()
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
    }

    private var healthCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Apple Health")
                    .sectionTitle()

                Button {
                    Task {
                        await syncService.requestHealthPermission()
                    }
                } label: {
                    Label("Permite citirea glicemiei", systemImage: "heart.text.square.fill")
                        .buttonLabel()
                }
            }
        }
    }

    private var keepAliveCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Keep Alive")
                    .sectionTitle()

                Toggle(isOn: $keepAliveEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Silent Tune")
                            .foregroundStyle(.white)
                            .font(.body.bold())

                        Text("Menține aplicația activă în fundal folosind redare audio silențioasă.")
                            .foregroundStyle(Color(hex: "A8ADB7"))
                            .font(.footnote)
                    }
                }
                .tint(Color(hex: "FF6B4A"))
                .onChange(of: keepAliveEnabled) { enabled in
                    if enabled {
                        SilentTuneManager.shared.start()
                    } else {
                        SilentTuneManager.shared.stop()
                    }
                }
            }
        }
    }

    private var syncCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Sincronizare")
                    .sectionTitle()

                Button {
                    Task {
                        await syncService.syncLatestGlucose()
                    }
                } label: {
                    Label("Sincronizează acum", systemImage: "arrow.triangle.2.circlepath")
                        .buttonLabel()
                }
                .disabled(nightscoutURL.isEmpty || apiSecret.isEmpty)

                Button {
                    syncService.resetSyncHistory()
                } label: {
                    Label("Resetează istoricul sync", systemImage: "trash")
                        .foregroundStyle(Color(hex: "FF6B4A"))
                        .font(.body.bold())
                }
            }
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "1A1D24"))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private extension Text {
    func sectionTitle() -> some View {
        self
            .font(.headline)
            .foregroundStyle(Color(hex: "FF6B4A"))
    }
}

private extension View {
    func textFieldStyleHeyGluco() -> some View {
        self
            .padding(14)
            .foregroundStyle(.white)
            .background(Color(hex: "0F1115"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func buttonLabel() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color(hex: "FF6B4A"))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .font(.body.bold())
    }
}

private extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}
