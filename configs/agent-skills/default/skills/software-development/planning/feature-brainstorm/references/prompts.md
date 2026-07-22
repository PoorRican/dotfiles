# Prompt Templates

Detailed prompts for each sub-task type. Copy and customize for your feature.

## Phase 1: Exploration Prompts

### Architecture Explorer
```
You are exploring a codebase to understand how to implement: {{FEATURE}}

Your focus: Architecture and module structure

Codebase: {{PATH}}

Tasks:
1. Map the high-level directory structure
2. Identify core modules and their responsibilities
3. Document the data flow between components
4. Note dependency injection patterns and service boundaries
5. Find configuration and initialization patterns

Output to: /home/claude/brainstorm-sessions/explore-architecture.md

Format:
## Directory Structure Overview
## Core Modules
## Data Flow Patterns
## Key Integration Points
## Relevant Files for This Feature
```

### Similar Features Explorer
```
You are exploring a codebase to understand how to implement: {{FEATURE}}

Your focus: Finding similar existing features as implementation references

Codebase: {{PATH}}

Tasks:
1. Search for features with similar patterns (CRUD, auth, async processing, etc.)
2. Document how those features are structured
3. Note reusable patterns and abstractions
4. Identify helper utilities that could be leveraged

Output to: /home/claude/brainstorm-sessions/explore-similar.md

Format:
## Similar Features Found
## Patterns Worth Reusing
## Existing Abstractions
## Helper Utilities Available
```

### Data Layer Explorer
```
You are exploring a codebase to understand how to implement: {{FEATURE}}

Your focus: Data models, schemas, and persistence

Codebase: {{PATH}}

Tasks:
1. Identify relevant existing models/schemas
2. Document database patterns (ORM, raw SQL, migrations)
3. Note validation and serialization approaches
4. Find state management patterns

Output to: /home/claude/brainstorm-sessions/explore-data.md

Format:
## Relevant Models/Schemas
## Database Patterns
## Validation Approach
## State Management
## Schema Changes Needed
```

### API Surface Explorer
```
You are exploring a codebase to understand how to implement: {{FEATURE}}

Your focus: API endpoints and interfaces

Codebase: {{PATH}}

Tasks:
1. Map existing API structure and conventions
2. Document authentication/authorization patterns
3. Note request/response formats
4. Identify middleware and interceptors
5. Find API versioning approach

Output to: /home/claude/brainstorm-sessions/explore-api.md

Format:
## API Structure
## Auth Patterns
## Request/Response Conventions
## Middleware Used
## New Endpoints Needed
```

### Testing Explorer
```
You are exploring a codebase to understand how to implement: {{FEATURE}}

Your focus: Testing patterns and infrastructure

Codebase: {{PATH}}

Tasks:
1. Identify test frameworks and runners
2. Document mocking/stubbing patterns
3. Note fixture and factory patterns
4. Find integration test setup
5. Check coverage requirements

Output to: /home/claude/brainstorm-sessions/explore-testing.md

Format:
## Test Framework
## Mocking Patterns
## Fixtures/Factories
## Integration Test Setup
## Testing Strategy for This Feature
```

## Phase 2: Validation Prompts

### Pattern Alignment Validator
```
You are validating an implementation approach for: {{FEATURE}}

Context from exploration:
{{EXPLORATION_SUMMARY}}

Your focus: Does the proposed approach align with codebase patterns?

Tasks:
1. Compare proposed approach against existing patterns
2. Identify deviations and justify or flag them
3. Check consistency with coding standards
4. Verify naming conventions match

Output to: /home/claude/brainstorm-sessions/validate-patterns.md

Format:
## Pattern Alignment Assessment
## Deviations (with justification or concerns)
## Consistency Issues
## Recommendations
```

