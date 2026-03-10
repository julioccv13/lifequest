# LifeQuest

Flutter app for an offline-first life coaching RPG.

## Project layout

```text
lifequest/
├── assets/demo/        # demo JSON exports for local import
├── lib/
│   ├── app/            # app entry widget
│   ├── core/           # shared platform and infrastructure services
│   ├── data/           # models and repositories
│   ├── domain/         # use cases
│   └── features/       # UI grouped by feature
├── test/               # widget and app tests
└── web/                # PWA/web shell
```

## Local docs

Project documentation is maintained outside the repo in the canonical docs folder:

- `/home/julio/workspace/personal/docs/lifequest/documentos/overview.md`
- `/home/julio/workspace/personal/docs/lifequest/documentos/repo-architecture.md`
- `/home/julio/workspace/personal/docs/lifequest/documentos/setup.md`

Task logs live in:

- `/home/julio/workspace/personal/docs/lifequest/tasks/`

## Setup

```bash
flutter pub get
flutter run
```

For web:

```bash
flutter run -d chrome
flutter build web --release --base-href "/lifequest/"
```

## Demo data

A sample export file is available at `assets/demo/sample_data.json`.
Import it from Settings using its local filesystem path.
