# ultimc - Forth on Ultibo

# Requires:
* any model of raspberry pi
* a computer that can write an sd card
* an sd card that you can erase - its contents will be destroyed
* usb keyboard
* an hdmi tv and an hdmi cable

# Steps:
* with the computer
    * format the sd card as FAT32
        * this destroys the current contents of the sd card
    * download the zip file
    * unzip it to the sd card
    * safely eject the sd card
* insert the sd card into the pi
* connect the pi to the tv using the hdmi cable
* connect the pi to the usb keyboard
* turn on the tv
* apply power to the pi
* if using a tv, you should see a green border with large white regions with black text

# Operation:
    * enter forth commands, for instance:
        * Ultibo.Uses.Platform.ActivityLedEnable
        * Ultibo.Uses.Platform.ActivityLedOn
        * Ultibo.Uses.Platform.ActivityLedOff
         