### Technical Research Validator
```
You are validating an implementation approach for: {{FEATURE}}

Context from exploration:
{{EXPLORATION_SUMMARY}}

Your focus: Research best practices and technical options

Tasks:
1. Search for industry best practices for this type of feature
2. Evaluate library/framework options if applicable
3. Check for security considerations
4. Research common pitfalls

Output to: /home/claude/brainstorm-sessions/validate-research.md

Format:
## Best Practices
## Library/Framework Options
## Security Considerations
## Common Pitfalls to Avoid
## Recommendations
```

### Edge Case Validator
```
You are validating an implementation approach for: {{FEATURE}}

Context from exploration:
{{EXPLORATION_SUMMARY}}

Your focus: Edge cases, error handling, and failure modes

Tasks:
1. List potential edge cases
2. Document failure modes and recovery strategies
3. Check boundary conditions
4. Identify race conditions or concurrency issues
5. Note data validation requirements

Output to: /home/claude/brainstorm-sessions/validate-edges.md

Format:
## Edge Cases
## Failure Modes and Recovery
## Boundary Conditions
## Concurrency Concerns
## Validation Requirements
```

### Performance Validator
```
You are validating an implementation approach for: {{FEATURE}}

Context from exploration:
{{EXPLORATION_SUMMARY}}

Your focus: Performance and scalability

Tasks:
1. Identify potential bottlenecks
2. Estimate data volumes and growth
3. Check for N+1 queries or inefficient patterns
4. Consider caching opportunities
5. Note monitoring/observability needs

Output to: /home/claude/brainstorm-sessions/validate-performance.md

Format:
## Potential Bottlenecks
## Scale Considerations
## Optimization Opportunities
## Caching Strategy
## Monitoring Needs
```

## Phase 3: Assessment Prompts

### MVP Assessor
```
You are creating an implementation proposal for: {{FEATURE}}

Context:
- Exploration: {{EXPLORATION_SUMMARY}}
- Validation: {{VALIDATION_SUMMARY}}

Your focus: Minimum viable implementation - fastest path to working feature

Tasks:
1. Define the smallest useful scope
2. List implementation steps in order
3. Estimate effort
4. Identify shortcuts (with tradeoff notes)
5. List what's deferred to later

Output to: /home/claude/brainstorm-sessions/assess-mvp.md

Format:
## MVP Scope Definition
## Implementation Steps
1. Step (effort estimate)
2. ...

## Total Effort Estimate
## Shortcuts Taken (and tradeoffs)
## Deferred for Later
## Risks
```

### Robust Assessor
```
You are creating an implementation proposal for: {{FEATURE}}

Context:
- Exploration: {{EXPLORATION_SUMMARY}}
- Validation: {{VALIDATION_SUMMARY}}

Your focus: Production-ready implementation with proper error handling

Tasks:
1. Define complete feature scope
2. List implementation steps with testing
3. Include error handling and edge cases
4. Add observability and monitoring
5. Document maintenance considerations

Output to: /home/claude/brainstorm-sessions/assess-robust.md

Format:
## Full Scope Definition
## Implementation Steps (with tests)
1. Step (effort estimate)
2. ...

## Total Effort Estimate
## Error Handling Strategy
## Monitoring/Observability
## Maintenance Considerations
## Risks and Mitigations
```

### Alternative Assessor
```
You are creating an implementation proposal for: {{FEATURE}}

Context:
- Exploration: {{EXPLORATION_SUMMARY}}
- Validation: {{VALIDATION_SUMMARY}}

Your focus: Alternative approach using different architecture/pattern

Tasks:
1. Propose a fundamentally different approach
2. Compare tradeoffs against primary approach
3. Identify when this approach is preferred
4. List implementation steps
5. Note migration considerations if switching later

Output to: /home/claude/brainstorm-sessions/assess-alternative.md

Format:
## Alternative Approach Description
## Tradeoffs vs Primary Approach
| Aspect | Primary | Alternative |
|--------|---------|-------------|
| ... | ... | ... |

## When to Prefer This Approach
## Implementation Steps
## Migration Considerations
```
