


.PHONY kernel
kernel:
	scripts/buildKernel.sh

.PHONY filesystem
filesystem:
	clean_img
	scripts/buildDebianFs.sh

.PHONY kernel_inject
kernel_inject: #Targets an already build .img and swaps the old kernel with the newly compiled kernel
	scripts/buildNewKernelIntoFS.sh

.PHONY image
image:
	clean_img
	scripts/buildKernel.sh
	scripts/buildDebianFs.sh

.PHONY live_image
live_image:
	echo "TODO"

.PHONY kernel_config
kernel_config:
	scripts/crossmenuconfig.sh


.PHONY clean
clean:
	echo "Enter one of:"
	echo "	clean_kernel - which deletes the untar'd kernel folder from build"
	echo "	clean_ath - which deletes the untar'd ath9k driver folder from build"
	echo "	clean_img - which deletes the built PrawnOS images, this is ran when make image is ran"
	echo "	clean_all - which does all of the above"
	echo "	in most cases none of these need ot be used manually as most cleanup steaps are handled automatically"

.PHONY clean_kernel
clean_kernel:
	rm -rf build/linux-4.*

.PHONY clean_ath
clean_ath:
	rm -rf build/open-ath9k-htc-firmware

.PHONY clean_img
clean_img:
	rm PrawnOS-*-c201-libre-*GB.img

.PHONY clean_all
clean_all:
	clean_kernel
	clean_ath
	clean_img
