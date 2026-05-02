# Build APK / install on Android and iOS (Growsphere)

All commands below assume a terminal **in the project root** (`growspehere_v1`), with Flutter installed and on `PATH`.

```powershell
cd path\to\Hackathon_Project\growspehere_v1
flutter pub get
flutter gen-l10n
```

**Android release builds:** use **JDK 17** for Gradle and compilation. AGP 8.x will fail on Java 11 (e.g. Android Studio’s old `jre` folder).

- **Recommended (all Flutter commands):**  
  `flutter config --jdk-dir="C:\path\to\jdk-17"`  
  Use a real JDK 17 install (e.g. [Eclipse Temurin 17](https://adoptium.net/), or Android Studio’s **`jbr`** folder — often `C:\Program Files\android-studio\jbr` or `...\Android Studio\jbr`, not `jre`).
- **Or** set `JAVA_HOME` to that JDK before `flutter build apk`.
- **Or** set `org.gradle.java.home` in [`android/gradle.properties`](android/gradle.properties) to a **real** JDK root (see comments in that file). The path must exist and contain `bin\java.exe`; a wrong path makes Gradle fail immediately.

If you see **`Invalid depfile`** or odd build errors after changing l10n or `pubspec.yaml`, run **`flutter clean`** then **`flutter pub get`** and **`flutter gen-l10n`** before building again.

If you see `Timeout ... exclusive access ... gradle-8.7-all.zip`, see **Troubleshooting** at the bottom of this file.

---

## Android — release APK

### 1. One-time signing setup

1. Create a keystore (keep the file and passwords private):
   ```powershell
   keytool -genkey -v -keystore growsphere-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias growsphere
   ```
2. Create `android\key.properties` (do **not** commit real secrets to public git):
   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=growsphere
   storeFile=C:\\path\\to\\growsphere-upload-keystore.jks
   ```
3. Wire signing in `android\app\build.gradle` per Flutter’s [official signing doc](https://docs.flutter.dev/deployment/android#signing-the-app) if not already configured.

For local testing only, you can skip signing and use a **debug** APK (unsigned for store, fine for sideload to your own device):

```powershell
flutter build apk --debug
```

Output: `build\app\outputs\flutter-apk\app-debug.apk`

### 2. Release APK (signed)

```powershell
flutter build apk --release
```

Typical output: `build\app\outputs\flutter-apk\app-release.apk`

### 3. Install on a physical Android device

**Option A — USB (ADB)**

1. On the phone: **Settings → Developer options → USB debugging** (enable).
2. Connect USB; install [Google USB Driver](https://developer.android.com/studio/run/oem-usb) if Windows does not see the device.
3. On PC:
   ```powershell
   flutter devices
   adb install -r build\app\outputs\flutter-apk\app-release.apk
   ```
   (`-r` replaces an existing install.)

**Option B — copy APK**

1. Copy `app-release.apk` to the phone (USB, email, cloud).
2. On the phone, open the file; allow **Install unknown apps** for that source if prompted.

**Option B — run from Flutter (debug)**

```powershell
flutter run -d <device_id>
```

---

## Android App Bundle (Play Store)

```powershell
flutter build appbundle --release
```

Output: `build\app\outputs\bundle\release\app-release.aab`  
Upload this file in [Google Play Console](https://play.google.com/console).

---

## iOS — build and install

iOS **release** builds and device install require **macOS** with **Xcode** and an **Apple Developer** account (free or paid).

### 1. One-time on Mac

```bash
cd path/to/growspehere_v1
flutter pub get
flutter gen-l10n
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

In Xcode:

1. Select the **Runner** target → **Signing & Capabilities**.
2. Choose your **Team**; set a unique **Bundle Identifier** (e.g. `com.yourname.growsphere`).
3. Connect an iPhone → select it as run destination → **Run** (▶) for a debug install on device.

### 2. IPA for TestFlight / Ad Hoc

From the project root on Mac:

```bash
flutter build ipa --release
```

Follow Flutter’s [iOS deployment](https://docs.flutter.dev/deployment/ios) guide: use Xcode **Organizer** to upload to App Store Connect, or export an Ad Hoc IPA for registered devices.

### 3. Install on a physical iPhone (simple paths)

- **Development:** Xcode **Run** to a connected device (as above).
- **TestFlight:** Upload build in App Store Connect → add testers → install **TestFlight** app on the phone.
- **Ad Hoc:** Export IPA with the correct provisioning profile and device UDIDs registered.

---

## Checklist before shipping

- [ ] `flutter analyze` clean (or acceptable warnings documented).
- [ ] `flutter test` passes.
- [ ] Android: `minSdk`, permissions in `AndroidManifest.xml`, signing for release.
- [ ] iOS: `Info.plist` usage strings (camera, photos, location) match features you ship.
- [ ] Version in `pubspec.yaml` (`version: x.y.z+build`).

---

## Troubleshooting (Android)

### `Timeout ... waiting for exclusive access to file: ...gradle-8.7-all.zip`

Gradle is trying to **download or unpack** the wrapper ZIP while **another process** holds a lock on the same file (common if **Android Studio** and **PowerShell** both run a build, or a previous build was interrupted).

1. **Close** Android Studio (and any other IDE running Gradle for this project).
2. Stop daemons (from `android` folder):
   ```powershell
   cd "D:\Hackathon Project\growspehere_v1\android"
   .\gradlew.bat --stop
   ```
3. In **Task Manager**, end stray **Java** / **Gradle** processes if any remain.
4. Delete the **partial** Gradle 8.7 distro folder (path is in the error, usually under your user folder):
   ```text
   C:\Users\<YourUser>\.gradle\wrapper\dists\gradle-8.7-all\<random-folder>\
   ```
   Delete the **inner** random-named folder (or the whole `gradle-8.7-all` folder). Gradle will re-download on the next build.
5. Run **one** build only:
   ```powershell
   cd "D:\Hackathon Project\growspehere_v1"
   flutter build apk --release
   ```

If it still hangs: temporarily **pause antivirus** real-time scan on `.gradle`, or set `GRADLE_USER_HOME` to another drive to use a fresh cache (advanced).

For day-to-day **Windows desktop** runs and optional login startup scripts, see **[WINDOWS_DESKTOP_RUN.md](WINDOWS_DESKTOP_RUN.md)**.
