"""
Streamlit GUI for Scryfall Magic Card Filter
Allows interactive selection of color combinations and keyword filters
"""

import streamlit as st
import pandas as pd
import requests
import json
import gzip
import re
import unicodedata
from pathlib import Path

# Color mapping
COLORS = {
    "White": "W",
    "Blue": "U",
    "Black": "B",
    "Red": "R",
    "Green": "G",
    "Colorless": "C",
}

# Icon URLs for mana symbols (Scryfall SVGs)
ICON_URLS = {
    "W": "https://svgs.scryfall.io/card-symbols/W.svg",
    "U": "https://svgs.scryfall.io/card-symbols/U.svg",
    "B": "https://svgs.scryfall.io/card-symbols/B.svg",
    "R": "https://svgs.scryfall.io/card-symbols/R.svg",
    "G": "https://svgs.scryfall.io/card-symbols/G.svg",
    "C": "https://svgs.scryfall.io/card-symbols/C.svg",
}

# Default keyword list
DEFAULT_KEYWORDS = [
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


def download_scryfall_oracle_bulk(out_path: Path) -> Path:
    """Downloads the latest Scryfall 'oracle_cards' bulk file."""
    resp = requests.get("https://api.scryfall.com/bulk-data", timeout=60)
    resp.raise_for_status()
    meta = resp.json()
    oracle = next(x for x in meta["data"] if x.get("type") == "oracle_cards")
    url = oracle["download_uri"]

    r = requests.get(url, stream=True, timeout=300)
    r.raise_for_status()

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
    """Loads a Scryfall bulk JSON file."""
    if str(path).endswith(".gz"):
        with gzip.open(path, "rb") as f:
            return json.load(f)
    else:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)


def normalize_keywords(card: dict):
    """Get keywords list. For multi-face cards, union face keywords too."""
    kws = set(card.get("keywords") or [])
    faces = card.get("card_faces") or []
    for face in faces:
        for kw in (face.get("keywords") or []):
            kws.add(kw)
    return sorted(kws)


def get_type_line(card: dict):
    """Use card's type_line. If missing (rare), use faces type_line union."""
    tl = card.get("type_line")
    if tl:
        return tl
    faces = card.get("card_faces") or []
    tls = [f.get("type_line") for f in faces if f.get("type_line")]
    return " // ".join(tls)


def get_creature_types(card: dict) -> list:
    """Extract creature types from type_line (e.g., 'Legendary Creature — Human Soldier' -> ['Human', 'Soldier'])"""
    type_line = get_type_line(card)
    if "Creature" not in type_line:
        return []
    
    # Split on — (em dash) to get the creature types part
    parts = type_line.split("—")
    if len(parts) < 2:
        return []
    
    creature_types_str = parts[1].strip()
    # Split on space to get individual types
    return [ct.strip() for ct in creature_types_str.split() if ct.strip()]


def is_creature(card: dict) -> bool:
    return "Creature" in (get_type_line(card) or "")


def ci_is_subset(card: dict, color_set: set) -> bool:
    # Legacy function - keep for compatibility but prefer ci_matches
    ci = set(card.get("color_identity") or [])
    return ci.issubset(color_set)


def ci_matches(card: dict, selected_colors: set, operator: str = "exact") -> bool:
    """Match card color_identity against selected colors.
    - If `Colorless` selected (represented by 'C'), require empty color_identity.
    - Otherwise require exact match between card's color_identity and selected colors.
    """
    has_colorless = "C" in selected_colors
    selected = set(selected_colors) - {"C"}
    ci = set(card.get("color_identity") or [])

    if operator == "exact":
        if has_colorless:
            return ci == set()
        return ci == selected

    if operator == "any":
        if has_colorless:
            return ci == set()
        return len(ci & selected) > 0

    if operator == "all":
        if has_colorless:
            return ci == set()
        return selected.issubset(ci)

    if operator == "subset":
        if has_colorless:
            return ci == set()
        return ci.issubset(selected)

    if operator == "exclude":
        if has_colorless:
            return ci != set()
        return len(ci & selected) == 0

    # fallback to exact
    if has_colorless:
        return ci == set()
    return ci == selected


def is_commander_legal(card: dict) -> bool:
    leg = card.get("legalities") or {}
    return leg.get("commander") == "legal"


