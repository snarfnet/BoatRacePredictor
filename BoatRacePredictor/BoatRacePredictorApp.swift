import SwiftUI

@main
struct BoatRacePredictorApp: App {
    @StateObject private var resultStore = ResultStore()
    @StateObject private var dataManager = DataManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(resultStore)
                .environmentObject(dataManager)
                .onAppear {
                    dataManager.loadRaces()
                }
        }
    }
}
