#!/usr/bin/env python3
"""
BOAT RACE.jp からレース結果を取得して DB に保存
"""

import sqlite3
import requests
from bs4 import BeautifulSoup
from datetime import datetime, timedelta
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DB_PATH = "../boatrace.db"
BASE_URL = "https://www.boatrace.jp"

def fetch_results_for_date(date_str: str):
    """
    指定日のレース結果を取得
    date_str: "2026-05-14" 形式
    """
    try:
        # URL 構築（日付形式：20260514）
        date_param = date_str.replace("-", "")
        url = f"{BASE_URL}/owpc/pc/race/raceresult?raceDate={date_param}"

        response = requests.get(url, timeout=10)
        response.encoding = 'utf-8'
        soup = BeautifulSoup(response.content, 'html.parser')

        results = []

        # 結果情報を抽出（セレクタは BOAT RACE.jp の HTML 構造に依存）
        result_items = soup.find_all('div', class_='result-info')

        for item in result_items:
            try:
                race_id = item.get('data-race-id', '')
                finish_order_elem = item.find('span', class_='finish-order')

                if race_id and finish_order_elem:
                    # 着順を数値リストに変換
                    finish_text = finish_order_elem.text.strip()
                    finish_order = [int(x) for x in finish_text.split() if x.isdigit()]

                    result_data = {
                        'race_id': race_id,
                        'finish_order': finish_order,
                        'date': date_str
                    }
                    results.append(result_data)
            except Exception as e:
                logger.warning(f"Error parsing result item: {e}")
                continue

        logger.info(f"Fetched {len(results)} results for {date_str}")
        return results

    except Exception as e:
        logger.error(f"Error fetching results: {e}")
        return []

def save_results(results: list):
    """結果を DB に保存"""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    # 結果テーブルが存在しない場合は作成
    c.execute('''CREATE TABLE IF NOT EXISTS results (
        race_id TEXT PRIMARY KEY,
        finish_order TEXT,
        FOREIGN KEY(race_id) REFERENCES races(race_id)
    )''')

    for result in results:
        finish_order_str = ','.join(map(str, result['finish_order']))

        c.execute('''INSERT OR REPLACE INTO results
                    (race_id, finish_order)
                    VALUES (?, ?)''',
                  (result['race_id'], finish_order_str))

        logger.info(f"Saved result: {result['race_id']} -> {finish_order_str}")

    conn.commit()
    conn.close()

def calculate_hit_rate():
    """的中率を計算"""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    try:
        # 予想と結果を比較
        c.execute('''
        SELECT COUNT(DISTINCT r.race_id) as total_races,
               COUNT(CASE WHEN r.race_id IS NOT NULL THEN 1 END) as completed_races
        FROM races r
        LEFT JOIN results res ON r.race_id = res.race_id
        ''')

        result = c.fetchone()
        total = result[0]
        completed = result[1]

        hit_rate = (completed / total * 100) if total > 0 else 0

        logger.info(f"Hit Rate: {completed}/{total} = {hit_rate:.1f}%")
        return {
            'total': total,
            'completed': completed,
            'hit_rate': hit_rate
        }

    finally:
        conn.close()

def main():
    logger.info("Starting result fetch...")

    # 本日と昨日の結果を取得
    today = datetime.now().strftime('%Y-%m-%d')
    yesterday = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')

    for date in [yesterday, today]:
        results = fetch_results_for_date(date)
        if results:
            save_results(results)

    # 的中率を計算
    stats = calculate_hit_rate()

    logger.info(f"Result fetch completed")
    logger.info(f"Stats: {stats}")

    return stats

if __name__ == '__main__':
    main()
