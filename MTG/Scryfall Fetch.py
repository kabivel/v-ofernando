import json
import re
import gzip
import io
import unicodedata
from pathlib import Path

import pandas as pd
import requests


JESKAI = {"W", "U", "R"}

# Exact keyword list requested (case-insensitive match)
KEYWORD_LIST = [
    "Flying",
    "First strike",
    "Vigilance",
    "Trample",
    "Reach",
    "Protection",
    "Menace",
    "Lifelink",
    "Indestructible",
    "Hexproof",
    "Haste",
    "Deathtouch",
    "Double strike",
    "Partner",
]


def _normalize_kw_text(s: str) -> str:
    if not s:
        return ""
    s2 = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode("ascii")
    return re.sub(r"\s+", " ", s2).strip().lower()


# precompute normalized set for fast membership checks
KEYWORD_SET = set(_normalize_kw_text(k) for k in KEYWORD_LIST)

def download_scryfall_oracle_bulk(out_path: Path) -> Path:
    """
    Downloads the latest Scryfall 'oracle_cards' bulk file.
    Returns the path to the downloaded JSON (or JSON.GZ).
    """
    resp = requests.get("https://api.scryfall.com/bulk-data", timeout=60)
    resp.raise_for_status()
    meta = resp.json()
    oracle = next(x for x in meta["data"] if x.get("type") == "oracle_cards")
    url = oracle["download_uri"]

    r = requests.get(url, stream=True, timeout=300)
    r.raise_for_status()

    # If the remote file is gzipped, preserve the .gz extension locally so
    # load_bulk_cards can detect and open it correctly.
    final_path = out_path
    if url.lower().endswith(".gz"):
        final_path = out_path.with_name(out_path.name + ".gz")

    final_path.parent.mkdir(parents=True, exist_ok=True)
    with open(final_path, "wb") as f:
        for chunk in r.iter_content(chunk_size=1024 * 1024):
            if chunk:
                f.write(chunk)
    return final_path


def load_bulk_cards(path: Path):
    """
    Loads a Scryfall bulk JSON file.
    Supports .json and .json.gz
    """
    if str(path).endswith(".gz"):
        with gzip.open(path, "rb") as f:
            return json.load(f)
    else:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)


def normalize_keywords(card: dict):
    """
    Get keywords list. For multi-face cards, union face keywords too.
    """
    kws = set(card.get("keywords") or [])
    faces = card.get("card_faces") or []
    for face in faces:
        for kw in (face.get("keywords") or []):
            kws.add(kw)
    return sorted(kws)


def get_type_line(card: dict):
    """
    Use card's type_line. If missing (rare), use faces type_line union.
    """
    tl = card.get("type_line")
    if tl:
        return tl
    faces = card.get("card_faces") or []
    tls = [f.get("type_line") for f in faces if f.get("type_line")]
    return " // ".join(tls)


def is_creature(card: dict) -> bool:
    return "Creature" in (get_type_line(card) or "")


def ci_is_jeskai_subset(card: dict) -> bool:
    ci = set(card.get("color_identity") or [])
    return ci.issubset(JESKAI)


def is_commander_legal(card: dict) -> bool:
    leg = card.get("legalities") or {}
    return leg.get("commander") == "legal"


def main():
    out_dir = Path("out")
    out_dir.mkdir(exist_ok=True)

    # Choose file name. Scryfall download_uri is usually .json; sometimes people prefer .json.gz.
    bulk_path = out_dir / "oracle-cards.json"
    bulk_path = download_scryfall_oracle_bulk(bulk_path)

    cards = load_bulk_cards(bulk_path)

    rows = []
    for c in cards:
        # Clean filters to keep dataset relevant for EDH
        if c.get("lang") != "en":
            continue
        if c.get("digital") is True:
            continue
        if not is_commander_legal(c):
            continue
        if not is_creature(c):
            continue
        if not ci_is_jeskai_subset(c):
            continue

        kws = normalize_keywords(c)

        # match only keywords from the exact requested list (case-insensitive)
        matched = [kw for kw in kws if _normalize_kw_text(kw) in KEYWORD_SET]
        if len(matched) < 3:
            continue

        rows.append({
            "scryfall_id": c.get("id"),
            "name": c.get("name"),
            "mana_cost": c.get("mana_cost"),
            "type_line": get_type_line(c),
            "power": c.get("power"),
            "toughness": c.get("toughness"),
            "cmc": c.get("cmc"),
            "rarity": c.get("rarity"),
            "color_identity": "".join(c.get("color_identity") or []),
            "keywords": "|".join(kws),
            "keyword_count": len(kws),
            "matched_keywords": "|".join(matched),
            "matched_keyword_count": len(matched),
            "oracle_text": c.get("oracle_text"),
            "scryfall_uri": c.get("scryfall_uri"),
        })

    df = pd.DataFrame(rows).sort_values(["keyword_count", "name"], ascending=[False, True])
    out_csv = out_dir / "jeskai_creatures_keywords_ge3.csv"
    df.to_csv(out_csv, index=False, encoding="utf-8")

    print(f"Saved {len(df)} cards to: {out_csv.resolve()}")

if __name__ == "__main__":
    main()