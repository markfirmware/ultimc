program gimpppmtest;

{$mode objfpc}{$H+}

uses
	GimpPpm;

begin
	LoadPpm('logo.ppm');
	FreeMem(PpmBuffer);
end.


