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
        TProc = procedure();

        TTokenType = (Eof, Word, Int);

        TState = (compiling, interpreting);

var

        state:TState;
        tib:string; // terminal input buffer
        yypos:Integer; // a position within tib
        yylval_i:Integer;
        yylval_text:string;

	yytext:string;
        IntStack: array[1..200] of Integer;
        IntStackSize:Integer;

        // dictionary items
        latest:Integer; // the latest word being defined

        hptr:Integer; // pointer into the heap
        //ip:Integer; // instruction pointer to the heap
        heap:array[1..10000] of byte;



//procedure InitLexer(s:String);
//function yylex(var the_yytext:String):TTokenType;
procedure GluteRepl();
procedure AddAtomic(immediate:byte;name:string; ptr:Pointer);
procedure Push(val:integer);
function yylex() : TTokenType;
procedure yyparse();

implementation

//const SingleQuote:integer = $27;



function DictName(ptr:Integer):string;
var i:Integer;
begin
        DictName := '';
        for i:= 1 to heap[ptr+5] do DictName += char(heap[ptr+5+i]);
end;
function GetHeap32(pos:Integer):Integer;
begin
        Move(heap[pos], GetHeap32, 4);
end;

function P_find(name:string): Integer;
begin
        name := UpperCase(name);
        P_find := latest;
        while P_find <> 0 do
        begin
                if DictName(P_find) = name then exit;
                P_find := GetHeap32(P_find);
        end;

        writeln('FIND failed for word:',name);

end;

procedure HeapByte(b:byte);
begin
        heap[hptr] := b;
        inc(hptr);
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
var offset:Integer;NameLength:byte;
begin
        NameLength := heap[d+5];
        offset := d  + 4 + 1 + NameLength + 1;
        //writeln('WordCodeptr:offset:', offset);
        WordCodeptr := GetHeapPointer(offset);
        //writeln('WordCodeptr:',  Int64(WordCodeptr));

end;

procedure AddAtomic(immediate:byte; name:string; ptr:Pointer);
var
        tmp, i:Integer;
begin
        tmp := hptr; // this will become the new top of the dictionary
        Heap32(latest);  // link
        HeapByte(immediate); // flags, of which immediate is one
        heap[hptr] := length(name); inc(hptr); // name length

        // write out the name
        for i := 1 to length(name) do
        begin
                heap[hptr] := ord(name[i]);
                inc(hptr);
        end;

        HeapPointer(ptr); // codeptr
        latest := tmp;

end;

procedure EvalInteger(val:Integer);
var
        bytes: array[0..3] of byte;
        i: Integer;
begin
        //writeln('EvalInteger called:', val);
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
        //writeln('PrintStack called');
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

procedure CreateWith(proc:TProc);
begin
     yylex();
     //AddDictEntry(yytext, proc);
     yyparse();
end;


procedure P_word();
begin
     yylex();
end;

procedure P_create();
begin
     P_word(); // read the name of the function being defined
end;

procedure DoCol();
begin
     writeln('DoCol TODO');
end;


procedure Colon();
begin
     P_create(); // construct the dictionary entry header
     state := compiling;
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
                //writeln('yylex:int:', yylval_i);
        end
        else
        begin
                yylex := Word;
                yylval_text := yytext;
                //writeln('yylex:word:', yylval_text);

        end;
end;


procedure EvalWord(name:string);
var wptr:Integer; ptr:Pointer; ptr1:TProc;
begin
        wptr := P_find(name);
        if wptr = 0 then
        begin
                writeln('Word unfound:', name);
                exit;
        end;

        //writeln('word found');
        ptr := WordCodeptr(wptr);
        //writeln('word found:', Integer(ptr));
        if state = compiling then
        begin
                HeapPointer(ptr);
        end
        else
        begin
             ptr1 := TProc(ptr);
             ptr1();
        end;
end;

procedure EvalToken(yytype:TTokenType);
//var ptr:TGluteProc;
begin
     //writeln('EvalToken called:', yytext);
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
     d := latest;
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
        latest := 0;
        //ip := 1;
        tib := '';
        yytext := '';
        yypos := 1;
        //dptr := 1;
        //heaptop := 1;
        hptr := 1;
        state := interpreting;
        //heap1 := malloc(10000);

        // prefix normal words with 0, immediate words with 1
        AddAtomic(0, '.S',  @PrintStack);
        AddAtomic(0, '+',  @Plus);
        AddAtomic(0, '.', @Dot);
        AddAtomic(0, 'DUP', @Dup);
        AddAtomic(0, 'BRANCH', @Branch);
        AddAtomic(0, '?BRANCH', @qBranch);
        //AddAtomic('dump', @Dump);
        AddAtomic(0, ':', @Colon);
        AddAtomic(1, ';', @Semicolon);
        AddAtomic(0, 'WORDS', @Words);
        AddAtomic(0, 'CREATE', @P_create);
        writeln('Init:@PrintStack:',  Int64(@PrintStack));
        //lookup('create');
end;

end.

