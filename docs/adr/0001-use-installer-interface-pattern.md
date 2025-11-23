# 0001. Use Installer Interface Pattern

**Date:** 2025-01-23

**Status:** Accepted

**Deciders:** Francisco Güemes

## Context

MyLiCuLa includes multiple installation scripts in the `setup/` directory that handle different aspects of system configuration (packages, bash scripts, keyboard shortcuts, etc.). Without a standardized approach, each script had:

- Different function names and signatures
- Inconsistent error handling
- Varying validation approaches
- No enforcement of common patterns
- Difficult to maintain and extend

The project needed a way to ensure all installation scripts follow the same interface and execution flow while maintaining flexibility for script-specific logic.

## Decision

Implement a **standardized installer interface** that all scripts in `setup/` must follow. This interface is defined in `lib/installer_common.sh` and enforced at runtime.

### Required Functions

All installer scripts must implement three functions:

1. **`get_installer_name()`** - Return human-readable installer name
2. **`validate_environment()`** - Check prerequisites and readiness
   - Return 0: Ready to install
   - Return 1: Validation failed
   - Return 2: Already installed (idempotent check)
3. **`run_installation()`** - Perform actual installation
   - Return 0: Success
   - Return 1: Failure

### Optional Functions

4. **`cleanup_on_failure()`** - Clean up after installation failure (default: no-op)

### Standard Execution Flow

Scripts call `execute_installer()` from `lib/installer_common.sh`, which:

1. Validates that required functions exist
2. Calls `validate_environment()`
3. Handles return code 2 (already installed) gracefully
4. Calls `run_installation()` if validation passes
5. Calls `cleanup_on_failure()` if installation fails

### Template

A complete template is provided in `setup/template_installer.sh`.

## Consequences

### Positive

- **Consistency**: All installers follow the same pattern
- **Enforcement**: Interface is validated at runtime
- **Idempotency**: Built-in support for "already installed" state
- **Error Handling**: Standardized cleanup mechanism
- **Maintainability**: Easy to understand and modify scripts
- **Documentation**: Clear contract for what installers must do
- **Onboarding**: New contributors can copy the template

### Negative

- **Boilerplate**: Some additional code required for each script
- **Learning Curve**: Contributors must understand the interface pattern
- **Refactoring**: Existing scripts required significant refactoring

### Neutral

- **Template Method Pattern**: Uses a well-known design pattern
- **Bash Limitations**: Pattern works within bash constraints

## Alternatives Considered

### Alternative 1: No Standard Interface

**Description:** Let each script implement its own approach

**Rejected because:**
- Led to inconsistent behavior across scripts
- Made maintenance difficult
- No way to ensure quality standards
- Difficult for new contributors to understand patterns

### Alternative 2: External Configuration Files

**Description:** Define installer behavior in YAML/JSON configuration files

**Rejected because:**
- Over-engineered for the project's needs
- Added external dependencies (jq, yq parsers)
- Made debugging more difficult
- Reduced flexibility for script-specific logic

### Alternative 3: Object-Oriented Approach (Python/Ruby)

**Description:** Rewrite installation system in Python/Ruby with classes

**Rejected because:**
- Project is committed to bash for system integration
- Adds runtime dependencies
- Doesn't leverage existing bash script ecosystem
- Over-complicated for the use case

## References

- [Template Method Pattern (Wikipedia)](https://en.wikipedia.org/wiki/Template_method_pattern)
- `lib/installer_common.sh` - Interface implementation
- `setup/README.md` - Full interface documentation
- `setup/template_installer.sh` - Complete template

## Notes

### Implementation Phases

The interface was implemented in phases:

- **Phase 1**: Initial design and `installer_common.sh` implementation
- **Phase 2**: Template creation and documentation
- **Phase 3**: Refactoring existing scripts (13 scripts total)
- **Phase 4**: Validation logic added to `install.sh`
- **Phase 5**: Runtime enforcement implemented

### Return Code Convention

The return code 2 for "already installed" is crucial for idempotency. Scripts can run multiple times without side effects:

```bash
validate_environment() {
    if [[ already_installed ]]; then
        return 2  # Skip installation
    fi
    return 0
}
```

### Future Considerations

- Consider adding `pre_installation()` hook if needed
- May add `post_installation()` hook for notifications
- Could extend with `rollback()` for complex installations
