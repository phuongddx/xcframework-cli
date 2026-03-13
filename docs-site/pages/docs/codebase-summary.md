# Codebase Summary

**Last Updated:** February 15, 2026
**Files:** 31 (lib/), 23 (spec/)
**LOC:** 4,645 (implementation) + 4,419 (tests)

---

## Quick Navigation

- **Gem Entry:** `lib/xcframework_cli.rb` - loads all modules
- **CLI Dispatcher:** `lib/xcframework_cli/cli/runner.rb` - Thor command routing
- **Build Pipeline:** `lib/xcframework_cli/builder/orchestrator.rb` - coordinates build flow
- **Platform Registry:** `lib/xcframework_cli/platform/registry.rb` - creates platform instances
- **Configuration:** `lib/xcframework_cli/config/loader.rb` - YAML/JSON loading and validation
- **Tests:** `spec/unit/` - 280+ test cases,  80%+ coverage

