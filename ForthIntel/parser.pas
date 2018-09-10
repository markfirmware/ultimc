unit parser;

{$mode objfpc}{$H+}


interface

uses
	fgl,
	classes, {TStringStream }
 	character { IsWhiteSpace }
        , contnrs
	, sysutils
	, variants
	;

type
	TTokenType = (Eof, Unknown,  Identifier, Str, UInt);

        TVariantList  = specialize TFPGList<Variant>;
	TGluteProc = procedure();
        //TGluteFunc = function(vs:TVariantList):variant;

	TProcMap = specialize TFPGMap<string, TGluteProc>;
	//TProcMap = specialize TFPGMap<string, TGluteFunc>;


var
	cint:integer;
	tstr:TStringStream;
	yytype:TTokenType;
	yytext:string;
	procMap:TProcMap;
        //IntStack:TStack;
        //IntStack:TOrderedList;
        //IntStack:TList;
        IntStack: array[1..200] of Integer;
        IntStackSize:Integer;



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

procedure MakeUInt();
begin
	yytext := '';
	yytype := UInt;
	while isdigit(chr(cint)) and (cint <> -1) do begin
		yytext := yytext + chr(cint);
		cint := getchar();
	end;
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
	else if isdigit(chr(cint)) then
	begin
		MakeUInt();
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
{var
	idx:integer;}
begin
	{writeln('AddGluteProc:' + name);}
	procMap.Add(name, ptr);
	{writeln(idx);}
end;

procedure say();
begin
	yylex(yytext);
	writeln(yytext);
end;


function add1(vs:TVariantList):Variant;
{$push}{$warn 5024 off}
begin
	yylex(yytext);
	{writeln(yytype = UInt);}
	add1 := 1 + StrToInt(yytext);
	{writeln(add1);}
end;
{$pop}

procedure PrintStack();
var
        i:Integer;
begin
        for i := 1 to IntStackSize do
                write(IntStack[i], ' ');
        writeln('');
end;

procedure jesse();
begin
	writeln('Pinkman is not available right now');
end;

procedure yo();
begin
	writeln('Yo, yo, yo, 148-3369, representing the ABQ.');
end;

procedure xcept();
begin
	Raise exception.create('Xcept exception test');
end;

			
procedure DumpExceptionCallStack(E: Exception);
var
	I: Integer;
	Frames: PPointer;
	Report: string;
begin
	Report := 'Program exception! ' + LineEnding +
	'Stacktrace:' + LineEnding + LineEnding;
	if E <> nil then begin
		Report := Report + 'Exception class: ' + E.ClassName + LineEnding +
		'Message: ' + E.Message + LineEnding;
	end;
	Report := Report + BackTraceStrFunc(ExceptAddr);
	Frames := ExceptFrames;
	for I := 0 to ExceptFrameCount - 1 do
		Report := Report + LineEnding + BackTraceStrFunc(Frames[I]);
	
	{ShowMessage(Report);
	Halt; // End of program execution
	}

	writeln(Report);
end;


procedure MakeNum(var input:string; var pos:integer);
var
i:integer;
begin
        i := 0;
        while(isdigit(input[pos])) do
        begin
                i := 10 * i + (ord(input[pos]) - ord('0'));
                pos := pos +1;
        end;

        writeln('MakeNum:', i);

end;

procedure EvalWord(word: string);
var
idx:Integer;
ptr: TGluteProc;
begin
        idx := procMap.indexof(word);
        if idx = -1 then begin
                writeln('Unrecognised word:', word);
                exit;
        end;

        ptr := procMap.GetData(idx);
        ptr();
end;

procedure EvalYytext(yytext: string);
var
i:integer;
begin
        try
                i := StrToInt(yytext);
                IntStackSize := IntStackSize +1;
                IntStack[IntStackSize] := i;
        except
        On E: EConvertError do
           EvalWord(yytext);
        end;
        //writeln('Token is:', yytext, '.');
end;

procedure ParseLine(input:string);
var
pos, pos0:integer;
yytext:string;
more:boolean;
begin
        pos := 1;
        input := input +  ' '#0'';
        more := true;
        while more do
        begin
                while iswhitespace(input[pos]) do pos := pos + 1;
                pos0 := pos;
                while not iswhitespace(input[pos]) do pos := pos + 1;
                yytext := Copy(input, pos0, pos-pos0);
                if(length(yytext) > 0) and (yytext <> ''#0'') then
                begin
                        EvalYytext(yytext);
                end
                else more := false;
        end;

end;

procedure GluteRepl();
var 
input:string;
begin

	while true do begin
		try
		       	write(':');
			readln(input);
                        writeln('');
			if input = 'bye' then exit;
                        ParseLine(input);
			//InitLexer(input);
			//GluteEval();
		except
		on E: Exception do
			DumpExceptionCallStack(E);
		end;
	end;

end;


initialization
begin
	procMap := TProcMap.Create;
        //IntStack := TStack.Create;
        IntStackSize := 0;

	{AddGluteProc('add1', @add1);}
        AddGluteProc('.s',  @PrintStack);
              {
	AddGluteProc('say', @say);
	AddGluteProc('jesse', @jesse);
	AddGluteProc('xcept', @xcept);
	AddGluteProc('yo', @yo);
               }

end;

end.

