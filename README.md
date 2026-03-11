# genz (zapp) - Simplified Flutter Project

## Run
1) Create a Flutter project (if you don't already have one):
```bash
flutter create genz
```

2) Replace the generated `pubspec.yaml` and `lib/` folder with the ones in this zip.

3) Install packages:
```bash
flutter pub get
```

4) Amplify models (required):
```bash
amplify pull
amplify codegen models
```

5) Run:
```bash
flutter run
```

## Notes
- Package name in `pubspec.yaml` is **genz** to match your existing imports.
- If you want to rename it to `zapp`, tell me and I'll auto-refactor all imports + android package id.
