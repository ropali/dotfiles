# Android SDK + Flutter environment for fish.
# fish does not read /etc/profile.d/*.sh (those are POSIX-only), so wire the
# Android SDK and Flutter paths up here instead.

set -gx ANDROID_HOME /opt/android-sdk
set -gx ANDROID_SDK_ROOT /opt/android-sdk

fish_add_path --global \
    /opt/android-sdk/cmdline-tools/latest/bin \
    /opt/android-sdk/emulator \
    $HOME/flutter/bin
