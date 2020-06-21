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

{{< highlight bash >}}
ROOT_DIR=$HOME/Programming
{{< / highlight >}}

Download the [Android NDK](https://developer.android.com/ndk/downloads/)  then set both the `ANDROID_NDK_HOME`
and `NDK_HOME` environment variables to `$HOME/Library/Android/sdk/ndk-bundle`:

{{< highlight bash >}}
export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk-bundle
export NDK_HOME=ANDROID_NDK_HOME
{{< / highlight >}}

Make sure your [Flutter installation](https://flutter.dev/docs/get-started/install) doesn't have any
high-level issues, and make sure you're on the Beta channel to get access to the new Dart FFI features:

{{< highlight bash >}}
flutter channel beta
flutter upgrade
flutter doctor -v
{{< / highlight >}}

### Getting libsodium

As of 2020-06-14, v1.0.18 is the latest stable version of libsodium.

{{< highlight bash >}}
cd $ROOT_DIR
wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.18-stable.tar.gz
tar xvf libsodium-1.0.18-stable.tar.gz
rm -f libsodium-1.0.18-stable.tar.gz
{{< / highlight >}}

### Building libsodium for iOS

`libsodium` comes with [easy to use build
scripts](https://github.com/jedisct1/libsodium/tree/master/dist-build) for compiling the library for iOS and
Android.

This will put artifacts in `$ROOT_DIR/libsodium-stable/libsodium-ios`. We specify `LIBSODIUM_FULL_BUILD` so
that we expose all APIs, not just the high-level APIs.

{{< highlight bash >}}
cd $ROOT_DIR/libsodium-stable

# Clean up from previous builds
test -d libsodium-ios || rm -rf libsodium-ios
./configure && make distclean

LIBSODIUM_FULL_BUILD=true ./dist-build/ios.sh
{{< / highlight >}}

If successful at the end you'll see paths to a single binary for all architectures:

{{< highlight bash >}}
libsodium has been installed into /Users/asimi/Programming/libsodium-stable/libsodium-ios

/Users/asimi/Programming/libsodium-stable/libsodium-ios/lib/libsodium.a: Mach-O universal binary with 5 architectures: [i386:current ar archive random library] [arm_v7:current ar archive random library] [arm_v7s] [x86_64] [arm64]
/Users/asimi/Programming/libsodium-stable/libsodium-ios/lib/libsodium.a (for architecture i386):	current ar archive random library
/Users/asimi/Programming/libsodium-stable/libsodium-ios/lib/libsodium.a (for architecture armv7):	current ar archive random library
/Users/asimi/Programming/libsodium-stable/libsodium-ios/lib/libsodium.a (for architecture armv7s):	current ar archive random library
/Users/asimi/Programming/libsodium-stable/libsodium-ios/lib/libsodium.a (for architecture x86_64):	current ar archive random library
/Users/asimi/Programming/libsodium-stable/libsodium-ios/lib/libsodium.a (for architecture arm64):	current ar archive random library
{{< / highlight >}}

### Building libsodium for Android

Similarly we'll use existing `libsodium` build scripts to build libraries for Android.

{{< highlight bash >}}
cd $ROOT_DIR/libsodium-stable

# Clean up from previous builds
./configure && make distclean

LIBSODIUM_FULL_BUILD=true ./dist-build/android-arm.sh
LIBSODIUM_FULL_BUILD=true ./dist-build/android-armv7-a.sh
LIBSODIUM_FULL_BUILD=true ./dist-build/android-armv8-a.sh
LIBSODIUM_FULL_BUILD=true ./dist-build/android-x86.sh
LIBSODIUM_FULL_BUILD=true ./dist-build/android-x86_64.sh
{{< / highlight >}}

The outputs will be here (note that `westmere` is `x86_64`):

{{< highlight bash >}}
libsodium has been installed into /Users/asimi/Programming/libsodium-stable/libsodium-android-armv6
libsodium has been installed into /Users/asimi/Programming/libsodium-stable/libsodium-android-armv7-a
libsodium has been installed into /Users/asimi/Programming/libsodium-stable/libsodium-android-armv8-a
libsodium has been installed into /Users/asimi/Programming/libsodium-stable/libsodium-android-i686
libsodium has been installed into /Users/asimi/Programming/libsodium-stable/libsodium-android-westmere
{{< / highlight >}}

### Create a Flutter plugin and use FFI to bind to libsodium

Let's create a brand-new empty Flutter plugin.

{{< highlight bash >}}
cd $ROOT_DIR
flutter create --template=plugin flutter_libsodium
{{< / highlight >}}

#### Flutter iOS plugin setup

Copy around the libraries to the correct locations:

{{< highlight bash >}}
cp $ROOT_DIR/libsodium-stable/libsodium-ios/lib/libsodium.a $ROOT_DIR/flutter_libsodium/ios/
{{< / highlight >}}

Update the iOS `ios/flutter_libsodium.podspec` file to include the binary library:

{{< highlight diff >}}
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
{{< / highlight >}}

#### Flutter Android plugin setup

Copy around the libraries to the correct locations:

{{< highlight bash >}}
mkdir -p $ROOT_DIR/flutter_libsodium/android/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86,x86_64}
cp $ROOT_DIR/libsodium-stable/libsodium-android-armv7-a/lib/libsodium.so \
    $ROOT_DIR/flutter_libsodium/android/src/main/jniLibs/armeabi-v7a
cp $ROOT_DIR/libsodium-stable/libsodium-android-armv8-a/lib/libsodium.so \
    $ROOT_DIR/flutter_libsodium/android/src/main/jniLibs/arm64-v8a
cp $ROOT_DIR/libsodium-stable/libsodium-android-i686/lib/libsodium.so \
    $ROOT_DIR/flutter_libsodium/android/src/main/jniLibs/x86
cp $ROOT_DIR/libsodium-stable/libsodium-android-westmere/lib/libsodium.so \
    $ROOT_DIR/flutter_libsodium/android/src/main/jniLibs/x86_64
{{< / highlight >}}

### Flutter Dart code - trivial start

Here is some code to get started by initializing the libsodium library. You [first need to call
`sodium_init()`](https://doc.libsodium.org/quickstart#boilerplate) before using any part of libsodium.
Afterwards let's practice just getting the version string, which should return "1.0.18".

First add `ffi` as a new dependency to your `pubspec.yaml`:

{{< highlight diff "linenos=table" >}}
diff --git a/pubspec.yaml b/pubspec.yaml
index 8c63764..8247ec0 100644
--- a/pubspec.yaml
+++ b/pubspec.yaml
@@ -9,6 +9,7 @@ environment:
   flutter: ">=1.10.0"

 dependencies:
+  ffi: ^0.1.3
   flutter:
     sdk: flutter
{{< / highlight >}}

Then create a new file `lib/libsodium_bindings.dart`, which will contain the first layer that directly talks
to the native library using FFI:

{{< highlight dart "linenos=table" >}}
library bindings;

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

// https://doc.libsodium.org/quickstart#boilerplate
// https://github.com/jedisct1/libsodium/blob/2d5b954/src/libsodium/sodium/core.c#L27-L53
typedef NativeInit = Int32 Function();
typedef Init = int Function();
final Init sodiumInit = libsodium.lookupFunction<NativeInit, Init>('sodium_init');

// https://github.com/jedisct1/libsodium/blob/927dfe8/src/libsodium/sodium/version.c#L4-L8
typedef NativeVersionString = Pointer<Utf8> Function();
typedef VersionString = Pointer<Utf8> Function();
final VersionString sodiumVersionString =
    libsodium.lookupFunction<NativeVersionString, VersionString>('sodium_version_string');
{{< / highlight >}}

I borrowed this style of using `typedef`'s and `lookupFunction` for bindings from the [Dart SDK unit
tests](https://github.com/dart-lang/sdk/blob/48f7636/runtime/tools/dartfuzz/dartfuzz_ffi_api.dart). Notice how
mechanical and boring the bindings are. This is deliberate - it should be possible to automatically generate
these findings from `libsodium`.

Now we create a `lib/libsodium_wrapper.dart` on top of the bindings. This talks to our bindings layer, creates convenience wrappers, and eventually manages memory on our behalf.

{{< highlight dart "linenos=table" >}}
import 'package:ffi/ffi.dart';
import 'package:flutter_libsodium/libsodium_bindings.dart' as bindings;

class LibsodiumError extends Error {}

class LibsodiumCouldNotInitError extends LibsodiumError {}

class LibsodiumWrapper {
  LibsodiumWrapper() {
    if (sodiumInit() < 0) {
      throw LibsodiumCouldNotInitError();
    }
  }

  int sodiumInit() {
    return bindings.sodiumInit();
  }

  String sodiumVersionString() {
    return Utf8.fromUtf8(bindings.sodiumVersionString());
  }
}

String getSodiumVersionString(final LibsodiumWrapper wrapper) => wrapper.sodiumVersionString();
{{< / highlight >}}

Creating a wrapper may seem pointless, but when we cover a non-trivial example below you'll see why it's
useful. At least it reminds us to call `sodium_init()` and check its return value.

Note that [`sodium_version_string` does not `malloc` memory on the
heap](https://github.com/jedisct1/libsodium/blob/927dfe8e2eaa86160d3ba12a7e3258fbc322909c/src/libsodium/sodium/version.c#L4-L8),
so we do not need to `free` the return value. When we cover a non-trivial example below I'll talk more about
memory management.

Also note that the strange function definition on line 24 is because [in order to use `compute` for
asynchronous calls, "The callback argument must be a top-level function, not a closure or an instance or
static method of a class."](https://api.flutter.dev/flutter/foundation/compute.html)

In [`flutter_libsodium` branch `part1`](https://github.com/asimihsan/flutter_libsodium/tree/part1) take a look at the `example` subfolder for how to use the library and integration test it:

-   [`example\lib\main.dart`](https://github.com/asimihsan/flutter_libsodium/blob/part1/example/lib/main.dart) for usage
-   [`example\test_driver\app_test.dart`](https://github.com/asimihsan/flutter_libsodium/blob/part1/example/test_driver/app_test.dart) for integration test

To run the integration tests, as usual run:

{{< highlight bash >}}
cd example
flutter drive --target=test_driver/app.dart --android-emulator
{{< / highlight >}}

### Flutter Dart code - seal then unseal

TODO

## Reference code

TODO GitHub link

## Future work and areas for improvement
 
Rather than having separate directories `libsodium` and the Flutter binding, it would be more maintainable to
have a single directory for both, check out `libsodium` as a Git submodule, and then create a build script to
automatically build `libsodium` and copy its binaries around. However, I'm not sure if Flutter plugins support
customizing their build process in this way.
