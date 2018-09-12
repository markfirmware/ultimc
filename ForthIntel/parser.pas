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
          link:Integer; // link to the previous word in the dictionary
          codeptr:procedure();
          dptr:Integer;  // dataspace
        end;
        TWordPtr = ^TWord;

        TTokenType = (Eof, Word, Int);

        TState = (compiling, interpreting);

var
	//cint:integer;
	//tstr:TStringStream;
	//yytype:TTokenType;

        state:TState;
        tib:string; // terminal input buffer
        yypos:Integer; // a position within tib
        yylval_i:Integer;
        yylval_text:string;

	yytext:string;
	//procMap:TProcMap;
        IntStack: array[1..200] of Integer;
        IntStackSize:Integer;
        dict:Integer;
        dataspace: array [1..30000] of byte; // data used by the dictionary
        dptr:Integer; // pointer the dataspace
        worddptr:Integer; // pointer to the dataspace for the current word
        //heap: array[1..MAX_HEAP] of ^TWord;

        hptr:Integer; // pointer into the heap
        //heaptop:Integer;
        ip:Integer; // instruction pointer to the heap
        heap:array[1..10000] of byte;
        //heap1:Pointer;



//procedure InitLexer(s:String);
//function yylex(var the_yytext:String):TTokenType;
procedure GluteRepl();
procedure AddAtomic(name:string; ptr:Pointer);
procedure Push(val:integer);
function yylex() : TTokenType;
procedure yyparse();

implementation

//const SingleQuote:integer = $27;



function DictName(ptr:Integer):string;
var i:Integer;
begin
        DictName := '';
        for i:= 1 to heap[ptr+4] do DictName += char(heap[ptr+4+i]);
end;
function GetHeap32(pos:Integer):Integer;
begin
        Move(heap[pos], GetHeap32, 4);
end;

function lookup(name:string): Integer;
begin
        lookup := dict;
        while lookup <> 0 do
        begin
                if DictName(lookup) = name then exit;
                lookup := GetHeap32(lookup);
        end;

        writeln('lookup failed for word:',name);

end;

procedure Heap32(val:Integer);
begin
        Move(val, heap[hptr], 4);
        inc(hptr, 4);
end;
procedure HeapPointer(ptr:Pointer);
begin
        Move(ptr, heap[hptr], sizeof(Pointer));
        inc(hptr, sizeof(Pointer));
end;
function GetHeapPointer(pos:Integer) : Pointer;
begin
        Move(heap[pos], GetHeapPointer, sizeof(Pointer));
end;
function WordCodeptr(d:Integer):Pointer;
var offset:Integer;
begin
        offset := d  + 4 + heap[d+4] + 1;
        writeln('WordCodeptr:offset:', offset);
        WordCodeptr := GetHeapPointer(offset);
        writeln('WordCodeptr:',  Int64(WordCodeptr));

end;

procedure AddAtomic(name:string; ptr:Pointer);
var
        tmp, i:Integer;
begin
        tmp := hptr; // this will become the new top of the dictionary
        Heap32(dict);  // link
        heap[hptr] := length(name); inc(hptr); // name length

        // write out the name
        for i := 1 to length(name) do
        begin
                heap[hptr] := ord(name[i]);
                inc(hptr);
        end;

        HeapPointer(ptr); // codeptr
        dict := tmp;

end;

procedure PushInteger();
var
        bytes: array[0..3] of byte;
        val, i:Integer;
begin
        for i:= 0 to 3 do bytes[i] := dataspace[worddptr + i];
        val := 0; // supress compilation warning
        Move(bytes, val, 4);
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
        {*
        AddDictEntry('', @PushInteger);
        bytes[0] := 0; // suppress warning about not being initialised
        Move(val, bytes, 4);
        for i := 0 to 3 do  PushDataByte(bytes[i]);
        *}
        Push(val);
end;

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
end;

procedure Dot();
begin
        write(Pop(), ' ');
end;

procedure Dup();
var i:Integer;
begin
        i := Pop();
        Push(i);
        Push(i);
end;
procedure xcept();
begin
	Raise exception.create('Xcept exception test');
end;

procedure Noop;
begin
        // don't do anything
end;

procedure CreateWith(proc:TGluteProc);
begin
     yylex();
     //AddDictEntry(yytext, proc);
     yyparse();
end;

