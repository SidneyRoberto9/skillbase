---
name: spring-clean
description: Audits and auto-fixes modified Java / Spring Boot files against the m4all backend standards — constructor injection over @Autowired, explicit ResponseEntity.status(...).body(...), blocked ifs, no inline if/ternary, DTOs over Map.of. Use before committing API changes or when the user asks to standardize Spring/Java code.
---

# Spring Clean Skill

## Objective

Scan the modified Java / Spring Boot files and **automatically correct** every
deviation from the backend conventions. Fix in place, do not ask.

Target stack: Spring Boot 3.x, Java 17 (some legacy projects on Java 8/11 —
detect the version before refactoring).

---

## Step 1 — Determine the scope

```bash
git diff --name-only --diff-filter=ACM | grep '\.java$'
git diff --cached --name-only --diff-filter=ACM | grep '\.java$'
```

If the user names a controller / service / file, restrict to that path.

Detect the Java version from `pom.xml` (`<java.version>` / `maven.compiler`).
Do NOT introduce syntax above the project's Java level (e.g. no records,
switch-expressions, or `var` on a Java 8 project).

---

## Step 2 — Mandatory corrections

### Dependency injection

- Replace field `@Autowired` with constructor injection via Lombok
  `@RequiredArgsConstructor` on the class and `private final` fields.
- Remove the now-redundant `@Autowired` import.

### Controller responses

- Endpoints MUST return `ResponseEntity.status(HttpStatus.XXX).body(...)`.
- Replace shortcuts like `ResponseEntity.ok(x)` / `.notFound().build()` with the
  explicit `.status(...).body(...)` form, choosing the correct `HttpStatus`.
- Keep the response shape consistent across all endpoints in the controller
  (same wrapper/DTO style as its siblings).

### Control flow

- Every `if` MUST use a block with `{}`. NEVER inline `if`.
- NEVER ternary operators for control flow — refactor to explicit blocks or early returns.

### Data contracts

- NEVER `Map.of(...)` as a request body or response payload. Use a dedicated DTO.
  Create the DTO if it does not exist.
- On Java 17+ the m4all norm is **records** for DTOs
  (`public record PositionDTO(String id, String fullName) {}`) — default to
  records, matching the surrounding `dto` package. Use plain classes only for
  entities, or for DTOs on legacy Java 8/11 projects that have no records.

### Validation

- Annotate request-body DTO fields with Jakarta validation
  (`@NotNull`, `@NotBlank`, `@Email`, `@Size`, ...) and put `@Valid` on the
  controller parameter. Do not hand-roll null/blank checks the annotations cover.

### Error handling

- Do NOT build ad-hoc error payloads inside controllers. Throw a domain exception
  and let the project's global `@RestControllerAdvice` (under `infra/errors`)
  translate it to the standard error response. Reuse an existing handler/exception
  before adding a new one.

### Search / filter endpoints

- When an endpoint filters entities, expose every searchable field as an optional
  query parameter and build the query via a `Specification`.
- In specifications, every `if` uses `{}`.

---

## Step 3 — Apply & propagate

1. Read each file in scope, locate violations, rewrite the affected blocks fully.
2. When changing injection or a method signature, update every caller/usage so
   the module still compiles.
3. When introducing a DTO, place it in the domain's `dto` package following the
   real layout `br.com.media4all.<app>_api.<module>.<layer>` — e.g.
   `br.com.media4all.eleva_docs_api.position.dto`. Layers per module are
   `controllers` / `controller`, `services`, `entities`, `dto`, `repositories`.

---

## Step 4 — Verify

```bash
./mvnw -q compile           # or ./mvnw clean compile
```

Resolve any compilation error caused by the refactor, then report a concise list:
`<file>: <rule violated> → fixed`.

---

## Hard rules for the assistant

- Do NOT suggest alternatives or ask for permission.
- Do NOT exceed the project's Java language level.
- Auto-correct every infraction in the touched code before reporting done.
