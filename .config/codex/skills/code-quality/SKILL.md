---
name: code-quality
description: Write and review maintainable code using a strict Don't Repeat Yourself philosophy, least-common-denominator decomposition, reusable abstractions, single sources of truth, and proven existing implementations. Use for implementation, refactoring, architecture, code review, bug fixes, shared components, configuration, schemas, utilities, or dependency decisions where a change should be made once and propagate everywhere.
---

# Code Quality

Treat Don't Repeat Yourself as the governing principle. Make each rule, fact,
policy, and behavior authoritative in one place so future changes propagate to
every consumer.

## Work Reuse-First

Before writing code:

1. Read repository instructions and inspect the surrounding architecture.
2. Search the repository for equivalent behavior, shared primitives, constants,
   types, schemas, configuration, and established conventions.
3. Inspect the standard library, framework, and installed dependencies.
4. When needed, check current official documentation and mature external
   implementations before designing a custom solution.
5. Identify the single concept that owns the behavior and the places that consume
   it.

Prefer solutions in this order:

1. Reuse or extend the repository's existing implementation.
2. Use a standard-library or framework primitive.
3. Use a dependency already present in the project.
4. Adopt a focused, mature library or adapt a proven reference implementation.
5. Create the smallest coherent shared abstraction only when the earlier options
   do not fit.

Do not copy an implementation into another location merely because copying is
faster. Improve the authoritative implementation or extract the shared concept.

## Enforce One Source of Truth

- Store each piece of domain knowledge once: constants, tokens, routes, feature
  definitions, validation rules, defaults, schemas, status mappings, permissions,
  and business rules.
- Derive secondary forms from the authoritative source. Generate or transform
  types, validators, documentation, options, and lookup tables instead of keeping
  synchronized copies.
- Put variation in data, parameters, configuration, or interchangeable strategies
  instead of creating nearly identical branches or components.
- Hoist repeated attributes, feature gates, decorators, configuration, and setup
  to the narrowest common enclosing scope when the language or framework preserves
  the intended semantics. State the shared rule once without applying it to
  unrelated members.
- Route consumers through one shared API, component, helper, or policy boundary.
- Extend an existing abstraction when the concept belongs there; do not create a
  parallel utility with overlapping responsibility.
- Remove superseded duplicate paths when it is safe and within scope.
- Keep names and ownership explicit so future agents can find the source of truth.

Apply DRY to knowledge, not merely matching syntax. Similar-looking code may
represent different concepts and should remain separate when it changes for
different reasons. Conversely, repeated policy is duplication even when expressed
with different syntax.

For example, group platform-specific Rust methods under one conditional `impl`
instead of repeating the condition on every method:

```rust
// Bad: the same policy is repeated on each item.
impl Example {
    #[cfg(target_os = "linux")]
    fn linux_one() {}

    #[cfg(target_os = "linux")]
    fn linux_two() {}
}

// Good: the common owner states the policy once.
#[cfg(target_os = "linux")]
impl Example {
    fn linux_one() {}
    fn linux_two() {}
}
```

## Decompose to the Least Common Denominator

For all new and changed code, isolate the smallest coherent unit that contains the
behavior shared by every relevant consumer. Implement that common denominator
once, then compose specialized behavior around it.

- Separate invariant behavior from caller-specific policy, data, and side effects.
- Place the shared primitive at the lowest sensible layer that can own it without
  depending on specialized callers.
- Keep variation at the edges through arguments, data, configuration, adapters,
  callbacks, or small composed operations.
- Make higher-level functions delegate to the common primitive instead of
  repeating its mechanics.
- Give each extracted unit one meaningful responsibility and an independently
  testable contract.
- Reuse an existing lower-level primitive when one already expresses the common
  denominator.

Interpret "smallest" semantically, not by line count. Do not create meaningless
one-line wrappers, split a cohesive operation into fragments, or force unrelated
concepts through an over-general API. The correct denominator contains all and
only the behavior that must change together.

## Choose Abstractions Carefully

- Extract a shared abstraction when consumers represent the same concept or must
  change together.
- Keep independent concepts separate even if their current implementations happen
  to look alike.
- Prefer a small, composable interface over a general-purpose framework.
- Avoid wrappers that only rename a stable library API. Wrap dependencies when the
  boundary centralizes project policy, isolates volatility, or meaningfully
  simplifies consumers.
- Avoid boolean-heavy APIs and copy-pasted variants. Model meaningful variation
  directly.
- Do not speculate about distant reuse. Solve the known family of cases cleanly
  and leave an obvious extension point.

## Reuse Proven Implementations

Do not reinvent solved infrastructure such as parsing, serialization,
cryptography, authentication, date and time handling, retry logic, validation,
internationalization, accessibility primitives, or protocol clients.

Before adding a dependency, verify that it fits the project's runtime, license,
maintenance, security, size, and conventions. Prefer an already-installed
dependency when it is suitable. When adopting a library, use its intended API
rather than recreating part of it locally. Record the dependency in the normal
manifest and lockfile.

If a reference implementation cannot be used directly, preserve its established
semantics and cite its source in code only when that provenance will help future
maintenance.

## Implement for Change Once

- Make the narrowest change at the authoritative layer that fixes all affected
  consumers.
- Preserve public APIs and repository conventions unless changing them removes
  duplication and migration is in scope.
- Centralize magic values and cross-cutting policy; keep truly local details local.
- Keep functions and modules focused, but do not fragment a cohesive concept
  across files.
- Add tests at the shared boundary. Cover representative consumers and prove that
  configuration or policy changes propagate.
- Search again after implementation for stale copies, divergent spellings,
  parallel code paths, and duplicated fixtures.

## Review With the Change-Once Test

Before finishing, ask:

1. If this requirement changes, how many authoritative places must be edited?
2. Does any consumer encode knowledge that belongs to a shared owner?
3. Did this add a second way to do something the repository already supports?
4. Could a standard primitive, existing dependency, or proven library replace
   custom code?
5. Are derived values generated from the source, or manually synchronized?
6. Does the abstraction join code that changes together without coupling concepts
   that change independently?
7. Is shared behavior factored into the smallest coherent common denominator,
   with specialized variation composed at the edges?
8. Do tests protect the shared contract instead of repeating implementation
   details?

Refactor until the answer to the first question is one wherever the requirement is
conceptually shared. In the final response, identify the source of truth and note
the existing primitives or libraries reused.
