# ultimc

A Forth written in FreePascal that works on all Operating Systems, and includes a bare-metal ARM version (QEMU, and most Raspberry Pi's) comilable under Ultibo (see [fipq](fipq/README.md))

## boot.4th

The file `boot.4th` allows user-customisation of how the Forth starts. If you are using a UK keyboard under Ultibo, then you should include the line `uk-kbd` in there.

## ARM-specific

* [frambuffer](framebuffer.md)
* [GPIO](GPIO.md)
* serial port is being worked on by markfirmware. More details to follow.

## See also

* [tech](tech.md) - technical notes about the implementation
* [release-message](release-message.md) - created by MF (markfirmware)
