# Suggested Commands for re2q Development

## Setup Commands
```bash
bundle install              # Install Ruby dependencies
bin/rails db:create        # Create database
bin/rails db:migrate       # Run migrations
```

## Development Commands
```bash
bin/dev                    # Start development server
bin/jobs                   # Start Solid Queue worker (separate terminal)
bin/rails console          # Rails console
```

## Testing Commands
```bash
bin/rails test             # Run tests
bin/rails test:system      # Run system tests
```

## Linting & Formatting
```bash
bundle exec rubocop        # Run RuboCop linter
bundle exec rubocop -a     # Auto-fix RuboCop issues
```

## Database Commands
```bash
bin/rails db:reset         # Reset database
bin/rails db:seed          # Seed database
```

## Deployment
```bash
kamal setup                # Setup deployment
kamal deploy               # Deploy application
```

## GraphQL
- GraphiQL interface available in development mode
- Access via Rails server route (check routes)
