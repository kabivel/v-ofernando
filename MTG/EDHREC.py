import re
import json
import time
import unicodedata
from urllib.parse import quote

import pandas as pd
import requests


def slugify_name(name: str) -> str:
    """
    EDHREC uses URL-friendly slugs: lowercase, ascii, remove punctuation, spaces->hyphen.
    """
    x = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode("ascii")
    x = x.lower()
    x = re.sub(r"[^a-z0-9\s-]", "", x)
    x = re.sub(r"\s+", "-", x.strip())
    x = re.sub(r"-{2,}", "-", x)
    return x


def primary_side_name(name: str) -> str:
    """
    For double-faced cards or cards with ' // ' in the name, return only the primary side (left side).
    """
    if not name:
        return name
    # common separator for double-faced cards is ' // ' or '//'
    if '//' in name:
        return name.split('//', 1)[0].strip()
    return name


def fetch_edhrec_html_for_card(name: str, retries: int = 3):
    """
    Fetch and parse EDHREC card page (HTML scraping).
    Extracts deck count and other stats from the visible page.
    """
    slug = slugify_name(name)
    url = f"https://edhrec.com/cards/{slug}"
    
    for attempt in range(retries):
        try:
            r = requests.get(
                url,
                timeout=10,  # reduced timeout
                headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
            )
            r.raise_for_status()
            return r.text, url
        
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 404:
                raise  # Card not found, don't retry
            elif e.response.status_code in (429, 503):  # Rate limit or service unavailable
                if attempt < retries - 1:
                    wait_time = (2 ** attempt) * 2
                    time.sleep(wait_time)
                    continue
            raise
        except (requests.exceptions.Timeout, requests.exceptions.ConnectionError) as e:
            if attempt < retries - 1:
                wait_time = 2 ** attempt
                time.sleep(wait_time)
                continue
            raise


def _parse_deck_count_from_html(html: str):
    """
    Find the main deck count on the page (not commander breakdowns).
    Strategy:
    1. Look for "In XXX decks" pattern (main deck count indicator)
    2. Fallback to looking for numbers + K/M/B not marked as 'potential'
    3. Normalize separators and convert K/M/B to integers
    """
    # Strategy 1: Look for "In XXX decks" pattern (most reliable)
    main_pattern = re.compile(r'In\s+([\d.,]+)\s*([KMBkmb]?)\s*decks', re.IGNORECASE)
    for m in main_pattern.finditer(html):
        raw = m.group(1).strip()
        suf = m.group(2).upper()
        
        # Normalize thousands separators
        if raw.count('.') > 1 and raw.count(',') == 0:
            raw_norm = raw.replace('.', '')
        elif raw.count(',') > 1 and raw.count('.') == 0:
            raw_norm = raw.replace(',', '')
        else:
            raw_norm = raw.replace(',', '')
        
        try:
            num = float(raw_norm)
            if suf == 'K':
                num *= 1_000
            elif suf == 'M':
                num *= 1_000_000
            elif suf == 'B':
                num *= 1_000_000_000
            return int(num)
        except Exception:
            continue
    
    # Strategy 2: Fallback to general pattern (skip potential, return first valid)
    pattern = re.compile(r'([\d.,]+)\s*([KMBkmb]?)\s*decks', re.IGNORECASE)
    for m in pattern.finditer(html):
        ctx = html[max(0, m.start() - 40): m.end() + 40].lower()
        if 'potential' in ctx:
            continue
        raw = m.group(1).strip()
        suf = m.group(2).upper()
        
        # Normalize thousands separators
        if raw.count('.') > 1 and raw.count(',') == 0:
            raw_norm = raw.replace('.', '')
        elif raw.count(',') > 1 and raw.count('.') == 0:
            raw_norm = raw.replace(',', '')
        else:
            raw_norm = raw.replace(',', '')
        
        try:
            num = float(raw_norm)
            if suf == 'K':
                num *= 1_000
            elif suf == 'M':
                num *= 1_000_000
            elif suf == 'B':
                num *= 1_000_000_000
            return int(num)
        except Exception:
            continue
    
    return None


