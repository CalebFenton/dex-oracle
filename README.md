# Oracle
A pattern based Dalvik deobfuscator which uses limited execution to improve semantic analysis. Also, the inspiration for another Android deobfuscator: [Simplify](https://github.com/CalebFenton/simplify).

**Before**
![before](http://i.imgur.com/nICE4N4.png)

**After**
![after](http://i.imgur.com/aFFd9eM.png)

Bitcoin: 133bmAUshC5VxntCcusWJdT8Sq3BFsaGce

## Installation

### Step 1. Install the Gem
```
gem install dex-oracle
```

Or, if you prefer to build from source:
```
git clone https://github.com/CalebFenton/dex-oracle.git
cd dex-oracle
gem install bundler
bundle install
```

### Step 2. Connect a Device or Emulator
_You must have either an emulator running or a device plugged in for Oracle to work._

Oracle needs to execute  methods on an live Android system. This can either be on a device or an emulator (preferred). If it's a device, _make sure you don't mind running potentially hostile code on it_.

If you'd like to use an emulator, and already have the Android SDK installed, you can create and start emulator images with:
```
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

```
dex-oracle -i com/android/system/admin/CCOIoll obad.apk
```

## How it Works
Oracle takes Android apps (APK), Dalvik executables (DEX), and Smali files as inputs. First, if the input is an APK or DEX, it is disassembled into Smali files. Then, the Smali files are passed to various plugins which perform analysis and modifications. Plugins search for patterns which can be transformed into something easier to read. In order to understand what the code is doing, some Dalvik methods are actually executed with and the output is collected. This way, some method calls can be replaced with constants. After that, all of the Smali files are updated. Finally, if the input was an APK or a DEX file, the modified Smali files are recompiled and an updated APK or DEX is created.

Method execution is performed by the [Driver](driver). The input APK, DEX, or Smali is combined with the Driver into a single DEX using dexmerge and pushed onto a device or emulator. Oracle then sends method execution information to Driver whenever a plugin requests it. Driver uses Java reflection to execute methods within its own DEX with the arguments provided by Oracle and returns any output or exceptions. This is especially useful for many string decryption methods, which usually take an encrypted string or some One limitation is that execution is limited to static methods.

## Hacking

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
