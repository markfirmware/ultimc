program gimpppmtest;

{$mode objfpc}{$H+}

uses
	GimpPpm;

begin
	LoadPpm();
	FreeMem(PpmBuffer);
end.


