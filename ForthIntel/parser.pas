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

const MAX_HEAP = 10000;

type

        TWordType = (atomic, colonic, integral);
        TGluteProc = procedure();
        //TWordPtr = ^TWord;
        TWord = record
          name:string;
          link:^TWord; // link to the previous word in the dictionary
          codeptr:procedure();
          dptr:Integer;
          {*
          case wtype:TWordType of
               atomic: (ptr:procedure());
               colonic: (HeapIndex:Integer);
               integral: (int:Integer);
               *}
        end;
        TWordPtr = ^TWord;

        //TCell = Integer;

        TTokenType = (Eof, Word, Int);
        {*
        Tyylval = record case vtype:TTokenType of
          Eof: (finis:boolean);
          Int: (i:Integer);
          Word: (text:String);
        end;
        *}





	//TProcMap = specialize TFPGMap<string, TGluteProc>;


var
	//cint:integer;
	//tstr:TStringStream;
	//yytype:TTokenType;
        tib:string; // terminal input buffer
        yypos:Integer; // a position within tib
        yylval_i:Integer;
        yylval_text:string;

	yytext:string;
	//procMap:TProcMap;
        IntStack: array[1..200] of Integer;
        IntStackSize:Integer;
        dict:^TWord;
        dataspace: array [1..30000] of byte; // data used by the dictionary
        dptr:Integer; // pointer the dataspace
        worddptr:Integer; // pointer to the dataspace for the current word
        heap: array[1..MAX_HEAP] of ^TWord;
        ip:Integer; // instruction pointer to the heap



//procedure InitLexer(s:String);
//function yylex(var the_yytext:String):TTokenType;
procedure GluteRepl();
procedure AddAtomic(name:string; ptr:TGluteProc);
procedure Push(val:integer);

implementation

//const SingleQuote:integer = $27;


function lookup(name:string): TWordPtr;
begin
     //writeln('lookup called');
        lookup := dict;
        while (lookup <> Nil) and (lookup^.name <> name) do lookup := lookup^.link;

        if lookup = Nil then
        begin
                writeln('Word not found:', name);
                exit;
        end;
        worddptr := lookup^.dptr;
end;

procedure AddDictEntry(name:string; codeptr:TGluteProc);
var NewWord:^TWord;
begin
        New(NewWord);
        NewWord^.link := dict;
        NewWord^.name := name;
        NewWord^.codeptr := codeptr;
        NewWord^.dptr := dptr;
        dict := NewWord;
end;

procedure AddAtomic(name:string; ptr:TGluteProc);
//var        NewWord:^TWord;
begin
        {*
        New(NewWord);
        NewWord^.link := dict;
        NewWord^.name := name;
        NewWord^.ptr := ptr;
        dict := NewWord;
        *}
        AddDictEntry(name, ptr);
end;

procedure PushInteger();
var
        bytes: array[0..3] of byte;
        val, i:Integer;
begin
        for i:= 0 to 3 do bytes[i] := dataspace[worddptr + i];
        val := 0; // supress compilation warning
        Move(bytes, val, 4);
        //Push(val);
end;

procedure PushDataByte(b:byte);
begin
        dataspace[dptr] := b;
        dptr := dptr + 1;
end;

procedure EvalInteger(val:Integer);
var
        bytes: array[0..3] of byte;
        i: Integer;
begin
        writeln('EvalInteger called:', val);
        AddDictEntry('', @PushInteger);
        bytes[0] := 0; // suppress warning about not being initialised
        Move(val, bytes, 4);
        for i := 0 to 3 do  PushDataByte(bytes[i]);
        Push(val);
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
        writeln('PrintStack called');
        for i := 1 to IntStackSize do
                write(IntStack[i], ' ');
        writeln('');
end;

procedure Dot();
begin
        write(Pop(), ' ');
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


function IsInt() :Boolean;
begin
         try
                 IsInt := true;
                 yylval_i := StrToInt(yytext);
                 //yylex := Int;
                 //IntStackSize := IntStackSize +1;
                 //IntStack[IntStackSize] := i;
         except
         On E: EConvertError do IsInt := false;
         end;
end;

function yylex() : TTokenType;
label FindWord;
var len, pos0:Integer;
begin
        FindWord: // hunt around until we find a word
        //len := length(tib);
        if yypos > length(tib) then
        begin
                readln(tib);
                yypos := 1;
        end;
        len := length(tib);
        while (yypos <= len) and iswhitespace(tib[yypos]) do yypos := yypos +1;
        if yypos > len then goto FindWord;

        // now get the word
        pos0 := yypos;
        while (yypos < len) and (not iswhitespace(tib[yypos+1])) do yypos := yypos +1;
        yytext := Copy(tib, pos0, yypos-pos0 +1);
        yypos := yypos + 1;  // point beyond the end of the word

        yylex := Eof;
        if IsInt() then
        begin
                yylex := Int;
                writeln('yylex:int:', yylval_i);
        end
        else
        begin
                yylex := Word;
                yylval_text := yytext;
                writeln('yylex:word:', yylval_text);

        end;
end;

procedure EvalWord(name:string);
var wptr:TWordptr; ptr: TGluteProc;
begin
     wptr := lookup(name);
     if(wptr = Nil) then exit;
     writeln('word found');
     ptr := wptr^.codeptr;
     worddptr := wptr^.dptr;
     ptr();
end;

procedure EvalToken(yytype:TTokenType);
//var ptr:TGluteProc;
begin
     writeln('EvalToken called:', yytext);
        case yytype of
        Int: EvalInteger(yylval_i);
        Word: EvalWord(yylval_text);
        Eof: writeln('EvalToken:Eof');
        else writeln('EvalToken:unknown');
        end;

end;
procedure GluteRepl();
var yytype:TTokenType;
//input:string;
begin

	while true do begin
		try
		       	write(':');
			//readln(input);
                        yytype := yylex();
                        writeln('');
			if yytext = 'bye' then exit;
                        //ParseLine(input);
                        EvalToken(yytype);
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
        dict := Nil;
        ip := 1;
        tib := '';
        yytext := '';
        yypos := 1;
        dptr := 1;
        AddAtomic('.s',  @PrintStack);
        AddAtomic('+',  @Plus);
        AddAtomic('.', @Dot);


end;

end.

