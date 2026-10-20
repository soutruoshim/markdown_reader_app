# Markdown Reader — MVVM + Clean Architecture

Offline Flutter application for opening and reading local `.md` / `.markdown` files.

The full zero-to-production guide is in `docs/Flutter_Markdown_Reader_Zero_to_Production_MVVM.md`.

## Scope of this starter

- Native picker, strict UTF-8, max **2 MiB** per file
- Read-only GitHub-flavored Markdown renderer
- Preserves the previous document when selection is cancelled or fails
- File images **not loaded**, web links **not automatically opened**
- Uses feature-first Clean Architecture + Riverpod ViewModel
- Keeps the latest 20 documents as app-private offline snapshots
- Reopen from Recent Files (home list, quick-access chips while reading, or history drawer); remove one or clear all
- No server, authentication or remote database

## Requirements

- Flutter SDK on the stable channel, with Dart **3.12+**
- Android Studio and a configured Android SDK to run on Android
- iOS builds require macOS and Xcode

## Run from an extracted ZIP (platform folders not included)

1. Extract ZIP to `markdown_reader` and open its folder in terminal.
2. `flutter doctor -v`
3. `flutter create . --project-name markdown_reader --platforms=android`
   - On Windows, omit any platform not supported by your local Flutter setup.
4. `flutter pub get`
5. `dart format lib test`
6. `flutter analyze`
7. `flutter test`
8. `flutter run`

## Architecture

```text
Presentation (ReaderPage -> ReaderViewModel -> ReaderState)
             |                      |
Domain: OpenMarkdownDocument     Recent-document use cases
             |                      |
       DocumentRepository       RecentDocumentsRepository
             ^                      ^
Data: DocumentRepositoryImpl    LocalRecentDocumentsRepository
             |                      |
         file_picker           snapshots + preferences index
```

The domain layer never imports Flutter, Riverpod, or the file picker plugin.
`lib/features/reader/di/reader_providers.dart` wires the concrete objects.

## Recent Files behavior

- Successfully opened documents are stored as snapshots in the app support directory. This is necessary because OS-provider/cache file paths are not guaranteed to persist.
- Saved metadata lists files newest first; tapping reopens them offline without the native picker.
- Opening an existing snapshot moves it to the top. Duplicate filename + content is reused.
- 20 entries maximum; old snapshots are removed when the limit is exceeded. Removing/clearing history deletes app-private copies only, not original files.
- If a source file later changes, picking it again creates an updated snapshot. For privacy, recent-file content is kept locally and disappears when the app is uninstalled (subject to device backup policy).
- Android/iOS/desktop only. Web support requires a separate repository implementation.

## Release

- Set your unique Android `applicationId` and version in project metadata.
- Follow official Flutter docs to make your *own* upload signing key.
- `flutter build appbundle --release`
- Test the **signed** bundle on a physical Android device and via a Play internal-testing track.
- Do not commit signing credentials or personal documents.

## Known limitations / production hardening

- This ZIP is a **scaffold**, not a compiled or store-published app. No Flutter/Dart SDK is installed in the authoring environment, so device builds must be verified locally.
- File picker/provider variations require real-device testing, especially cloud-backed files.
- Large-document rendering/performance is unverified; 2 MiB hard limit limits exposure.
- Network/local images and opening links are disabled deliberately. Revisit with URI permission policy.
- Reading position and bookmarks are not yet persisted. Recent-file copies are local snapshots: external changes to the original are not automatically synchronized.
- Recent snapshots are supported on Android/iOS/desktop; Flutter Web requires a separate persistence adapter.
- Review app privacy policy, screenshots, Play listing, accessibility and target SDK requirements before release.

## References

- https://docs.flutter.dev/app-architecture/guide
- https://pub.dev/packages/file_picker
- https://pub.dev/packages/flutter_riverpod
- https://pub.dev/packages/flutter_markdown_plus
- https://docs.flutter.dev/deployment/android
