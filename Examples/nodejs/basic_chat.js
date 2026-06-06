// ContextScope — Node.js example
// Routes OpenAI SDK traffic through the local ContextScope proxy.

import OpenAI from 'openai';

// Point the SDK at the local proxy — no other code changes needed
const client = new OpenAI({
  baseURL: 'http://127.0.0.1:4319/v1',
  apiKey: 'your-upstream-api-key', // Your real key — forwarded to the provider
});

const response = await client.chat.completions.create({
  model: 'gpt-4o',
  messages: [
    { role: 'system', content: 'You are a helpful assistant.' },
    { role: 'user', content: 'What is the capital of France?' },
  ],
});

console.log(response.choices[0].message.content);
console.log(`\nTokens used: ${response.usage.total_tokens}`);
