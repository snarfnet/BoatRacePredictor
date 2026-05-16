import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var resultStore: ResultStore
    @EnvironmentObject private var dataManager: DataManager

    var body: some View {
        TabView {
            NavigationStack {
                RaceListView(races: dataManager.races.isEmpty ? SampleData.races : dataManager.races)
            }
            .tabItem {
                Label("予想", systemImage: "flag.checkered")
            }

            NavigationStack {
                StatsView(races: dataManager.races.isEmpty ? SampleData.races : dataManager.races)
            }
            .tabItem {
                Label("成績", systemImage: "chart.bar.xaxis")
            }

            NavigationStack {
                NotesView()
            }
            .tabItem {
                Label("注意", systemImage: "exclamationmark.shield")
            }
        }
        .tint(BoatTheme.teal)
    }
}

private struct RaceListView: View {
    let races: [BoatRace]
    @EnvironmentObject private var resultStore: ResultStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statsPanel

                ForEach(races) { race in
                    NavigationLink {
                        RaceDetailView(race: race)
                    } label: {
                        RaceCard(race: race, prediction: PredictionEngine.predict(race: race))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
        }
        .background(BoatTheme.background)
        .navigationTitle("舟読み")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日のレース")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(BoatTheme.ink)
            Text("展示、モーター、選手成績から買い目候補を出します。")
                .font(.subheadline)
                .foregroundStyle(BoatTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statsPanel: some View {
        let stats = resultStore.stats(for: races)

        return VStack(alignment: .leading, spacing: 14) {
            Text("成績サマリー")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(BoatTheme.ink)

            HStack(spacing: 12) {
                StatCard(
                    title: "的中率",
                    value: String(format: "%.1f%%", stats.hitRate),
                    icon: "star.fill",
                    color: .orange
                )

                StatCard(
                    title: "回収率",
                    value: String(format: "%.0f%%", stats.returnRate),
                    icon: "chart.line.uptrend.xyaxis",
                    color: stats.returnRate >= 100 ? .green : .red
                )

                StatCard(
                    title: "的中数",
                    value: "\(stats.hits)/\(stats.races)",
                    icon: "checkmark.circle.fill",
                    color: .blue
                )
            }
        }
        .padding(14)
        .background(BoatTheme.background.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(BoatTheme.teal.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(color)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(BoatTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.7))
        .cornerRadius(8)
    }
}

private struct RaceCard: View {
    let race: BoatRace
    let prediction: RacePrediction

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(race.stadium) \(race.raceNumber)R")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(BoatTheme.ink)
                    Text("\(race.grade) / 締切 \(race.deadline)")
                        .font(.subheadline)
                        .foregroundStyle(BoatTheme.muted)
                }
                Spacer()
                PredictionBadge(prediction: prediction)
            }

            HStack(spacing: 10) {
                MetricPill(title: "信頼度", value: "\(prediction.confidence)")
                MetricPill(title: "荒れ度", value: "\(prediction.upsetLevel)")
                MetricPill(title: "風", value: "\(Int(race.condition.windSpeed))m")
            }

            if let main = prediction.main, let rival = prediction.rival {
                HStack(spacing: 8) {
                    LaneChip(lane: main.entry.lane, label: "本命")
                    LaneChip(lane: rival.entry.lane, label: "対抗")
                    if let longshot = prediction.longshot {
                        LaneChip(lane: longshot.entry.lane, label: "穴")
                    }
                }
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(BoatTheme.line, lineWidth: 1)
        )
    }
}

private struct RaceDetailView: View {
    @EnvironmentObject private var resultStore: ResultStore
    let race: BoatRace

    private var prediction: RacePrediction {
        PredictionEngine.predict(race: race)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                RaceSummary(race: race, prediction: prediction)
                TicketSection(prediction: prediction)
                EntryScoreSection(prediction: prediction)
                ReasonSection(reasons: prediction.reasons)
                ResultInputSection(race: race, prediction: prediction)
            }
            .padding(18)
        }
        .background(BoatTheme.background)
        .navigationTitle("\(race.stadium) \(race.raceNumber)R")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct RaceSummary: View {
    let race: BoatRace
    let prediction: RacePrediction

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(race.stadium) \(race.raceNumber)R")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                Spacer()
                PredictionBadge(prediction: prediction)
            }

            Text("\(race.grade) / \(race.distance)m / 締切 \(race.deadline)")
                .font(.subheadline)
                .foregroundStyle(BoatTheme.muted)

            HStack(spacing: 10) {
                MetricPill(title: "天候", value: race.condition.weather)
                MetricPill(title: "風向", value: race.condition.windDirection)
                MetricPill(title: "波", value: "\(Int(race.condition.waveHeight))cm")
            }

            HStack(spacing: 8) {
                if let main = prediction.main { LaneChip(lane: main.entry.lane, label: "本命") }
                if let rival = prediction.rival { LaneChip(lane: rival.entry.lane, label: "対抗") }
                if let longshot = prediction.longshot { LaneChip(lane: longshot.entry.lane, label: "穴") }
            }
        }
        .panelStyle()
    }
}

