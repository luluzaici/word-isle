import SwiftUI

@main
struct WordIsleApp: App {
    @StateObject private var store = WordStore()

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @ObservedObject var store: WordStore

    @State private var tab = 0
    @State private var selectedWord: Word?
    @State private var session: StudyLaunch?
    @State private var showSettings = false

    var body: some View {
        TabView(selection: $tab) {
            HomeView(
                onStart: start,
                onOpenWord: { selectedWord = $0 },
                onSettings: { showSettings = true }
            )
            .tabItem { Label("学习", systemImage: "book.closed") }
            .tag(0)

            LibraryView(onOpenWord: { selectedWord = $0 })
                .tabItem { Label("词库", systemImage: "square.grid.2x2") }
                .tag(1)

            StatsView(onOpenWord: { selectedWord = $0 })
                .tabItem { Label("统计", systemImage: "chart.bar") }
                .tag(2)
        }
        .tint(Color.isleGreen)
        .toolbarBackground(Color.isleBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .environmentObject(store)
        .sheet(item: $selectedWord) { word in
            WordDetailView(word: word) { selected in
                selectedWord = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    session = StudyLaunch(
                        mode: .review,
                        words: store.makeQueue(mode: .review, fixed: [selected])
                    )
                }
            }
            .environmentObject(store)
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $session) { launch in
            StudySessionView(launch: launch)
                .environmentObject(store)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
                .presentationDetents([.large])
        }
    }

    private func start(_ mode: StudyMode) {
        let words = store.makeQueue(mode: mode)
        guard !words.isEmpty else { return }
        session = StudyLaunch(mode: mode, words: words)
    }
}
