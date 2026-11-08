import SwiftUI
import UIKit

struct OriginalContentView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @State private var tabNavigation: AppTabNavigationState
    @AppStorage(FeatureVisibility.cleanerStorageKey) private var cleanerEnabled = true
    @AppStorage(FeatureVisibility.wallpapersStorageKey) private var wallpapersEnabled = true

    init() {
#if targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        let initialTab: Int
        if arguments.contains("--simulate-files-tab") {
            initialTab = 1
        } else if arguments.contains("--simulate-patch-tab") {
            initialTab = 2
        } else if arguments.contains("--simulate-cleaner-tab") {
            initialTab = 3
        } else if arguments.contains("--simulate-wallpaper-tab") {
            initialTab = 4
        } else {
            initialTab = 0
        }
        _tabNavigation = State(initialValue: AppTabNavigationState(selectedTab: initialTab))
#else
        _tabNavigation = State(initialValue: AppTabNavigationState())
#endif
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .tint(AppTheme.accent)
        .imageScale(.small)
        .onChange(of: patchDraftCoordinator.request?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.patches.rawValue) }
        }
        .onChange(of: patchDraftCoordinator.importRequest?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.patches.rawValue) }
        }
        .onChange(of: cleanerEnabled) { _ in
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .onChange(of: wallpapersEnabled) { _ in
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .onAppear {
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
    }

    private var compactLayout: some View {
        TabView(selection: tabSelection) {
            ForEach(featureVisibility.visibleSections) { section in
                sectionContent(section)
                    .tabItem {
                        CompactTabLabel(
                            title: language.text(section.titleKey),
                            systemImage: section.systemImage
                        )
                    }
                    .tag(section.rawValue)
            }
        }
    }

    private var regularLayout: some View {
        NavigationSplitView {
            List {
                ForEach(featureVisibility.visibleSections) { section in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            tabNavigation.select(section.rawValue)
                        }
                    } label: {
                        Label(language.text(section.titleKey), systemImage: section.systemImage)
                            .fontWeight(section.rawValue == tabNavigation.selectedTab ? .semibold : .regular)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        section.rawValue == tabNavigation.selectedTab
                            ? AppTheme.accent.opacity(0.14)
                            : Color.clear
                    )
                    .accessibilityAddTraits(
                        section.rawValue == tabNavigation.selectedTab ? .isSelected : []
                    )
                }
            }
            .navigationTitle("3105")
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
        } detail: {
            sectionContent(selectedVisibleSection)
                .id(selectedVisibleSection.rawValue)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func sectionContent(_ section: AppSection) -> some View {
        switch section {
        case .home:
            DashboardView(
                cleanerEnabled: $cleanerEnabled,
                wallpapersEnabled: $wallpapersEnabled,
                wallpapersSupported: wallpapersSupported
            )
        case .files:
            AppDataBrowserView(
                tabSession: filesTabSession
            )
        case .patches:
            PatchProjectsView()
        case .cleaner:
            CleanerView()
        case .wallpapers:
            WallpaperLabView()
        }
    }

    private var tabSelection: Binding<Int> {
        Binding(
            get: { tabNavigation.selectedTab },
            set: { tabNavigation.select($0) }
        )
    }

    private var filesTabSession: Binding<FilesTabSession> {
        Binding(
            get: { tabNavigation.filesTabs },
            set: { tabNavigation.setFilesTabs($0) }
        )
    }

    private var featureVisibility: FeatureVisibility {
        FeatureVisibility(
            cleanerEnabled: cleanerEnabled,
            wallpapersEnabled: wallpapersEnabled,
            wallpapersSupported: wallpapersSupported
        )
    }

    private var wallpapersSupported: Bool {
        WallpaperFeatureSupportPolicy.isSupported(major: AppInfo.versionTuple.major)
    }

    private var selectedVisibleSection: AppSection {
        guard let section = AppSection(rawValue: tabNavigation.selectedTab),
              featureVisibility.isVisible(section) else {
            return .home
        }
        return section
    }
}

private struct CompactTabLabel: View {
    let title: String
    let systemImage: String

    @ViewBuilder
    var body: some View {
        if let image = UIImage(
            systemName: systemImage,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        )?.withRenderingMode(.alwaysTemplate) {
            Image(uiImage: image)
        } else {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
        }
        Text(title)
    }
}

private extension AppSection {
    var titleKey: String {
        switch self {
        case .home: return "tab.home"
        case .files: return "tab.files"
        case .patches: return "tab.patches"
        case .cleaner: return "tab.cleaner"
        case .wallpapers: return "tab.wallpapers"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .files: return "folder.fill"
        case .patches: return "shippingbox.fill"
        case .cleaner: return "sparkles"
        case .wallpapers: return "photo.on.rectangle.angled"
        }
    }
}

private struct DashboardView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @State private var showSettings = false
    @State private var showLogs = false
    @Binding var cleanerEnabled: Bool
    @Binding var wallpapersEnabled: Bool
    let wallpapersSupported: Bool

    var body: some View {
        NavigationStack {
            List {
                deviceSection
                featuresSection
            }
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.accent)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showLogs = true } label: {
                        Image(systemName: "apple.terminal")
                    }
                    .accessibilityLabel(language.text("accessibility.open_logs"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(language.text("accessibility.open_settings"))
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showLogs) { LogView() }
        }
    }

    private var featuresSection: some View {
        Section {
            Toggle(isOn: $cleanerEnabled) {
                Label(language.text("tab.cleaner"), systemImage: "sparkles")
            }
            if wallpapersSupported {
                Toggle(isOn: $wallpapersEnabled) {
                    Label(language.text("tab.wallpapers"), systemImage: "photo.on.rectangle.angled")
                }
            }
        } header: {
            Text(language.text("dashboard.features"))
        } footer: {
            Text(language.text("dashboard.features_footer"))
        }
    }

    private var deviceSection: some View {
        Section {
            LabeledContent(language.text("dashboard.hardware_model")) {
                Text(AppInfo.displayMachineName)
                    .font(.body.monospaced())
            }
            LabeledContent(language.text("settings.ios_version")) {
                Text("\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                    .font(.body.monospaced())
            }
            HStack {
                Text(language.text("settings.compatibility"))
                Spacer()
                Text(language.text(appState.isSupported ? "settings.supported" : "settings.unsupported"))
                .foregroundStyle(appState.isSupported ? Color.green : Color.red)
            }

            if appState.kernelExploitApplicable && AppInfo.versionTuple.major < 26 {
                HStack {
                    Text(language.text("dashboard.kernel_status"))
                    Spacer()
                    if appState.kernelExploitRunning {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text(language.text("dashboard.kernel_running"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(language.text(appState.exploitStatus.isSuccess ? "dashboard.kernel_active" : "dashboard.kernel_inactive"))
                        .foregroundStyle(appState.exploitStatus.isSuccess ? Color.green : Color.secondary)
                    }
                }
            }
        } header: {
            Text(language.text("common.device"))
        } footer: {
            Text(language.text("settings.supported_range_summary"))
        }
    }
}


// Panther presentation only. Patch application, validation, backup and recovery
// remain in the original PatchProjectsView / DevicePatchService flow.
private enum PantherTheme {
    static let background = Color(red: 0.015, green: 0.025, blue: 0.035)
    static let panel = Color(red: 0.025, green: 0.055, blue: 0.07)
    static let cyan = Color(red: 0.10, green: 0.77, blue: 0.97)
    static let green = Color(red: 0.25, green: 0.91, blue: 0.48)
    static let violet = Color(red: 0.72, green: 0.29, blue: 0.96)
    static let red = Color(red: 0.98, green: 0.20, blue: 0.32)
    static let text = Color.white
    static let muted = Color.gray
}

struct ContentView: View {
    @EnvironmentObject private var coordinator: PatchDraftCoordinator
    @State private var showTools = false
    var body: some View {
        PantherHomeView(showTools: $showTools)
            .fullScreenCover(isPresented: $showTools) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Panther IOS").font(.headline)
                        Spacer()
                        Button("Cerrar") { showTools = false }
                    }.padding()
                    OriginalContentView()
                }
            }
            .onChange(of: coordinator.request?.id) { id in
                if id != nil { showTools = true }
            }
            .onChange(of: coordinator.importRequest?.id) { id in
                if id != nil { showTools = true }
            }
    }
}

