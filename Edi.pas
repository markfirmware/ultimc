unit Edi;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils
  ;


procedure SayFile(filename:string);

implementation

procedure SayFile(filename:string);
var
	tfIn:TextFile;
	line:string;
begin
	AssignFile(tfIn, filename);
	reset(tfIn);

	while not eof(tfIn) do
	begin
		readln(tfIn, line);
		writeln(line);
	end;

	CloseFile(tfIn);
end;


end.

