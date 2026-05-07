@echo off
REM Install Streamlit
echo Installing Streamlit...
pip install streamlit

REM Run the GUI
echo Starting Scryfall Color Filter GUI...
streamlit run scryfall_gui.py
