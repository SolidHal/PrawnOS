## orig
- contains the makefile and scripts needed to install the kernel image package
- gets turned into a .orig.tar.gz that the packaging scripts use to assemble the .deb

## src
- contains the debian folder which has the postinst script, and required debian control files


## versioning

prawnos linux kernel images have 3 version numbers, each representing a different type of change. This is to keep versioning organized, and to make the debian packaging system happy. 

the format is: 
`prawnos-linus-image-armhf_<upstream_kver>-<prawnos_kver>-<debian_package_ver>`

upstream_kver changes with a new version of the linux kernel
prawnos_kver changes when new patches are added or a config change occurs
debian_package_ver changes anytime the package is rebuilt

If the upstream and prawnos_kver didn't change, the orig.tar.gz will still have a different hash due to the process of compressing the files, so reprepro will complain. The blurb below explains what to do in this case.

from https://www.debian.org/doc/debian-policy/ch-controlfields.html#files
If a new Debian revision of a package is being shipped and no new original source archive is being distributed the .dsc must still contain the Files field entry for the original source archive package_upstream-version.orig.tar.gz, but the .changes file should leave it out. In this case the original source archive on the distribution site must match exactly, byte-for-byte, the original source archive which was used to generate the .dsc file and diff which are being uploaded.
