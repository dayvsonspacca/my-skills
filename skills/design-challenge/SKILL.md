---
name: design-challenge
description: Generates a technical challenge for the user to build, a concrete product with numbered functional and non-functional requirements, measurable targets (latency, throughput, retention, availability) and acceptance scenarios, leaving every implementation choice (language, database, architecture, protocols) to the user. Use when the user asks for a design challenge, system design challenge, coding or technical challenge, a project to build for practice, or a "desafio técnico" / "desafio de design" / "desafio de system design", either with a random theme or with a theme they give, even a vague one ("something with payments", "algo com mapas").
metadata:
  version: "1.0.0"
---

# Design challenge

Write a challenge for the user to build: a concrete product with requirements precise enough to be checked. The user decides everything about how to build it: language, storage, architecture, protocols, libraries, tooling. The challenge only says what the system must do and how well.

Write it in the language the user is writing in.

## 1. Pick the theme

- **Specific theme** ("url shortener"): use it.
- **Vague theme** ("something with payments", "algo com mapas"): pick one concrete product inside it yourself and go on. Don't ask the user to narrow it down.
- **Random theme**: run `shuf -n 1 <skill-dir>/assets/themes.txt` and build a product from the domain it returns. Don't pick from memory: from memory you land on the same few classics every time.

Size it by the difficulty the user asked for. If they didn't say, use medium.

| Difficulty | Functional req. | Non-functional req. | Scale |
| ---------- | --------------- | ------------------- | ----- |
| easy       | 4–5             | 4–5                 | Hundreds of requests per second, data in the gigabytes |
| medium     | 6–8             | 6–8                 | Thousands of requests per second, data in the hundreds of gigabytes |
| hard       | 8–10            | 8–10                | Tens of thousands of requests per second at peak, terabytes of data, failure scenarios |

## 2. The black-box rule

Every requirement must be checkable from outside the system by someone who doesn't know what it's built with, using only a client, a clock, a load generator and the power switch. That is what leaves the "how" to the user.

So a requirement names a behavior or a measurable property, never a means. A means is anything the user would choose while building: a language, framework, database or kind of store, cache, queue, broker, protocol or format (HTTP, REST, gRPC, JSON), route, status code, algorithm, data structure, encoding, design pattern, architecture style, deployment or container setup, testing or observability tool, code layout.

When a draft line names a means, replace it with the property that means was supposed to deliver:

| Draft names a means | Rewritten as the property |
| ------------------- | ------------------------- |
| Use a cache on the redirect path | Redirect p99 ≤ 20 ms at 5,000 redirects/s sustained for 10 minutes |
| Record clicks through a queue so the redirect doesn't block | Recording a click adds at most 2 ms to the redirect p99. Redirects keep working even when clicks can't be recorded |
| Store money as integer cents, never floats | Amounts are exact to the cent. After any sequence of operations, the totals reconcile to the cent |
| Use the transactional outbox pattern | A state change and its notification both happen or neither does, even if the process is killed mid-operation |
| Use `SELECT ... FOR UPDATE` or optimistic locking | 50 simultaneous refunds on the same payment never add up to more than the captured amount |
| 7-character base62 code | Short codes are at most 8 characters, and after creating 1,000 links a client can't guess the next one |
| `POST /links` returns `201` with the code | A client can create a short link and gets its code back |
| Stateless app that runs as several instances | Killing any single process makes no request fail for more than 10 seconds |
| Runs with `docker compose up`, load test with k6 | (drop it: how the user runs and measures it is their call) |

## 3. Write the challenge

The challenge has these sections, in this order:

1. **Title**: the product's name and a one-line description.
2. **Context**: one paragraph. Who uses it, what for, and what makes it hard.
3. **Scale**: the numbers everything else is measured against. Users, request rates (average and peak), read/write mix, data volume and growth, how long data is kept.
4. **Functional requirements** (FR1, FR2…): each states what an actor can do, or what the system does when something happens, in domain terms. Give the concrete limits (lengths, ranges, quotas, time windows) and the edge cases that matter: invalid, expired, duplicated, concurrent, not found.
5. **Non-functional requirements** (NFR1, NFR2…): each has a number, a unit and the condition it's measured under. "p99 ≤ 50 ms at 2,000 req/s sustained for 10 minutes." "A link resolves for 5 years after it was created." "At most 1 in 10,000 clicks is lost." Cover what the theme calls for among: latency, throughput, availability, durability and retention, consistency (how stale a read can be, how soon a write is visible), behavior under failure (what keeps working when a part is down), security and abuse, privacy and data deletion. The numbers agree with the Scale section.
6. **Out of scope**: what they don't have to build.
7. **Acceptance scenarios**: 4 to 6 concrete tests, each with a setup, an action and the observable outcome, aimed at the hardest requirements.

The reply ends with the acceptance scenarios.

## 4. Check before sending

Go through the draft line by line:

- Could someone verify this line without knowing what the system is built with? If it names a means, rewrite it with the table above.
- Does every NFR have a number, a unit and a measurement condition? "Fast", "highly available" and "acceptable degradation" are not requirements yet.
- Do the NFR numbers agree with the Scale section?
- Does each acceptance scenario expect only what the requirements state? If a requirement leaves a formula or rule open, the scenario checks the bounds it set, not one specific result.
- Count the FRs, the NFRs and the acceptance scenarios. If any count is above the range for the difficulty, merge or cut requirements until it fits. The limit is what keeps the challenge buildable.

## After the challenge

When the user asks about a requirement, clarify it in the same black-box terms: what the system must do and how it will be checked. Implementation advice is for when the user explicitly asks for it.

If the user asks to save the challenge, write it to a markdown file at the path they give, or `CHALLENGE.md` in the current directory.
