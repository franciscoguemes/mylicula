# MyLiCuLa Refactoring Plan

## Overview
Simplify the project structure by consolidating `customize/linux/` and `customize/ubuntu/` into `setup/`, `uninstall/`, and `resources/` directories, reflecting the reality that this is a single-user, Ubuntu-focused customization layer.

**Key Decision**: Uninstall scripts promoted to root-level `uninstall/` directory (not `setup/uninstall/`) for clear separation between installation and removal operations.

---

## Current Structure

```
mylicula/
├── customize/
│   ├── linux/
│   │   ├── apps/
│   │   │   ├── install_flyway.sh
│   │   │   └── install_toolbox.sh
│   │   ├── clone_github_repositories.sh
│   │   ├── clone_gitlab_repositories.sh
│   │   ├── create_directory_structure.sh
│   │   ├── create_maven_global_configuration.sh
│   │   ├── install_bash_scripts.sh
│   │   └── uninstall/
│   │       └── uninstall_bash_scripts.sh
│   ├── ubuntu/
│   │   ├── create_keyboard_shortcuts_in_ubuntu.sh
│   │   ├── install_icons.sh
│   │   ├── install_packages.sh
│   │   ├── install_set-title_function.sh
│   │   ├── install_snap.sh
│   │   ├── install_templates.sh
│   │   ├── resources/
│   │   │   ├── apt/
│   │   │   │   ├── standard_packages.txt
│   │   │   │   └── custom_packages.txt
│   │   │   ├── images/
│   │   │   │   └── icons/
│   │   │   ├── snap/
│   │   │   │   └── list_of_snap.txt
│   │   │   └── templates/
│   │   │       ├── bash_script.sh
│   │   │       ├── python_script.py
│   │   │       ├── markdown.md
│   │   │       └── ... (various templates)
│   │   └── uninstall/
│   │       └── remove_keyboard_shortcuts_in_ubuntu.sh
│   ├── linux_setup.sh
│   └── ubuntu_setup.sh
├── scripts/
│   └── bash/
│       ├── gitlab/
│       ├── github/
│       ├── certificate/
│       └── ...
├── in_review/
├── install.sh
└── ...
```

---

## New Structure (Proposed)

```
mylicula/
├── setup/                              # All setup/installation scripts
│   ├── apps/
│   │   ├── install_flyway.sh
│   │   └── install_toolbox.sh
│   ├── clone_github_repositories.sh
│   ├── clone_gitlab_repositories.sh
│   ├── create_directory_structure.sh
│   ├── create_keyboard_shortcuts.sh     # Renamed (remove 'in_ubuntu' suffix)
│   ├── create_maven_global_configuration.sh
│   ├── install_bash_scripts.sh
│   ├── install_icons.sh
│   ├── install_packages.sh
│   ├── install_set-title_function.sh
│   ├── install_snap.sh
│   └── install_templates.sh
├── uninstall/                          # All uninstall/removal scripts
│   ├── remove_keyboard_shortcuts.sh
│   └── uninstall_bash_scripts.sh
├── resources/                          # All configuration files, templates, data
│   ├── apt/
│   │   ├── standard_packages.txt
│   │   └── custom_packages.txt
│   ├── icons/
│   │   ├── Nextcloud_directory.png
│   │   └── Mega-nz.png
│   ├── snap/
│   │   └── list_of_snap.txt
│   └── templates/
│       ├── bash_script.sh
│       ├── python_script.py
│       ├── markdown.md
│       └── ... (various templates)
├── scripts/                            # Helper/utility scripts (unchanged)
│   └── bash/
│       ├── gitlab/
│       ├── github/
│       ├── certificate/
│       └── ...
├── in_review/                          # Staging area (unchanged for now)
├── install.sh                          # Main entry point (needs updates)
└── ...
```

---

## Migration Map

### Files to Move

#### From `customize/linux/` → `setup/`

| Source | Destination | Notes |
|--------|-------------|-------|
| `customize/linux/apps/install_flyway.sh` | `setup/apps/install_flyway.sh` | Keep apps subdirectory |
| `customize/linux/apps/install_toolbox.sh` | `setup/apps/install_toolbox.sh` | Keep apps subdirectory |
| `customize/linux/clone_github_repositories.sh` | `setup/clone_github_repositories.sh` | - |
| `customize/linux/clone_gitlab_repositories.sh` | `setup/clone_gitlab_repositories.sh` | - |
| `customize/linux/create_directory_structure.sh` | `setup/create_directory_structure.sh` | - |
| `customize/linux/create_maven_global_configuration.sh` | `setup/create_maven_global_configuration.sh` | - |
| `customize/linux/install_bash_scripts.sh` | `setup/install_bash_scripts.sh` | - |

#### From `customize/ubuntu/` → `setup/`

