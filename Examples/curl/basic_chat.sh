#!/usr/bin/env bash
# ContextScope — curl example
# Routes a raw HTTP request through the local ContextScope proxy.

curl http://127.0.0.1:4319/v1/chat/completions \
  -s \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-upstream-api-key" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "What is the capital of France?"}
    ]
  }' | python3 -m json.tool
