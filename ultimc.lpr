program ultimc;

{$mode objfpc}{$H+}

{ Raspberry Pi 3 Application                                                   }
{  Add your program code below, add additional units to the "uses" section if  }
{  required and create new units by selecting File, New Unit from the menu.    }
{                                                                              }
{  To compile your program select Run, Compile (or Run, Build) from the menu.  }

uses
  RaspberryPi3,
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

  FramebufferDeviceFillRect(Fb, 0, 0, 500, 500, $44444444, FRAMEBUFFER_TRANSFER_DMA);

   WindowHandle:=ConsoleWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_FULL,True);
 ConsoleWindowWriteLn(WindowHandle,'Hello Ultibo!');

  LoadPpm(WindowHandle);
  FramebufferDevicePutRect(Fb, 0, 0, PpmBuffer, PpmWidth, PpmHeight, 0,  FRAMEBUFFER_TRANSFER_DMA);
  FreeMem(PpmBuffer);

   ThreadHalt(0);
end.

