# fipq

A Forth created with Ulitbo that runs bare-metal on a generic ARM. It is suitable for use with QEMU


## Building fipq

* Open up fipq.lpi using Ultibo
* Select menu item Run : Compile. This creates `kernel.bin`
* Run `install-kernel`. This transfers the kernel file to the QEMU disk image
