import Foundation

final class ResultStore: ObservableObject {
    @Published private(set) var results: [SavedRaceResult] = []

    private let storageKey = "boatRacePredictor.results"

    init() {
        load()
    }

    func result(for raceId: String) -> SavedRaceResult? {
        results.first { $0.raceId == raceId }
    }

    func save(raceId: String, finishOrder: [Int], payout: Int, stake: Int) {
        let result = SavedRaceResult(
            raceId: raceId,
            finishOrder: finishOrder,
            payout: payout,
            stake: stake,
            savedAt: Date()
        )
        results.removeAll { $0.raceId == raceId }
        results.append(result)
        persist()
    }

    func stats(for races: [BoatRace]) -> ResultStats {
        let predictions = Dictionary(uniqueKeysWithValues: races.map { race in
            (race.id, PredictionEngine.predict(race: race))
        })
        var hits = 0
        var stake = 0
        var returns = 0

        for result in results {
            guard let prediction = predictions[result.raceId] else { continue }
            stake += result.stake
            if PredictionEngine.isHit(prediction: prediction, result: result) {
                hits += 1
                returns += result.payout
            }
        }

        return ResultStats(races: results.count, hits: hits, stake: stake, returns: returns)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([SavedRaceResult].self, from: data)
        else { return }
        results = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(results) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
