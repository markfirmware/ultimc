unit glute;

{$mode objfpc}{$H+}

interface

uses
	fgl,
	classes, {TStringStream }
 	character; { IsWhiteSpace }
	

type
	TTokenType = (Eof, Unknown,  Identifier, Str);

	TGluteProc = procedure();

	TProcMap = specialize TFPGMap<string, TGluteProc>;


var
	cint:integer;
	tstr:TStringStream;
	yytype:TTokenType;
	yytext:string;
	procMap:TProcMap;



procedure InitLexer(s:String);
function yylex(var the_yytext:String):TTokenType;
procedure GluteRepl();
procedure AddGluteProc(name:string; ptr:TGluteProc);


implementation

const SingleQuote:integer = $27;
	

function getchar() : Integer;
begin
	try
		getchar := tstr.ReadByte();
	except
		on E: EStreamError do
			getchar := -1;
	end;
end;

procedure MakeIdentifier();
begin
	{writeln('making identifier');}
	yytext := '';
	yytype := Identifier;
	while isletterordigit(chr(cint)) and (cint <> -1) do begin
		yytext := yytext + chr(cint);
		{writeln('yyval~' + yyval); }
		cint := getchar();
	end;
	{writeln('Identifier:' + yytext);}
end;


procedure MakeQuotedString();
begin
	{writeln('making quoted string');}
	yytext := '';
	yytype := Str;
	while true do begin
		cint := getchar();
		if (cint = -1) or (cint = SingleQuote) then break;
		yytext := yytext + chr(cint);
	end;
	cint := getchar();
	{writeln('String:' + yytext);}
end;

procedure InitLexer(s:String);
begin
	tstr := TStringStream.Create(s);
	cint := getchar();
end;
		

function yylex(var the_yytext:string):TTokenType;
{var 
cint:integer; 
tstr:TStringStream;
yyval:String;}

begin
	the_yytext := '';
	yytext := '';
	yylex := Eof;
	if cint = -1 then exit;
	while iswhitespace(chr(cint)) do cint:= getchar();
	if cint = -1 then exit;

		
	if isletter(chr(cint)) then 
	begin
			MakeIdentifier();
	end
	else if cint = SingleQuote then 
	begin 
		MakeQuotedString();
	end
	else
	begin
		{writeln('token skipping');}
		yytype := Unknown;
		cint := getchar();
	end;

	the_yytext := yytext;
	yylex := yytype;
	{writeln('cint=' + chr(cint)); }

       
	{writeln('. EOI');}

end;

procedure AddGluteProc(name:string; ptr:TGluteProc);
var
	idx:integer;
begin
	writeln('AddGluteProc:' + name);
	idx := procMap.Add(name, ptr);
	writeln(idx);
end;

procedure say();
begin
	yylex(yytext);
	writeln(yytext);
end;

procedure GluteEval();
{var
	yytype:TTokenType;}
var ptr: TGluteProc;
idx: integer;
found:boolean;
begin

	yylex(yytext);

	idx := procMap.indexof(yytext);
	if idx = -1 then begin
		writeln('Unrecognised token:' + yytext);
		exit;
	end;

	ptr := procMap.GetData(idx);

	ptr();
	exit;

	if procMap.Find(yytext, idx) then begin
		ptr := procMap[yytext];
		ptr();
	end
	else
		writeln('Unrecognised token:' + yytext);

end;

procedure jesse();
begin
	writeln('Pinkman is not available right now');
end;
procedure yo();
begin
	writeln('Yo, yo, yo, 148-3369, representing the ABQ.');
end;

procedure GluteRepl();
var 
{ptr: Pointer;}
input:string;
{procMap: TFuncMap;}
begin
	AddGluteProc('say', @say);
	AddGluteProc('jesse', @jesse);
	AddGluteProc('yo', @yo);


	while true do begin
		write(':');
		readln(input);
		if input = 'quit' then exit;
		InitLexer(input);
		GluteEval();
	end;

end;


initialization
begin
	procMap := TProcMap.Create;
end;

end.

