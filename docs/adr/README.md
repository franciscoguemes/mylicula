# Architectural Decision Records (ADR)

This directory contains the Architectural Decision Records (ADRs) for the MyLiCuLa project.

## What is an ADR?

An Architectural Decision Record (ADR) is a document that captures an important architectural decision made along with its context and consequences.

ADRs help:
- **Document the "why"** behind important decisions
- **Provide context** for future maintainers
- **Track evolution** of the project's architecture
- **Avoid repeating** past mistakes
- **Facilitate onboarding** of new contributors

## When to Write an ADR

Create an ADR when making decisions about:
- Architecture patterns and conventions
- Technology choices (languages, frameworks, tools)
- Project structure and organization
- Key workflows and processes
- Standards and guidelines
- Breaking changes to established patterns

## ADR Format

ADRs follow a lightweight format (see [template.md](template.md)):

1. **Title** - Short, descriptive title (numbered sequentially)
2. **Status** - Current state: Proposed, Accepted, Deprecated, Superseded
3. **Context** - The problem and constraints
4. **Decision** - What was decided
5. **Consequences** - Positive, negative, and neutral outcomes
6. **Alternatives** - Other options considered and why they were rejected

## Naming Convention

ADRs are numbered sequentially and use the format:

```
XXXX-title-with-dashes.md
```

Examples:
- `0001-use-installer-interface-pattern.md`
- `0002-centralize-logs-in-var-log.md`
- `0003-configuration-driven-scripts.md`

## Process for Creating ADRs

### 1. Copy the Template

```bash
cp docs/adr/template.md docs/adr/XXXX-your-decision-title.md
```

### 2. Fill in the Template

- Use the next available number (check existing ADRs)
- Write clear, concise descriptions
- Include context and rationale
- Document alternatives considered
- Describe consequences honestly (pros and cons)

### 3. Set Initial Status

New ADRs typically start as **Proposed** until reviewed and approved.

### 4. Commit and Review

```bash
git add docs/adr/XXXX-your-decision-title.md
git commit -m "docs: add ADR-XXXX about [topic]"
```

### 5. Update Status

Once accepted, change status to **Accepted** and update the date.

## ADR Lifecycle

```
Proposed → Accepted → [Deprecated | Superseded]
```

- **Proposed**: Initial state, under discussion
- **Accepted**: Decision is approved and implemented
- **Deprecated**: No longer recommended, but not replaced
- **Superseded**: Replaced by a newer ADR (link to the new one)

## Current ADRs

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](0001-use-installer-interface-pattern.md) | Use Installer Interface Pattern | Accepted | 2025-01-23 |
| [0002](0002-centralize-logs-in-var-log-mylicula.md) | Centralize Logs in /var/log/mylicula | Accepted | 2025-01-23 |
| [0003](0003-configuration-driven-scripts.md) | Configuration-Driven Scripts | Accepted | 2025-01-23 |
| [0004](0004-package-installation-structure.md) | Package Installation Structure with Metadata Comments | Accepted | 2025-01-23 |
| [0005](0005-integrate-bash-scripts-into-repository.md) | Integrate Bash Scripts into Repository | Accepted | 2025-01-23 |

## Further Reading

- [Architectural Decision Records (Michael Nygard)](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- [ADR GitHub Organization](https://adr.github.io/)
- [Markdown ADR (MADR)](https://adr.github.io/madr/)

## Questions?

For questions about ADRs or to discuss a potential architectural decision, please open an issue or discussion on the repository.
