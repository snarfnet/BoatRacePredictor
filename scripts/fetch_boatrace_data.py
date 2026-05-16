#!/usr/bin/env python3
"""
BOAT RACE.jp からレースデータを取得して SQLite に保存するスクリプト
"""

import requests
from bs4 import BeautifulSoup
import sqlite3
import json
from datetime import datetime, timedelta
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 設定
DB_PATH = "../boatrace.db"
BASE_URL = "https://www.boatrace.jp"

def init_db():
    """SQLite データベース初期化"""
    conn = sqlite3.connect(DB_PATH)
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

    # 結果テーブル
    c.execute('''CREATE TABLE IF NOT EXISTS results (
        race_id TEXT PRIMARY KEY,
        finish_order TEXT,
        payout INTEGER,
        FOREIGN KEY(race_id) REFERENCES races(race_id)
    )''')

    conn.commit()
    conn.close()
    logger.info("Database initialized")

def fetch_today_races():
    """本日のレース情報取得"""
    try:
        url = f"{BASE_URL}/owpc/pc/race/index"
        response = requests.get(url, timeout=10)
        response.encoding = 'utf-8'
        soup = BeautifulSoup(response.content, 'html.parser')

        races = []

        # レース情報を抽出（セレクタは BOAT RACE.jp の HTML 構造に依存）
        race_items = soup.find_all('div', class_='race-info')

        for item in race_items:
            try:
                race_id = item.get('data-race-id', '')
                stadium = item.find('span', class_='stadium-name')
                race_num = item.find('span', class_='race-number')

                if race_id and stadium:
                    race_data = {
                        'race_id': race_id,
                        'stadium': stadium.text.strip(),
                        'race_number': int(race_num.text) if race_num else 0,
                        'date': datetime.now().strftime('%Y-%m-%d'),
                    }
                    races.append(race_data)
            except Exception as e:
                logger.warning(f"Error parsing race item: {e}")
                continue

        logger.info(f"Fetched {len(races)} races")
        return races

    except Exception as e:
        logger.error(f"Error fetching races: {e}")
        return []

def fetch_race_details(race_id):
    """レース詳細情報取得"""
    try:
        url = f"{BASE_URL}/owpc/pc/race/racedetail?raceId={race_id}"
        response = requests.get(url, timeout=10)
        response.encoding = 'utf-8'
        soup = BeautifulSoup(response.content, 'html.parser')

        details = {
            'weather': 'Unknown',
            'wind_direction': 'Unknown',
            'wind_speed': 0.0,
            'wave_height': 0.0,
            'entries': []
        }

        # 天候情報抽出
        weather_elem = soup.find('span', class_='weather')
        if weather_elem:
            details['weather'] = weather_elem.text.strip()

        # 選手情報抽出
        entry_rows = soup.find_all('tr', class_='entry-row')
        for row in entry_rows:
            try:
                lane = row.find('td', class_='lane')
                name = row.find('td', class_='racer-name')

                if lane and name:
                    entry = {
                        'lane': int(lane.text),
                        'racer_name': name.text.strip(),
                        'racer_id': row.get('data-racer-id', ''),
                        'racer_class': row.get('data-class', ''),
                        'national_win_rate': 0.0,
                        'local_win_rate': 0.0,
                        'start_timing': 0.0,
                        'motor_number': 0,
                        'motor_second_rate': 0.0,
                        'boat_number': 0,
                        'boat_second_rate': 0.0,
                        'exhibition_time': 0.0,
                        'tilt': 0.0,
                    }
                    details['entries'].append(entry)
            except Exception as e:
                logger.warning(f"Error parsing entry: {e}")
                continue

        return details

    except Exception as e:
        logger.error(f"Error fetching race details: {e}")
        return None

def save_races(races, details_list):
    """レース情報を DB に保存"""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    for race, details in zip(races, details_list):
        if not details:
            continue

        # レース情報保存
        c.execute('''INSERT OR REPLACE INTO races
                    (race_id, date, stadium, race_number, grade, distance,
                     weather, wind_direction, wind_speed, wave_height)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
                  (race['race_id'],
                   race['date'],
                   race['stadium'],
                   race['race_number'],
                   race.get('grade', 'Unknown'),
                   race.get('distance', 1800),
                   details['weather'],
                   details['wind_direction'],
                   details['wind_speed'],
                   details['wave_height']))

        # 選手情報保存
        for entry in details['entries']:
            c.execute('''INSERT INTO entries
                        (race_id, lane, racer_name, racer_id, racer_class, branch,
                         national_win_rate, local_win_rate, start_timing,
                         motor_number, motor_second_rate, boat_number,
                         boat_second_rate, exhibition_time, tilt)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
                      (race['race_id'],
                       entry['lane'],
                       entry['racer_name'],
                       entry['racer_id'],
                       entry['racer_class'],
                       entry.get('branch', ''),
                       entry['national_win_rate'],
                       entry['local_win_rate'],
                       entry['start_timing'],
                       entry['motor_number'],
                       entry['motor_second_rate'],
                       entry['boat_number'],
                       entry['boat_second_rate'],
                       entry['exhibition_time'],
                       entry['tilt']))

    conn.commit()
    conn.close()
    logger.info("Races saved to database")

def main():
    """メイン処理"""
    logger.info("Starting data fetch...")

    # DB 初期化
    init_db()

    # 本日のレース取得
    races = fetch_today_races()

    if not races:
        logger.warning("No races found")
        return

    # 各レースの詳細を取得
    details_list = []
    for race in races:
        details = fetch_race_details(race['race_id'])
        details_list.append(details)

    # DB に保存
    save_races(races, details_list)

    logger.info("Data fetch completed")

if __name__ == '__main__':
    main()
