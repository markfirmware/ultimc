program ultimc;

{$mode objfpc}{$H+}

{ Raspberry Pi 3 Application                                                   }
{  Add your program code below, add additional units to the "uses" section if  }
{  required and create new units by selecting File, New Unit from the menu.    }
{                                                                              }
{  To compile your program select Run, Compile (or Run, Build) from the menu.  }

uses
  RaspberryPi3,
  Keymap_UK,
  GlobalConfig,
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  SysUtils,
  Classes,
  Ultibo,
  Console,
  Framebuffer,
  GimpPpm
  , parser
  , secondary
  , forthgpio
  //, Glute
  //, GimpPpmGlute
  //, EdiGlute}
;


var Fb:PFramebufferDevice;
 FramebufferProperties:TFramebufferProperties;
 WindowHandle:TWindowHandle;

begin
  Fb:=FrameBufferDeviceGetDefault;
  Sleep(100);
  FrameBufferProperties.Depth:=32;
  FrameBufferProperties.PhysicalWidth:= 1920 div 2;
  FrameBufferProperties.PhysicalHeight:=1080 div 2;
  FrameBufferProperties.VirtualWidth:=FrameBufferProperties.PhysicalWidth;
  FrameBufferProperties.VirtualHeight:=FrameBufferProperties.PhysicalHeight * 2;
  FrameBufferDeviceAllocate(Fb,@FrameBufferProperties);
  Sleep(100);
  FrameBufferDeviceSetDefault(Fb);
  FrameBufferDeviceGetProperties(Fb,@FrameBufferProperties);
  //SetGimpPpmGluteFb(Fb);

  FramebufferDeviceFillRect(Fb, 0, 0, 500, 500, $44444444, FRAMEBUFFER_TRANSFER_DMA);

   WindowHandle:=ConsoleWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_FULL,True);

   //KeymapFindByName('UK');
   //KeymapSetDefault();
   //KEYMAP_DEFAULT := 'UK';
   //Keymap_UKInit();
 ConsoleWindowWriteLn(WindowHandle,'Ultimc started');

 {Wait for C: drive to be ready}
 ConsoleWindowWrite(WindowHandle, 'Mounting drive...');
 while not DirectoryExists('C:\') do sleep(1000); // 1 second
 ConsoleWindowWriteLn(WindowHandle,'OK');

 using_raspberry := true; // needed to fix readln(0 wierdness
 MainRepl();
 ThreadHalt(0);
end.

