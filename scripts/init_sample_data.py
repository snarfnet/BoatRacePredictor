#!/usr/bin/env python3
"""
サンプルデータを SQLite に挿入するスクリプト
"""

import sqlite3
import json
from pathlib import Path

# DB パス
DB_PATH = Path(__file__).parent.parent / "boatrace.db"

# サンプルデータ（SampleData.swift から）
SAMPLE_RACES = [
    {
        "id": "2026-05-14-heiwajima-8",
        "date": "2026-05-14",
        "stadium": "平和島",
        "race_number": 8,
        "grade": "一般",
        "distance": 1800,
        "weather": "晴",
        "wind_direction": "向かい風",
        "wind_speed": 4.0,
        "wave_height": 3.0,
        "entries": [
            {"lane": 1, "racer_name": "青木 亮", "racer_id": "4511", "racer_class": "A1", "branch": "東京",
             "national_win_rate": 6.72, "local_win_rate": 6.41, "start_timing": 0.14,
             "motor_number": 31, "motor_second_rate": 38.5, "boat_number": 22, "boat_second_rate": 33.8,
             "exhibition_time": 6.72, "tilt": -0.5},
            {"lane": 2, "racer_name": "森川 蓮", "racer_id": "4820", "racer_class": "A2", "branch": "愛知",
             "national_win_rate": 5.84, "local_win_rate": 5.21, "start_timing": 0.16,
             "motor_number": 44, "motor_second_rate": 31.2, "boat_number": 61, "boat_second_rate": 30.4,
             "exhibition_time": 6.79, "tilt": -0.5},
            {"lane": 3, "racer_name": "片桐 航", "racer_id": "4368", "racer_class": "A1", "branch": "福岡",
             "national_win_rate": 6.31, "local_win_rate": 6.08, "start_timing": 0.12,
             "motor_number": 17, "motor_second_rate": 42.1, "boat_number": 18, "boat_second_rate": 37.2,
             "exhibition_time": 6.70, "tilt": 0.0},
            {"lane": 4, "racer_name": "西尾 悠", "racer_id": "5082", "racer_class": "B1", "branch": "三重",
             "national_win_rate": 4.92, "local_win_rate": 4.44, "start_timing": 0.18,
             "motor_number": 53, "motor_second_rate": 28.9, "boat_number": 47, "boat_second_rate": 26.9,
             "exhibition_time": 6.84, "tilt": -0.5},
            {"lane": 5, "racer_name": "小田 桜", "racer_id": "4902", "racer_class": "A2", "branch": "大阪",
             "national_win_rate": 5.58, "local_win_rate": 5.90, "start_timing": 0.15,
             "motor_number": 12, "motor_second_rate": 44.8, "boat_number": 39, "boat_second_rate": 41.0,
             "exhibition_time": 6.74, "tilt": 0.0},
            {"lane": 6, "racer_name": "早瀬 真", "racer_id": "5224", "racer_class": "B1", "branch": "群馬",
             "national_win_rate": 4.21, "local_win_rate": 3.98, "start_timing": 0.19,
             "motor_number": 66, "motor_second_rate": 25.7, "boat_number": 14, "boat_second_rate": 28.1,
             "exhibition_time": 6.88, "tilt": 0.5},
        ]
    },
    {
        "id": "2026-05-14-suminoe-10",
        "date": "2026-05-14",
        "stadium": "住之江",
        "race_number": 10,
        "grade": "予選特賞",
        "distance": 1800,
        "weather": "曇",
        "wind_direction": "追い風",
        "wind_speed": 2.0,
        "wave_height": 1.0,
        "entries": [
            {"lane": 1, "racer_name": "坂本 海斗", "racer_id": "4078", "racer_class": "A1", "branch": "大阪",
             "national_win_rate": 7.02, "local_win_rate": 7.48, "start_timing": 0.13,
             "motor_number": 21, "motor_second_rate": 36.7, "boat_number": 54, "boat_second_rate": 35.6,
             "exhibition_time": 6.81, "tilt": -0.5},
            {"lane": 2, "racer_name": "石原 奏", "racer_id": "4644", "racer_class": "B1", "branch": "滋賀",
             "national_win_rate": 4.85, "local_win_rate": 5.02, "start_timing": 0.17,
             "motor_number": 39, "motor_second_rate": 30.0, "boat_number": 25, "boat_second_rate": 27.3,
             "exhibition_time": 6.91, "tilt": -0.5},
            {"lane": 3, "racer_name": "長谷川 圭", "racer_id": "4330", "racer_class": "A2", "branch": "兵庫",
             "national_win_rate": 5.91, "local_win_rate": 5.66, "start_timing": 0.16,
             "motor_number": 58, "motor_second_rate": 39.4, "boat_number": 11, "boat_second_rate": 34.9,
             "exhibition_time": 6.86, "tilt": 0.0},
            {"lane": 4, "racer_name": "伊東 翠", "racer_id": "4988", "racer_class": "A1", "branch": "香川",
             "national_win_rate": 6.46, "local_win_rate": 5.70, "start_timing": 0.11,
             "motor_number": 6, "motor_second_rate": 47.5, "boat_number": 36, "boat_second_rate": 38.4,
             "exhibition_time": 6.79, "tilt": 0.0},
            {"lane": 5, "racer_name": "中里 大", "racer_id": "4701", "racer_class": "B1", "branch": "埼玉",
             "national_win_rate": 4.48, "local_win_rate": 4.35, "start_timing": 0.20,
             "motor_number": 62, "motor_second_rate": 23.6, "boat_number": 19, "boat_second_rate": 25.1,
             "exhibition_time": 6.96, "tilt": -0.5},
            {"lane": 6, "racer_name": "水野 輝", "racer_id": "4112", "racer_class": "A2", "branch": "福井",
             "national_win_rate": 5.77, "local_win_rate": 5.14, "start_timing": 0.15,
             "motor_number": 72, "motor_second_rate": 41.8, "boat_number": 68, "boat_second_rate": 32.2,
             "exhibition_time": 6.88, "tilt": 0.5},
        ]
    }
]

