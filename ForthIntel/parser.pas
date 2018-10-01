unit parser;

{$mode objfpc}{$H+}


interface

uses
	fgl,
	classes, {TStringStream }
 	character { IsWhiteSpace }
        //, contnrs
        //, GStack
        , sysutils
	, variants
	;

const MAX_HEAP = 10000;


type
          {$ifdef CPU32}
          TCell = Int32;
          {$else}
          TCell = Int64;
          {$endif}
          TCellPtr = TCell; // hopefully will eliminate confusion


          TProc = procedure();

          THeaderPtr = ^THeader;
          THeader = record // a header for a word
                  link:THeaderPtr;
                  flags:byte;
                  name:PString;
                  codeptr:TProc;
                  hptr:Integer; // pointer to the heap
          end; // data will extend beyond this

        TWordType = (atomic, colonic, integral);

        //TFileSteamStack = specialize TStack<TFileStream>;
        TFileSteamStack = specialize TFPGObjectList<TFileStream>;


        TTokenType = (Eof, Word, Int);
        TReadLinePtr = procedure(var text:string);

        TState = (compiling, interpreting);
        const elit = %10 ; // implies that word contains embedded literal





var
                hptr:Integer; // pointer into the heap
        heap:array[1..MAX_HEAP] of byte;
        latest:THeaderPtr; // the latest word being defined



        using_raspberry:Boolean;

        state:TState;
        tib:string; // terminal input buffer
        yypos:Integer; // a position within tib
        yylval_i:TCell;
        yylval_text:string;

	yytext:string;
        IntStack: array[1..200] of TCell;
        IntStackSize:Integer;
        ReadLinePtr:TReadLinePtr;



        ip:Integer; // instruction pointer to the heap

        {* this points to the data on the heap of the word. Very magical! *}
        wptr:Integer;
        calling_ip:Integer;
        //colon_hdr:THeaderPtr; // the header of the current word being defined

        rstack:array[1..200] of TCell; // return stack
        rsp:Integer; // return stack pointer

        execstack:array[1..200] of THeaderPtr;
        esp:Integer; // top of call stack

        bye:boolean; // time for dinner

        //fpin: TFileStream;
        fsstack:TFileSteamStack;


procedure HeapifyByte(b:byte);
procedure HeapifyCell(val:TCell);
procedure HeapifyHeader(hdr:THeaderPtr);

procedure HeapPointer(ptr:Pointer);
function ToHeaderPtr(ip:Integer):THeaderPtr;
function GetHeapByte(pos:TCellPtr):byte;
function GetHeapCell(pos:TCellPtr): TCell;
function GetHeapPointer(pos:Integer) : Pointer;
procedure SetHeapCell(ptr:TCellPtr; val:TCell);
//procedure InitLexer(s:String);
//function yylex(var the_yytext:String):TTokenType;
procedure CreateHeader(immediate:byte; name:string; proc:TProc);
procedure EvalString(str:string);
procedure ExecHeader(ptr:THeaderPtr);
procedure HeapifyWord(name:string);
procedure MainRepl();
function MakeString():string;
procedure AddPrim(flags:byte;name:string; ptr:TProc);
procedure Push(val:TCell);
function Pop(): TCell;
function yylex() : TTokenType;
procedure yyparse();
procedure P_word();
function P_find(name:string): THeaderPtr;
//procedure ExecHeader(ptr:THeaderPtr);
procedure DoCol();
procedure CreateReadStream(name:string);
function rpop():Integer;
procedure P_backslash();
procedure P_create();


implementation


{$push}
{$hints off}   // hide warning var not initialized
function ToHeaderPtr(ip:Integer):THeaderPtr;
begin
     Move(heap[ip], ToHeaderPtr, sizeof(Pointer));
end;
function GetHeapCell(pos:TCellPtr): TCell;
begin
     Move(heap[pos], GetHeapCell, sizeof(TCell));
end;
function GetHeapPointer(pos:Integer) : Pointer;
begin
        Move(heap[pos], GetHeapPointer, sizeof(Pointer));
end;
function GetHeapByte(pos:TCellPtr):byte;
begin
     Move(heap[pos], GetHeapByte, sizeof(byte));
end;
{$pop}

procedure SetHeapCell(ptr:TCellPtr; val:TCell);
begin
        Move(val, heap[ptr], sizeof(TCell));
