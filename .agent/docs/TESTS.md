# 🧪 Tests Documentation

> **FILE:** `docs/TESTS.md`
> **PURPOSE:** Test strategy, coverage status, and test suite documentation
> **DEPENDS ON:** Source files, test files
> **DEPENDED ON BY:** CI pipeline, release checklist
> **LAST MODIFIED:** See git log
> **UPDATE TRIGGER:** Any test added, modified, or removed

---

## 📊 Coverage Overview

| Module | Unit Tests | Integration | E2E | Coverage % | Status |
|---|---|---|---|---|---|
| `.agent/` framework | N/A (docs) | N/A | Manual | — | 🟡 Manual only |
| `scripts/` | 🟡 Partial | ⚪ None | ⚪ None | ~40% | 🟡 Needs work |
| `src/` (your code) | ⚪ None yet | ⚪ None yet | ⚪ None yet | 0% | ⚪ Not started |

---

## 🗂️ Test Strategy

### Unit Tests
- **Scope:** Individual functions / modules in isolation
- **Tool:** Language-native (pytest, jest, go test, etc.)
- **Location:** `tests/unit/` or co-located with source (`*.test.*`)
- **Prompt:** Use `unit-isolate` or `test-skeleton` from `prompts.config.md`

### Integration Tests
- **Scope:** Multiple modules working together
- **Tool:** Language-native + test containers / mocks
- **Location:** `tests/integration/`
- **Prompt:** Use `mock-strategy`, `test-skeleton`

### End-to-End Tests
- **Scope:** Full user flows / API flows
- **Tool:** Playwright, Cypress, Postman, etc.
- **Location:** `tests/e2e/`

### Stress / Performance Tests
- **Scope:** Load, concurrency, memory under pressure
- **Tool:** k6, Locust, custom scripts
- **Location:** `tests/stress/`
- **Prompt:** Use `stress-scenario`, `perf-profiler`

### Fuzz Tests
- **Scope:** Unexpected / adversarial inputs
- **Tool:** Language-native fuzzers (AFL, go-fuzz, Atheris)
- **Location:** `tests/fuzz/`
- **Prompt:** Use `input-fuzzing`

---

## 🧪 Script Test Coverage

### `scripts/health-check.sh`
| Test | Type | Status |
|---|---|---|
| All required files exist | Unit | ⚪ TODO |
| `.locked` valid JSON | Unit | ⚪ TODO |
| No stale SOFT locks | Unit | ⚪ TODO |
| Dump inbox check | Unit | ⚪ TODO |

### `scripts/lock-manager.sh`
| Test | Type | Status |
|---|---|---|
| Lock acquisition | Unit | ⚪ TODO |
| Lock release | Unit | ⚪ TODO |
| Stale lock detection | Unit | ⚪ TODO |
| Concurrent lock conflict | Integration | ⚪ TODO |

---

## ✅ Test Run Protocol

Before any PR to `release`:

```bash
# 1. Run all unit tests
<language test command>

# 2. Run integration tests
<integration test command>

# 3. Check coverage
<coverage tool command>

# 4. Run framework health check
bash scripts/health-check.sh

# 5. Document results in this file (table above)
```

---

## 📝 Test Change Log

| Date | Change | Affected Tests | Author |
|---|---|---|---|
| 2026-02-23 | Initial TESTS.md created | — | system-init |

---

## 🔗 References

- Test skeleton prompt: `.agent/config/prompts.config.md` → `test-skeleton`
- Coverage gap prompt: `prompts.config.md` → `test-coverage-gap`
- Mock strategy prompt: `prompts.config.md` → `mock-strategy`

*Always update coverage table after adding/removing tests. Cascade check: CHANGELOG.md*
