# EARS Format Reference

**Easy Approach to Requirements Syntax** - A structured way to write clear, testable acceptance criteria.

## Patterns

### 1. Event-Driven (Most Common)
For responses to specific triggers or actions.

```
WHEN [event/trigger occurs]
THEN the [system/feature] SHALL [expected response]
```

**Examples:**
- WHEN a user clicks "Submit" THEN the system SHALL validate all form fields
- WHEN payment is received THEN the system SHALL send confirmation email

### 2. State-Driven
For behavior that depends on system state.

```
WHILE [in specific state/condition]
THE [system/feature] SHALL [required behavior]
```

**Examples:**
- WHILE user is logged in THE system SHALL display their profile icon
- WHILE in maintenance mode THE system SHALL show read-only notice

### 3. Conditional
For behavior that depends on conditions.

```
IF [condition is true]
THEN the [system/feature] SHALL [action/response]
```

**Examples:**
- IF file size exceeds 100MB THEN the system SHALL reject the upload
- IF user has admin role THEN the system SHALL display admin panel

### 4. Optional/Where (Qualifiers)
For adding specificity to other patterns.

```
WHERE [qualifier]
THE [system/feature] SHALL [behavior]
```

**Examples:**
- WHERE network is unavailable THE system SHALL queue requests for retry
- WHERE user is on mobile THE system SHALL display responsive layout

### 5. Unwanted Behavior (Negative)
For explicitly stating what should NOT happen.

```
IF [condition]
THEN the [system/feature] SHALL NOT [unwanted action]
```

**Examples:**
- IF session expired THEN the system SHALL NOT allow data modification
- IF payment fails THEN the system SHALL NOT process the order

## Combining Patterns

Patterns can be combined for complex requirements:

```
WHEN user submits form
IF validation fails
THEN the system SHALL highlight invalid fields
AND SHALL NOT submit the form
```

## Keywords

| Keyword | Meaning |
|---------|---------|
| **SHALL** | Required behavior (must happen) |
| **SHALL NOT** | Prohibited behavior (must not happen) |
| **WHEN** | Event trigger |
| **IF** | Condition check |
| **WHILE** | State dependency |
| **AND** | Additional requirement |
| **OR** | Alternative requirement |

## Tips for Good EARS Criteria

1. **One behavior per criterion** - Don't combine multiple unrelated behaviors
2. **Testable** - Each criterion should be verifiable
3. **Specific** - Avoid vague terms like "quickly" or "user-friendly"
4. **Complete** - Cover happy path, errors, and edge cases
5. **Consistent** - Use same terminology throughout

## Categories to Cover

### Happy Path
Normal successful operation

### Error Handling
What happens when things go wrong

### Edge Cases
Boundary conditions and unusual scenarios

### Security
Authentication, authorization, data protection

### Performance
Response times, load handling (when relevant)