end;
procedure HeapifyHeader(hdr:THeaderPtr);
begin
        Move(hdr, heap[hptr], sizeof(Pointer));
        inc(hptr, sizeof(Pointer));
end;

procedure HeapifyByte(b:byte);
begin
        heap[hptr] := b;
        inc(hptr);
end;


procedure HeapifyCell(val:TCell);
begin
     Move(val, heap[hptr], sizeof(TCell));
     inc(hptr, sizeof(TCell));
end;
procedure HeapPointer(ptr:Pointer);
begin
        Move(ptr, heap[hptr], sizeof(Pointer));
        inc(hptr, sizeof(Pointer));
end;


function P_find(name:string): THeaderPtr;
begin
     P_find := latest;
     name := UpperCase(name);
     while (P_find <> Nil) and (P_find^.name^ <> name) do P_find := P_find^.link;
     if(P_find = Nil) then Raise exception.create(name + ' unfound');
end;

procedure HeapifyWord(name:string);
begin
     HeapPointer(P_find(name));
end;


procedure CreateHeader(immediate:byte; name:string; proc:TProc);
var h:THeaderPtr;
begin
     New(h);
     h^.link:= latest;
     h^.flags := immediate;
     h^.name:= NewStr(UpperCase(name));
     h^.codeptr := proc;
     h^.hptr := hptr; // top of the heap
     latest := h;
end;

procedure AddPrim(flags:byte; name:string; ptr:TProc);
begin
     CreateHeader(flags, name, ptr);
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
procedure PushExecStack(h:THeaderPtr);
begin
     inc(esp);
     execstack[esp] := h;
end;

procedure PopExecStack();
begin
     inc(esp, -1);
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

procedure P_lrb_create_rrb();
begin
     Push(TCell(wptr));
end;

procedure P_create();
begin
     P_word(); // read the name of the word being defined
     //writeln(' word being created is:', yytext);
     CreateHeader(0, yytext, @P_lrb_create_rrb); // it assumes its not immediate
     //HeapifyWord('BRANCH');
     //HeapifyCell(sizeof(TCell));
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
end;
procedure P_semicolon();
begin
     HeapPointer(P_find(';'));
     state := interpreting;
end;

procedure ExecHeader(ptr:THeaderPtr);
var ptr1:TProc;
begin
     PushExecStack(ptr);
     //writeln('Executing stack depth:', csp, ' ', ptr^.name^);


     ptr1 := TProc(ptr^.codeptr);
     wptr := ptr^.hptr;
     ptr1();
     PopExecStack();
end;

procedure DoCol(); // the inner interpreter
//var ip0:TCell;
label again, finis;
var hdr:THeaderPtr;
begin
   ip := wptr;
again:
   hdr := ToHeaderPtr(ip);
   if (hdr^.codeptr = @P_semicolon) or (hdr^.codeptr = @P_exit) then goto finis;



   rpush(ip + sizeof(Pointer));
   ExecHeader(hdr);
   ip := rpop();

   //inc(ip, sizeof(Pointer));
   goto again;

finis:

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

{* TODO this should allow for nested includes. See also ReadLine *}
procedure CreateReadStream(name:string);
begin
     //fpin := TFileStream.Create(name, fmOpenRead);
     fsstack.Add(TFileStream.Create(name, fmOpenRead));

end;