private struct TicketSection: View {
    let prediction: RacePrediction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("3連単候補", systemImage: "ticket")
            if prediction.shouldSkip {
                Text("見送り寄り。買うなら点数を絞る想定です。")
                    .font(.subheadline)
                    .foregroundStyle(BoatTheme.warning)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 124), spacing: 10)], spacing: 10) {
                ForEach(prediction.tickets) { ticket in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(ticket.lanes.map(String.init).joined(separator: "-"))
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(BoatTheme.ink)
                        Text(ticket.note)
                            .font(.caption)
                            .foregroundStyle(BoatTheme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(BoatTheme.soft)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .panelStyle()
    }
}

private struct EntryScoreSection: View {
    let prediction: RacePrediction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("出走表と評価", systemImage: "list.number")
            ForEach(prediction.scoredBoats) { scored in
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        LaneNumber(lane: scored.entry.lane)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(scored.entry.racerName)
                                .font(.headline)
                                .foregroundStyle(BoatTheme.ink)
                            Text("\(scored.entry.racerClass) / \(scored.entry.branch) / M\(scored.entry.motorNumber)")
                                .font(.caption)
                                .foregroundStyle(BoatTheme.muted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(String(format: "%.1f", scored.score))")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                            Text(scored.role.rawValue)
                                .font(.caption)
                                .foregroundStyle(roleColor(scored.role))
                        }
                    }

                    HStack(spacing: 6) {
                        ValueTag("勝率 \(String(format: "%.2f", scored.entry.nationalWinRate))")
                        ValueTag("展示 \(String(format: "%.2f", scored.entry.exhibitionTime))")
                        ValueTag("M2 \(String(format: "%.1f", scored.entry.motorSecondRate))%")
                    }

                    if !scored.signals.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(scored.signals, id: \.self) { signal in
                                Text(signal)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(BoatTheme.teal)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(BoatTheme.teal.opacity(0.10))
                                    .clipShape(Capsule())
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.vertical, 8)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(BoatTheme.line)
                        .frame(height: 1)
                }
            }
        }
        .panelStyle()
    }

    private func roleColor(_ role: BoatRole) -> Color {
        switch role {
        case .main: BoatTheme.teal
        case .rival: BoatTheme.blue
        case .longshot: BoatTheme.warning
        case .press: BoatTheme.muted
        }
    }
}

private struct ReasonSection: View {
    let reasons: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("予想根拠", systemImage: "text.magnifyingglass")
            ForEach(reasons, id: \.self) { reason in
                Text(reason)
                    .font(.subheadline)
                    .foregroundStyle(BoatTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(BoatTheme.soft)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .panelStyle()
    }
}

private struct ResultInputSection: View {
    @EnvironmentObject private var resultStore: ResultStore
    let race: BoatRace
    let prediction: RacePrediction

    @State private var orderText = "1-3-2"
    @State private var payoutText = "1240"
    @State private var stakeText = "800"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("結果登録", systemImage: "checkmark.seal")

            if let saved = resultStore.result(for: race.id) {
                let hit = PredictionEngine.isHit(prediction: prediction, result: saved)
                Text(hit ? "的中: \(saved.payout)円" : "不的中")
                    .font(.headline)
                    .foregroundStyle(hit ? BoatTheme.teal : BoatTheme.warning)
            }

