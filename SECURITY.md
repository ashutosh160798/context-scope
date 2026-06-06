# Security Policy

## Supported Versions

| Version | Supported |
|---|---|
| 0.x pre-release | Best effort |

ContextScope is pre-release software. Security fixes are applied to the `main` branch and released in the next tagged version.

## Threat Model

ContextScope is a **local-first** developer tool. The primary attack surfaces are:

- The local HTTP proxy (`127.0.0.1:4319` by default) accepting requests
- API key handling — keys pass through the proxy but must never be logged, stored in SQLite, or emitted to the UI
- The `.contextscope.json` export format — must redact secrets before writing
- The local SQLite database — file permissions must prevent other users on the same machine from reading it

Out of scope: vulnerabilities in upstream LLM providers, attacks requiring physical machine access.

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Report privately via:

1. **GitHub Security Advisory:** [Open a private advisory](https://github.com/ashutosh160798/context-scope/security/advisories/new) (preferred)
2. **Email:** ashutoshaggarwal98@gmail.com — include "SECURITY" in the subject line

Please include:
- A description of the vulnerability and its potential impact
- Steps to reproduce or a proof-of-concept
- The version or commit hash you tested against

We aim to:
- Acknowledge receipt within **5 business days**
- Provide a fix or mitigation within **30 days** of confirmation

We will credit reporters in the release notes unless you prefer to remain anonymous.