procedure ReadLine();
//var foo:TFileStream;
var ch:Char; fpin:TFileStream;
begin
     //fpin := Nil;
     //fpin := Nil;
     yypos := 1;

     {* just using "stdin" *}
     //if fpin = Nil then
     if fsstack.Count = 0 then
     begin
             //{$ifdef USES_ARM}
             ReadLinePtr(tib);
             //{$else}
             //readln(tib);
             //{$endif}
          if using_raspberry then writeln(''); // seems to be a quirk
          exit;
     end;

     {* we're inputting from a file *}
     tib := '';
     ch := #0;
     fpin := fsstack.Last;
     while (fpin.Read(ch, 1) = 1) and (ch <> #10) do tib += ch;
     if (fpin.Position >= fpin.Size) and (fsstack.count > 0) then
     begin
          //fpin.free();
          //fpin := Nil;
          //writeln('About to free');
          //fsstack.last.free();
          //write('About to delete fsstack top...');
          //writeln('Size of fsstack is:', fsstack.count);
          fsstack.Delete(fsstack.count-1);
          //writeln('Size of fsstack is now:', fsstack.count);
          //writeln('DONE');

     end;
     {*
     if (fpin.Read(ch, 1) = 0) then
     begin
          fpin.free();
          fpin := Nil;
     end;
     *}
     //writeln('ReadLine:tib:', tib);

end;

function yylex() : TTokenType;
label FindWord;
var len, pos0:Integer;
begin
        FindWord: // hunt around until we find a word
        //len := length(tib);
        if yypos > length(tib) then
        begin
           ReadLine()
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
        if (state = compiling) and mediate(h) then
        begin
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
     HeapifyCell(val);
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
end;

procedure P_branch();
var offset:TCell;
begin
     offset := GetHeapCell(rstack[rsp]);
     rstack[rsp] += offset;
end;
procedure P_abranch();
var offset:TCell;
begin
     offset := GetHeapCell(rstack[rsp]);
     rstack[rsp] := offset;
end;
procedure P_0branch();
var offset:TCell;
begin
     offset := GetHeapCell(rstack[rsp]);
     //writeln('branch offset:', offset);
     if Pop() = 0 then rstack[rsp] += offset else rstack[rsp] += sizeof(TCell);
end;

procedure P_backslash();
begin
     yypos := length(tib) +1 ; {* simulate an end of line *}
end;
procedure DisasterRecovery();
begin
     P_backslash(); {* just trash the input buffer *}
     IntStackSize := 0; {* reset the stack *}
     rsp := 0; {* reset the return stack? *}
     state := interpreting;

end;

procedure ProcessTib();
label again;
begin
     again:
     yyparse();
     if (yypos < length(tib)) and (not bye) then goto again;
end;

function MakeString():string;
var len, str, i:Integer;
begin
     MakeString := '';
     len := pop();
     str := pop();
     for i := 1 to len do MakeString += char(heap[str + i - 1]);
end;

procedure EvalString(str:string);
begin
     tib := str;
     yypos := 1;
     ProcessTib();
end;

procedure P_eval();
begin
     EvalString(MakeSTring());
     //tib := MakeString();
     //yypos := 1;
     //ProcessTib();
end;

procedure TryLoading(path:string);
begin
     write('Loading ', path, '...');
     try
           CreateReadStream(path);
           writeln('OK');
     except on E:Exception do
     	    writeln('FAILED');
     end;
end;

procedure MainRepl();
//var yytype:TTokenType;
//input:string;
begin
     TryLoading('boot.4th');

     while true do
     try
                ProcessTib();
                if bye then exit;
                //if (yypos >= length(tib)) and (fpin = Nil) then writeln(' ok');
                if (yypos >= length(tib)) and (fsstack.count = 0) then writeln(' ok');

     except
		on E: Exception do
                begin
			DumpExceptionCallStack(E);
                        DisasterRecovery();
                end;

     end;
end;

procedure StdinReadLn(var text:string);
begin
     readln(text);
end;

initialization
begin
          hptr := 1;
        using_raspberry := false;
        ReadLinePtr := @StdinReadLn;
        //procMap := TProcMap.Create;
        IntStackSize := 0;
        latest := Nil;
        //ip := 1;
        tib := '';
        yytext := '';
        yypos := 1;
        //dptr := 1;
        //heaptop := 1;

        state := interpreting;
        rsp := 0;
        esp := 0;
        bye := false;
        //fsstack.Create();
        fsstack := TFileSteamStack.Create;
        //New(fsstack);
        //fpin := Nil;
        //heap1 := malloc(10000);

        //ReadLinePtr := ^ReadLn;

        // prefix normal words with 0, immediate words with 1

        AddPrim(elit, 'BRANCH', @P_branch);
        AddPrim(elit, '0BRANCH', @P_0branch);
        AddPrim(elit, 'ABRANCH', @P_abranch);
        AddPrim(0, ':', @P_colon);
        AddPrim(1, ';', @P_semicolon);
        AddPrim(0, 'CREATE', @P_create);
        AddPrim(0, 'DOCOL', @docol);
        AddPrim(0, 'BYE', @P_bye);
        AddPrim(0, 'EXIT', @P_exit);
        AddPrim(elit, 'LIT', @P_lit);
        AddPrim(0, ',', @P_comma);
        AddPrim(1, '\', @P_backslash);
        AddPrim(0, '(CREATE)', @P_lrb_create_rrb);
        AddPrim(0, '$EVAL', @P_eval);
        //AddPrim(0, 'CONSTANT', @P_constant);

        //lookup('create');
end;

end.

