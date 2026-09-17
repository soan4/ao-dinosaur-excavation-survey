import SwiftUI

@main struct DinosaurDigApp: App {
    @StateObject private var store: GameStore
    @Environment(\.scenePhase) private var scenePhase
    init() {
        let testing = ProcessInfo.processInfo.arguments.contains("--ui-testing")
        let defaults = testing ? UserDefaults(suiteName:"DinosaurDig.UITesting")! : .standard
        if testing { defaults.removePersistentDomain(forName:"DinosaurDig.UITesting") }
        _store = StateObject(wrappedValue:GameStore(defaults:defaults))
    }
    var body: some Scene {
        WindowGroup {
            DigView(store:store)
                .preferredColorScheme(.light)
                .onChange(of:scenePhase) { _, phase in if phase != .active { store.save() } }
        }
    }
}
