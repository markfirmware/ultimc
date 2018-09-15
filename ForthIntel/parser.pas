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

        {$ifdef CPU32}
        TCell = Int32;
        {$else}
        TCell = Int64;
        {$endif}

        TTokenType = (Eof, Word, Int);

        TState = (compiling, interpreting);

        THeaderPtr = ^THeader;
        THeader = record // a header for a word
          link:THeaderPtr;
          flags:byte;
          name:PString;
          codeptr:TProc;
          hptr:Integer; // pointer to the heap
        end; // data will extend beyond this
var
        using_raspberry:Boolean;

        state:TState;
        tib:string; // terminal input buffer
        yypos:Integer; // a position within tib
        yylval_i:TCell;
        yylval_text:string;

	yytext:string;
        IntStack: array[1..200] of TCell;
        IntStackSize:Integer;

        // dictionary items
        latest:THeaderPtr; // the latest word being defined

        hptr:Integer; // pointer into the heap
        ip:Integer; // instruction pointer to the heap
        heap:array[1..10000] of byte;
        wptr:Integer; // some kind of word pointer
        //iptr:Integer; // some kind of instruction pointer

        rstack:array[1..200] of TCell; // return stack
        rsp:Integer; // return stack pointer

        bye:boolean; // time for dinner



//procedure InitLexer(s:String);
//function yylex(var the_yytext:String):TTokenType;
procedure GluteRepl();
procedure AddPrim(immediate:byte;name:string; ptr:TProc);
procedure Push(val:TCell);
function Pop(): TCell;
function yylex() : TTokenType;
procedure yyparse();
procedure P_word();
function P_find(name:string): THeaderPtr;
procedure ExecHeader(ptr:THeaderPtr);
procedure DoCol();
function ToHeaderPtr(ip:Integer):THeaderPtr;
procedure HeapifyHeader(hdr:THeaderPtr);

implementation

{$push}
//{$warn 5057 off}  // hide warning var not initialized
{$hints off}   // hide warning var not initialized

function ToHeaderPtr(ip:Integer):THeaderPtr;
begin
     Move(heap[ip], ToHeaderPtr, sizeof(Pointer));
end;
function GetHeapCell(pos:Integer): TCell;
begin
     Move(heap[pos], GetHeapCell, sizeof(TCell));
end;
function GetHeapPointer(pos:Integer) : Pointer;
begin
        Move(heap[pos], GetHeapPointer, sizeof(Pointer));
end;
{$pop}

function P_find(name:string): THeaderPtr;
begin
     P_find := latest;
     name := UpperCase(name);
     while (P_find <> Nil) and (P_find^.name^ <> name) do P_find := P_find^.link;
     if(P_find = Nil) then Raise exception.create(name + ' unfound');
end;


procedure HeapifyHeader(hdr:THeaderPtr);
begin
        Move(hdr, heap[hptr], sizeof(Pointer));
        inc(hptr, sizeof(Pointer));
end;

procedure HeapByte(b:byte);
begin
        heap[hptr] := b;
        inc(hptr);
end;

procedure HeapifyCell(val:TCell);
begin
     Move(val, heap[hptr], sizeof(TCell));
     inc(hptr, sizeof(TCell));
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

procedure NoOp();
begin
        // a procedure that does nothing gracefully
end;

procedure CreateHeader(immediate:byte; name:string; proc:TProc);
var h:THeaderPtr;
begin
     New(h);
     //tmp := h;
     h^.link:= latest;
     h^.flags := immediate;
     h^.name:= NewStr(UpperCase(name));
     h^.codeptr := proc;
     h^.hptr := hptr; // top of the heap
     //HeapifyHeader(hdr);
     latest := h;
     //writeln('latest', latest);

end;

procedure AddPrim(immediate:byte; name:string; ptr:TProc);
begin
     CreateHeader(immediate, name, ptr);
     //HeapPointer(ptr); // codeptr
end;

procedure P_bye();
begin
     bye := true;
end;

procedure Push(val:TCell);
begin
     IntStackSize := IntStackSize +1;
     IntStack[IntStackSize] := val;
end;

function Pop(): TCell;
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
procedure P_comma();
begin
     //val := Pop();
     HeapifyCell(Pop());
end;


procedure P_word();
begin
     yylex();
end;

procedure P_create();
begin
     P_word(); // read the name of the word being defined
     //writeln(' word being created is:', yytext);
     CreateHeader(0, yytext, @NoOp); // it assumes its not immediate
end;

procedure rpush(i:Integer);
begin
     inc(rsp);
     rstack[rsp] := i;
end;

