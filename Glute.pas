unit glute;

{$mode objfpc}{$H+}

interface

uses
	classes, {TStringStream }
       character; { IsWhiteSpace }
	

procedure Tokenise(instr:String);

implementation

	
function getchar(tstr:TStringStream) : Integer;
begin
	try
		getchar := tstr.ReadByte();
	except
		on E: EStreamError do
			getchar := -1;
	end;
end;

procedure MakeIdentifier(var cint: integer; tstr:TStringStream; var yyval:String);
begin
	yyval := '';
	while isletterordigit(chr(cint)) and (cint <> -1) do begin
		yyval := yyval + chr(cint);
		{ writeln('yyval~' + yyval); }
		cint := getchar(tstr);
	end;
	writeln('Identifier:' + yyval);
end;


procedure Tokenise(instr:String);
var 
cint:integer; 
tstr:TStringStream;
b: byte;
yyval:String;
begin

	tstr := TStringStream.Create(instr);
	cint := getchar(tstr);
		
	while cint <> -1 do begin
		yyval := '';
		while iswhitespace(chr(cint)) do cint:= getchar(tstr);
		if cint = -1 then break;

		if isletter(chr(cint)) then 
		begin
			MakeIdentifier(cint, tstr, yyval);
			end

		else
			cint := getchar(tstr);

		{ writeln('cint=' + chr(cint)); }

	end;
       
	{writeln('. EOI');}

end;

end.

