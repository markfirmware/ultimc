unit gimpppm;

{$mode objfpc}{$H+}

interface 




uses
	Sysutils;
	
procedure LoadPpm();

var PpmBuffer: PByte; { caller of LoadPpm() must FreeMem this buffer }

implementation

procedure LoadPpm();
var
	tfIn : TextFile;
	width, height, maxval, row, col, r, g, b, offset: Integer;
begin
	AssignFile(tfIn, 'logo.ppm');
	reset(tfIn);

	readln(tfIn); { s/b P3 }
	readln(tfIn); { s/b comment about being created by GIMP }
	read(tfIn, width);
	read(tfIn, height);
	read(tfIn, maxval);
	assert(maxval <= 255, 'PPM maxval too high for me to handle');

	GetMem(PpmBuffer, width*height*4);
	offset := 0;
	for row := 1 to width  do for col := 1 to height do
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
