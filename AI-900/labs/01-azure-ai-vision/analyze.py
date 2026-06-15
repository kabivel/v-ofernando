"""Analyze an image with Azure AI Vision.

Usage:
    python analyze.py <image-url>

Env vars required:
    AZURE_AI_VISION_ENDPOINT  - e.g. https://<name>.cognitiveservices.azure.com/
    AZURE_AI_VISION_KEY       - key1 from the resource

Docs:
    https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/overview
    https://learn.microsoft.com/en-us/python/api/overview/azure/ai-vision-imageanalysis-readme
"""
import os
import sys
import json
from azure.ai.vision.imageanalysis import ImageAnalysisClient
from azure.ai.vision.imageanalysis.models import VisualFeatures
from azure.core.credentials import AzureKeyCredential


def main(image_url: str) -> None:
    endpoint = os.environ.get("AZURE_AI_VISION_ENDPOINT")
    key = os.environ.get("AZURE_AI_VISION_KEY")
    if not endpoint or not key:
        sys.exit("Set AZURE_AI_VISION_ENDPOINT and AZURE_AI_VISION_KEY env vars.")

    client = ImageAnalysisClient(endpoint=endpoint, credential=AzureKeyCredential(key))

    # Each VisualFeature is a separate billable analysis.
    result = client.analyze_from_url(
        image_url=image_url,
        visual_features=[
            VisualFeatures.CAPTION,
            VisualFeatures.TAGS,
            VisualFeatures.OBJECTS,
        ],
        gender_neutral_caption=True,
    )

    print(json.dumps({
        "caption": {
            "text": result.caption.text if result.caption else None,
            "confidence": result.caption.confidence if result.caption else None,
        },
        "tags": [
            {"name": t.name, "confidence": round(t.confidence, 3)}
            for t in (result.tags.list if result.tags else [])
        ],
        "objects": [
            {
                "name": o.tags[0].name if o.tags else None,
                "box": {
                    "x": o.bounding_box.x,
                    "y": o.bounding_box.y,
                    "w": o.bounding_box.width,
                    "h": o.bounding_box.height,
                },
            }
            for o in (result.objects.list if result.objects else [])
        ],
    }, indent=2))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: python analyze.py <image-url>")
    main(sys.argv[1])
