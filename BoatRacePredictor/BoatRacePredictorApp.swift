import SwiftUI

@main
struct BoatRacePredictorApp: App {
    @StateObject private var resultStore = ResultStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(resultStore)
        }
    }
}
