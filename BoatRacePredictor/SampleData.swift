import Foundation

enum SampleData {
    static let races: [BoatRace] = [
        BoatRace(
            id: "2026-05-14-heiwajima-8",
            date: "2026-05-14",
            stadium: "平和島",
            raceNumber: 8,
            deadline: "14:18",
            grade: "一般",
            distance: 1800,
            condition: RaceCondition(weather: "晴", windDirection: "向かい風", windSpeed: 4.0, waveHeight: 3.0),
            entries: [
                BoatEntry(lane: 1, racerName: "青木 亮", racerId: "4511", racerClass: "A1", branch: "東京", nationalWinRate: 6.72, localWinRate: 6.41, startTiming: 0.14, motorNumber: 31, motorSecondRate: 38.5, boatNumber: 22, boatSecondRate: 33.8, exhibitionTime: 6.72, tilt: -0.5, predictedCourse: 1),
                BoatEntry(lane: 2, racerName: "森川 蓮", racerId: "4820", racerClass: "A2", branch: "愛知", nationalWinRate: 5.84, localWinRate: 5.21, startTiming: 0.16, motorNumber: 44, motorSecondRate: 31.2, boatNumber: 61, boatSecondRate: 30.4, exhibitionTime: 6.79, tilt: -0.5, predictedCourse: 2),
                BoatEntry(lane: 3, racerName: "片桐 航", racerId: "4368", racerClass: "A1", branch: "福岡", nationalWinRate: 6.31, localWinRate: 6.08, startTiming: 0.12, motorNumber: 17, motorSecondRate: 42.1, boatNumber: 18, boatSecondRate: 37.2, exhibitionTime: 6.70, tilt: 0.0, predictedCourse: 3),
                BoatEntry(lane: 4, racerName: "西尾 悠", racerId: "5082", racerClass: "B1", branch: "三重", nationalWinRate: 4.92, localWinRate: 4.44, startTiming: 0.18, motorNumber: 53, motorSecondRate: 28.9, boatNumber: 47, boatSecondRate: 26.9, exhibitionTime: 6.84, tilt: -0.5, predictedCourse: 4),
                BoatEntry(lane: 5, racerName: "小田 桜", racerId: "4902", racerClass: "A2", branch: "大阪", nationalWinRate: 5.58, localWinRate: 5.90, startTiming: 0.15, motorNumber: 12, motorSecondRate: 44.8, boatNumber: 39, boatSecondRate: 41.0, exhibitionTime: 6.74, tilt: 0.0, predictedCourse: 5),
                BoatEntry(lane: 6, racerName: "早瀬 真", racerId: "5224", racerClass: "B1", branch: "群馬", nationalWinRate: 4.21, localWinRate: 3.98, startTiming: 0.19, motorNumber: 66, motorSecondRate: 25.7, boatNumber: 14, boatSecondRate: 28.1, exhibitionTime: 6.88, tilt: 0.5, predictedCourse: 6)
            ]
        ),
        BoatRace(
            id: "2026-05-14-suminoe-10",
            date: "2026-05-14",
            stadium: "住之江",
            raceNumber: 10,
            deadline: "19:38",
            grade: "予選特賞",
            distance: 1800,
            condition: RaceCondition(weather: "曇", windDirection: "追い風", windSpeed: 2.0, waveHeight: 1.0),
            entries: [
                BoatEntry(lane: 1, racerName: "坂本 海斗", racerId: "4078", racerClass: "A1", branch: "大阪", nationalWinRate: 7.02, localWinRate: 7.48, startTiming: 0.13, motorNumber: 21, motorSecondRate: 36.7, boatNumber: 54, boatSecondRate: 35.6, exhibitionTime: 6.81, tilt: -0.5, predictedCourse: 1),
                BoatEntry(lane: 2, racerName: "石原 奏", racerId: "4644", racerClass: "B1", branch: "滋賀", nationalWinRate: 4.85, localWinRate: 5.02, startTiming: 0.17, motorNumber: 39, motorSecondRate: 30.0, boatNumber: 25, boatSecondRate: 27.3, exhibitionTime: 6.91, tilt: -0.5, predictedCourse: 2),
                BoatEntry(lane: 3, racerName: "長谷川 圭", racerId: "4330", racerClass: "A2", branch: "兵庫", nationalWinRate: 5.91, localWinRate: 5.66, startTiming: 0.16, motorNumber: 58, motorSecondRate: 39.4, boatNumber: 11, boatSecondRate: 34.9, exhibitionTime: 6.86, tilt: 0.0, predictedCourse: 3),
                BoatEntry(lane: 4, racerName: "伊東 翠", racerId: "4988", racerClass: "A1", branch: "香川", nationalWinRate: 6.46, localWinRate: 5.70, startTiming: 0.11, motorNumber: 6, motorSecondRate: 47.5, boatNumber: 36, boatSecondRate: 38.4, exhibitionTime: 6.79, tilt: 0.0, predictedCourse: 4),
                BoatEntry(lane: 5, racerName: "中里 大", racerId: "4701", racerClass: "B1", branch: "埼玉", nationalWinRate: 4.48, localWinRate: 4.35, startTiming: 0.20, motorNumber: 62, motorSecondRate: 23.6, boatNumber: 19, boatSecondRate: 25.1, exhibitionTime: 6.96, tilt: -0.5, predictedCourse: 5),
                BoatEntry(lane: 6, racerName: "水野 輝", racerId: "4112", racerClass: "A2", branch: "福井", nationalWinRate: 5.77, localWinRate: 5.14, startTiming: 0.15, motorNumber: 72, motorSecondRate: 41.8, boatNumber: 68, boatSecondRate: 32.2, exhibitionTime: 6.88, tilt: 0.5, predictedCourse: 6)
            ]
        ),
        BoatRace(
            id: "2026-05-14-marugame-12",
            date: "2026-05-14",
            stadium: "丸亀",
            raceNumber: 12,
            deadline: "20:45",
            grade: "ドリーム",
            distance: 1800,
            condition: RaceCondition(weather: "雨", windDirection: "横風", windSpeed: 6.0, waveHeight: 5.0),
            entries: [
                BoatEntry(lane: 1, racerName: "三浦 晴", racerId: "3941", racerClass: "A1", branch: "岡山", nationalWinRate: 7.18, localWinRate: 6.62, startTiming: 0.15, motorNumber: 10, motorSecondRate: 33.1, boatNumber: 50, boatSecondRate: 31.1, exhibitionTime: 6.76, tilt: -0.5, predictedCourse: 1),
                BoatEntry(lane: 2, racerName: "北村 樹", racerId: "4022", racerClass: "A1", branch: "香川", nationalWinRate: 6.88, localWinRate: 7.10, startTiming: 0.13, motorNumber: 25, motorSecondRate: 40.6, boatNumber: 20, boatSecondRate: 37.8, exhibitionTime: 6.72, tilt: -0.5, predictedCourse: 2),
                BoatEntry(lane: 3, racerName: "宮田 翔", racerId: "4215", racerClass: "A2", branch: "広島", nationalWinRate: 5.96, localWinRate: 6.11, startTiming: 0.14, motorNumber: 49, motorSecondRate: 45.9, boatNumber: 9, boatSecondRate: 42.4, exhibitionTime: 6.70, tilt: 0.0, predictedCourse: 3),
                BoatEntry(lane: 4, racerName: "藤野 月", racerId: "4733", racerClass: "A1", branch: "徳島", nationalWinRate: 6.42, localWinRate: 5.74, startTiming: 0.12, motorNumber: 33, motorSecondRate: 36.2, boatNumber: 77, boatSecondRate: 36.0, exhibitionTime: 6.73, tilt: 0.0, predictedCourse: 4),
                BoatEntry(lane: 5, racerName: "榊原 凛", racerId: "4899", racerClass: "A2", branch: "愛媛", nationalWinRate: 5.69, localWinRate: 5.82, startTiming: 0.16, motorNumber: 69, motorSecondRate: 48.0, boatNumber: 31, boatSecondRate: 39.5, exhibitionTime: 6.71, tilt: 0.5, predictedCourse: 5),
                BoatEntry(lane: 6, racerName: "大野 迅", racerId: "4507", racerClass: "A1", branch: "山口", nationalWinRate: 6.22, localWinRate: 5.30, startTiming: 0.18, motorNumber: 3, motorSecondRate: 29.5, boatNumber: 65, boatSecondRate: 30.8, exhibitionTime: 6.82, tilt: 0.0, predictedCourse: 6)
            ]
        )
    ]
}
