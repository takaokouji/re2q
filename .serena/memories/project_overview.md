# re2q Project Overview

## Purpose
re2q (Realtime Two-Choice Quiz) is a realtime two-choice quiz application supporting up to 400 concurrent users.

## Tech Stack

### Backend
- Ruby 3.4.6
- Rails 8.0.3
- SQLite (development & production DB)
- Solid Cache (high-speed answer caching)
- Solid Queue (async job processing)
- GraphQL (`graphql-ruby`)

### Frontend
- React
- TypeScript
- Apollo Client
- Located in: `frontend/` directory

## Key Architecture

### High-Speed Answer Processing
```
User Answer → Solid Cache (ultra-fast write)
                  ↓
          Solid Queue Job (1s interval)
                  ↓
          SQLite DB (batch persistence)
```

### Session Management
- QR code access generates unique `player_uuid`
- Stored in HTTP Cookie (Secure, HttpOnly)
- Persistent device identification

### Realtime Updates
- GraphQL Polling (no WebSocket/Action Cable)
- Users poll GraphQL queries for state updates

## Project Structure
- `app/graphql/` - GraphQL schema, types, mutations, resolvers
- `app/models/` - Core models (Player, Question, Answer, CurrentQuizState, QuizStateManager, RankingCalculator)
- `app/jobs/` - Async jobs for answer persistence and ranking calculation
- `frontend/` - React/TypeScript frontend
- `config/` - Rails configuration
- `db/` - Database migrations and schema

## Important Models
- **Player**: uuid, answer history
- **Question**: correct answer, duration_seconds, position
- **Answer**: player_id, question_id, answer content
- **CurrentQuizState**: singleton model for current quiz state
- **QuizStateManager**: PORO for state management logic
- **RankingCalculator**: PORO for ranking calculation
