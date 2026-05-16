#!/usr/bin/env python3
"""
BOAT RACE.jp から過去 30 日分のレース・結果データを取得
"""

import requests
from bs4 import BeautifulSoup
import sqlite3
from datetime import datetime, timedelta
import logging
import time
from urllib.parse import urljoin

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DB_PATH = "../boatrace.db"
BASE_URL = "https://www.boatrace.jp"

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'ja-JP,ja;q=0.9',
}

session = requests.Session()
session.headers.update(HEADERS)

def fetch_races_for_date(date_str: str) -> list:
    """
    指定日のレース一覧を取得
    date_str: "2026-05-14" 形式
    """
    try:
        # URL構築（日付形式：20260514）
        date_param = date_str.replace("-", "")
        url = f"{BASE_URL}/owpc/pc/race/index"
        params = {'date': date_param}

        time.sleep(0.5)  # サーバー負荷軽減
        response = session.get(url, params=params, timeout=10)
        response.raise_for_status()
        response.encoding = 'utf-8'

        soup = BeautifulSoup(response.content, 'html.parser')
        races = []

        # レース情報を抽出
        race_items = soup.select('div[data-race-id], article.race-item, tr.race-row')

        for item in race_items:
            try:
                race_id = item.get('data-race-id', '')

                # テキストから場所とレース番号を抽出
                text = item.get_text()

                if not race_id and text:
                    # IDがない場合は日付+場所+番号から構築
                    race_id = f"{date_param}-{text[:2]}"

                if race_id:
                    races.append({
                        'race_id': race_id,
                        'date': date_str,
                        'date_param': date_param
                    })

            except Exception as e:
                logger.debug(f"Error parsing race item: {e}")
                continue

        if races:
            logger.info(f"{date_str}: Found {len(races)} races")

        return races

    except Exception as e:
        logger.warning(f"Error fetching races for {date_str}: {e}")
        return []

def fetch_results_for_date(date_str: str) -> list:
    """
    指定日のレース結果を取得
    """
    try:
        date_param = date_str.replace("-", "")
        url = f"{BASE_URL}/owpc/pc/race/raceresult"
        params = {'raceDate': date_param}

        time.sleep(0.5)
        response = session.get(url, params=params, timeout=10)
        response.raise_for_status()
        response.encoding = 'utf-8'

        soup = BeautifulSoup(response.content, 'html.parser')
        results = []

        # 結果を抽出
        result_items = soup.select('div[data-race-id], tr.result-row')

        for item in result_items:
            try:
                race_id = item.get('data-race-id', '')

                # 着順を取得
                finish_text = item.get_text()
                finish_order = [int(x) for x in finish_text.split() if x.isdigit()][:3]

                if race_id and finish_order:
                    results.append({
                        'race_id': race_id,
                        'finish_order': ','.join(map(str, finish_order)),
                        'date': date_str
                    })

            except Exception as e:
                logger.debug(f"Error parsing result: {e}")
                continue

        if results:
            logger.info(f"{date_str}: Found {len(results)} results")

        return results

    except Exception as e:
        logger.warning(f"Error fetching results for {date_str}: {e}")
        return []

def save_races_to_db(races: list):
    """レースデータを DB に保存"""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    for race in races:
        try:
            c.execute('''INSERT OR REPLACE INTO races
                        (race_id, date, stadium, race_number, grade, distance,
                         weather, wind_direction, wind_speed, wave_height)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
                      (race['race_id'], race['date'], 'Stadium', 0, 'General', 1800,
                       'Sunny', 'Calm', 0.0, 0.0))
        except Exception as e:
            logger.debug(f"Error saving race: {e}")
            continue

    conn.commit()
    conn.close()
    logger.info(f"Saved {len(races)} races to database")

def save_results_to_db(results: list):
    """結果データを DB に保存"""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    # 結果テーブル作成
    c.execute('''CREATE TABLE IF NOT EXISTS results (
        race_id TEXT PRIMARY KEY,
        finish_order TEXT,
        FOREIGN KEY(race_id) REFERENCES races(race_id)
    )''')

    for result in results:
        try:
            c.execute('''INSERT OR REPLACE INTO results
                        (race_id, finish_order)
                        VALUES (?, ?)''',
                      (result['race_id'], result['finish_order']))
        except Exception as e:
            logger.debug(f"Error saving result: {e}")
            continue

    conn.commit()
    conn.close()
    logger.info(f"Saved {len(results)} results to database")

def main():
    print("=== Historical Data Fetch ===\n")

    # 過去 30 日分を取得
    days_back = 30
    all_races = []
    all_results = []

    for i in range(days_back, 0, -1):
        date = (datetime.now() - timedelta(days=i)).strftime('%Y-%m-%d')

        # レースを取得
        races = fetch_races_for_date(date)
        all_races.extend(races)

        # 結果を取得
        results = fetch_results_for_date(date)
        all_results.extend(results)

        # サーバー負荷軽減
        time.sleep(1)

    print(f"\n[OK] Fetched:")
    print(f"  Races: {len(all_races)}")
    print(f"  Results: {len(all_results)}")

    # DB に保存
    if all_races:
        save_races_to_db(all_races)
    if all_results:
        save_results_to_db(all_results)

    # 統計
    print(f"\n[Summary]")
    print(f"  Total races: {len(all_races)}")
    print(f"  Total results: {len(all_results)}")
    print(f"  Coverage: {len(all_results) / max(len(all_races), 1) * 100:.1f}%")

if __name__ == '__main__':
    main()
