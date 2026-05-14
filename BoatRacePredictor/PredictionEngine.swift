import Foundation

enum PredictionEngine {
    static func predict(race: BoatRace) -> RacePrediction {
        let fastestExhibition = race.entries.map(\.exhibitionTime).min() ?? 6.80
        let averageMotor = average(race.entries.map(\.motorSecondRate))

        let rawScores = race.entries.map { entry in
            let courseScore = courseBase(entry.predictedCourse, race: race)
            let playerScore = normalize(entry.nationalWinRate, min: 3.5, max: 7.5)
            let localScore = normalize(entry.localWinRate, min: 3.5, max: 7.5)
            let motorScore = normalize(entry.motorSecondRate, min: 20, max: 50)
            let exhibitionScore = clamp(100 - ((entry.exhibitionTime - fastestExhibition) * 260), lower: 35, upper: 100)
            let startScore = clamp(100 - ((entry.startTiming - 0.10) * 500), lower: 35, upper: 100)
            let weatherScore = weatherAdjustment(entry: entry, race: race)

            var score = courseScore * 0.22
            score += playerScore * 0.18
            score += localScore * 0.10
            score += motorScore * 0.18
            score += exhibitionScore * 0.14
            score += startScore * 0.10
            score += weatherScore * 0.08

            var signals: [String] = []
            if entry.predictedCourse == 1 && score >= 72 { signals.append("イン安定") }
            if entry.motorSecondRate >= averageMotor + 5 { signals.append("モーター上位") }
            if entry.exhibitionTime <= fastestExhibition + 0.03 { signals.append("展示良好") }
            if entry.startTiming <= 0.13 { signals.append("スタート早い") }
            if entry.localWinRate >= entry.nationalWinRate + 0.35 { signals.append("当地相性") }
            if race.condition.windSpeed >= 5 && entry.predictedCourse >= 3 && entry.predictedCourse <= 5 {
                signals.append("風で浮上")
            }

            return (entry: entry, score: round(score * 10) / 10, signals: signals)
        }

        let sorted = rawScores.sorted { $0.score > $1.score }
        let topGap = (sorted.first?.score ?? 0) - (sorted.dropFirst().first?.score ?? 0)
        let scoreSpread = (sorted.first?.score ?? 0) - (sorted.last?.score ?? 0)
        let upsetLevel = computeUpsetLevel(race: race, topGap: topGap, scoreSpread: scoreSpread)
        let confidence = computeConfidence(topGap: topGap, spread: scoreSpread, upsetLevel: upsetLevel)
        let shouldSkip = confidence < 52 || upsetLevel >= 75

        let longshotLane = sorted
            .dropFirst(2)
            .max { left, right in
                longshotScore(left.entry, baseScore: left.score, fastestExhibition: fastestExhibition) <
                    longshotScore(right.entry, baseScore: right.score, fastestExhibition: fastestExhibition)
            }?.entry.lane

        let scoredBoats = sorted.enumerated().map { index, item in
            let role: BoatRole
            if index == 0 {
                role = .main
            } else if index == 1 {
                role = .rival
            } else if item.entry.lane == longshotLane {
                role = .longshot
            } else {
                role = .press
            }

            return ScoredBoat(
                entry: item.entry,
                score: item.score,
                rank: index + 1,
                role: role,
                signals: item.signals
            )
        }

        return RacePrediction(
            raceId: race.id,
            scoredBoats: scoredBoats,
            tickets: generateTickets(scoredBoats: scoredBoats, shouldSkip: shouldSkip),
            confidence: confidence,
            upsetLevel: upsetLevel,
            shouldSkip: shouldSkip,
            reasons: generateReasons(race: race, scoredBoats: scoredBoats, topGap: topGap)
        )
    }

    static func isHit(prediction: RacePrediction, result: SavedRaceResult) -> Bool {
        prediction.tickets.contains { ticket in
            ticket.lanes == Array(result.finishOrder.prefix(ticket.lanes.count))
        }
    }

