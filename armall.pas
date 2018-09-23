unit armall;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils
  , Console
  , FrameBuffer
  , GlobalConst
  , GlobalTypes
  , Keymap
  , Keymap_UK
  , Threads

  , parser
  , secondary
  ;


var Fb:PFramebufferDevice;
 FramebufferProperties:TFramebufferProperties;
 WindowHandle:TWindowHandle;

procedure  StartArmAll();

implementation

procedure  StartArmAll();
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

 KeymapSetDefault(KeymapFindByName('UK'));

 using_raspberry := true; // needed to fix readln(0 wierdness
 MainRepl();
 ThreadHalt(0);
end;

end.

