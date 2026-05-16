import Foundation
import SQLite3

final class DataManager: ObservableObject {
    @Published var races: [BoatRace] = []
    @Published var isLoading = false

    private var db: OpaquePointer?
    private let fileName = "boatrace.db"

    init() {
        openDatabase()
    }

    // MARK: - Database Setup

    private func openDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(fileName)

        if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
            print("Successfully opened database at \(fileURL.path)")
        } else {
            print("Unable to open database")
        }
    }

    private func createTablesIfNeeded() {
        let createRacesTable = """
        CREATE TABLE IF NOT EXISTS races (
            race_id TEXT PRIMARY KEY,
            date TEXT,
            stadium TEXT,
            race_number INTEGER,
            grade TEXT,
            distance INTEGER,
            weather TEXT,
            wind_direction TEXT,
            wind_speed REAL,
            wave_height REAL
        )
        """

        let createEntriesTable = """
        CREATE TABLE IF NOT EXISTS entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            race_id TEXT,
            lane INTEGER,
            racer_name TEXT,
            racer_id TEXT,
            racer_class TEXT,
            branch TEXT,
            national_win_rate REAL,
            local_win_rate REAL,
            start_timing REAL,
            motor_number INTEGER,
            motor_second_rate REAL,
            boat_number INTEGER,
            boat_second_rate REAL,
            exhibition_time REAL,
            tilt REAL,
            FOREIGN KEY(race_id) REFERENCES races(race_id)
        )
        """

        executeStatement(createRacesTable)
        executeStatement(createEntriesTable)
    }

    // MARK: - Database Operations

    func loadRaces() {
        isLoading = true
        defer { isLoading = false }

        var races: [BoatRace] = []
        let query = "SELECT * FROM races ORDER BY date DESC LIMIT 30"

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("Failed to prepare query")
            return
        }

        while sqlite3_step(statement) == SQLITE_ROW {
            let raceId = String(cString: sqlite3_column_text(statement, 0))
            let date = String(cString: sqlite3_column_text(statement, 1))
            let stadium = String(cString: sqlite3_column_text(statement, 2))
            let raceNumber = Int(sqlite3_column_int(statement, 3))
            let grade = String(cString: sqlite3_column_text(statement, 4))
            let distance = Int(sqlite3_column_int(statement, 5))
            let weather = String(cString: sqlite3_column_text(statement, 6))
            let windDirection = String(cString: sqlite3_column_text(statement, 7))
            let windSpeed = Double(sqlite3_column_double(statement, 8))
            let waveHeight = Double(sqlite3_column_double(statement, 9))

            let condition = RaceCondition(
                weather: weather,
                windDirection: windDirection,
                windSpeed: windSpeed,
                waveHeight: waveHeight
            )

            let entries = loadEntries(for: raceId)

            let race = BoatRace(
                id: raceId,
                date: date,
                stadium: stadium,
                raceNumber: raceNumber,
                deadline: "",
                grade: grade,
                distance: distance,
                condition: condition,
                entries: entries
            )

            races.append(race)
        }

        sqlite3_finalize(statement)

        DispatchQueue.main.async {
            self.races = races
        }
    }

    private func loadEntries(for raceId: String) -> [BoatEntry] {
        var entries: [BoatEntry] = []
        let query = "SELECT * FROM entries WHERE race_id = ? ORDER BY lane"

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return entries
        }

        sqlite3_bind_text(statement, 1, raceId, -1, SQLITE_TRANSIENT)

        while sqlite3_step(statement) == SQLITE_ROW {
            let lane = Int(sqlite3_column_int(statement, 2))
            let racerName = String(cString: sqlite3_column_text(statement, 3))
            let racerId = String(cString: sqlite3_column_text(statement, 4))
            let racerClass = String(cString: sqlite3_column_text(statement, 5))
            let branch = String(cString: sqlite3_column_text(statement, 6))
            let nationalWinRate = Double(sqlite3_column_double(statement, 7))
            let localWinRate = Double(sqlite3_column_double(statement, 8))
            let startTiming = Double(sqlite3_column_double(statement, 9))
            let motorNumber = Int(sqlite3_column_int(statement, 10))
            let motorSecondRate = Double(sqlite3_column_double(statement, 11))
            let boatNumber = Int(sqlite3_column_int(statement, 12))
            let boatSecondRate = Double(sqlite3_column_double(statement, 13))
            let exhibitionTime = Double(sqlite3_column_double(statement, 14))
            let tilt = Double(sqlite3_column_double(statement, 15))

            let entry = BoatEntry(
                lane: lane,
                racerName: racerName,
                racerId: racerId,
                racerClass: racerClass,
                branch: branch,
                nationalWinRate: nationalWinRate,
                localWinRate: localWinRate,
                startTiming: startTiming,
                motorNumber: motorNumber,
                motorSecondRate: motorSecondRate,
                boatNumber: boatNumber,
                boatSecondRate: boatSecondRate,
                exhibitionTime: exhibitionTime,
                tilt: tilt,
                predictedCourse: 0
            )

            entries.append(entry)
        }

        sqlite3_finalize(statement)
        return entries
    }

    func insertRaces(_ races: [BoatRace]) {
        for race in races {
            let insertRaceQuery = """
            INSERT OR REPLACE INTO races
            (race_id, date, stadium, race_number, grade, distance, weather, wind_direction, wind_speed, wave_height)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """

            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, insertRaceQuery, -1, &statement, nil) == SQLITE_OK else {
                continue
            }

            sqlite3_bind_text(statement, 1, race.id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, race.date, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, race.stadium, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 4, Int32(race.raceNumber))
            sqlite3_bind_text(statement, 5, race.grade, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 6, Int32(race.distance))
            sqlite3_bind_text(statement, 7, race.condition.weather, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 8, race.condition.windDirection, -1, SQLITE_TRANSIENT)
            sqlite3_bind_double(statement, 9, race.condition.windSpeed)
            sqlite3_bind_double(statement, 10, race.condition.waveHeight)

            if sqlite3_step(statement) == SQLITE_DONE {
                print("Successfully inserted race: \(race.id)")
            } else {
                print("Failed to insert race: \(race.id)")
            }

            sqlite3_finalize(statement)

            // Insert entries
            for entry in race.entries {
                let insertEntryQuery = """
                INSERT INTO entries
                (race_id, lane, racer_name, racer_id, racer_class, branch, national_win_rate, local_win_rate, start_timing,
                 motor_number, motor_second_rate, boat_number, boat_second_rate, exhibition_time, tilt)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """

                var entryStatement: OpaquePointer?
                guard sqlite3_prepare_v2(db, insertEntryQuery, -1, &entryStatement, nil) == SQLITE_OK else {
                    continue
                }

                sqlite3_bind_text(entryStatement, 1, race.id, -1, SQLITE_TRANSIENT)
                sqlite3_bind_int(entryStatement, 2, Int32(entry.lane))
                sqlite3_bind_text(entryStatement, 3, entry.racerName, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(entryStatement, 4, entry.racerId, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(entryStatement, 5, entry.racerClass, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(entryStatement, 6, entry.branch, -1, SQLITE_TRANSIENT)
                sqlite3_bind_double(entryStatement, 7, entry.nationalWinRate)
                sqlite3_bind_double(entryStatement, 8, entry.localWinRate)
                sqlite3_bind_double(entryStatement, 9, entry.startTiming)
                sqlite3_bind_int(entryStatement, 10, Int32(entry.motorNumber))
                sqlite3_bind_double(entryStatement, 11, entry.motorSecondRate)
                sqlite3_bind_int(entryStatement, 12, Int32(entry.boatNumber))
                sqlite3_bind_double(entryStatement, 13, entry.boatSecondRate)
                sqlite3_bind_double(entryStatement, 14, entry.exhibitionTime)
                sqlite3_bind_double(entryStatement, 15, entry.tilt)

                sqlite3_step(entryStatement)
                sqlite3_finalize(entryStatement)
            }
        }

        DispatchQueue.main.async {
            self.loadRaces()
        }
    }

    private func executeStatement(_ sql: String) {
        var errorMessage: UnsafeMutablePointer<CChar>?

        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            let error = String(cString: errorMessage ?? "Unknown error")
            print("Error executing statement: \(error)")
            sqlite3_free(errorMessage)
        }
    }

    deinit {
        sqlite3_close(db)
    }
}
