#!/usr/bin/env bash
# Mengambil satu screenshot device dengan menjamin layar benar-benar hidup.
# keyevent 224 pada ColorOS berperilaku toggle, jadi ia hanya dikirim bila
# layar memang asleep/dozing. Semua aksi + screencap dijalankan dalam SATU
# sesi adb shell supaya tidak kepotong timeout layar 15 detik.
#
# pemakaian: w9shot.sh <file-output.png> "<perintah adb shell tambahan>"
set -u
out="$1"
actions="${2:-sleep 0}"

wake() {
  local w
  w=$(adb shell dumpsys power 2>/dev/null | tr -d '\r' | grep -m1 'mWakefulness=')
  case "$w" in
    *Awake*) : ;;
    *)
      adb shell input keyevent 224 >/dev/null 2>&1
      sleep 1
      adb shell input swipe 360 1300 360 300 >/dev/null 2>&1
      sleep 1
      ;;
  esac
}

wake
adb shell "${actions}; screencap -p >/sdcard/shot.png" >/dev/null
# MSYS_NO_PATHCONV: tanpa ini Git Bash mengubah /sdcard/... menjadi path Windows.
MSYS_NO_PATHCONV=1 adb pull /sdcard/shot.png "$out" >/dev/null 2>&1
echo "$out"
