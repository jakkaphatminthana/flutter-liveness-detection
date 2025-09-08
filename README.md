# Flutter Liveness Detection
Flutter app for real-time liveness detection using ML Kit Face Detection

## 📱 Requirements
- Flutter 3.0+
- Android API 21+
- iOS 15.5+

## 🛠️ Tech Stack
- Flutter – Cross-platform mobile framework
- Google ML Kit – Face detection and recognition APIs
- Camera Plugin – Real-time camera stream processing
- Dart – Programming language for Flutter
- Android/iOS Native – Platform-specific implementations

## 🚀 Setup

### 1. Android Configuration
AndroidManifest.xml

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

build.gradle

```gradle
dependencies {
    implementation("com.google.mlkit:face-detection:16.1.7")
}
```

### 2. iOS Configuration
Info.plist

```markdown
<key>NSCameraUsageDescription</key>
<string>The app needs access to the camera to take photos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>The app needs access to the photo library to save and select photos.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>The app needs permission to save photos to the photo library.</string>
```

Podfile

```ruby
platform :ios, '15.5'
...
use_modular_headers!
...
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # for ML Kit and Camera
    target.build_configurations.each do |config|
      # add preprocessor definitions
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'COCOAPODS=1',
      ]
      
      # setting for ML Kit
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
      
      # protect bitcode issues
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # setting for camera and ML Kit
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
      
      # add Metal support for ML Kit
      config.build_settings['MTL_ENABLE_DEBUG_INFO'] = 'INCLUDE_SOURCE'
      
      # memory management
      config.build_settings['CLANG_ARC_MIGRATE_EMIT_ERRORS'] = 'YES'
      
      # add support for large binary
      config.build_settings['STRIP_INSTALLED_PRODUCT'] = 'NO' if config.name == 'Debug'
    end
    
    # GoogleMLKit pods
    if target.name.start_with?('GoogleMLKit') || target.name.start_with?('MLKit')
      target.build_configurations.each do |config|
        config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
        config.build_settings['CLANG_WARN_STRICT_PROTOTYPES'] = 'NO'
      end
    end
  end
end
```

## 📦 Usage
```bash
flutter pub get
flutter run
```
