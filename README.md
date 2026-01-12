# aya_isp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Release signing

1. Generate a release keystore (keep it outside version control). For example:

   ```bash
   keytool -genkeypair \
     -keystore android/keystores/release.jks \
     -alias aya_isp \
     -keyalg RSA \
     -keysize 2048 \
     -validity 10000
   ```
   Create the `android/keystores` folder first if it does not already exist and adjust the path if you prefer to store the file elsewhere.

2. Copy `android/key.properties.example` to `android/key.properties` and replace the placeholder values with your keystore path and passwords. The `key.properties` file is ignored by git so the credentials stay private.

3. Build a signed artifact once the keystore is configured:

   ```bash
   cd android && ./gradlew bundleRelease
   # or
   flutter build apk --release
   ```

   The release build will now use your keystore if the `key.properties` file exists; otherwise it falls back to the debug signing key for testing.
