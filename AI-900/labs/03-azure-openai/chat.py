"""Chat completion via Azure OpenAI Service.

Usage:
    python chat.py "your question here"

Env vars required:
    AZURE_OAI_ENDPOINT     - e.g. https://<name>.openai.azure.com/
    AZURE_OAI_KEY          - key1 from the resource
    AZURE_OAI_DEPLOYMENT   - the deployment name (NOT the model name)
    AZURE_OAI_API_VERSION  - optional, default 2024-10-21

Docs:
    https://learn.microsoft.com/en-us/azure/ai-services/openai/overview
    https://learn.microsoft.com/en-us/azure/ai-services/openai/chatgpt-quickstart
"""
import os
import sys
import json
from openai import AzureOpenAI


def main(question: str) -> None:
    endpoint = os.environ.get("AZURE_OAI_ENDPOINT")
    key = os.environ.get("AZURE_OAI_KEY")
    deployment = os.environ.get("AZURE_OAI_DEPLOYMENT", "chat")
    api_version = os.environ.get("AZURE_OAI_API_VERSION", "2024-10-21")
    if not endpoint or not key:
        sys.exit("Set AZURE_OAI_ENDPOINT and AZURE_OAI_KEY env vars.")

    client = AzureOpenAI(
        azure_endpoint=endpoint,
        api_key=key,
        api_version=api_version,
    )

    response = client.chat.completions.create(
        model=deployment,  # deployment name, NOT model name
        messages=[
            {
                "role": "system",
                "content": (
                    "You are a concise instructor for Microsoft AI-900. "
                    "Answer in 3 sentences max. Cite Microsoft Learn URLs when relevant."
                ),
            },
            {"role": "user", "content": question},
        ],
        temperature=0.3,
        max_tokens=400,
    )

    choice = response.choices[0]
    print(json.dumps({
        "answer": choice.message.content,
        "finish_reason": choice.finish_reason,
        "usage": {
            "prompt_tokens": response.usage.prompt_tokens,
            "completion_tokens": response.usage.completion_tokens,
            "total_tokens": response.usage.total_tokens,
        },
        "content_filter_results": getattr(choice, "content_filter_results", None),
    }, indent=2, default=str))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit('Usage: python chat.py "your question here"')
    main(sys.argv[1])
