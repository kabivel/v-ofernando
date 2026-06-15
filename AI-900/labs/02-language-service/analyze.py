"""Analyze product reviews with Azure AI Language.

Env vars required:
    AZURE_AI_LANG_ENDPOINT
    AZURE_AI_LANG_KEY

Docs:
    https://learn.microsoft.com/en-us/azure/ai-services/language-service/overview
    https://learn.microsoft.com/en-us/python/api/overview/azure/ai-textanalytics-readme
"""
import os
import sys
import json
from azure.core.credentials import AzureKeyCredential
from azure.ai.textanalytics import TextAnalyticsClient

REVIEWS = [
    "The Surface Laptop battery lasted all day and the screen is gorgeous. Best purchase I've made this year!",
    "Azure support helped me migrate my SQL Server database in two hours. Very smooth experience.",
    "The keyboard backlight stopped working after a week. Disappointed with Contoso's build quality.",
    "Setup took five minutes. Office 365 sync was seamless from day one in Lisbon.",
]


def main() -> None:
    endpoint = os.environ.get("AZURE_AI_LANG_ENDPOINT")
    key = os.environ.get("AZURE_AI_LANG_KEY")
    if not endpoint or not key:
        sys.exit("Set AZURE_AI_LANG_ENDPOINT and AZURE_AI_LANG_KEY env vars.")

    client = TextAnalyticsClient(endpoint=endpoint, credential=AzureKeyCredential(key))

    languages = client.detect_language(documents=REVIEWS)
    sentiments = client.analyze_sentiment(documents=REVIEWS)
    key_phrases = client.extract_key_phrases(documents=REVIEWS)
    entities = client.recognize_entities(documents=REVIEWS)

    for i, review in enumerate(REVIEWS):
        print(json.dumps({
            "review": review,
            "language": languages[i].primary_language.iso6391_name if not languages[i].is_error else None,
            "sentiment": sentiments[i].sentiment if not sentiments[i].is_error else None,
            "confidence": {
                "positive": round(sentiments[i].confidence_scores.positive, 3),
                "neutral": round(sentiments[i].confidence_scores.neutral, 3),
                "negative": round(sentiments[i].confidence_scores.negative, 3),
            } if not sentiments[i].is_error else None,
            "key_phrases": list(key_phrases[i].key_phrases) if not key_phrases[i].is_error else None,
            "entities": [
                {"text": e.text, "category": e.category, "confidence": round(e.confidence_score, 3)}
                for e in entities[i].entities
            ] if not entities[i].is_error else None,
        }, indent=2))
        print("---")


if __name__ == "__main__":
    main()