function rpop():Integer;
begin
   rpop := rstack[rsp];
   //push(rpop);
   inc(rsp, -1);
end;
procedure P_Exit();
begin
   // don't do anything. Let DOCOL detect and handle things
   writeln('TODO Exit');
   //ip := rpop();
end;
procedure P_semicolon();
begin
     HeapPointer(P_find(';'));
     state := interpreting;
end;
procedure DoCol(); // the inner interpreter
//var ip:TCell;
label again;
var hdr:THeaderPtr;
begin
   ip := wptr;
again:
   hdr := ToHeaderPtr(ip);
   if (hdr^.codeptr = @P_semicolon) or (hdr^.codeptr = @P_exit) then exit;
   rpush(ip + sizeof(Pointer));
   ExecHeader(hdr);
   ip := rpop();
   //inc(ip, sizeof(Pointer));
   goto again;
end;


procedure P_colon();
begin
     P_create(); // construct the dictionary entry header
     latest^.codeptr:= @DoCol;
     //HeapPointer(@Docol);
     //HeapPointer(hptr); // this will be used to DOCOL to set the UP
     state := compiling;
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
        yylval_i := TCell(0);
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
                                yylval_i := 10 * yylval_i;
                                yylval_i += (ord(yytext[i]) - ord('0'));
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
                if using_raspberry then writeln(''); // seems to be a quirk
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

procedure ExecHeader(ptr:THeaderPtr);
var ptr1:TProc;
begin
        ptr1 := TProc(ptr^.codeptr);
        wptr := ptr^.hptr;
        ptr1();
end;

function mediate(h:THeaderPtr):boolean; // opposite of immediate
//var flags:byte;
begin
        //flags := heap[wptr+4];
     //mediate := ((flags and 1) = 0);
     mediate := ((h^.flags and 1) = 0);
end;

procedure EvalWord(name:string);
var h:THeaderPtr;
begin
        h := P_find(name);
        //ptr := Pointer(WordCodeptr(header));
        if (state = compiling) and mediate(h) then
        begin
                //writeln('Compiling ', name);
                HeapPointer(h);
        end
        else
        begin
                ExecHeader(h);
        end;
end;
procedure P_lit();
var val:TCell;
begin
     val :=  GetHeapCell(rstack[rsp]);
     rstack[rsp] += sizeof(TCell);
     //writeln('Lit value:', val);
     //inc(ip, sizeof(TCell));
     Push(val);
end;

procedure EvalInteger(val:TCell);
begin
     if state = interpreting then
     begin
        Push(val);
        exit;
     end;

     // compiling
     EvalWord('LIT');
     //CreateHeader(0, 'LIT', @P_lit);
     HeapifyCell(val);
     //writeln('rsp-top:', rstack[rsp]);
     //writeln('EvalInteger value:', val);
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

procedure P_branch();
var offset:TCell;
begin
     offset := GetHeapCell(rstack[rsp]);
     //writeln('branch offset:', offset);
     rstack[rsp] += offset + sizeof(TCell);
end;
procedure qBranch();
var offset:TCell;
begin
     offset := GetHeapCell(rstack[rsp]);
     //writeln('branch offset:', offset);
     if Pop() = 0 then rstack[rsp] += offset;
     rstack[rsp] += sizeof(TCell);
end;

procedure GluteRepl();
//var yytype:TTokenType;
//input:string;
begin
     //info();
     while true do begin
             try
                        //write(':');
                        yyparse();
			if bye then exit;
                        if yypos >= length(tib) then writeln(' ok'); // although it might not be
                        //Dump();
		except
		on E: Exception do
			DumpExceptionCallStack(E);
		end;
     end;

end;


initialization
begin
        using_raspberry := false;
        //procMap := TProcMap.Create;
        IntStackSize := 0;
        latest := Nil;
        //ip := 1;
        tib := '';
        yytext := '';
        yypos := 1;
        //dptr := 1;
        //heaptop := 1;
        hptr := 1;
        state := interpreting;
        rsp := 0;
        bye := false;
        //heap1 := malloc(10000);

        // prefix normal words with 0, immediate words with 1

        AddPrim(0, 'BRANCH', @P_branch);
        AddPrim(0, '?BRANCH', @qBranch);
        AddPrim(0, ':', @P_colon);
        AddPrim(1, ';', @P_semicolon);
        AddPrim(0, 'CREATE', @P_create);
        AddPrim(0, 'DOCOL', @docol);
        AddPrim(0, 'BYE', @P_bye);
        AddPrim(0, 'EXIT', @P_exit);
        AddPrim(0, 'LIT', @P_lit);
        AddPrim(0, ',', @P_comma);
        //lookup('create');
end;

end.