def parse_edhrec_data(html: str):
    """
    Extract deck count, similar cards, and top commanders from EDHREC HTML page.
    """
    deck_count = _parse_deck_count_from_html(html)
    similar_cards = None
    top_commanders = None
    
    # Extract top commanders from the card grid using proximity matching
    # Find all Card_name positions and their content
    card_name_matches = [
        (m.start(), m.group(1))
        for m in re.finditer(r'Card_name__\w+">([^<]+)<', html)
    ]
    
    # Find all CardLabel_stat positions and their content
    card_stat_matches = [
        (m.start(), m.group(1))
        for m in re.finditer(r'CardLabel_stat__\w+"[^>]*>([^<]+)', html)
    ]
    
    # Match each card name to the nearest stat that comes after it
    if card_name_matches and card_stat_matches:
        matched_cards = []
        for name_pos, name in card_name_matches:
            # Find the closest stat that comes after this name
            next_stats = [(stat_pos, stat) for stat_pos, stat in card_stat_matches if stat_pos > name_pos]
            
            if next_stats:
                closest_stat = min(next_stats, key=lambda x: x[0])
                stat_value = closest_stat[1]
                
                # Clean up card name
                name = name.strip().replace('&#x27;', "'").replace('&quot;', '"').replace('&amp;', '&')
                
                # Extract percentage from stat (remove trailing % if present)
                stat_value = stat_value.replace('%', '').strip()
                
                try:
                    stat_float = float(stat_value)
                    matched_cards.append((name, stat_float))
                except ValueError:
                    pass
        
        # Top commanders are typically the first 20-24 cards on the page
        # Usually these are commanders with lower percentages (< 3%), 
        # before the page transitions to High Lift Cards or other sections
        if matched_cards:
            # Find natural cutoff: usually around card 20-24 or where percentage jumps dramatically
            top_cmdr_list = []
            high_pct_count = 0
            
            for i, (name, percentage) in enumerate(matched_cards):
                # Hard limit at 25 cards
                if i >= 25:
                    break
                
                # Soft limit: if we see 3+ high percentage cards in a row (>15%), stop
                if percentage > 15:
                    high_pct_count += 1
                    if high_pct_count >= 3:
                        break
                else:
                    high_pct_count = 0
                
                top_cmdr_list.append(name)
            
            if top_cmdr_list:
                top_commanders = top_cmdr_list
    
    # Extract similar cards from embedded JSON
    try:
        scripts = re.findall(r'<script[^>]+type=["\']application/json["\'][^>]*>(.*?)</script>', html, re.DOTALL | re.IGNORECASE)
        for s in scripts:
            try:
                data = json.loads(s)
            except Exception:
                continue
            
            # Look for data in props.pageProps.data
            if (isinstance(data, dict) and 'props' in data and 
                isinstance(data['props'], dict) and 'pageProps' in data['props']):
                page_data = data['props']['pageProps'].get('data', {})
                
                if isinstance(page_data, dict):
                    # Extract similar cards (unranked, just similar)
                    if 'similar' in page_data and similar_cards is None:
                        similar_list = page_data['similar']
                        if isinstance(similar_list, list) and len(similar_list) > 0:
                            cards = []
                            for item in similar_list:
                                if isinstance(item, dict) and 'name' in item:
                                    cards.append(item['name'])
                            if cards:
                                similar_cards = cards
    except Exception:
        pass
    
    return {
        "deck_count": deck_count,
        "similar_cards": similar_cards,
        "top_commanders": top_commanders,
    }


def main():
    df = pd.read_csv("out/jeskai_creatures_keywords_ge3.csv")
    print(f"Processing {len(df)} cards from CSV...\n")

    edh_rows = []
    success_count = 0
    error_count = 0

    for i, row in df.iterrows():
        name = row["name"]
        print(f"[{i + 1}/{len(df)}] Fetching: {name}...", end=" ", flush=True)

        # Build image URL from Scryfall ID if available
        card_image_url = None
        if "scryfall_id" in row and pd.notna(row["scryfall_id"]):
            scryfall_id = row["scryfall_id"]
            # Format: https://cards.scryfall.io/large/front/{first_char}/{second_char}/{id}.jpg
            card_image_url = f"https://cards.scryfall.io/large/front/{scryfall_id[0]}/{scryfall_id[1]}/{scryfall_id}.jpg"

        try:
            fetch_name = primary_side_name(name)
            html, url = fetch_edhrec_html_for_card(fetch_name)
            data = parse_edhrec_data(html)

            edh_rows.append({
                "name": name,
                "card_image_url": card_image_url,
                "edhrec_source_url": url,
                "edhrec_deck_count": data.get("deck_count"),  # int or None
                "edhrec_similar_cards": "; ".join(data.get("similar_cards")) if data.get("similar_cards") else None,
                "edhrec_top_commanders": "; ".join(data.get("top_commanders")) if data.get("top_commanders") else None,
            })
            print(f"✓ ({data.get('deck_count')} decks)")
            success_count += 1

            time.sleep(0.3)  # be respectful to EDHREC server
        
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 404:
                print(f"✗ (not found)")
            else:
                print(f"✗ (HTTP {e.response.status_code})")
            error_count += 1
            edh_rows.append({
                "name": name,
                "card_image_url": card_image_url,
                "edhrec_source_url": None,
                "edhrec_deck_count": None,
                "edhrec_similar_cards": None,
                "edhrec_top_commanders": None,
                "edhrec_error": f"HTTP {e.response.status_code}",
            })
        
        except Exception as e:
            print(f"✗ ({type(e).__name__})")
            error_count += 1
            edh_rows.append({
                "name": name,
                "card_image_url": card_image_url,
                "edhrec_source_url": None,
                "edhrec_deck_count": None,
                "edhrec_similar_cards": None,
                "edhrec_top_commanders": None,
                "edhrec_error": str(e)[:100],  # truncate long error messages
            })

    print(f"\n✓ Success: {success_count}, ✗ Errors: {error_count}\n")

    edh = pd.DataFrame(edh_rows)
    # Convert deck_count to nullable Int64 to avoid float conversion
    edh['edhrec_deck_count'] = edh['edhrec_deck_count'].astype('Int64')
    out = df.merge(edh, on="name", how="left")
    out.to_csv("out/jeskai_creatures_keywords_ge3_with_edhrec.csv", index=False, encoding="utf-8")
    print("✓ Saved: out/jeskai_creatures_keywords_ge3_with_edhrec.csv")

if __name__ == "__main__":
    main()