def filter_cards(cards, selected_colors, selected_keywords, min_keywords, creature_types_filter=None, color_operator="exact"):
    """Filter cards based on selected criteria."""
    
    keyword_set = set(_normalize_kw_text(k) for k in selected_keywords)
    rows = []
    
    for c in cards:
        # Language and format filters
        if c.get("lang") != "en":
            continue
        if c.get("digital") is True:
            continue
        if not is_commander_legal(c):
            continue
        if not is_creature(c):
            continue
        if not ci_matches(c, selected_colors, color_operator):
            continue

        # Creature type filter
        if creature_types_filter and len(creature_types_filter) > 0:
            creature_types = get_creature_types(c)
            if not any(ct in creature_types_filter for ct in creature_types):
                continue

        kws = normalize_keywords(c)
        matched = [kw for kw in kws if _normalize_kw_text(kw) in keyword_set]
        
        if len(matched) < min_keywords:
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
            "creature_types": ", ".join(get_creature_types(c)),
            "keywords": "|".join(kws),
            "keyword_count": len(kws),
            "matched_keywords": "|".join(matched),
            "matched_keyword_count": len(matched),
            "oracle_text": c.get("oracle_text"),
            "scryfall_uri": c.get("scryfall_uri"),
        })

    return pd.DataFrame(rows).sort_values(["keyword_count", "name"], ascending=[False, True])