    private static func generateTickets(scoredBoats: [ScoredBoat], shouldSkip: Bool) -> [Ticket] {
        let sorted = scoredBoats.sorted { $0.score > $1.score }
        guard sorted.count >= 4 else { return [] }

        if shouldSkip {
            return [
                Ticket(lanes: [sorted[0].entry.lane, sorted[1].entry.lane, sorted[2].entry.lane], note: "参考"),
                Ticket(lanes: [sorted[1].entry.lane, sorted[0].entry.lane, sorted[2].entry.lane], note: "押さえ")
            ]
        }

        let axis = sorted[0]
        let second = Array(sorted[1...3])
        var tickets: [Ticket] = []

        for boat2 in second {
            for boat3 in second where boat2.entry.lane != boat3.entry.lane {
                tickets.append(Ticket(lanes: [axis.entry.lane, boat2.entry.lane, boat3.entry.lane], note: "軸固定"))
            }
        }

        if let longshot = scoredBoats.first(where: { $0.role == .longshot }),
           !tickets.contains(where: { $0.lanes.contains(longshot.entry.lane) }) {
            tickets.append(Ticket(lanes: [axis.entry.lane, sorted[1].entry.lane, longshot.entry.lane], note: "穴3着"))
            tickets.append(Ticket(lanes: [sorted[1].entry.lane, axis.entry.lane, longshot.entry.lane], note: "逆転"))
        }

        var seen: Set<[Int]> = []
        return tickets.filter { seen.insert($0.lanes).inserted }.prefix(8).map { $0 }
    }

    private static func generateReasons(race: BoatRace, scoredBoats: [ScoredBoat], topGap: Double) -> [String] {
        guard let main = scoredBoats.first(where: { $0.role == .main }) else { return [] }
        let rival = scoredBoats.first(where: { $0.role == .rival })
        let longshot = scoredBoats.first(where: { $0.role == .longshot })

        var reasons: [String] = []
        reasons.append("\(main.entry.lane)号艇は総合スコアが最上位。\(main.signals.joined(separator: "、"))を評価。")
        if let rival {
            reasons.append("\(rival.entry.lane)号艇は相手候補。勝率と展示のバランスがよい。")
        }
        if let longshot {
            reasons.append("\(longshot.entry.lane)号艇は穴候補。モーターか展示に上積みがある。")
        }
        if topGap < 4 {
            reasons.append("上位差が小さいため、買い目は広げすぎない。")
        }
        if race.condition.windSpeed >= 5 {
            reasons.append("風速\(Int(race.condition.windSpeed))mで水面はやや不安定。センター勢の浮上に注意。")
        }
        reasons.append("予想は参考情報です。的中や利益を保証するものではありません。")
        return reasons
    }

    private static func courseBase(_ course: Int, race: BoatRace) -> Double {
        let base: [Int: Double] = [1: 100, 2: 72, 3: 68, 4: 60, 5: 45, 6: 32]
        var value = base[course] ?? 40
        if race.stadium == "平和島", course == 1 { value -= 6 }
        if race.condition.windSpeed >= 5, (3...5).contains(course) { value += 8 }
        if race.condition.waveHeight >= 5, course == 6 { value -= 4 }
        return value
    }

    private static func weatherAdjustment(entry: BoatEntry, race: BoatRace) -> Double {
        var score = 62.0
        if race.condition.windDirection == "向かい風", entry.predictedCourse <= 2 { score += 8 }
        if race.condition.windDirection == "追い風", entry.predictedCourse == 1 { score += 6 }
        if race.condition.windDirection == "横風", (3...5).contains(entry.predictedCourse) { score += 8 }
        if race.condition.waveHeight >= 4, entry.startTiming <= 0.13 { score += 6 }
        return clamp(score, lower: 35, upper: 100)
    }

    private static func computeUpsetLevel(race: BoatRace, topGap: Double, scoreSpread: Double) -> Int {
        var level = 42.0
        level -= topGap * 4
        level -= scoreSpread * 0.4
        level += race.condition.windSpeed * 4
        level += race.condition.waveHeight * 3
        if race.condition.windDirection == "横風" { level += 10 }
        return Int(clamp(level, lower: 10, upper: 92).rounded())
    }

    private static func computeConfidence(topGap: Double, spread: Double, upsetLevel: Int) -> Int {
        var confidence = 48.0
        confidence += topGap * 5.5
        confidence += spread * 0.35
        confidence -= Double(upsetLevel) * 0.35
        return Int(clamp(confidence, lower: 25, upper: 90).rounded())
    }

    private static func longshotScore(_ entry: BoatEntry, baseScore: Double, fastestExhibition: Double) -> Double {
        var value = baseScore
        value += normalize(entry.motorSecondRate, min: 20, max: 50) * 0.20
        value += clamp(100 - ((entry.exhibitionTime - fastestExhibition) * 260), lower: 35, upper: 100) * 0.15
        if entry.predictedCourse >= 5 { value += 4 }
        return value
    }

    private static func normalize(_ value: Double, min: Double, max: Double) -> Double {
        clamp((value - min) / (max - min) * 100, lower: 0, upper: 100)
    }

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func clamp(_ value: Double, lower: Double, upper: Double) -> Double {
        Swift.min(Swift.max(value, lower), upper)
    }
}
