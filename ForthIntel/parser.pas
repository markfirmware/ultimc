unit parser;

{$mode objfpc}{$H+}


interface

uses
	//fgl,
	classes, {TStringStream }
 	character { IsWhiteSpace }
        //, contnrs
	, sysutils
	, variants
	;

type
	TTokenType = (Eof, Unknown,  Identifier, Str, UInt);

        TWordType = (atomic, compound);
        TGluteProc = procedure();
        //TWordPtr = ^TWord;
        TWord = record
          next:^TWord;
          name:string;
          case wtype:TWordType of
               atomic: (ptr:procedure());
               compound: (HeapIndex:Integer);
        end;

	//TProcMap = specialize TFPGMap<string, TGluteProc>;


var
	cint:integer;
	tstr:TStringStream;
	yytype:TTokenType;
	yytext:string;
	//procMap:TProcMap;
        IntStack: array[1..200] of Integer;
        IntStackSize:Integer;
        heap:^TWord;



//procedure InitLexer(s:String);
//function yylex(var the_yytext:String):TTokenType;
procedure GluteRepl();
procedure AddGluteProc(name:string; ptr:TGluteProc);


implementation

//const SingleQuote:integer = $27;




procedure AddGluteProc(name:string; ptr:TGluteProc);
var
        NewWord:^TWord;
begin
	//procMap.Add(name, ptr);

        New(NewWord);
        NewWord^.next := heap;
        NewWord^.name := name;
        NewWord^.ptr := ptr;
        heap := NewWord;
end;


//function add1(vs:TVariantList):Variant;
//{$push}{$warn 5024 off}
//begin
//	yylex(yytext);
//	add1 := 1 + StrToInt(yytext);
//end;
//{$pop}

function Pop(): Integer;
begin
        Pop := 0;
        if(IntStackSize<1) then
        begin
                writeln('Stack underflow');
                exit;
        end;

        Pop := IntStack[IntStackSize];
        IntStackSize := IntStackSize - 1;


end;

procedure Push(val:integer);
begin
        IntStackSize := IntStackSize +1;
        IntStack[IntStackSize] := val;
end;

procedure Plus();
begin
        Push(Pop() + Pop());
end;

procedure PrintStack();
var
        i:Integer;
begin
        for i := 1 to IntStackSize do
                write(IntStack[i], ' ');
        writeln('');
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



procedure EvalWord(word: string);
var
//idx:Integer;
ptr: TGluteProc;
hptr:^TWord;
begin
        {
        idx := procMap.indexof(word);
        if idx = -1 then begin
                writeln('Unrecognised word:', word);
                exit;
        end;

        ptr := procMap.GetData(idx);
        ptr();
        }

        // alternative method
        hptr := heap;
        while (hptr <> Nil ) and (hptr^.name <> word) do hptr := hptr^.next;
        if hptr = Nil then begin
                writeln('Unrecognised word:', word);
                exit;
        end;
        ptr := hptr^.ptr;
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
		except
		on E: Exception do
			DumpExceptionCallStack(E);
		end;
	end;

end;


initialization
begin
        //procMap := TProcMap.Create;
        IntStackSize := 0;

        heap := Nil;
        AddGluteProc('.s',  @PrintStack);
        AddGluteProc('+',  @Plus);


end;

end.

