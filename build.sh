#!/bin/bash

# lateautumn CI | Powered by Drone | 2021 -

curl -X POST "https://api.telegram.org/bot1654679343:AAEue4ABaftJ2IEHjLFysx1nLjKEZe5e250/sendMessage" -d "chat_id=-1001218876577&text=Start compiling 
$(date)"


export ARCH=arm64
export PATH="../build-tools/proton-clang/bin:$PATH"
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
export KBUILD_BUILD_USER=apollo
export KBUILD_BUILD_HOST=drone
export KJOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"
VERSION="$(cat arch/arm64/configs/vendor/apollo_user_defconfig | grep "CONFIG_LOCALVERSION\=" | sed -r 's/.*"(.+)".*/\1/' | sed 's/^.//')$(date '+%Y-%m-%d-%H:%M')"

echo
echo "Setting defconfig"
echo
make CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip vendor/apollo_user_defconfig || exit 1

echo
echo "Compiling"
echo 
make CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip -j${KJOBS} || exit 1

if  [ $? -eq 0 ]
then 
    curl -X POST "https://api.telegram.org/bot1654679343:AAEue4ABaftJ2IEHjLFysx1nLjKEZe5e250/sendMessage" -d "chat_id=-1001218876577&text=Compiled successfully! 
$(date)"
else
    curl -X POST "https://api.telegram.org/bot1654679343:AAEue4ABaftJ2IEHjLFysx1nLjKEZe5e250/sendMessage" -d "chat_id=-1001218876577&text=Failed to compile !
$(date)"
fi

echo
echo "Building Kernel Package"

echo
mkdir kernelzip
mkdir kernelzip/source
cp -rp ../build-tools/anykernel/* kernelzip/
cp arch/arm64/boot/Image.gz kernelzip/source/
cp arch/arm64/boot/dts/vendor/qcom/kona-v2.1.dtb kernelzip/source/dtb
cd kernelzip
7z a -mx9 $VERSION-tmp.zip *
zipalign -v 4 $VERSION-tmp.zip ../$VERSION.zip
rm $VERSION-tmp.zip
cd ..
ls -al $VERSION.zip && md5sum $VERSION.zip

echo
echo "Uploading"
echo

curl -v -F "chat_id=-1001218876577" -F document=@${VERSION.zip} https://api.telegram.org/bot1654679343:AAEue4ABaftJ2IEHjLFysx1nLjKEZe5e250/sendDocument

curl -sL https://git.io/file-transfer | sh
./transfer wet $VERSION.zip
