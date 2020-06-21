# How to build libsodium for flutter

There is a pre-existing Flutter package https://github.com/firstfloorsoftware/flutter_sodium but it version controls the binaries so we have to trust they are built correctly and with the correct source code. Instead let's do everything from scratch, and also use Dart's new FFI that is in beta.

## Pre-requisites

I happen to work in `$HOME/Programming`, but change this to anywhere you prefer.

```
ROOT_DIR=$HOME/Programming
```

Download the Android NDK https://developer.android.com/ndk/downloads/ then setboth  the `ANDROID_NDK_HOME` and `NDK_HOME` environment variables to `$HOME/Library/Android/sdk/ndk-bundle`.

Make sure your Flutter installation doesn't have any high-level issues, and make sure you're on the Beta channel to get access to the new Dart FFI features:

```
flutter channel beta
flutter upgrade
flutter doctor -v
```

## Getting libsodium

As of 2020-06-14, v1.0.18 is the latest stable version of libsodium.

```
cd $ROOT_DIR
wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.18-stable.tar.gz
tar xvf libsodium-1.0.18-stable.tar.gz
rm -f libsodium-1.0.18-stable.tar.gz
```

## Building libsodium for iOS

This will put artifacts in `$ROOT_DIR/libsodium-stable/libsodium-ios`. We specify `LIBSODIUM_FULL_BUILD` so that we expose all APIs, not just the high-level APIs.

```
cd $ROOT_DIR/libsodium-stable

# Clean up from previous builds
test -d libsodium-ios || rm -rf libsodium-ios
./configure && make distclean

LIBSODIUM_FULL_BUILD=true ./dist-build/ios.sh
```

If successful at the end you'll see paths to a single binary for all architectures:

```
libsodium has been installed into /Users/asimi/Programming/libsodium-stable/libsodium-ios

/Users/asimi/Programming/libsodium-stable/libsodium-ios/lib/libsodium.a: Mach-O universal binary with 5 architectures: [i386:current ar archive random library] [arm_v7:current ar archive random library] [arm_v7s] [x86_64] [arm64]
/Users/asimi/Programming/libsodium-stable/libsodium-ios/lib/libsodium.a (for architecture i386):	current ar archive random library
/Users/asimi/Programming/libsodium-stable/libsodium-ios/lib/libsodium.a (for architecture armv7):	current ar archive random library
/Users/asimi/Programming/libsodium-stable/libsodium-ios/lib/libsodium.a (for architecture armv7s):	current ar archive random library
/Users/asimi/Programming/libsodium-stable/libsodium-ios/lib/libsodium.a (for architecture x86_64):	current ar archive random library
/Users/asimi/Programming/libsodium-stable/libsodium-ios/lib/libsodium.a (for architecture arm64):	current ar archive random library
```

## Building libsodium for Android

```
cd $ROOT_DIR/libsodium-stable

# Clean up from previous builds
./configure && make distclean

LIBSODIUM_FULL_BUILD=true ./dist-build/android-arm.sh
LIBSODIUM_FULL_BUILD=true ./dist-build/android-armv7-a.sh
LIBSODIUM_FULL_BUILD=true ./dist-build/android-armv8-a.sh
LIBSODIUM_FULL_BUILD=true ./dist-build/android-x86.sh
LIBSODIUM_FULL_BUILD=true ./dist-build/android-x86_64.sh
```

The outputs will be here (note that `westmere` is `x86_64`):

```
libsodium has been installed into /Users/asimi/Programming/libsodium-stable/libsodium-android-armv6
libsodium has been installed into /Users/asimi/Programming/libsodium-stable/libsodium-android-armv7-a
libsodium has been installed into /Users/asimi/Programming/libsodium-stable/libsodium-android-armv8-a
libsodium has been installed into /Users/asimi/Programming/libsodium-stable/libsodium-android-i686
libsodium has been installed into /Users/asimi/Programming/libsodium-stable/libsodium-android-westmere
```

## Create a Flutter plugin and use FFI to bind to libsodium

```
cd $ROOT_DIR
flutter create --template=plugin flutter_libsodium
```

### Flutter iOS plugin setup

Copy around the libraries to the correct locations:

```
cp $ROOT_DIR/libsodium-stable/libsodium-ios/lib/libsodium.a $ROOT_DIR/flutter_libsodium/ios/
```

