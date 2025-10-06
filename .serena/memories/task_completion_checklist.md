# Task Completion Checklist

When completing a task, always perform these steps:

## 1. Run Linting
```bash
bundle exec rubocop
```
If there are auto-fixable issues:
```bash
bundle exec rubocop -a
```

## 2. Run Tests
```bash
bin/rails test
```

For system tests (if UI changes):
```bash
bin/rails test:system
```

## 3. Verify Changes
- Check that code follows project conventions
- Ensure GraphQL schema is consistent
- Verify both backend and frontend are in sync (if applicable)

## 4. Git Workflow
- Create feature branch from `main`
- Commit with descriptive messages in Japanese or English
- Reference issue numbers (e.g., `Issue #9 対応`)

## 5. Issue Reference
According to CLAUDE.md, when working on issues:
1. Confirm issue content
2. Check related design principles in CLAUDE.md
3. Consider implementation impact
4. Ensure backend/frontend consistency
5. Implement with tests

## Performance Considerations
- Remember: 400 concurrent users target
- Use Solid Cache for high-speed writes
- Use Solid Queue for async processing
- Avoid blocking operations
