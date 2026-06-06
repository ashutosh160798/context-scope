"""
ContextScope — Python example
Routes OpenAI SDK traffic through the local ContextScope proxy.
"""

from openai import OpenAI

# Point the SDK at the local proxy — no other code changes needed
client = OpenAI(
    base_url="http://127.0.0.1:4319/v1",
    api_key="your-upstream-api-key",  # Your real key — forwarded to the provider
)

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "What is the capital of France?"},
    ],
)

print(response.choices[0].message.content)
print(f"\nTokens used: {response.usage.total_tokens}")
