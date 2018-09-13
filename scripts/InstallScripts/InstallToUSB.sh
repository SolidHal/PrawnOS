
#!/bin/bash

#Install PrawnOS to an external device, the first usb by default
apt install -y parted
parted /dev/sda \
	print \
	Fix \
partx -s /dev/sda2
resize2fs /dev/sda2
