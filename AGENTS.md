# Agent Guidelines & Repository Context

## Core Rules & Single Source of Truth

1. **Frozen Core Contract**: Always read [tech.md](file:///c:/Users/ervin/Documents/Projects/Flutter/diary_flutter/tech.md) first. It is the single source of truth for the entire architecture, data models, Hive boxes, and API contracts. Follow it literally.
2. **Never Invent Contracts**: Never invent missing endpoints, model fields, or database tables mid-task. If something is missing, output a `CONTRACT GAP` block (what is needed, why, proposed shape), update `tech.md`, and bump its version before proceeding.
3. **Follow Staged Workflow**: Build one vertical slice at a time according to [WORKFLOW.md](file:///c:/Users/ervin/Documents/Projects/Flutter/diary_flutter/WORKFLOW.md). Use `lib/features/bells` as the reference architectural pattern.
4. **Log Updates & Bump Version**: Always after a big feature or fix, log the changes in [UPDATES.md](file:///c:/Users/ervin/Documents/Projects/Flutter/diary_flutter/UPDATES.md) specifying the date and version, and update the app version in [pubspec.yaml](file:///c:/Users/ervin/Documents/Projects/Flutter/diary_flutter/pubspec.yaml). Do NOT write verification or test execution sections in `UPDATES.md`.
5. **Preserve Comments**: Never delete existing code comments. You may update them for clarity, but do not strip comments from the codebase.
6. **Language & Conventions**: Write all code, commits, PR summaries, and documentation in English. Follow Conventional Commits (`type(scope): summary`).
7. **Verification**: Every slice must pass `flutter analyze` (zero issues), `dart format`, and `flutter test` before it is considered done.