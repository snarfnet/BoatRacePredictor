import Foundation

struct RaceCondition: Codable, Hashable {
    let weather: String
    let windDirection: String
    let windSpeed: Double
    let waveHeight: Double
}

struct BoatEntry: Identifiable, Codable, Hashable {
    var id: Int { lane }
    let lane: Int
    let racerName: String
    let racerId: String
    let racerClass: String
    let branch: String
    let nationalWinRate: Double
    let localWinRate: Double
    let startTiming: Double
    let motorNumber: Int
    let motorSecondRate: Double
    let boatNumber: Int
    let boatSecondRate: Double
    let exhibitionTime: Double
    let tilt: Double
    let predictedCourse: Int
}

struct BoatRace: Identifiable, Codable, Hashable {
    let id: String
    let date: String
    let stadium: String
    let raceNumber: Int
    let deadline: String
    let grade: String
    let distance: Int
    let condition: RaceCondition
    let entries: [BoatEntry]
}

struct ScoredBoat: Identifiable, Hashable {
    var id: Int { entry.lane }
    let entry: BoatEntry
    let score: Double
    let rank: Int
    let role: BoatRole
    let signals: [String]
}

enum BoatRole: String, Hashable {
    case main = "本命"
    case rival = "対抗"
    case longshot = "穴"
    case press = "押さえ"
}

struct Ticket: Identifiable, Hashable {
    let id = UUID()
    let lanes: [Int]
    let note: String
}

struct RacePrediction: Hashable {
    let raceId: String
    let scoredBoats: [ScoredBoat]
    let tickets: [Ticket]
    let confidence: Int
    let upsetLevel: Int
    let shouldSkip: Bool
    let reasons: [String]

    var main: ScoredBoat? { scoredBoats.first { $0.role == .main } }
    var rival: ScoredBoat? { scoredBoats.first { $0.role == .rival } }
    var longshot: ScoredBoat? { scoredBoats.first { $0.role == .longshot } }
}

struct SavedRaceResult: Identifiable, Codable, Hashable {
    var id: String { raceId }
    let raceId: String
    let finishOrder: [Int]
    let payout: Int
    let stake: Int
    let savedAt: Date
}

struct ResultStats {
    let races: Int
    let hits: Int
    let stake: Int
    let returns: Int

    var hitRate: Double {
        guard races > 0 else { return 0 }
        return Double(hits) / Double(races) * 100
    }

    var returnRate: Double {
        guard stake > 0 else { return 0 }
        return Double(returns) / Double(stake) * 100
    }
}
