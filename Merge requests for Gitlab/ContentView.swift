import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GitLabViewModel()
    @AppStorage("gitlabToken") private var apiToken: String = ""
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Sélecteur d'onglets
            Picker("", selection: $selectedTab) {
                Text("Mes MRs (\(viewModel.createdMRs.count))").tag(0)
                Text("À réviser (\(viewModel.assignedMRs.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                if apiToken.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "key.fill").font(.system(size: 40))
                        Text("Token manquant").font(.headline)
                        Text("Ouvrez les réglages (⌘,) pour configurer l'accès.")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.isLoading && viewModel.createdMRs.isEmpty && viewModel.assignedMRs.isEmpty {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Synchronisation GitLab...").font(.caption).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    let mrs = selectedTab == 0 ? viewModel.createdMRs : viewModel.assignedMRs
                    if mrs.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "sun.max").font(.system(size: 30))
                            Text("Rien à signaler").font(.headline)
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(mrs) { mr in
                            MRRow(mr: mr)
                        }
                        .listStyle(.inset)
                    }
                }
            }
            .frame(minHeight: 500)

            Divider()
            footer
        }
        .onAppear { if !apiToken.isEmpty { Task { await viewModel.fetchAll(token: apiToken) } } }
    }
    
    var footer: some View {
        HStack {
            SettingsLink {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            
            Button {
                Task { await viewModel.fetchAll(token: apiToken) }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            if viewModel.isLoading {
                ProgressView().controlSize(.small)
            }
            
            Spacer()
            
            Button("Quitter") { NSApplication.shared.terminate(nil) }
                .controlSize(.small)
        }
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct MRRow: View {
    let mr: MergeRequest
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar de l'auteur
            AsyncImage(url: URL(string: mr.author.avatarUrl ?? "")) { image in
                image.resizable()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 34, height: 34)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                // Titre
                HStack(alignment: .top) {
                    if mr.draft {
                        Text("DRAFT")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2)).cornerRadius(4)
                    }
                    Text(mr.title)
                        .fontWeight(.semibold)
                        .font(.system(size: 14))
                        .lineLimit(2)
                }
                
                // Métadonnées
                HStack(spacing: 4) {
                    Text(mr.references.full).fontWeight(.bold)
                    Text("•")
                    Text("par \(mr.author.name)")
                    Text("•")
                    Text(mr.createdAt.relativeTime())
                }
                .font(.system(size: 11))
                .foregroundColor(.secondary)

                // Labels
                if !mr.labels.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(mr.labels, id: \.self) { label in
                                Text(label)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(labelColor(label).opacity(0.15))
                                    .foregroundColor(labelColor(label))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { if let url = URL(string: mr.webUrl) { NSWorkspace.shared.open(url) } }
    }
    
    func labelColor(_ label: String) -> Color {
        let l = label.lowercased()
        if l.contains("feature") || l.contains("🚀") { return .blue }
        if l.contains("bug") || l.contains("🐛") { return .red }
        if l.contains("enhancement") || l.contains("amélioration") { return .green }
        return .secondary
    }
}

struct SettingsView: View {
    @AppStorage("gitlabToken") private var apiToken: String = ""
    var body: some View {
        Form {
            Section {
                SecureField("GitLab Personal Access Token :", text: $apiToken)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Configuration").fontWeight(.bold)
            }
        }
        .padding(30)
        .frame(width: 450, height: 150)
    }
}

extension Date {
    func relativeTime() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
