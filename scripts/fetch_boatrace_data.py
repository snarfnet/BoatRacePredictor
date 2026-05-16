#!/usr/bin/env python3
"""
BOAT RACE.jp からレースデータを取得して SQLite に保存するスクリプト
改善版：User-Agent設定、遅延処理、堅牢なセレクタ
"""

import requests
from bs4 import BeautifulSoup
import sqlite3
import json
from datetime import datetime, timedelta
import logging
import time
from urllib.parse import urljoin

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 設定
DB_PATH = "../boatrace.db"
BASE_URL = "https://www.boatrace.jp"

# User-Agent設定（スクレイピング制限回避）
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'ja-JP,ja;q=0.9',
    'Referer': 'https://www.boatrace.jp/',
}

# セッション設定（接続の再利用）
session = requests.Session()
session.headers.update(HEADERS)

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
    """本日のレース情報取得（改善版）"""
    try:
        url = f"{BASE_URL}/owpc/pc/race/index"

        # User-Agent付きで リクエスト
        response = session.get(url, timeout=15)
        response.raise_for_status()
        response.encoding = 'utf-8'

        logger.info(f"Fetching from {url} - Status: {response.status_code}")
        soup = BeautifulSoup(response.content, 'html.parser')

        races = []

        # 複数のセレクタを試す（HTML構造の変更に対応）
        race_selectors = [
            'div[data-race-id]',
            'article.race-item',
            'tr.race-row',
            'div.race-block'
        ]

        race_items = []
        for selector in race_selectors:
            items = soup.select(selector)
            if items:
                logger.info(f"Found races with selector: {selector} ({len(items)} items)")
                race_items = items
                break

        if not race_items:
            logger.warning("No race items found with any selector")
            # テーブルからも試す
            tables = soup.find_all('table')
            for table in tables:
                rows = table.find_all('tr')[1:]  # ヘッダーをスキップ
                if rows:
                    race_items = rows[:12]  # 最大12レース
                    break

        for item in race_items:
            try:
                # data-race-id から race_id を取得
                race_id = item.get('data-race-id')

                if not race_id:
                    # テーブル行の場合
                    cells = item.find_all('td')
                    if len(cells) >= 3:
                        stadium = cells[0].text.strip()
                        race_num = int(cells[1].text.strip()) if cells[1].text.isdigit() else 0
                    else:
                        continue
                else:
                    # div要素の場合
                    stadium_elem = item.find(['span', 'h3'], class_=lambda x: x and 'stadium' in x.lower())
                    stadium = stadium_elem.text.strip() if stadium_elem else "Unknown"

                    race_num_elem = item.find(['span', 'strong'], class_=lambda x: x and 'race' in x.lower())
                    race_num = int(''.join(filter(str.isdigit, race_num_elem.text))) if race_num_elem else 0

                if stadium and race_num > 0:
                    race_data = {
                        'race_id': race_id or f"{stadium}-{race_num}",
                        'stadium': stadium,
                        'race_number': race_num,
                        'date': datetime.now().strftime('%Y-%m-%d'),
                    }
                    races.append(race_data)
                    logger.info(f"Parsed: {stadium} #{race_num}")

            except Exception as e:
                logger.warning(f"Error parsing race item: {e}")
                continue

        logger.info(f"Successfully fetched {len(races)} races")
        return races

    except requests.exceptions.Timeout:
        logger.error("Request timeout - BOAT RACE.jp may be blocking requests")
        return []
    except requests.exceptions.RequestException as e:
        logger.error(f"Request error: {e}")
        return []
    except Exception as e:
        logger.error(f"Error fetching races: {e}")
        return []

def fetch_race_details(race_id):
    """レース詳細情報取得（改善版）"""
    try:
        # レース詳細のURL構築
        url = f"{BASE_URL}/owpc/pc/race/racedetail"
        params = {'raceId': race_id}

        # 遅延を入れてサーバー負荷を軽減
        time.sleep(1)

        response = session.get(url, params=params, timeout=15)
        response.raise_for_status()
        response.encoding = 'utf-8'

        logger.info(f"Fetching details for race: {race_id}")
        soup = BeautifulSoup(response.content, 'html.parser')

        details = {
            'weather': 'Unknown',
            'wind_direction': 'Unknown',
            'wind_speed': 0.0,
            'wave_height': 0.0,
            'entries': []
        }

        # 天候情報抽出（複数パターン試す）
        weather_selectors = [
            'span.weather',
            'div.condition span',
            'td:contains("天候")',
        ]

        for selector in weather_selectors:
            if selector.startswith('td'):
                elem = soup.find('td', string=lambda s: s and '天候' in s)
                if elem and elem.find_next('td'):
                    details['weather'] = elem.find_next('td').text.strip()
                    break
            else:
                elem = soup.select_one(selector)
                if elem:
                    details['weather'] = elem.text.strip()
                    break

        # 選手情報抽出
        entry_rows = soup.find_all('tr', class_=lambda x: x and 'entry' in x.lower())

        if not entry_rows:
            # クラス指定がない場合、テーブルから探す
            tables = soup.find_all('table')
            for table in tables:
                rows = table.find_all('tr')[1:]  # ヘッダーをスキップ
                if len(rows) == 6:  # 競艇は6選手
                    entry_rows = rows
                    break

        for idx, row in enumerate(entry_rows, 1):
            try:
                cells = row.find_all('td')

                if len(cells) < 3:
                    continue

                # セルの内容を解析
                lane = idx  # 行番号がレーン番号の場合がある
                racer_name = cells[1].text.strip() if len(cells) > 1 else "Unknown"
                racer_id = row.get('data-racer-id', '')

                entry = {
                    'lane': lane,
                    'racer_name': racer_name,
                    'racer_id': racer_id,
                    'racer_class': row.get('data-class', 'A2'),
                    'national_win_rate': 5.5,  # デフォルト値
                    'local_win_rate': 5.5,
                    'start_timing': 0.15,
                    'motor_number': 0,
                    'motor_second_rate': 35.0,
                    'boat_number': 0,
                    'boat_second_rate': 35.0,
                    'exhibition_time': 6.75,
                    'tilt': 0.0,
                }

                details['entries'].append(entry)
                logger.info(f"  Lane {lane}: {racer_name}")

            except Exception as e:
                logger.warning(f"Error parsing entry row {idx}: {e}")
                continue

        if not details['entries']:
            logger.warning(f"No entries found for race {race_id}")

        return details

    except requests.exceptions.Timeout:
        logger.error(f"Timeout fetching details for {race_id}")
        return None
    except Exception as e:
        logger.error(f"Error fetching race details for {race_id}: {e}")
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