def init_db():
    """データベース初期化"""
    conn = sqlite3.connect(str(DB_PATH))
    c = conn.cursor()

    # レーステーブル
    c.execute('''CREATE TABLE IF NOT EXISTS races (
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
    )''')

    # 選手テーブル
    c.execute('''CREATE TABLE IF NOT EXISTS entries (
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
    )''')

    conn.commit()
    conn.close()
    print(f"[OK] Database initialized at {DB_PATH}")

def insert_sample_data():
    """サンプルデータを挿入"""
    conn = sqlite3.connect(str(DB_PATH))
    c = conn.cursor()

    for race in SAMPLE_RACES:
        # レース情報を挿入
        c.execute('''INSERT OR REPLACE INTO races
                    (race_id, date, stadium, race_number, grade, distance,
                     weather, wind_direction, wind_speed, wave_height)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
                  (race['id'], race['date'], race['stadium'], race['race_number'],
                   race['grade'], race['distance'], race['weather'],
                   race['wind_direction'], race['wind_speed'], race['wave_height']))

        # 選手情報を挿入
        for entry in race['entries']:
            c.execute('''INSERT INTO entries
                        (race_id, lane, racer_name, racer_id, racer_class, branch,
                         national_win_rate, local_win_rate, start_timing,
                         motor_number, motor_second_rate, boat_number,
                         boat_second_rate, exhibition_time, tilt)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
                      (race['id'], entry['lane'], entry['racer_name'], entry['racer_id'],
                       entry['racer_class'], entry['branch'], entry['national_win_rate'],
                       entry['local_win_rate'], entry['start_timing'], entry['motor_number'],
                       entry['motor_second_rate'], entry['boat_number'], entry['boat_second_rate'],
                       entry['exhibition_time'], entry['tilt']))

        print(f"[OK] Inserted race: {race['stadium']} #{race['race_number']}")

    conn.commit()
    conn.close()
    print(f"\n[OK] Sample data inserted successfully")

def verify_data():
    """データ検証"""
    conn = sqlite3.connect(str(DB_PATH))
    c = conn.cursor()

    c.execute("SELECT COUNT(*) FROM races")
    race_count = c.fetchone()[0]

    c.execute("SELECT COUNT(*) FROM entries")
    entry_count = c.fetchone()[0]

    print(f"\n=== Database Verification ===")
    print(f"Total races: {race_count}")
    print(f"Total entries: {entry_count}")

    # サンプルレース表示
    c.execute("SELECT race_id, stadium, race_number FROM races")
    print("\nRaces:")
    for row in c.fetchall():
        print(f"  - {row[1]} #{row[2]} ({row[0]})")

    conn.close()

if __name__ == '__main__':
    print("=== Initializing Boatrace Database ===\n")
    init_db()
    insert_sample_data()
    verify_data()
    print("\n[OK] Ready to use!")
