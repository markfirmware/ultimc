unit gimpppm;

{$mode objfpc}{$H+}

interface 




uses
	{
  GlobalConfig,
  GlobalTypes,
  Platform,
  Threads,
  Classes,
  Ultibo,
  Console,
  }
	Sysutils;

{ procedure LoadPpm(); }
	{ procedure LoadPpm(var WindowHandle:TWindowHandle); }
procedure LoadPpm(filename:String);

var PpmBuffer: PByte; { caller of LoadPpm() must FreeMem this buffer }
        PpmWidth, PpmHeight : Integer;
	{        PpmStatus : Integer; }
	

implementation

{procedure LoadPpm(var WindowHandle:TWindowHandle); }
procedure LoadPpm(filename:String);
var
	tfIn : TextFile;
	{ fname : String; }
	maxval, row, col, r, g, b, offset: Integer;
begin
	{	PpmStatus := 0; }

	{ fname := 'c:\logo.ppm'; }

        if not FileExists(filename) then raise exception.create('LoadPpm:File does not exist:' + filename);

	AssignFile(tfIn, filename);
	reset(tfIn);

	readln(tfIn); { s/b P3 }
	readln(tfIn); { s/b comment about being created by GIMP }
	read(tfIn, PpmWidth);
	read(tfIn, PpmHeight);
	read(tfIn, maxval);
	assert(maxval <= 255, 'PPM maxval too high for me to handle');


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


end;

end.
