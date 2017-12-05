unit gimpppm;

{$mode objfpc}{$H+}

interface 




uses
         {RaspberryPi3,}
  GlobalConfig,
 { GlobalConst, }
  GlobalTypes,
  Platform,
  Threads,
{  SysUtils, }
  Classes,
  Ultibo,
	Sysutils, Console;

{ procedure LoadPpm(); }
procedure LoadPpm(var WindowHandle:TWindowHandle);

var PpmBuffer: PByte; { caller of LoadPpm() must FreeMem this buffer }
        PpmWidth, PpmHeight : Integer;
        PpmStatus : Integer;

implementation

procedure LoadPpm(var WindowHandle:TWindowHandle);
var
	tfIn : TextFile;
        fname : String;
	maxval, row, col, r, g, b, offset: Integer;
begin
        fname := 'c:\logo.ppm';

        if FileExists(fname) then
             ConsoleWindowWriteLn(WindowHandle,'File exists')
             else
               ConsoleWindowWriteLn(WindowHandle,'File not exists');


        ConsoleWindowWriteLn(WindowHandle,'Stage 1');
	AssignFile(tfIn, fname);
        ConsoleWindowWriteLn(WindowHandle,'Assigned ok');
	reset(tfIn);
        ConsoleWindowWriteLn(WindowHandle,'reset ok');

	readln(tfIn); { s/b P3 }
	readln(tfIn); { s/b comment about being created by GIMP }
	read(tfIn, PpmWidth);
	read(tfIn, PpmHeight);
	read(tfIn, maxval);
	assert(maxval <= 255, 'PPM maxval too high for me to handle');
                ConsoleWindowWriteLn(WindowHandle,'Stage 3');


	GetMem(PpmBuffer, PpmWidth*PpmHeight*4);
	offset := 0;
	for row := 1 to PpmWidth  do for col := 1 to PpmHeight do
		begin
			{ observe proper endianness }
			PpmBuffer[offset+3] := $FF; { alpha fully opaque } 
			read(tfIn, r); { red }
			PpmBuffer[offset+2] := r;
			read(tfIn, g); { green }
			PpmBuffer[offset+1] := g; 
			read(tfIn, b); { blue }
			PpmBuffer[offset+0] := b;
			Inc(offset, 4);
		end;

	CloseFile(tfIn);
                ConsoleWindowWriteLn(WindowHandle,'Stage Final');


end;

end.
