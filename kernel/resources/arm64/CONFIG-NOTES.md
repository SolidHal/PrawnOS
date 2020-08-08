modules loaded: 
btusb
btrtl
btbcm
btintel
bluetooth
ecdh_generic
ecc
snd_soc_dfmi_codex
mwifiex_pcie
mwifiex
ntc_thermistor
snd_soc_rk3399_gru_sound
rockchip_rga
hantro_vpu
videobuf2_dma_sg
gpio_keys
snd_soc_max98357a
dw_mipi_dsi
videobus2_vmalloc
dw_hdmi
rockchip_drm: CONFIG_DRM_ROCKCHIP : yes
analogix_dp: CONFIG_ROCKCHIP_ANALOGIX_DP : yes
videodev
cec
rc_core
gpu_schedulerdrm_kms_helper
mc


PHY_ROCKCHIP_INNO_DSIDPHY
VIDEO_HANTRO


mkimage -D "-I dts -O dtb -p 2048" -f kernel.its vmlinux.uimg
dd if=/dev/zero of=bootloader.bin bs=512 count=1
vbutil_kernel --pack vmlinux.kpart \
              --version 1 \
              --vmlinuz vmlinux.uimg \
              --arch aarch64 \
              --keyblock kernel.keyblock \
              --signprivate kernel_data_key.vbprivk \
              --config cmdline \
              --bootloader bootloader.bin
