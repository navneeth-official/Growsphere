# Run Growsphere on Windows

This project is a Flutter app. On Windows you normally use the **Flutter SDK** and run the **Windows** desktop target.

## Prerequisites

1. **Windows 10/11** (64-bit) with enough disk space for the Flutter SDK and Android Studio (optional if you only build Windows).
2. **Flutter** for Windows installed and on `PATH`, or in a default location such as:
   - `%LOCALAPPDATA%\flutter\bin`
   - `%USERPROFILE%\flutter\bin`
3. From a terminal in the project folder, a healthy toolchain:
   ```powershell
   flutter doctor -v
   ```
   Enable **Visual Studio** workload “Desktop development with C++” for Windows desktop builds.

## Quick run (recommended)

1. Open **File Explorer** and go to the project’s `scripts` folder:
   `Hackathon_Project\growspehere_v1\scripts`
2. Double-click **`run_growsphere_windows.bat`**  
   - First run may take a while (`pub get`, code generation, compile).
3. The app launches with **`flutter run -d windows`**. Press **Ctrl+C** in the console window to stop.

### Command-line options

From **PowerShell** in the `scripts` folder:

| Command | Purpose |
|--------|---------|
| `.\run_growsphere_windows.ps1` | Same as double-clicking the `.bat` |
| `.\run_growsphere_windows.ps1 -Doctor` | Run `flutter doctor -v` only |
| `.\run_growsphere_windows.ps1 -BuildRelease` | Build a release `.exe` under `build\windows\...` (no hot reload) |

From **cmd**:

```bat
cd path\to\growspehere_v1\scripts
run_growsphere_windows.bat
run_growsphere_windows.bat -Doctor
run_growsphere_windows.bat -BuildRelease
```

## Auto-start when Windows signs in (optional)

This is useful for **development** demos; it opens a **console** and runs `flutter run` each login.

1. Open PowerShell **as your normal user** (not necessarily admin).
2. Run:
   ```powershell
   cd path\to\growspehere_v1\scripts
   .\install_windows_startup.ps1
   ```
3. A shortcut appears in your user **Startup** folder. To open that folder quickly: **Win+R** → type `shell:startup` → Enter.

**Remove auto-start:**

```powershell
.\install_windows_startup.ps1 -Remove
```

**Production-style start:** After `.\run_growsphere_windows.ps1 -BuildRelease`, create a shortcut yourself in `shell:startup` that targets the generated `.exe` under:

`build\windows\x64\runner\Release\`

(Exact `.exe` name matches the Flutter project name.)

## Troubleshooting

- **“Flutter was not found”**  
  Install Flutter and add its `bin` directory to your user **PATH**, or install under `%LOCALAPPDATA%\flutter` so the script can find it.

- **`flutter pub get` errors**  
  Run from the **repository root** (the Windows scripts already `cd` there).

- **CMake / Visual Studio errors on Windows build**  
  Run **Visual Studio Installer** → modify your VS edition → enable **Desktop development with C++** → retry `flutter doctor`.

For Android APK and iOS install steps, see **[MOBILE_BUILD_INSTALL.md](MOBILE_BUILD_INSTALL.md)**.