def main():
    st.set_page_config(page_title="Scryfall Color Filter", layout="wide")
    st.title("🎴 Scryfall Color Combination Filter")
    
    st.markdown("""
    Select Magic card colors and keywords to filter creatures from Scryfall.
    """)
    
    # Sidebar for configuration
    with st.sidebar:
        st.header("⚙️ Configuration")
        
        # Color selection
        st.subheader("Choose Colors")
        col_buttons = st.columns(6)
        selected_colors = set()
        # Color operator (how to interpret the selected colors)
        color_operator = st.selectbox(
            "Color operator:",
            options=[
                ("Exact match", "exact"),
                ("Any (includes at least one)", "any"),
                ("All (card includes all selected)", "all"),
                ("Subset (card's identity is subset of selected)", "subset"),
                ("Exclude (cards with none of selected)", "exclude"),
            ],
            format_func=lambda x: x[0],
            index=0,
            key="color_operator"
        )
        # store operator code
        color_operator = color_operator[1]
        
        for idx, (color_name, color_code) in enumerate(COLORS.items()):
            with col_buttons[idx]:
                icon_url = ICON_URLS.get(color_code)
                if icon_url:
                    st.image(icon_url, width=36)
                # show checkbox without long label so UI is icon-first
                if st.checkbox("", value=False, key=f"color_{color_name}"):
                    selected_colors.add(color_code)
                # small caption to help identify the icon
                st.caption(color_name)
        
        # Validate colorless selection
        if not selected_colors:
            st.warning("⚠️ Select at least one color!")
            selected_colors = {"W"}  # Default
        elif "C" in selected_colors and len(selected_colors) > 1:
            st.warning("⚠️ 'Colorless' cannot be combined with other colors — using Colorless only.")
            selected_colors = {"C"}
        
        # If operator is incompatible with Colorless selection, enforce Colorless-only behavior
        if "C" in selected_colors and color_operator != "exact":
            st.info("Note: Colorless selection only supports 'Exact match'. Using Exact behavior.")
            color_operator = "exact"
        
        st.divider()
        
        # Action buttons
        run_filter = st.button("🔍 Run Filter", type="primary", use_container_width=True)
        st.subheader("Choose Keywords")
        all_keywords = st.checkbox("Select All Keywords", value=True, key="select_all_keywords")
        
        if all_keywords:
            selected_keywords = DEFAULT_KEYWORDS
        else:
            selected_keywords = st.multiselect(
                "Keywords to match:",
                DEFAULT_KEYWORDS,
                default=DEFAULT_KEYWORDS[:3]
            )
        
        # Minimum keywords
        min_keywords = st.slider(
            "Minimum keywords to match:",
            min_value=1,
            max_value=len(selected_keywords),
            value=3
        )
        
        st.divider()
        
        # Creature type filter (will be populated after data loads)
        st.subheader("Choose Creature Types (Optional)")
        creature_type_filter = st.multiselect(
            "Filter by creature type (e.g., Angel, Knight, Vampire):",
            st.session_state.get("creature_type_options", []),
            placeholder="Load data first to see available creature types",
            key="creature_type_filter"
        )
        
        st.divider()
    
    # Main content area
    if run_filter or "df_results" in st.session_state:
        with st.spinner("Downloading Scryfall data..."):
            try:
                out_dir = Path("out")
                bulk_path = out_dir / "oracle-cards.json"
                
                # Download if not exists
                if not bulk_path.exists() and not (out_dir / "oracle-cards.json.gz").exists():
                    st.info("📥 Downloading Scryfall oracle data (first time only)...")
                    bulk_path = download_scryfall_oracle_bulk(bulk_path)
                else:
                    if (out_dir / "oracle-cards.json.gz").exists():
                        bulk_path = out_dir / "oracle-cards.json.gz"
                
                st.success("✅ Data loaded!")
                
                with st.spinner("Filtering cards..."):
                    cards = load_bulk_cards(bulk_path)

                    # Populate creature type options for the sidebar multiselect
                    all_types = set()
                    for c in cards:
                        for ct in get_creature_types(c):
                            all_types.add(ct)
                    options = sorted(all_types)
                    st.session_state["creature_type_options"] = options

                    df = filter_cards(cards, selected_colors, selected_keywords, min_keywords, creature_type_filter, color_operator)
                    st.session_state.df_results = df

                # Allow immediate refinement by creature type using computed options
                options = st.session_state.get("creature_type_options", [])
                if options:
                    refine_selection = st.multiselect(
                        "Refine results by creature type:",
                        options,
                        default=creature_type_filter or [],
                        key="refine_creature_types"
                    )
                    if refine_selection:
                        def row_has_any(ct_list_str, sel):
                            if not ct_list_str:
                                return False
                            row_types = [x.strip() for x in ct_list_str.split(",")]
                            return any(s in row_types for s in sel)

                        df = df[df["creature_types"].apply(lambda s: row_has_any(s, refine_selection))]
                
                # Display results
                st.subheader(f"📊 Results: {len(df)} cards found")
                
                col1, col2, col3 = st.columns(3)
                with col1:
                    st.metric("Total Cards", len(df))
                with col2:
                    avg_keywords = df["keyword_count"].mean() if len(df) > 0 else 0
                    st.metric("Avg Keywords", f"{avg_keywords:.1f}")
                with col3:
                    avg_cmc = df["cmc"].mean() if len(df) > 0 else 0
                    st.metric("Avg CMC", f"{avg_cmc:.1f}")
                
                # Display table with CMC color coding
                display_df = df[["name", "type_line", "creature_types", "cmc", "rarity", "keyword_count", "matched_keyword_count"]].copy()

                # Normalize CMC for display: convert floats that are whole numbers to ints
                def _normalize_cmc_value(v):
                    try:
                        if v is None:
                            return ""
                        fv = float(v)
                        if fv.is_integer():
                            return int(fv)
                        return fv
                    except Exception:
                        return v

                display_df["cmc"] = display_df["cmc"].apply(_normalize_cmc_value)

                def _cmc_style(v):
                    try:
                        n = int(float(v))
                    except Exception:
                        return ""
                    palette = {
                        0: "#eeeeee",
                        1: "#d0f0ff",
                        2: "#b6f7c6",
                        3: "#b6d0ff",
                        4: "#e7b6ff",
                        5: "#ffd1b6",
                        6: "#ff9b9b",
                        7: "#ff6b6b",
                        8: "#ff3b3b",
                    }
                    col = palette.get(min(n, 8), "#ff3b3b")
                    return f"background-color: {col}; color: #111;"

                try:
                    styled = display_df.style.applymap(_cmc_style, subset=["cmc"])
                    st.dataframe(styled, use_container_width=True, height=400)
                except Exception:
                    # Fallback if styler isn't supported in this Streamlit version
                    st.dataframe(display_df, use_container_width=True, height=400)

                # Legend for CMC colors
                legend_items = [
                    ("0", "#eeeeee"),
                    ("1", "#d0f0ff"),
                    ("2", "#b6f7c6"),
                    ("3", "#b6d0ff"),
                    ("4", "#e7b6ff"),
                    ("5", "#ffd1b6"),
                    ("6", "#ff9b9b"),
                    ("7", "#ff6b6b"),
                    ("8+", "#ff3b3b"),
                ]
                legend_html = ""
                for label, col in legend_items:
                    legend_html += f"<span style='display:inline-block;width:14px;height:14px;background:{col};border:1px solid #888;margin-right:6px;'></span><span style='margin-right:12px'>{label}</span>"
                st.markdown(legend_html, unsafe_allow_html=True)

                # When exporting, normalize CMC in the saved CSV as well
                save_df = df.copy()
                save_df["cmc"] = save_df["cmc"].apply(_normalize_cmc_value)
                
                # Export options
                st.divider()
                col_export1, col_export2 = st.columns(2)
                
                with col_export1:
                    csv = save_df.to_csv(index=False, encoding="utf-8")
                    st.download_button(
                        label="📥 Download CSV",
                        data=csv,
                        file_name=f"cards_{''.join(sorted(selected_colors))}.csv",
                        mime="text/csv"
                    )
                
                with col_export2:
                    # Save to file
                    color_name = "_".join(sorted([cn for cn, cc in COLORS.items() if cc in selected_colors]))
                    out_csv = Path("out") / f"cards_{color_name}.csv"
                    save_df.to_csv(out_csv, index=False, encoding="utf-8")
                    st.success(f"✅ Saved to: {out_csv}")
                
            except Exception as e:
                st.error(f"❌ Error: {str(e)}")
                st.info("Make sure you have an internet connection for the first download.")


if __name__ == "__main__":
    main()
