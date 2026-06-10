import SwiftUI

struct AccountSheet: View {

    @Environment(AuthState.self) private var authState
    @Environment(BlogModel.self) private var blogModel
    @Environment(CatalogueModel.self) private var catalogueModel
    @Environment(\.dismiss) private var dismiss

    @State private var isFullSyncing = false

    var body: some View {
        NavigationStack {
            Group {
                if authState.isSignedIn {
                    Form {
                        Section("Sync") {
                            Button {
                                Task { await fullSync() }
                            } label: {
                                HStack {
                                    Label("Full Sync", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                                    Spacer()
                                    if isFullSyncing {
                                        ProgressView()
                                    }
                                }
                            }
                            .disabled(isFullSyncing)
                        }

                        Section {
                            Button("Sign Out", role: .destructive) {
                                Task { await authState.signOut() }
                            }
                        }
                    }
                } else {
                    SignInView()
                }
            }
            .navigationTitle("Account")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .frame(minWidth: 320, minHeight: 380)
        .onChange(of: authState.isSignedIn) { _, _ in dismiss() }
    }

    private func fullSync() async {
        isFullSyncing = true
        defer { isFullSyncing = false }
        // Reset hasMore so views show load-more again after a full sync
        try? await blogModel.syncEngine.syncFull()
    }
}
