# Code Style and Conventions

## Ruby/Rails Style
- Uses `rubocop-rails-omakase` for linting (Omakase Ruby styling for Rails)
- Configuration: `.rubocop.yml`

## Naming Conventions
- Models: PascalCase (e.g., `QuizStateManager`, `CurrentQuizState`)
- Files: snake_case (e.g., `quiz_state_manager.rb`, `current_quiz_state.rb`)
- GraphQL Types: PascalCase with `Type` suffix (e.g., `CurrentQuizStateType`, `QuestionType`)
- GraphQL Mutations: PascalCase with `Mutation` suffix (e.g., `StartQuestionMutation`, `SubmitAnswerMutation`)

## GraphQL Conventions
- Use `global_id_field :id` for GraphQL Type IDs
- Use `loads: Types::SomeType` for mutations that accept GraphQL IDs
- Mutation fields include:
  - Primary return object (e.g., `current_quiz_state`)
  - `errors` array for error messages

## Rails 8 Features
- Use Rails 8 modern features
- Solid Cache for caching
- Solid Queue for background jobs
- No Action Cable (use GraphQL polling instead)

## Japanese Comments
- Project uses Japanese for documentation and comments in CLAUDE.md and README.md
- Code comments should be in Japanese when appropriate for this project
