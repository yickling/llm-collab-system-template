# Task Types

Each file defines the OPERATION format for one task type. All tasks use the canonical envelope from `../TASK_FORMAT.md`.

| Type | File | Description | Modifies Files? |
|------|------|-------------|-----------------|
| EDIT | [EDIT.md](EDIT.md) | Replace exact string with another exact string | Yes |
| CREATE | [CREATE.md](CREATE.md) | Create new file with exact content | Yes |
| APPEND | [APPEND.md](APPEND.md) | Add content to end of file | Yes |
| INSERT | [INSERT.md](INSERT.md) | Insert content at specific location | Yes |
| DELETE | [DELETE.md](DELETE.md) | Remove a file | Yes |
| RENAME | [RENAME.md](RENAME.md) | Move or rename a file | Yes |
| RUN | [RUN.md](RUN.md) | Execute command, report output | No (typically) |
| VALIDATE | [VALIDATE.md](VALIDATE.md) | Run command, check expected output | No |
| SEARCH_REPORT | [SEARCH_REPORT.md](SEARCH_REPORT.md) | Find pattern, report results | No |
