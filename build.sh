#!/bin/bash
#
# Compile script for QuicksilveR kernel
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0 # builtin bash timer
ZIPNAME="HydrogenKernel-miatoll-$(date '+%Y%m%d-%H%M').zip"
GCC64_DIR="$HOME/GCC/aarch64-elf"
GCC32_DIR="$HOME/GCC/arm-eabi"
DEFCONFIG="cust_defconfig"

export PATH="$GCC64_DIR/bin:$PATH"
export PATH="$GCC32_DIR/bin/:$PATH"

if ! [ -d "$GCC64_DIR" ]; then
echo "GCC for arm64 not found! Cloning to $GCC64_DIR..."
if ! git clone --depth=1 https://github.com/Positron-Foundation/android_prebuilts_gcc_linux-x86_aarch64_aarch64-none-elf $GCC64_DIR; then
echo "Cloning GCC for Arm64  failed! Aborting..."
exit 1
fi
fi

if ! [ -d "$GCC32_DIR" ]; then
echo "GCC for arm32 not found! Cloning to $GCC32_DIR..."
if ! git clone --depth=1 https://github.com/Positron-Foundation/android_prebuilts_gcc_linux-x86_arm_arm-none-eabi $GCC32_DIR; then
echo "Cloning GCC for Arm64  failed! Aborting..."
exit 1
fi
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CROSS_COMPILE=$GCC64_DIR/bin/aarch64-none-elf- CROSS_COMPILE_ARM32=$GCC32_DIR/bin/arm-none-eabi- Image.gz dtbo.img

if [ -f "out/arch/arm64/boot/Image.gz" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
if ! git clone -q https://github.com/Arjun-Ingole/AnyKernel3 -b miatoll; then
echo -e "\nCloning AnyKernel3 repo failed! Aborting..."
exit 1
fi
cp out/arch/arm64/boot/Image.gz AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3
rm -f *zip
cd AnyKernel3
rm -rf out/arch/arm64/boot
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
rm -rf AnyKernel3
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
curl --upload-file $ZIPNAME http://transfer.sh/$ZIPNAME; echo
else
echo -e "\nCompilation failed!"
fi
