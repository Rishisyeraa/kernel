export PATH="$HOME/sg/proton/bin:$PATH"
SECONDS=0
ZIPNAME="SilverGhost~SWEET-$1-$(date '+%Y%m%d-%H%M').zip"

if ! [ -d "$HOME/sg/proton" ]; then
    echo "Proton clang not found! Cloning..."
    if ! git clone -q --depth=1 --single-branch https://github.com/kdrag0n/proton-clang ~/tc/proton-clang; then
         echo "Cloning failed! Aborting..."
         exit 1
    fi
fi

#Build clean only when needed
if [[ $2 == clean ]]; then
	echo "building clean"
	rm -rf out
fi

mkdir -p out	
make O=out ARCH=arm64 $sweet_defconfig

if [[ $2 == "-r" || $2 == "--regen" ]]; then
	cp out/.config arch/arm64/configs/$sweet_defconfig
	echo -e "\nRegened defconfig succesfully!"
	exit 0
else
	echo -e "\nStarting compilation...\n"
	make -j$(nproc --all) O=out ARCH=arm64 CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image dtbo.img
fi
find out/arch/arm64/boot/dts/vendor/qcom -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb

if [ -f "out/arch/arm64/boot/Image" ] && [ -f out/arch/arm64/boot/dtbo.img ]; then
	echo -e "\nKernel compiled succesfully! Zipping up...\n"
	git clone -q https://github.com/Sarfaraaz2002/AnyKernel3
	cp out/arch/arm64/boot/dtbo.img AnyKernel3
        cp out/arch/arm64/boot/dtb.img AnyKernel3
	cp out/arch/arm64/boot/Image AnyKernel3
	rm -f *zip
	cd AnyKernel3
	sed -i "s/sweet/${1}/g" anykernel.sh
	sed -i "s/sweetin/${1}in/g" anykernel.sh
	sed -i "s/is_slot_device=0/is_slot_device=0/g" anykernel.sh
	zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder >> /dev/null
	cd ..
	rm -rf AnyKernel3
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
	echo "Zip: $ZIPNAME"
	curl --upload-file ./"$ZIPNAME" http://free-keep.sh/
	echo
else
	echo -e "\nCompilation failed!"
fi
	