Update the iOS `podspec` file to include the binary library:

```
diff --git a/ios/flutter_libsodium.podspec b/ios/flutter_libsodium.podspec
index 0ae9b0f..e4ad522 100644
--- a/ios/flutter_libsodium.podspec
+++ b/ios/flutter_libsodium.podspec
@@ -16,8 +16,10 @@ A new flutter plugin project.
   s.source_files = 'Classes/**/*'
   s.dependency 'Flutter'
   s.platform = :ios, '8.0'
+  s.vendored_libraries = 'libsodium.a'

   # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
   s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
   s.swift_version = '5.0'
+  s.xcconfig = { 'OTHER_LDFLAGS' => '-force_load "${PODS_ROOT}/../.symlinks/plugins/flutter_libsodium/ios/libsodium.a"'}
 end
```

### Flutter Android plugin setup

Copy around the libraries to the correct locations:

```
mkdir -p $ROOT_DIR/flutter_libsodium/android/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86,x86_64}
cp $ROOT_DIR/libsodium-stable/libsodium-android-armv7-a/lib/libsodium.so \
    $ROOT_DIR/flutter_libsodium/android/src/main/jniLibs/armeabi-v7a
cp $ROOT_DIR/libsodium-stable/libsodium-android-armv8-a/lib/libsodium.so \
    $ROOT_DIR/flutter_libsodium/android/src/main/jniLibs/arm64-v8a
cp $ROOT_DIR/libsodium-stable/libsodium-android-i686/lib/libsodium.so \
    $ROOT_DIR/flutter_libsodium/android/src/main/jniLibs/x86
cp $ROOT_DIR/libsodium-stable/libsodium-android-westmere/lib/libsodium.so \
    $ROOT_DIR/flutter_libsodium/android/src/main/jniLibs/x86_64
```

### Flutter Dart code - trivial start

Here is the code to get started by initializing the libsodium library, and get the version string:

```
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

final libsodium = _load();

DynamicLibrary _load() {
  if (Platform.isAndroid) {
    return DynamicLibrary.open("libsodium.so");
  } else {
    return DynamicLibrary.process();
  }
}

class LibsodiumBindings {
  final int Function() sodium_init =
      libsodium.lookup<NativeFunction<Int32 Function()>>('sodium_init').asFunction();
  final Pointer<Utf8> Function() sodium_version_string = libsodium
      .lookup<NativeFunction<Pointer<Utf8> Function()>>('sodium_version_string')
      .asFunction();
}

class LibsodiumError extends Error {}

class LibsodiumCouldNotInitError extends LibsodiumError {}

class LibsodiumWrapper {
  final LibsodiumBindings _bindings = LibsodiumBindings();

  LibsodiumWrapper() {
    if (sodiumInit() < 0) {
      throw LibsodiumCouldNotInitError();
    }
  }

  int sodiumInit() {
    return _bindings.sodium_init();
  }

  String sodiumVersionString() {
    return Utf8.fromUtf8(_bindings.sodium_version_string());
  }
}
```

If you change the `example/lib/main.dart` to create a `LibsodiumWrapper` instance then call `wrapper.sodiumVersionString()` you'll see it output "1.0.18".

### Flutter Dart code - seal then unseal

This is a more complex, realistic example where you want to encrypt then decrypt something.

Let's use a Python program to generate a public/private key pair, and encode the public key as base64 for use in Flutter to seal something:

```
import base64
from nacl.public import PrivateKey

keypair = PrivateKey.generate()
print("Public key: " + base64.b64encode(keypair.public_key.encode()).decode('utf-8'))
print("Private key: " + base64.b64encode(keypair.encode()).decode('utf-8'))
```

The encoded public key is `31SbsmXLwc3fPOLsM0Ztg+WNJL2UKRpaDKMvtoSdQQQ=`. Let's use this in Flutter to seal then encode a message:

```

```




`libsodium` uses a lot of macro constant values. Thankfully there are corresponding methods that return these constants, e.g. see https://github.com/jedisct1/libsodium/blob/927dfe8/src/libsodium/crypto_secretbox/crypto_secretbox.c.

Note that these constants are all defined as `size_t`. See:

-   "How to define a type like size_t??": https://github.com/dart-lang/sdk/issues/39372
-   "dart:ffi int, long, etc": https://github.com/dart-lang/sdk/issues/36140

