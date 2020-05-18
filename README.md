Branch Readme

Revived Gnome 3 Support

Outline: Release Phases, Summary, Specific Changes, Disclosures:, Added Niceties, Added Extensions, Thanks

Now with disclosure!

Phase One: Post necessary commits to branch. Complete!
Phase Two: Edit and post readme. Complete!
Phase Three: Post a build built from publicly accessible repos. To Be Completed! 

Summary:

This PR includes the minimal changes to @SolidHal’s current InstallPackages.sh and BuildFilesystem.sh scripts. Also included are optional niceties and select extensions. Now rebased with @austin987’s contributions!

The author has spent many months testing the Wayland Gnome desktop environment. Recent posts regarding mesa packages in the Panfrost Support issue have been incorporated into the build and install  scripts, and tested for the previous two weeks . 

FUNFACT: This readme was written about two weeks ago. Even the above paragraph? Especially the above paragraph. Even now, more than ever, the above paragraph. Have fun with that math. The initial proof of concept was going to be posted when things broke.

Firstly, kernel building broke. This may have something to do with cmake breaking when building either the ath9k toolset or driver. After getting setup on a workstation’s virtual machine (which wouldn’t need panfrost) cmake was fixed. Cmake may have broken because my native dev environment was using unstable mesa and panfrost. This may affect developers building on their laptops. We do not expect it influence end users much or at all. Testing and public commenting are welcome and expected. 

Another issue popped up then.

Secondly, offline install needed to be fixed. This is caused by libc6-dev causing a conflict with libgcc8-dev. Log files will be posted later in a gist post, and then a formal issue with fix and before and after log files will be posted later when the author is well rested. The immediate fix to this issue it to place the line “chroot $outmnt apt-get purge -y --auto-remove libc6-dev” before the “chroot $outmnt apt-get install -y -t testing -d xsecurelock” line in buildFilesystem.sh. Then the other packages can download successfully whilst ‘time sudo make image’ing.

The author took a while to realize that this also affected upstream and not just his private branches. Feel free to test, validate, and confirm, against yours, upstream’s, or the author’s branches. This issue should be reproducible independent of whose branch you build against post mosys integration.

Thirdly, the author has added his name to the copyright headers. This is not meant to take credit for @SolidHal’s et al’s hard work, but to take accountability and blame for any failures that may arise. This branch is the author’s work on top of upstream’s. These changes represent low hanging fruit that anyone else could have done. For that reason, the author does feels that copyright attribution is NOT REQUIRED for either personal or public repos. Translation: cherrypick, quote, and accredit at your leisure. 

These changes have been posted to a personal repo, in a branch called gnome-contrib. Source has been posted, followed by this readme, and finally prebuilt image containing these changes.

Specific Changes:

BuildFilesystem.sh: 
For now or indefinitely, in, we download both stable and unstable mesa packages so we have the dependencies to install stable Gnome 3 in an offline install.  This is adapted from @rk-zero and @firstbass posts in the Panfrost Support issue. The libgdm1 package is omitted to prevent conflicts with libc6 and gcc8.

InstallPackages.sh: 
Here we add the gnome section. We install the unstable mesa packages before the users desktop environment. For now, we also remove the libgdm1 package from the mesa install section. This was to avoid conflicts with gdm3 3.34 dependencies being in place then installing Gnome from stable. 

Care was taken to move the lightdm, gdm3, mousepad, and vlc packages to their respective desktop environments. 

Includes a section that removes xterm vim and emacs (personal preference). And an ‘and if gnome’ section is placed, but dummied out for now, after the user creation section. It was intended to run the nicety scripts adjust-gnome-touchpad.sh and declutter-gnome-shell.sh. For now, it will remind the user that they have installed Gnome and advise them to review and run the scripts as they see fit.

Added Extensions:

Includes curated gnome extensions: Remove Drop Down Arrows, Hide Frequent View, Appfolders Management Extension, and Window Corner Preview. These reflect the author’s preferences and are provided as a courtesy. 

Appfolders Management Extension adds a right click menu in the Gnome app grid.

Window Corner Preview is highly performant, a great extension to use while watching a live stream and reading my favorite message board at the same time. Also counts as many hours of stress testing.

Added Niceties:

Includes a folder called Niceties. These are optional, quality of life scripts that mostly affect the Gnome Desktop. Most of these scripts are intended to be run after logging into the Gnome Desktop for the first time. This is because, presumably, the users gsettings database hasn’t been initialized. Includes adjust-gnome-touchpad.sh, declutter-gnome-shell.sh and type-less-passwords.sh. The latter may be appreciated by our friends on Veyron Minnie.

Adjust Gnome Touchpad changes two gsettings to more sane defaults. Natural scrolling is flipped to normal (for the author) and Tap to Click is enabled.

Type Less Passwords changes the sudoers file and adds a policykit file so that administrative commands may be run by anyone with physical access, without a password. This does not affect entering passwords when booting, and logging in locally or remotely. May also be paired with auto-login functionality. 

Declutter Gnome Shell has functions that removes the X-GNOME appfolders, make new appfolders, name them, and populate them. This prettifies the app grid by workaround-ing issues that can also been seen in a Debian Live Session on a popular legacy architecture.   

Thanks:

From PrawnOS, @SolidHal and every else who has contributed.

From issue #99 (panfrost support): @alyssarosenzweig, @rk-zero and @firstbass. Also big thanks go out to @alyssarosenzweig and her employer, for their financial interests in panfrost and wayland, two things I like a lot. Also Gnome, and no v-sync tearing is also nice.
