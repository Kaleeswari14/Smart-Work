# Android Build & Deployment Guide (`deployment_guide.md`)

This guide walks through building, signing, and deploying the Work Management Android APK.

---

## 📱 Build Types
* **Debug APK:** Used during active development. Includes debugging symbols, hot reload support, and default debug signing keystore.
* **Release APK:** Production-ready, tree-shaken, code-minified (R8/Proguard), and cryptographically signed with a secure private keystore.

---

## 🔑 Keystore Configuration (Release Signing)
* **Keystore Location:** `android/work_app_release.jks`
* **Key Algorithm:** RSA 2048-bit (SHA256withRSA)
* **Validity:** 10,000 days
* **Certificate Authority / Issuer:** `CN=Smartiva Technologies, OU=Mobile Dev, O=Smartiva, L=Chennai, ST=Tamil Nadu, C=IN`
* **Alias:** `work_app_key`

### Configuration in `android/key.properties`:
```properties
storePassword=SmartWorkApp2026!
keyPassword=SmartWorkApp2026!
keyAlias=work_app_key
storeFile=../work_app_release.jks
```

> **Security Note:** `android/key.properties` and `*.jks` are protected in `.gitignore` and never committed to source control.

---

## 📦 Production Release APK Output
* **Application Name:** **Smartiva**
* **Application Icon:** Official Smartiva origami ribbon logo (all mipmap densities hdpi to xxxhdpi)
* **Output APK Path:**
  `build/app/outputs/flutter-apk/app-release.apk`
* **File Size:** ~57.3 MB (All-in-one standalone package with complete bundled MaterialIcons font)
* **Build Command:**
  ```powershell
  $env:Path = "C:\Program Files\Microsoft\jdk-17.0.21.21-hotspot\bin;$env:Path;G:\flutter\bin"
  flutter build apk --release --no-tree-shake-icons
  ```

---

## 📲 How to Install on Android Devices

### Method 1: USB / ADB Installation (Direct)
1. Enable **Developer Options** and **USB Debugging** on your Android smartphone.
2. Connect your phone to your PC via USB cable.
3. Run the following command from the project root:
   ```powershell
   adb install -r "build/app/outputs/flutter-apk/app-release.apk"
   ```

### Method 2: Direct Phone Transfer (WhatsApp / Google Drive / Bluetooth)
1. Copy `app-release.apk` to your phone via USB file transfer, Google Drive, or messaging.
2. On your phone, tap the `.apk` file.
3. Allow "Install unknown apps" permission for your file manager/browser if prompted.
4. Tap **Install** -> Open **Smartiva Work Management**!

---

## 🛡️ Android Permissions Declared in `AndroidManifest.xml`
* `android.permission.INTERNET`: Required for Supabase cloud sync, realtime database updates, and authentication.
* `android.permission.ACCESS_NETWORK_STATE`: Required for detecting online/offline connectivity status.