private struct PantherRoute: Identifiable {
    let id = UUID()
    let category: String?
}

private struct PantherHomeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @Binding var showTools: Bool
    @State private var destination: PantherRoute?
    @State private var selectedCategory: String?
    @State private var libraryCount = 0
    @State private var workspaceCount = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                stage
                library
            }
            .padding(16)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background(PantherTheme.background.ignoresSafeArea())
        .foregroundStyle(PantherTheme.text)
        .preferredColorScheme(.dark)
        .sheet(item: $destination, onDismiss: reload) { route in
            VStack(spacing: 0) {
                HStack {
                    Text(route.category ?? "PATCHES").font(.headline)
                    Spacer()
                    Button("Cerrar") { destination = nil }
                }.padding()
                PatchProjectsView(category: route.category)
            }
        }
        .onAppear(perform: reload)
        .onChange(of: scenePhase) { phase in
            if phase == .active { reload() }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Panther").font(.system(size: 32, weight: .light))
                    Text("IOS").font(.system(size: 32, weight: .bold))
                        .foregroundStyle(PantherTheme.cyan)
                }.minimumScaleFactor(0.7).lineLimit(1)
                Text("iOS \(AppInfo.osVersion)")
                    .font(.subheadline).foregroundStyle(PantherTheme.muted)
            }
            Spacer(minLength: 8)
            Button { showTools = true } label: {
                Image(systemName: "ellipsis")
                    .font(.title3.weight(.bold))
                    .frame(width: 48, height: 48)
                    .background(PantherTheme.panel, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(PantherTheme.cyan.opacity(0.5)))
            }.accessibilityLabel("Herramientas originales, archivos y ajustes")
                .foregroundStyle(PantherTheme.cyan)
        }
    }

    private var stage: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle().fill(appState.isSupported ? PantherTheme.green : PantherTheme.red)
                    .frame(width: 7, height: 7)
                Text(appState.isSupported ? "PATCH CONTROL" : "iOS NO COMPATIBLE")
                Spacer()
                Text("PRECISION · CONTROL").foregroundStyle(PantherTheme.muted)
            }.font(.system(size: 9, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.6)

            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                ZStack {
                    Circle().stroke(PantherTheme.cyan.opacity(0.7), lineWidth: 1)
                        .frame(width: width * 0.94, height: width * 0.94)
                        .shadow(color: PantherTheme.cyan.opacity(0.45), radius: 12)
                    Image("PantherCharacter")
                        .resizable().scaledToFit()
                        .frame(width: width * 0.72, height: height * 0.91)
                    slot("HEAD", icon: "person.crop.circle", color: PantherTheme.cyan)
                        .position(x: width * 0.22, y: height * 0.16)
                    slot("NECK", icon: "figure.stand", color: PantherTheme.violet)
                        .position(x: width * 0.78, y: height * 0.35)
                    slot("CHEST", icon: "tshirt", color: PantherTheme.green)
                        .position(x: width * 0.22, y: height * 0.87)
                    VStack(spacing: 10) {
                        weapon("WEAPON1", image: "WeaponSlot1")
                        weapon("WEAPON2", image: "WeaponSlot2")
                    }.frame(width: width * 0.35)
                        .position(x: width * 0.80, y: height * 0.77)
                }
            }.aspectRatio(0.82, contentMode: .fit)

            HStack {
                Text(selectedCategory ?? "PATCHES")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PantherTheme.cyan)
                Spacer()
                Button {
                    destination = PantherRoute(category: selectedCategory)
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title2)
                        .frame(width: 60, height: 44)
                        .background(PantherTheme.background, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(PantherTheme.red, lineWidth: 1.5))
                }.foregroundStyle(PantherTheme.red)
                    .accessibilityLabel("Abrir parches para aplicar o restaurar")
            }
        }.padding(14)
            .background(PantherTheme.panel, in: RoundedRectangle(cornerRadius: 8))
    }

    private var library: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("PATCH LIBRARY").font(.headline.weight(.medium))
                Spacer()
                Button { reload() } label: {
                    Image(systemName: "arrow.clockwise").frame(width: 44, height: 44)
                }.accessibilityLabel("Actualizar biblioteca")
                    .foregroundStyle(PantherTheme.cyan)
            }
            HStack {
                metric("PAQUETES", value: libraryCount, color: PantherTheme.cyan)
                Spacer()
                metric("WORKSPACES", value: workspaceCount, color: PantherTheme.green)
            }
            Button {
                destination = PantherRoute(category: nil)
            } label: {
                Label("IMPORTAR / GESTIONAR", systemImage: "folder.badge.plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(PantherTheme.cyan.opacity(0.5)))
            }.foregroundStyle(PantherTheme.cyan)
        }.padding(4)
    }

    private func metric(_ title: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(value)").font(.system(size: 30, weight: .light)).foregroundStyle(color)
            Text(title).font(.caption2).foregroundStyle(PantherTheme.muted)
        }
    }

    private func slot(_ title: String, icon: String, color: Color) -> some View {
        Button {
            selectedCategory = title
            destination = PantherRoute(category: title)
        } label: {
            HStack(spacing: 7) {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.system(size: 12, weight: .bold)).lineLimit(1)
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(color)
            }
            .frame(width: 120, height: 48)
            .background(PantherTheme.background.opacity(0.93), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: selectedCategory == title ? 2 : 1))
        }.buttonStyle(.plain).accessibilityLabel("Parches \(title)")
    }

    private func weapon(_ category: String, image: String) -> some View {
        Button {
            selectedCategory = category
            destination = PantherRoute(category: category)
        } label: {
            Image(image).resizable().scaledToFit()
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(PantherTheme.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(PantherTheme.cyan.opacity(0.6)))
        }.accessibilityLabel("Parches \(category)")
    }

    private func reload() {
        libraryCount = PatchProjectLibrary.load().count
        if let root = try? PatchWorkspaceService.patchesRootURL(),
           let urls = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
            workspaceCount = urls.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }.count
        } else {
            workspaceCount = 0
        }
    }
}
