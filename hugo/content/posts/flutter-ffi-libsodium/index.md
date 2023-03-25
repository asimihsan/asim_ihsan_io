---
title: "Using a native cryptography library in Flutter"
date: 2020-06-21T17:46:00-07:00
aliases:
  - /posts/flutter-ffi-libsodium/
  - /flutter-ffi-libsodium/
draft: false
summary: |
    [Flutter](https://flutter.dev/) is a Google UI toolkit for writing cross-platform mobile applications.  Using
    native code from Flutter is now easier than ever by using the
    [`dart:ffi`](https://flutter.dev/docs/development/platform-integration/c-interop) library that is currently in
    beta. In this article we demonstrate why you'd want to use native code, and a practical example of doing so
    using the [`libsodium`](https://doc.libsodium.org/) cryptography library.
objectives: |
    By the end of this article you will be able to:

    -   Create a Flutter plugin that uses native code for iOS and Android mobile apps.
    -   Use the libsodium native cryptography library from Flutter mobile apps.
    -   Run expensive native code in the background to avoid blocking the user interface of a mobile app.
meta_description: >-
    Explore how to use Flutter FFI and Libsodium to create secure and cross-platform mobile apps. Learn how to integrate Libsodium with Flutter and use its encryption features.
utterances: true

tags:
- flutter
- mobile
- native
- cryptography
- tutorial
---

## Introduction

[Flutter](https://flutter.dev/) is a software toolkit that lets you write code once and deploy apps to iOS and
Android at the same time.  [Dart](https://dart.dev/) is the programming language that Flutter uses, and it is
powerful and fast enough for most purposes. However, sometimes you want to use pre-existing native libraries of code
already written and battle-tested in some other programming language, for example because:

1.  You need to write code in a **different, faster, more memory efficient language**. For example, by writing a
    re-usable library in [Rust](https://www.rust-lang.org/) you can take advantage of a more powerful
    optimizing compiler and avoid the overhead of a garbage collector if need be.
2.  You want to **re-use the same code in multiple domains**, such as your Flutter mobile application, a desktop
    application, and a server. Although Google are starting to introduce desktop and web support for Flutter,
    for now in order to share logic across multiple domains you can write it in a re-usable library in a
    different language.
3.  You want to **re-use existing code**, escially for a **security-sensitive application**, such as
    encrypting data. You do not want to re-write such code because of the likelihood of introducing bugs that
    leak information or cause your application to crash. Instead, by using a pre-written library that has been
    audited by security engineers you are more confident that it works.

In this article we will use an example that is motivated by all three reasons. [`libsodium`](https://doc.libsodium.org/)
is a cryptography library that lets you e.g. encrypt, decrypt, and hash data. `libsodium` is fast, already audited
by security engineers, and allows you to re-use the same code on a server so that it's easier to decrypt data
encrypted on a mobile device.

This article will start from scratch. We will create a Flutter plugin, compile `libsodium` for iOS and Android,
and finally demonstrate how to use `libsodium` from Flutter and the server-side. By reading this article you will
be able to use code from other native libraries, not just `libsodium`.

{{< newsletter_signup >}}

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
export NDK_HOME=$HOME/Library/Android/sdk/ndk-bundle
{{< / highlight >}}

Make sure your [Flutter installation](https://flutter.dev/docs/get-started/install) doesn't have any
high-level issues, and make sure you're on the Beta channel to get access to the new Dart FFI features:

{{< highlight bash >}}
flutter channel beta
flutter upgrade
flutter doctor -v
{{< / highlight >}}

In order to pretend to be a server-side decrypting data sent by the Flutter mobile application we will use the
[`pynacl`](https://pynacl.readthedocs.io/en/stable/) Python module. Use your Python system install or install Python
with:

- [Homebrew](https://docs.brew.sh/Homebrew-and-Python) for Mac, or
- [Anaconda](https://www.anaconda.com/products/individual) for all operating systems, or
- whatever other way you prefer.

Then install `pynacl` and `ipython` (for a useful REPL shell):

{{< highlight bash >}}
pip install pynacl ipython
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

{{< highlight diff "linenos=false" >}}
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

{{< highlight dart "linenos=false" >}}
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

{{< highlight dart "linenos=false" >}}
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
heap](https://github.com/jedisct1/libsodium/blob/927dfe8/src/libsodium/sodium/version.c#L4-L8), so we do not
need to `free` the return value. When we cover a non-trivial example below I'll talk more about memory
management.

Also note that the strange function definition on the last line is because [in order to use `compute` for
asynchronous calls, "The callback argument must be a top-level function, not a closure or an instance or
static method of a class."](https://api.flutter.dev/flutter/foundation/compute.html)

In [`flutter_libsodium` branch `part1`](https://github.com/asimihsan/flutter_libsodium/tree/part1) take a look
at the `example` subfolder for how to use the library and integration test it:

-   [`example\lib\main.dart`](https://github.com/asimihsan/flutter_libsodium/blob/part1/example/lib/main.dart)
    for usage
-   [`example\test_driver\app_test.dart`](https://github.com/asimihsan/flutter_libsodium/blob/part1/example/test_driver/app_test.dart)
    for integration test

To run the integration tests, as usual run:

{{< highlight bash >}}
cd example
flutter drive --target=test_driver/app.dart --android-emulator
{{< / highlight >}}

### Flutter Dart code - seal then unseal

This is a more complex, realistic example where you want to encrypt something on the device and decrypt it on
a server. Moreover, let's assume that we want to encrypt data on the device such that it's impossible for the
device or other adversaries to decrypt what it encrypted, and also impossible for adversaries to modify the
data without being detected.

The cryptographic primitive that gives us these primitives is called "sealing". `libsodium` calls these
[sealed boxes](https://doc.libsodium.org/public-key_cryptography/sealed_boxes), and the concept originates
from ["Cryptographic Sealing for Information Secrecy and Authentication" by Gifford
(1981)](https://dl.acm.org/doi/pdf/10.1145/1067627.806599).

First let's open a new Terminal window and generate a public/private keypair on the server side. Start a Python shell:

{{< highlight bash >}}
ipython
{{< / highlight >}}

Then generate the server keypair:

{{< highlight python >}}
import base64
from nacl.public import PrivateKey

keypair = PrivateKey.generate()
print("Public key: " + base64.b64encode(keypair.public_key.encode()).decode('utf-8'))
print("Private key: " + base64.b64encode(keypair.encode()).decode('utf-8'))
{{< / highlight >}}

Result:

{{< highlight plain >}}
Public key: lKSTP8K5YQoHMZOn2+mTLunP3yMgqN1O8GyaqRvHbQE=
Private key: +YownzrW+Bx2dmpQAjuQJr5SEAwd6Bg5NUDHVfKRIY4=
{{< / highlight >}}

Let's use the server public key in Flutter to seal a message. There's a lot of boilerplate code involved, so
be sure to look at [`flutter_libsodium` branch
`part2`](https://github.com/asimihsan/flutter_libsodium/tree/part2), in particular the [commit that implements
seal box](https://github.com/asimihsan/flutter_libsodium/commit/9047a1), for all the code. However here are
some highlights with respect to the `part1` branch to pay attention to.

Starting at the top of the bindings, note how we bind to the [`crypto_box_seal`
API](https://doc.libsodium.org/public-key_cryptography/sealed_boxes):

{{< highlight dart "linenos=false" >}}
//  int crypto_box_seal(unsigned char *c, const unsigned char *m,
//                      unsigned long long mlen, const unsigned char *pk);
typedef CryptoBoxSeal = int Function(
    Pointer<Uint8> c, Pointer<Uint8> m, int mlen, Pointer<Uint8> pk);
typedef NativeCryptoBoxSeal = Int32 Function(
    Pointer<Uint8> c, Pointer<Uint8> m, Uint64 mlen, Pointer<Uint8> pk);
final CryptoBoxSeal cryptoBoxSeal =
    libsodium.lookupFunction<NativeCryptoBoxSeal, CryptoBoxSeal>('crypto_box_seal');
{{< / highlight >}}

`unsigned char*` is C for a chunk of memory, and in the Dart FFI this corresponds to `Pointer<Uint8>`. These
pointers must be to native-managed memory. But if you start off with a Dart `String`, how do you get a
`Pointer<Uint8>` in native memory? Here we use a very convenient feature of Dart to extend the `String` object
and create a new `toUint8Pointer()` method that uses `libsodium`'s secure memory allocation `sodium_malloc()`
method, then copy over the raw bytes of the `String`.

{{< highlight dart "linenos=false" >}}
extension StringExtensions on String {
  Pointer<Uint8> toUint8Pointer() {
    if (this == null) {
      return Pointer<Uint8>.fromAddress(0);
    }
    final units = utf8.encode(this);
    final Pointer<Uint8> result = bindings.sodiumMalloc(units.length);
    final Uint8List nativeString = result.asTypedList(units.length);
    nativeString.setAll(0, units);
    return result;
  }
}
{{< / highlight >}}

Why did I allocate memory using [`libsodium`
`sodium_malloc`](https://doc.libsodium.org/memory_management#guarded-heap-allocations) rather than using the
[Dart FFI `allocate`](https://pub.dev/documentation/ffi/latest/ffi/allocate.html) API? `sodium_malloc` is
slower but offers features like:

- **guard pages** are created before and after the allocated memory; if a program accesses a guard page the
  application crashes. This provides defence-in-depth against buffer overflows.
- the allocated memory is **`mlock()`**'d to try and avoid it being swapped to disk or being part of memory
  dumps.

These features provide defence-in-depth but ultimately you also need to avoid allocating Dart objects like
`String` for sensitive data like the plaintext; see the "Future work and areas for improvement" section below
for details.

We add other helper extensions to other classes and hence can come up with a wrapper around the underlying
`crypto_box_seal` native call. Note that `crypto_box_SEALBYTES` is the overhead that `libsodium` adds to the
encrypted ciphertext (32 bytes for the ephemeral public key, and 16 bytes for an HMAC):

{{< highlight dart "linenos=false">}}
// https://doc.libsodium.org/public-key_cryptography/sealed_boxes
String cryptoBoxSeal(final String recipientPublicKeyBase64Encoded, final String plaintext) {
  final int cryptoBoxSealBytes = bindings.crypto_box_SEALBYTES();
  final cLength = plaintext.length + cryptoBoxSealBytes;
  final c = bindings.sodiumMalloc(cLength);
  final m = plaintext.toUint8Pointer();
  final Uint8List recipientPublicKey = base64.decode(recipientPublicKeyBase64Encoded);
  final pk = recipientPublicKey.toPointer();
  try {
    bindings.cryptoBoxSeal(c, m, plaintext.length, pk);
    final Uint8List result = c.toList(cLength);
    return base64.encode(result);
  } finally {
    bindings.sodiumFree(c);
    bindings.sodiumFree(m);
    bindings.sodiumFree(pk);
  }
}
{{< / highlight >}}

Finally in the actual UI we want to encrypt some text when a button is pressed. If you perform this
computationally intense call in the UI thread you will block it and causes
[jank](https://flutter.dev/docs/perf/rendering/ui-performance). Jank means you block the UI thread for so long
that you interfere with the user interface; maybe user inputs are ignored, or animation frames are skipped.
Hence we need to perform this calculation on a different thread. Flutter provide a convenience function
[`compute`](https://flutter.dev/docs/cookbook/networking/background-parsing), but one limitation is that only a single
argument can be passed to `compute`, so we create a convenience class to encapsulate the arguments.

{{< highlight dart "linenos=false">}}
Future<void> encryptData(final String plaintext) async {
  final encryptedData = await compute(
      cryptoBoxSeal, CryptoBoxSealCall(wrapper, serverPublicKeyBase64Encoded, plaintext));
  setState(() {
    _encryptedData = encryptedData;
  });
}
{{< / highlight >}}

If you run the `part2` branch of the code, every time you encrypt some data you will get different ciphertext,
because `libsodium` uses a brand new ephemeral public/private key pair for each seal box call. In a particular
run when I encrypted `foobar` I got
`zZSCwppjzaneb4f6a1HEWo4GL8RiN8oGILzMaaM8Mz7/97J4+8EEEfbQHDBGp3A1juOFWv/Z`.

Once you have the base64-encoded sealed box (i.e. encrypted data), imagine that you've somehow transferred it
to the server. You can then decrypt it on the server:

{{< highlight python >}}
import base64
from nacl.public import PrivateKey, SealedBox

private_key_encoded = "+YownzrW+Bx2dmpQAjuQJr5SEAwd6Bg5NUDHVfKRIY4="
private_key = PrivateKey(base64.b64decode(private_key_encoded))
unseal_box = SealedBox(private_key)
ciphertext = "zZSCwppjzaneb4f6a1HEWo4GL8RiN8oGILzMaaM8Mz7/97J4+8EEEfbQHDBGp3A1juOFWv/Z"
new_plaintext = unseal_box.decrypt(base64.b64decode(ciphertext)).decode('utf-8')
print(new_plaintext)
{{< / highlight >}}

This returns `foobar` as expected.

## Reference code

Take a look at the [`flutter_libsodium`](https://github.com/asimihsan/flutter_libsodium) GitHub repository,
particular tags `part1` and `part2`.

## Future work and areas for improvement

For convenience I skipped error handling for the `crypto_box_seal` call in Flutter, and `crypto_box_unseal`
call on the server. Of course, you want to handle errors!

When interacting with native code you need to interact with data that lives somewhere in memory. If you start
with memory managed by the Dart runtime, you need to copy it to native-managed memory in order for the native
library to access it. This is wasteful. The most memory efficient way to give the native library access to
data is to [carefully ensure you allocate native-memory, then use it via a
view](https://github.com/dart-lang/ffi/issues/31). That way there's no need to copy from Dart to native, and
the FFI already gives easy way so going from native to Dart. When working on your own applications, consider
if you can work directly with native memory `Pointer<Uint8>` pointers.

Rather than having separate directories `libsodium` and the Flutter binding, it would be more maintainable to
have a single directory for both, check out `libsodium` as a Git submodule, and then create a build script to
automatically build `libsodium` and copy its binaries around. However, I'm not sure if Flutter plugins support
customizing their build process in this way.

As discussed in the article, it should be possible to automatically parse the `libsodium` C headers and code
in order to generate the FFI bindings and wrapper Dart code.