| Source | Destination | Notes |
|--------|-------------|-------|
| `customize/ubuntu/create_keyboard_shortcuts_in_ubuntu.sh` | `setup/create_keyboard_shortcuts.sh` | ✏️ **Rename**: Remove `_in_ubuntu` suffix |
| `customize/ubuntu/install_icons.sh` | `setup/install_icons.sh` | - |
| `customize/ubuntu/install_packages.sh` | `setup/install_packages.sh` | - |
| `customize/ubuntu/install_set-title_function.sh` | `setup/install_set-title_function.sh` | - |
| `customize/ubuntu/install_snap.sh` | `setup/install_snap.sh` | - |
| `customize/ubuntu/install_templates.sh` | `setup/install_templates.sh` | - |

#### From `customize/linux/uninstall/` → `uninstall/`

| Source | Destination | Notes |
|--------|-------------|-------|
| `customize/linux/uninstall/uninstall_bash_scripts.sh` | `uninstall/uninstall_bash_scripts.sh` | Promoted to root-level directory |

#### From `customize/ubuntu/uninstall/` → `uninstall/`

| Source | Destination | Notes |
|--------|-------------|-------|
| `customize/ubuntu/uninstall/remove_keyboard_shortcuts_in_ubuntu.sh` | `uninstall/remove_keyboard_shortcuts.sh` | ✏️ **Rename**: Remove `_in_ubuntu` suffix |

#### From `customize/ubuntu/resources/` → `resources/`

| Source | Destination | Notes |
|--------|-------------|-------|
| `customize/ubuntu/resources/apt/` | `resources/apt/` | Move entire directory |
| `customize/ubuntu/resources/images/icons/` | `resources/icons/` | Flatten: remove 'images' level |
| `customize/ubuntu/resources/snap/` | `resources/snap/` | Move entire directory |
| `customize/ubuntu/resources/templates/` | `resources/templates/` | Move entire directory |

#### Setup Entry Scripts

| Source | Destination | Notes |
|--------|-------------|-------|
| `customize/linux_setup.sh` | **DELETE** | ❌ No longer needed (merge into install.sh) |
| `customize/ubuntu_setup.sh` | **DELETE** | ❌ No longer needed (merge into install.sh) |

---

## Files That Need Path Updates

### 1. **`install.sh`** (Root)
**Current references:**
```bash
local setup_script="${SCRIPT_DIR}/customize/linux_setup.sh"
local setup_script="${SCRIPT_DIR}/customize/ubuntu_setup.sh"
```

**Changes needed:**
- Remove calls to `linux_setup.sh` and `ubuntu_setup.sh`
- Call scripts in `setup/` directory directly
- Update comments referencing `customize/`

---

### 2. **Scripts in `setup/` that reference BASE_DIR**

All scripts using `$BASE_DIR` pattern should continue working as-is since they:
- Search for `lib/common.sh` relative to script location
- Auto-detect project root
- Don't hardcode `customize/` paths

**Scripts with BASE_DIR logic (no changes needed):**
- `setup/clone_github_repositories.sh`
- `setup/clone_gitlab_repositories.sh`
- `uninstall/uninstall_bash_scripts.sh`

---

### 3. **`setup/create_keyboard_shortcuts.sh`** (formerly `create_keyboard_shortcuts_in_ubuntu.sh`)

**Current reference:**
```bash
echo "    ./customize/ubuntu/remove_keyboard_shortcuts_in_ubuntu.sh"
```

**Update to:**
```bash
echo "    ./uninstall/remove_keyboard_shortcuts.sh"
```

**Current reference:**
```bash
echo "${COLOR_YELLOW}[HINT]${COLOR_RESET} Please run: sudo customize/linux/install_bash_scripts.sh"
```

**Update to:**
```bash
echo "${COLOR_YELLOW}[HINT]${COLOR_RESET} Please run: sudo setup/install_bash_scripts.sh"
```

---

### 4. **Scripts referencing resource paths**

**Scripts that may reference `customize/ubuntu/resources/`:**
- `setup/install_templates.sh` → Update to `resources/templates/`
- `setup/install_icons.sh` → Update to `resources/icons/`
- `setup/install_packages.sh` → Update to `resources/apt/`
- `setup/install_snap.sh` → Update to `resources/snap/`

---

### 5. **Documentation Files**

**Files to update:**
- `README.md` - Update all references to `customize/` → `setup/` and `resources/`
- `CLAUDE.md` - Update project structure documentation
- `.claude/CLAUDE.md` - Update script development workflow
- `TODO.md` - Update any references to old paths
- `Testing.md` - Update testing paths

---

## Breaking Changes & Migration Notes

### ⚠️ Breaking Changes

1. **Path Changes**
   - All paths referencing `customize/linux/` or `customize/ubuntu/` will break
   - Users with custom scripts calling these paths need to update

2. **Entry Points**
   - `customize/linux_setup.sh` - **REMOVED**
   - `customize/ubuntu_setup.sh` - **REMOVED**
   - Main entry point remains: `install.sh`

3. **Script Names**
   - `create_keyboard_shortcuts_in_ubuntu.sh` → `create_keyboard_shortcuts.sh`
   - `remove_keyboard_shortcuts_in_ubuntu.sh` → `remove_keyboard_shortcuts.sh`

