---
title: "[DRAFT] Using a native cryptography library in Flutter"
date: 2020-06-19T17:24:19-07:00
draft: true
katex: true
summary: |
    [Flutter](https://flutter.dev/) is a Google UI toolkit for writing cross-platform mobile applications.  Using
    native code from Flutter is now easier than ever by using the
    [`dart:ffi`](https://flutter.dev/docs/development/platform-integration/c-interop) library that is currently in
    beta. In this article we demonstrate why you'd want to use native code, and a practical example of doing so
    using the [`libsodium`](https://doc.libsodium.org/) cryptography library.

    Topics: flutter, mobile, native, cryptography, tutorial
---

## Learning objectives

By the end of this article you will be able to:

-   Create a Flutter plugin that uses native code for iOS and Android mobile apps.
-   Use the libsodium native cryptography library from Flutter mobile apps.
-   Run expensive native code in the background to avoid blocking the user interface of a mobile app.

## Introduction

[Flutter](https://flutter.dev/) is a software toolkit that lets you write code once and deploy apps to iOS and
Android at the same time.  [Dart](https://dart.dev/) is the programming language that Flutter uses, and it is
powerful and fast enough for most purposes. However, sometimes you want to use pre-existing native libraries of code
already written and battle-tested in some other programming language, for example because:

1.  The code is for a **security-sensitive application**, such as encrypting data. You do not want to re-write
    such code because of the likelihood of introducing bugs that leak information or cause your application to
    crash. Instead, by using a pre-written library that has been audited by security engineers you are more
    confident that it works.
2.  You want to **re-use the same code in multiple domains**, such as your Flutter mobile application, a desktop
    application, and a server. Although Google are starting to introduce desktop and web support for Flutter,
    for now in order to share logic across multiple domains you can write it in a re-usable library in a
    different language.
3.  You need to write code in a **different, faster, more memory efficient language**. For example, by writing a
    re-usable library in [Rust](https://www.rust-lang.org/) you can take advantage of a more powerful
    optimizing compiler and avoid the overhead of a garbage collector if need be.

In this article we will use an example that is motivated by all three reasons. [`libsodium`](https://doc.libsodium.org/)
is a cryptography library that lets you e.g. encrypt, decrypt, and hash data. `libsodium` is fast, already audited
by security engineers, and allows you to re-use the same code on a server so that it's easier to decrypt data
encrypted on a mobile device.

This article will start from scratch. We will create a Flutter plugin, compile `libsodium` for iOS and Android,
and finally demonstrate how to use `libsodium` from Flutter and the server-side. By reading this article you will
be able to use code from other native libraries, not just `libsodium`.

## Prior art, references, and other resources

[Rust once and share it with Android, iOS and
Flutter](https://dev.to/robertohuertasm/rust-once-and-share-it-with-android-ios-and-flutter-286o) is a
fantastic article that similarly starts from scratch and shows you how to share a library written in Rust with
Android, iOS, and Flutter. However, since this article does not use the new `dart:ffi` feature currently in
beta, there is a lot of overhead because you need to write custom code in Swift and Kotlin to share the
library with iOS and Android respectively. I will be writing a follow-up article showing how easy it is to use
a real-world Rust library example in Flutter.

[`flutter_sodium`](https://github.com/firstfloorsoftware/flutter_sodium) is an existing Flutter plugin that
uses the new `dart:ffi` feature to bind with `libsodium`. I was motivated to write this article by reading
through the code of `flutter_sodium`, but I've made some different implementation choices. Moreover,
`flutter_sodium` uses pre-built `libsodium` libraries, whereas this article will show you how to re-compile
`libsodium` from scratch.

For background on Flutter plugins see:

- [Developing packages & plugins](https://flutter.dev/docs/development/packages-and-plugins/developing-packages)
- [Binding to native code using `dart:ffi`](https://flutter.dev/docs/development/platform-integration/c-interop)

## How-to

### Pre-requisites

I happen to work in `$HOME/Programming`, but change this to anywhere you prefer.

```
ROOT_DIR=$HOME/Programming
```

Download the [Android NDK](https://developer.android.com/ndk/downloads/)  then set both the `ANDROID_NDK_HOME`
and `NDK_HOME` environment variables to `$HOME/Library/Android/sdk/ndk-bundle`:

```
export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk-bundle
export NDK_HOME=ANDROID_NDK_HOME
```

Make sure your [Flutter installation](https://flutter.dev/docs/get-started/install) doesn't have any
high-level issues, and make sure you're on the Beta channel to get access to the new Dart FFI features:

```
flutter channel beta
flutter upgrade
flutter doctor -v
```

### Getting libsodium

As of 2020-06-14, v1.0.18 is the latest stable version of libsodium.

```
cd $ROOT_DIR
wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.18-stable.tar.gz
tar xvf libsodium-1.0.18-stable.tar.gz
rm -f libsodium-1.0.18-stable.tar.gz
```

### Building libsodium for iOS

`libsodium` comes with [easy to use build
scripts](https://github.com/jedisct1/libsodium/tree/master/dist-build) for compiling the library for iOS and
Android.

This will put artifacts in `$ROOT_DIR/libsodium-stable/libsodium-ios`. We specify `LIBSODIUM_FULL_BUILD` so
that we expose all APIs, not just the high-level APIs.

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

### Building libsodium for Android

Similarly we'll use existing `libsodium` build scripts to build libraries for Android.

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

### Create a Flutter plugin and use FFI to bind to libsodium

Let's create a brand-new empty Flutter plugin.

```
cd $ROOT_DIR
flutter create --template=plugin flutter_libsodium
```

#### Flutter iOS plugin setup

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

#### Flutter Android plugin setup

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

## Future work and areas for improvement
 
TODO
