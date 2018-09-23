unit armall;

{$mode objfpc}{$H+}

interface

uses
  // QEMUVersatilePB ,
  Console
  , FrameBuffer
  , GlobalConst
  , GlobalTypes
  , Keymap
  , Keymap_UK
  , Platform
  , Threads
  , SysUtils
  , Classes
  , Ultibo


  , secondary
  , parser
  ;


var Fb:PFramebufferDevice;
 FramebufferProperties:TFramebufferProperties;
 WindowHandle:TWindowHandle;
 c_drive_required:Boolean;

procedure  StartArmAll();

procedure OptionallyMountDrive();

implementation

procedure WritelnConsole(msg:string);
begin
  ConsoleWindowWriteLn(WindowHandle,msg);
end;

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

  //FramebufferDeviceFillRect(Fb, 0, 0, 500, 500, $44444444, FRAMEBUFFER_TRANSFER_DMA);

   WindowHandle:=ConsoleWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_FULL,True);

    // FramebufferDeviceFillRect(Fb, 0, 0, 500, 500, $44444444, FRAMEBUFFER_TRANSFER_DMA);

   //KeymapFindByName('UK');
   //KeymapSetDefault();
   //KEYMAP_DEFAULT := 'UK';
   //Keymap_UKInit();
 WritelnConsole('Ultimc started');

 OptionallyMountDrive();

 KeymapSetDefault(KeymapFindByName('UK'));
 //WritelnConsole('Start typing, see what happens.');

 using_raspberry := true; // needed to fix readln() wierdness
 MainRepl();
 ThreadHalt(0);
end;

procedure OptionallyMountDrive();
begin
  ConsoleWindowWrite(WindowHandle, 'Mounting drive... ');
 if not c_drive_required then begin
   WritelnConsole('SKIPPED');
   exit;
 end;

 {Wait for C: drive to be ready}

 while not DirectoryExists('C:\') do
 begin
   sleep(1000); // 1 second
 end;
 WritelnConsole('OK');

end;

initialization
begin
  c_drive_required := True;
end;

end.