            TextField("着順 例: 1-3-2", text: $orderText)
                .textFieldStyle(.roundedBorder)
            TextField("払戻金", text: $payoutText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            TextField("投資額", text: $stakeText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

            Button {
                let order = orderText
                    .split(separator: "-")
                    .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                resultStore.save(
                    raceId: race.id,
                    finishOrder: order,
                    payout: Int(payoutText) ?? 0,
                    stake: Int(stakeText) ?? 0
                )
            } label: {
                Label("保存", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(BoatTheme.teal)
            .disabled(orderText.isEmpty)
        }
        .panelStyle()
    }
}

private struct StatsView: View {
    @EnvironmentObject private var resultStore: ResultStore
    let races: [BoatRace]

    var body: some View {
        let stats = resultStore.stats(for: races)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("成績")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(BoatTheme.ink)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    BigMetric(title: "予想数", value: "\(stats.races)")
                    BigMetric(title: "的中数", value: "\(stats.hits)")
                    BigMetric(title: "的中率", value: "\(String(format: "%.1f", stats.hitRate))%")
                    BigMetric(title: "回収率", value: "\(String(format: "%.1f", stats.returnRate))%")
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle("登録済み", systemImage: "tray.full")
                    ForEach(resultStore.results) { result in
                        HStack {
                            Text(result.finishOrder.map(String.init).joined(separator: "-"))
                                .font(.headline)
                            Spacer()
                            Text("投資 \(result.stake)円 / 払戻 \(result.payout)円")
                                .font(.caption)
                                .foregroundStyle(BoatTheme.muted)
                        }
                        .padding(.vertical, 8)
                    }
                    if resultStore.results.isEmpty {
                        Text("レース詳細から結果を登録すると、ここに集計されます。")
                            .font(.subheadline)
                            .foregroundStyle(BoatTheme.muted)
                    }
                }
                .panelStyle()
            }
            .padding(18)
        }
        .background(BoatTheme.background)
        .navigationTitle("成績")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NotesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("利用時の注意")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                Text("このアプリの予想は、公開データと独自ロジックにもとづく参考情報です。的中や利益を保証するものではありません。舟券の購入はご自身の判断で行ってください。")
                    .font(.body)
                    .foregroundStyle(BoatTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle("MVPでできること", systemImage: "wrench.and.screwdriver")
                    Text("仮データを使った予想、買い目表示、予想理由、結果登録、成績集計まで確認できます。データ取得は次の段階で追加します。")
                        .font(.subheadline)
                        .foregroundStyle(BoatTheme.muted)
                }
                .panelStyle()
            }
            .padding(18)
        }
        .background(BoatTheme.background)
        .navigationTitle("注意")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PredictionBadge: View {
    let prediction: RacePrediction

    var body: some View {
        Text(prediction.shouldSkip ? "見送り" : grade)
            .font(.caption.weight(.black))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(prediction.shouldSkip ? BoatTheme.warning : BoatTheme.teal)
            .clipShape(Capsule())
    }

    private var grade: String {
        if prediction.confidence >= 75 { return "A" }
        if prediction.confidence >= 60 { return "B" }
        return "C"
    }
}

private struct SectionTitle: View {
    let title: String
    let systemImage: String

    init(_ title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(BoatTheme.ink)
    }
}

private struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(BoatTheme.muted)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(BoatTheme.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(BoatTheme.soft)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct BigMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(BoatTheme.muted)
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(BoatTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(BoatTheme.line, lineWidth: 1))
    }
}

private struct LaneChip: View {
    let lane: Int
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            LaneNumber(lane: lane)
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(BoatTheme.ink)
        }
        .padding(.trailing, 10)
        .background(BoatTheme.soft)
        .clipShape(Capsule())
    }
}

private struct LaneNumber: View {
    let lane: Int

    var body: some View {
        Text("\(lane)")
            .font(.system(size: 16, weight: .black, design: .rounded))
            .foregroundStyle(laneForeground)
            .frame(width: 30, height: 30)
            .background(laneBackground)
            .clipShape(Circle())
    }

    private var laneBackground: Color {
        switch lane {
        case 1: .white
        case 2: .black
        case 3: .red
        case 4: .blue
        case 5: .yellow
        default: .green
        }
    }

    private var laneForeground: Color {
        lane == 1 || lane == 5 ? .black : .white
    }
}

private struct ValueTag: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(BoatTheme.muted)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(BoatTheme.soft)
            .clipShape(Capsule())
    }
}

private enum BoatTheme {
    static let background = Color(red: 0.95, green: 0.97, blue: 0.96)
    static let soft = Color(red: 0.90, green: 0.96, blue: 0.95)
    static let ink = Color(red: 0.06, green: 0.12, blue: 0.14)
    static let muted = Color(red: 0.38, green: 0.47, blue: 0.49)
    static let line = Color(red: 0.80, green: 0.87, blue: 0.86)
    static let teal = Color(red: 0.00, green: 0.37, blue: 0.50)
    static let blue = Color(red: 0.12, green: 0.31, blue: 0.72)
    static let warning = Color(red: 0.72, green: 0.24, blue: 0.16)
}

private extension View {
    func panelStyle() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(BoatTheme.line, lineWidth: 1))
    }
}

#Preview {
    ContentView()
        .environmentObject(ResultStore())
}
