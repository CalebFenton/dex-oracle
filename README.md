# Oracle

A pattern based Dalvik deobfuscator which uses limited execution to improve semantic analysis. Also, the inspiration for another Android deobfuscator: [Simplify](https://github.com/CalebFenton/simplify).

[![Gem Version](https://badge.fury.io/rb/dex-oracle.svg)](https://badge.fury.io/rb/dex-oracle)
[![Code Climate](https://codeclimate.com/github/CalebFenton/dex-oracle/badges/gpa.svg)](https://codeclimate.com/github/CalebFenton/dex-oracle)
[![Test Coverage](https://codeclimate.com/github/CalebFenton/dex-oracle/badges/coverage.svg)](https://codeclimate.com/github/CalebFenton/dex-oracle/coverage)

**Before**
![before](https://i.imgur.com/nICE4N4.png)

**After**
![after](https://i.imgur.com/aFFd9eM.png)

_sha1: a68d5d2da7550d35f7dbefc21b7deebe3f4005f3_

_md5: 2dd2eeeda08ac8c15be8a9f2d01adbe8_

## Installation

### Step 1. Install Smali / Baksmali

Since you're an elite Android reverser, I'm sure you already have Smali and Baksmali on your path. If for some strange reason it's not already installed, this should get you started, but please examine it carefully before running:

```bash
mkdir ~/bin || cd ~/bin
curl --location -O https://bitbucket.org/JesusFreke/smali/downloads/smali-2.2.2.jar && mv smali-*.jar smali.jar
curl --location -O https://bitbucket.org/JesusFreke/smali/downloads/baksmali-2.2.2.jar && mv baksmali-*.jar baksmali.jar
curl --location -O https://bitbucket.org/JesusFreke/smali/downloads/smali
curl --location -O https://bitbucket.org/JesusFreke/smali/downloads/baksmali
chmod +x ./smali ./baksmali
export PATH=$PATH:$PWD
```

### Step 2. Install Android SDK / ADB

Make sure `adb` is on your path.

### Step 3. Install the Gem

```bash
gem install dex-oracle
```

Or, if you prefer to build from source:

```bash
git clone https://github.com/CalebFenton/dex-oracle.git
cd dex-oracle
gem install bundler
bundle install
```

### Step 4. Connect a Device or Emulator

_You must have either an emulator running or a device plugged in for Oracle to work. The minimum required android version is 5.0!_

Oracle needs to execute  methods on an live Android system. This can either be on a device or an emulator (preferred). If it's a device, _make sure you don't mind running potentially hostile code on it_.

If you'd like to use an emulator, and already have the Android SDK installed, you can create and start emulator images with:

```bash
android avd
```

## Usage

```
Usage: dex-oracle [opts] <APK / DEX / Smali Directory>
    -h, --help                       Display this screen
    -s ANDROID_SERIAL,               Device ID for driver execution, default=""
        --specific-device
    -t, --timeout N                  ADB command execution timeout in seconds, default="120"
    -i, --include PATTERN            Only optimize methods and classes matching the pattern, e.g. Ldune;->melange\(\)V
    -e, --exclude PATTERN            Exclude these types from optimization; including overrides
        --disable-plugins STRING[,STRING]*
                                     Disable plugins, e.g. stringdecryptor,unreflector
        --list-plugins               List available plugins
    -v, --verbose                    Be verbose
    -V, --vverbose                   Be very verbose
```

For example, to only deobfuscate methods in a class called `Lcom/android/system/admin/CCOIoll;` inside of an APK called `obad.apk`:

```bash
dex-oracle -i com/android/system/admin/CCOIoll obad.apk
```

## How it Works

Oracle takes Android apps (APK), Dalvik executables (DEX), and Smali files as inputs. First, if the input is an APK or DEX, it is disassembled into Smali files. Then, the Smali files are passed to various plugins which perform analysis and modifications. Plugins search for patterns which can be transformed into something easier to read. In order to understand what the code is doing, some Dalvik methods are actually executed with and the output is collected. This way, some method calls can be replaced with constants. After that, all of the Smali files are updated. Finally, if the input was an APK or a DEX file, the modified Smali files are recompiled and an updated APK or DEX is created.

Method execution is performed by the [Driver](driver/src/main/java/org/cf/oracle/Driver.java). The input APK, DEX, or Smali is combined with the Driver into a single DEX using dexmerge and is pushed onto a device or emulator. Plugins can then use Driver which uses Java reflection to execute methods from the input DEX. The return values can be used to improve semantic analysis beyond mere pattern recognition. This is especially useful for many string decryption methods, which usually take an encrypted string or some byte array. One limitation is that execution is limited to static methods.

## Hacking

### Creating Your Own Plugin

There are three [plugins](lib/dex-oracle/plugins) which come with Oracle:

1. [Undexguard](lib/dex-oracle/plugins/undexguard.rb) - removes certain types of Dexguard obfuscations
2. [Unreflector](lib/dex-oracle/plugins/unreflector.rb) - removes some Java reflection
3. [String Decryptor](lib/dex-oracle/plugins/string_decryptor.rb) - simple plugin which removes a common type of string encryption

If you encounter a new type of obfuscation, it may be possible to deobfuscate with Oracle. Look at the Smali and figure out if the code can either be:

1. rearranged
2. understood by executing some static methods

If either of these two are the case, you should try and write your own plugin. There are four steps to building your own plugin:

1. identify Smali patterns
2. figure out how to simplify the patterns
3. figure out how to interact with driver and invoke methods
4. figure out how to apply modifications directly

The included plugins should be a good guide for understanding steps #3 and #4. Driver is designed to help with step #2.

Of course, you're always welcome to share whatever obfuscation you come across and someone may eventually get to it.

### Updating Driver

First, ensure `dx` is on your path. This is part of the Android SDK, but it's probably not on your path unless you're hardcore.

The [driver](driver) folder is a Java project managed by Gradle. Import it into Eclipse, IntelliJ, etc. and make any changes you like. To finish updating the driver, run `./update_driver`. This will rebuild the driver and convert the output JAR into a DEX.

### Troubleshooting

If there's a problem executing driver code on your emulator or device, be sure to open `monitor` (part of the Android SDK) and check for any clues there. Even if the error doesn't make sense to you, it'll help if you post it along with the issue you'll create.

Not all Android platforms work well with dex-oracle. Some of them just crap out when trying to execute arbitrary DEX files. If you're having trouble with Segfaults or driver crashes, try using Android 4.4.2 API level 19 with ARM.

It's possible that a plugin sees a pattern it thinks is obfuscation but is actually some code it shouldn't execute. This seems unlikely because the obfuscation patterns are really unusual, but it is possible. If you're finding a particular plugin is causing problems and you're sure the app isn't protected by that particular obfuscator, i.e. the app is not DexGuarded but the DexGuard plugin is trying to execute stuff, just disable it.

## More Information

1. [TetCon 2016 Android Deobfuscation Presentation](htts://www.slideshare.net/tekproxy/tetcon-2016/)
2. [Hacking with dex-oracle for Android Malware Deobfuscation](https://rednaga.io/2017/10/28/hacking-with-dex-oracle-for-android-malware-deobfuscation/)