procedure Create();
begin
     CreateWith(@Noop);
        //yylex();
        //AddDictEntry(yytext, @Noop);
        //yyparse();
end;

procedure DoCol();
begin
     writeln('DoCol TODO');
end;

procedure Colon();
begin
        state := compiling;
        CreateWith(@DoCol);
     //writeln('Colon TODO');


end;

procedure SemiColon();
begin
     state := interpreting;
        writeln('Semicolon TODO');
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
var pos, sgn, len, i:Integer;
begin
        yylval_i := 0;
        IsInt := true;
        pos := 1;
        sgn := 1;
        len := length(yytext);

        // deal with potential negative
        if yytext[1] = '-' then
        begin
                sgn := -1;
                pos := pos +1;
                if pos> len then
                begin
                        IsInt := false;
                        exit;
                end;
        end;

        for i:= pos to len do
                begin
                        if isdigit(yytext[i]) then
                        begin
                                yylval_i := 10 * yylval_i + (ord(yytext[i]) - ord('0'));
                        end
                        else
                        begin
                                IsInt := false;
                                exit;
                                end;
                end;

        yylval_i := sgn * yylval_i;

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


{*
procedure CallCodePtr(fn:TGluteProc);
begin
        fn();
end;

*}

procedure EvalWord(name:string);
var wptr:Integer; ptr:Pointer; ptr1:TGluteProc;
begin
        wptr := lookup(name);
        if wptr = 0 then
        begin
                writeln('Word unfound:', name);
                exit;
        end;

        writeln('word found');
        ptr := WordCodeptr(wptr);
        writeln('word found:', Integer(ptr));
        //CallCodePtr(ptr);
        ptr1 := TGluteProc(ptr);
        ptr1();
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
procedure yyparse();
var yystype:TTokenType;
begin
     yystype := yylex();
     EvalToken(yystype);
//     heap[heaptop] := dict;
  //   heaptop := heaptop + 1;
end;

procedure Branch();
var i:Integer; yytype:TTokenType;
begin
        yytype := yylex();
        EvalToken(yytype);
end;
procedure qBranch();
var i:Integer; yytype:TTokenType;
begin
     yytype := yylex();
     EvalToken(yytype);
end;
procedure words();
var d:Integer;
begin
     d := dict;
     {*
     while (d <> 0) do
     begin
             write(d^.name, ' ');
             d := d^.link;
     end;
     *}
     writeln();
end;

procedure Dump();
{
var
        i:Integer;
        w, d:TWordPtr;
        codeptr:TGluteProc;
        }
begin
     {*
     writeln('Heap:');
     for i:= 1 to heaptop-1 do
     begin
             write('Heap:', i, ' ');
             w := heap[i];

             // reverse lookup the codeptr
             codeptr := w^.codeptr;
             d := dict;
             while d^.codeptr <> codeptr do d := d^.link;
             writeln(w^.name, ' ', d^.name);
     end;
     writeln('dataspace:');
     for i := 1 to dptr-1 do
     begin
             writeln(i, '   ' , dataspace[i]);
     end;
     words();
     *}
end;

procedure info();
begin
     writeln('Sizeof:Integer: ', sizeof(Integer));
     writeln('Sizeof:Int64:   ', sizeof(Int64));
     writeln('Sizeof:Pointer: ', sizeof(Pointer));
end;

procedure GluteRepl();
//var yytype:TTokenType;
//input:string;
begin
     info();
     while true do begin
             try
                        write(':');
                        yyparse();
			if yytext = 'bye' then exit;
                        //Dump();
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
        dict := 0;
        ip := 1;
        tib := '';
        yytext := '';
        yypos := 1;
        dptr := 1;
        //heaptop := 1;
        hptr := 1;
        state := interpreting;
        //heap1 := malloc(10000);

        AddAtomic('.s',  @PrintStack);
        AddAtomic('+',  @Plus);
        AddAtomic('.', @Dot);
        AddAtomic('dup', @Dup);
        AddAtomic('branch', @Branch);
        AddAtomic('branch?', @qBranch);
        AddAtomic('dump', @Dump);
        AddAtomic(':', @Colon);
        AddAtomic(';', @Semicolon);
        AddAtomic('words', @Words);
        AddAtomic('create', @Create);
        writeln('Init:@PrintStack:',  Int64(@PrintStack));
        //lookup('create');
end;

end.