### ✅ What Stays the Same

1. **Helper Scripts** - `scripts/bash/` structure unchanged
2. **Install Entry** - `install.sh` remains the main entry point
3. **Auto-detection** - BASE_DIR auto-detection continues to work
4. **In Review** - `in_review/` staging area unchanged (for now)

---

## Migration Steps (Ordered)

### Phase 1: Create New Structure
1. Create `setup/` directory
2. Create `setup/apps/` subdirectory
3. Create `uninstall/` directory (at root level)
4. Create `resources/` directory
5. Create `resources/apt/` subdirectory
6. Create `resources/icons/` subdirectory
7. Create `resources/snap/` subdirectory
8. Create `resources/templates/` subdirectory

### Phase 2: Move Scripts
9. Move all files from `customize/linux/` → `setup/` (except uninstall subdirectory)
10. Move all files from `customize/ubuntu/` → `setup/` (except uninstall subdirectory)
11. Move `customize/linux/uninstall/uninstall_bash_scripts.sh` → `uninstall/uninstall_bash_scripts.sh`
12. Move `customize/ubuntu/uninstall/remove_keyboard_shortcuts_in_ubuntu.sh` → `uninstall/remove_keyboard_shortcuts.sh`
13. Rename `create_keyboard_shortcuts_in_ubuntu.sh` → `create_keyboard_shortcuts.sh`

### Phase 3: Move Resources
14. Move `customize/ubuntu/resources/apt/` → `resources/apt/`
15. Move `customize/ubuntu/resources/images/icons/` → `resources/icons/`
16. Move `customize/ubuntu/resources/snap/` → `resources/snap/`
17. Move `customize/ubuntu/resources/templates/` → `resources/templates/`

### Phase 4: Update Path References
18. Update `install.sh` - Remove calls to setup scripts
19. Update `setup/create_keyboard_shortcuts.sh` - Fix paths in messages
20. Update `setup/install_templates.sh` - Update to `resources/templates/`
21. Update `setup/install_icons.sh` - Update to `resources/icons/`
22. Update `setup/install_packages.sh` - Update to `resources/apt/`
23. Update `setup/install_snap.sh` - Update to `resources/snap/`

### Phase 5: Update Documentation
24. Update `README.md`
25. Update `CLAUDE.md`
26. Update `.claude/CLAUDE.md`
27. Update `TODO.md` (if applicable)
28. Update `Testing.md` (if applicable)

### Phase 6: Cleanup
29. Delete `customize/linux_setup.sh`
30. Delete `customize/ubuntu_setup.sh`
31. Delete `customize/` directory (should be empty)
32. Run syntax checks on all moved scripts
33. Test `install.sh` to verify it works

### Phase 7: Commit
34. Git add all changes
35. Create commit with clear message
36. Optionally create git tag for this refactoring milestone

---

## Validation Checklist

After migration, verify:

- [ ] All scripts in `setup/` pass syntax check: `bash -n setup/**/*.sh`
- [ ] `install.sh` runs without errors
- [ ] All paths in scripts correctly reference new locations
- [ ] Documentation is updated
- [ ] No broken references to `customize/` remain
- [ ] Git status shows expected changes (moves, not deletions/additions)
- [ ] All scripts maintain executable permissions

---

## Rollback Plan

If issues arise:
1. **Git revert** - Rollback the refactoring commit
2. **Manual restore** - Move files back from `setup/` and `resources/` to `customize/`

---

## Post-Refactoring Benefits

✅ **Simpler structure** - No artificial linux/ubuntu split
✅ **Clearer organization** - `setup/` = install, `uninstall/` = remove, `resources/` = data
✅ **Easier maintenance** - Less directory nesting
✅ **Better mental model** - Matches actual usage (Ubuntu-only, single user)
✅ **Consistent naming** - Remove redundant `_in_ubuntu` suffixes
✅ **Clear separation** - Installation and uninstallation scripts at top level

---

## Questions to Resolve Before Starting

1. **Keep `in_review/` or rename to `staging/`?**
   - Recommendation: Keep `in_review/` for now, address separately

2. **Merge setup scripts into `install.sh` or keep them?**
   - Recommendation: Delete `linux_setup.sh` and `ubuntu_setup.sh`, call scripts directly from `install.sh`

3. **Handle scripts in `in_review/` that reference old paths?**
   - Recommendation: Update them as part of this refactoring

---

## Timeline Estimate

- **Phase 1-3 (Structure & Moves):** 15 minutes
- **Phase 4 (Path Updates):** 30 minutes
- **Phase 5 (Documentation):** 20 minutes
- **Phase 6 (Cleanup & Testing):** 15 minutes
- **Phase 7 (Commit):** 5 minutes

**Total: ~1.5 hours**

---

## Ready to Proceed?

Review this plan and let me know:
1. Any changes to the proposed structure?
2. Any files I missed?
3. Ready to execute the refactoring?

Once approved, I'll execute all phases systematically.
