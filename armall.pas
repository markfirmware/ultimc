unit armall;

{$mode objfpc}{$H+}

interface

// USES_ARM is defined

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
  , heapfuncs

  , texteditor
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

procedure ReadLnConsole(var text:string);
begin
 ConsoleWindowReadLn(WindowHandle, text);

end;

procedure  StartArmAll();
begin
  Fb:=FrameBufferDeviceGetDefault;
  Sleep(100);
  FrameBufferProperties.Depth:= 32;
  FrameBufferProperties.Order:= FRAMEBUFFER_ORDER_RGB;
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


function percent(v:TCell; pc:TCell):TCell;
begin
 percent := TCell(round(v * pc / 100));
end;

procedure P_to_rgb16();
var b,g,r, rgb:TCell;
begin
 b := percent(pop(), 31);
 g := percent(pop(), 63);
 r := percent(pop(), 31);
 rgb := (r shl 11) + (g shl 5) + b;
 push(rgb);
end;


procedure P_to_rgba16();
var b,g,r, a, rgba:TCell;
begin
 a := pop();
 b := pop();
 g := pop();
 r := pop();
 rgba := (r shl 12) + (g shl 8) + (b shl 4) + a;
 push(rgba);
end;

procedure P_fbrect();
var x0, y0, x1, y1, rgb16:LongWord;
begin
 rgb16 := pop();
 y1 := pop();
 x1 := pop();
 y0 := pop();
 x0 := pop();
 FramebufferDeviceFillRect(Fb, x0, y0, x1, y1, rgb16, FRAMEBUFFER_TRANSFER_DMA);
end;

procedure sqre(color:LongWord);
begin
 FramebufferDeviceFillRect(Fb, 0, 0, 500, 500, color, FRAMEBUFFER_TRANSFER_DMA);
end;

procedure P_red();
begin
 sqre(%0000000011110000); // this actually is red
end;
procedure P_green();
begin
 sqre(%1111000000001111);  // this is acutally green
end;
procedure P_blue();
begin
 sqre(%0000111100000000); // black
 sqre(%0000111100001111); // black
 sqre(%1111111100001111); // green
 sqre(%1111000011111111); // yellow
 sqre(%0000000011111111); // red
 sqre(%1111111111111111); // yellow
 sqre(0); // black
 sqre(%1111);  //black
 sqre(%11111111); //red
 sqre(%111111111111); //red
 sqre(%101010101010); // reddish
 sqre(%010101010101); // deeper red
 sqre($F000); // green
 sqre($F0FF); //yellow
 sqre($FF00); //
 sqre($FFFFFFFF); //   white
 sqre($FFFF0000); //   blue
 sqre($FF00FF00); //   green
 sqre($FF0000FF); // red
 //sqre($FFFF0000); //   blue
 sqre($FFFF0000); //   blue
 sqre($FFFF00); //   cyan
 sqre($FF00FF); // magenta
 sqre($00FFFF);  //yellow
 sqre($333333);  //grey'ish
 sqre($333333*5);  //lighter grey'ish
 sqre($888800); //   very nice cyan
 sqre($880088); // purple
 sqre($000088);



end;


initialization
begin
  ReadLinePtr := @ReadLnConsole;
  c_drive_required := True;
  AddPrim(0, 'FBRECT', @P_fbrect);
  AddPrim(0, '>RGB16', @P_to_rgb16);
  AddPrim(0, '>RGBA16', @P_to_rgba16);
  AddPrim(0, 'RED', @P_red);
  AddPrim(0, 'GREEN', @P_green);
  AddPrim(0, 'BLUE', @P_blue);
  AddPrim(0, 'EDITOR', @TextEditorMain);
end;

end.

