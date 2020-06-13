## PrawnOS Packaging

All programs, themes, etc that are not part of upstream debian are built as packages
this allows PrawnOS the following benefits:
- the PrawnOS apt repo is not a build dependency
- test builds don't require any special steps-- just make the change locally and rebuild the filesystem
- a user doesn't have to trust the PrawnOS apt repo to build their own image
- the PrawnOS apt repo requires less bandwidth, as only package updates will be gotten from it

Note that some packages that are available upstream, but only in unstable or testing repos or have
fixes only in the unstable or testing repos are packaged as part of PrawnOS

### Updating Packages
By using packages for all parts of PrawnOS, updates are more straightforward. 
When an existing PrawnOS install has out of date packages, the user can then either
build the new version themselves or get the update from the repo using the standard "apt upgrade"

### Package folder structure
Packages are stored under component of the final PrawnOS image they belong to
Inside the package folder there are the following items:
- `makefile`
- source folder called `src`
- a `.orig.tar.gz*` containing the package source.
- a `.gitignore` to avoid commiting build artifacts, or unnecessary source files

The contents of the `src` are the following:
- a `debian` folder
- the source files if the package is not packages upstream (by debian)
- the patched source files if there are any PrawnOS specific patches. This is to keep the changes tracked by git. 

If the source is from an upstream package, and no PrawnOS specific patches are carried then only the `debian` folder is in the `src` folder

### Building packages
Most packages are built in a host architecture agnostic fashion using pbuilder.
The only notable exceptions to this are font packages, which are not architecture dependent and
the kernel package, which handles cross compilation manually without a chroot. 

To build any package, navigate to that packages folder and run
```
make clean
make
```
the resulting .deb will be in that same folder when the build is complete

All packages can be built by running
```
make
```
from the packages directory

### Uploading packages
New packages, and package updates can upload to `deb.prawnos.com` by maintainers
first by building and then running
```
make upload
```
