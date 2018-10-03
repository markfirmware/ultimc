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
        TWritePtr = procedure(text:string);

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
        WritePtr:TWritePtr;



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


        blocks: array [1..64, 1..16] of string;
        blk, bln:Integer;


procedure ForthWriteLn(text:string);
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
procedure RunForthRepl();
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


procedure ForthWriteLn(text:string);
begin
        WritePtr(text);
        writePtr(AnsiChar(#10));
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
                forthwriteln('Stack underflow');
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
     CreateHeader(0, yytext, @P_lrb_create_rrb); // it assumes its not immediate
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
	forthwriteln(Report);
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
             ReadLinePtr(tib);
          if using_raspberry then forthwriteln(''); // seems to be a quirk
          exit;
     end;

     {* we're inputting from a file *}
     tib := '';
     ch := #0;
     fpin := fsstack.Last;
     while (fpin.Read(ch, 1) = 1) and (ch <> #10) do tib += ch;
     if (fpin.Position >= fpin.Size) and (fsstack.count > 0) then
     begin
          fsstack.Delete(fsstack.count-1);
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
        end
        else
        begin
                yylex := Word;
                yylval_text := yytext;
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
begin
     case yytype of
        Int: EvalInteger(yylval_i);
        Word: EvalWord(yylval_text);
        Eof: forthwriteln('EvalToken:Eof');
        else forthwriteln('EvalToken:unknown');
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
     if Pop() = 0 then rstack[rsp] += offset else rstack[rsp] += sizeof(TCell);
end;
procedure P_0abranch();
var offset:TCell;
begin
     offset := GetHeapCell(rstack[rsp]);
     if Pop() = 0 then rstack[rsp] := offset else rstack[rsp] += sizeof(TCell);
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
     writeptr(concat('Loading ', path, '...'));
     try
           CreateReadStream(path);
           forthwriteln('OK');
     except on E:Exception do
     	    forthwriteln('FAILED');
     end;
end;
procedure RunForthRepl();
begin
     while true do
     try
           ProcessTib();
           if bye then exit;
           if (yypos >= length(tib)) and (fsstack.count = 0) then forthwriteln(' ok');

     except
   	   on E: Exception do
           begin
   		DumpExceptionCallStack(E);
                   DisasterRecovery();
           end;
     end;

end;

procedure MainRepl();
//var yytype:TTokenType;
//input:string;
begin
     TryLoading('boot.4th');
     RunForthRepl();
end;

procedure StdinReadLn(var text:string);
begin
     readln(text);
end;

procedure StdoutWrite(text:string);
begin
     write(text);
end;


{$push}
{$hints off}   // hide warning var not initialized
function PopHeader():THeaderPtr;
begin
     PopHeader := THeaderPtr(Pop());
end;
{$pop}

procedure P_printstack();
var
        i:Integer;
begin
        for i := 1 to IntStackSize do
                writeptr(Format('%D ', [IntStack[i]])); // , ' '));
end;
procedure P_plus();
begin
        Push(Pop() + Pop());
end;
procedure P_minus();
begin
        Push(-Pop() + Pop());
end;
procedure P_mul();
begin
        Push(Pop() * Pop());
end;
procedure P_div();
var t1,t2:TCell;
begin
        t1 := Pop();
        t2 := Pop();
        Push(t2 div t1);
end;
procedure P_gt();
var t1,t2:TCell;
begin
        t1 := Pop();
        t2 := Pop();
        if t2 > t1 then Push(1) else Push(0);
end;
procedure P_lt();
var t1,t2:TCell;
begin
        t1 := Pop();
        t2 := Pop();
        if t2 < t1 then Push(1) else Push(0);
end;
procedure P_eq();
var t1,t2:TCell;
begin
        t1 := Pop();
        t2 := Pop();
        if t2 = t1 then Push(1) else Push(0);
end;


procedure P_dot();
begin
        writeptr(Format('%D ', [Pop()])); // , ' ');
end;

procedure P_dup();
var i:Integer;
begin
        i := Pop();
        Push(i);
        Push(i);
end;
procedure P_xcept();
begin
	Raise exception.create('Xcept exception test');
end;

procedure PrintSize(TypeName:string; TypeSize:Integer);
begin
        writeptr(concat(TypeName, '(', inttostr(TypeSize), '), '));
end;

procedure P_info();
begin
        writeptr('sizes: ');
        PrintSize('cell', sizeof(TCell));
        PrintSize('int', sizeof(Integer));
        PrintSize('int64', sizeof(Int64));
        PrintSize('pointer', sizeof(Pointer));
        forthwriteln('Require sizes cell = pointer');
end;

procedure P_words();
var d:THeaderPtr;
begin
     d := latest;
     while d <> Nil do
     begin
       forthwriteln(d^.name^);
       d := d^.link;
     end;
end;

procedure P_tick();
var h:THeaderPtr; //h64:Int64;
begin
     P_word();
     h := P_find(yytext);
     //h64 := Int64(h);
     //Push(TCell(h));
     HeapifyHeader(h);

end;
procedure P_execute();
var ptr:THeaderPtr;
begin
     //ptr := THeaderPtr(Pop());
     ptr := PopHeader();
     ExecHeader(ptr);
end;


procedure P_see();
var hdr:THeaderPtr; ip:Integer;name:String; flags:byte; is_imm:byte;
label again;
begin
     P_word();
     hdr := P_find(yytext);

     flags := hdr^.flags;
     is_imm := flags and 1;
     if(hdr^.codeptr <> @Docol) then
     begin
             writeptr(Uppercase(yytext));
             writeptr(' is primitive ');
             if (is_imm  = 1) then writeptr('IMMEDIATE ');
             forthwriteln('');
             exit;
     end;

     ip := hdr^.hptr;
again:
     hdr := ToHeaderPtr(ip);
     name := hdr^.name^;
     writeptr(name);
     writeptr(' ');
     if (hdr^.flags and elit) > 0 then
     begin
             inc(ip, sizeof(Pointer));
             write(GetHeapCell(ip), ' '); // TODO soprt this out
     end;
     inc(ip, sizeof(Pointer));

     if name <> ';' then goto again;
     if (is_imm  = 1) then writeptr('IMMEDIATE ');

end;
procedure P_lsb();
begin
     state := interpreting;
end;
procedure P_rsb();
begin
     state := compiling;
end;
procedure P_cell();
begin
     Push(sizeof(TCell));
end;
procedure P_clearstack();
begin
     IntStackSize := 0;
end;

procedure P_include();
begin
     P_word();
     CreateReadStream(yytext);
end;
procedure P_here();
begin
     Push(hptr);
end;

procedure P_allot();
begin
     hptr += pop();
end;

procedure P_immediate();
//var offset:TCellPtr; flags:byte;
begin
     latest^.flags:= latest^.flags or 1;
end;
procedure P_at();
begin
     Push(GetHeapCell(Pop));
end;

procedure P_exclaim();
var pos:TCellPtr; val:Tcell;
begin
     pos := Pop();
     val := Pop();
     SetHeapCell(pos, val);
end;

procedure P_latest();
begin
     //push(TCell(latest));
     HeapifyHeader(latest);
end;

procedure P_to_hptr();
var hdr: THeaderPtr;
begin
     //hdr := THeaderPtr(Pop());
     hdr := PopHeader();
     push(hdr^.hptr);
end;
procedure P_swap();
var t1,t2:TCell;
begin
     t1 := Pop();
     t2 := Pop();
     Push(t1);
     Push(t2);
end;

procedure P_not();
begin
     if Pop() = 0 then Push(1) else Push(0);
end;


procedure EmbedLiteral(val:TCell);
begin
     HeapifyWord('LIT');
     HeapifyCell(val);
end;
procedure P_if();
begin
     //HeapPointer(P_find('0ABRANCH'));
     HeapifyWord('0ABRANCH');
     P_here();
     HeapPointer(Pointer($BAD)); // this is backpatched later by THEN ($BAD = 2989)
end;

procedure P_then();
//var  backpatch, offset:TCell;
begin
     //backpatch := Pop();
     //offset := hptr - backpatch;
     //SetHeapCell(backpatch, offset);
     SetHeapCell(Pop(), hptr);
end;

procedure P_else();
var where:Integer;
begin
     HeapifyWord('ABRANCH');
     where := hptr;
     HeapPointer(Pointer($BAD));
     HeapifyWord('BRANCH');
     P_then();
     //HeapPointer(Pointer($BAD));
     Push(where);

end;
procedure P_begin();
begin
     P_here();
end;
procedure P_again();
begin
     HeapifyWord('ABRANCH');
     HeapifyCell(Pop());
end;

procedure P_compile_comma();
begin
     HeapifyCell(Pop());
end;

procedure P_backtick();
begin
     P_word();
     HeapPointer(P_find('LIT'));
     HeapPointer(P_find(yytext));
     HeapPointer(P_find('compile,'));
end;


procedure P_colon_noname();
var h:THeaderPtr; s:PString;
begin

     New(s);
     s^ := 'UNNAMED';
     // almost as for CreateHeader
     New(h);
     h^.link:= latest;
     h^.flags := 0 ; //immediate;
     h^.name:= s;
     h^.codeptr := @DoCol;
     h^.hptr := hptr; // top of the heap
     state := compiling;
     //Push(TCell(h));
     HeapifyHeader(h);

end;



procedure P_string();
var count, pos:TCell;
begin
     if state = compiling then // P_if() else P_here();
     begin
             HeapifyWord('ABRANCH');
             pos := hptr;
             HeapPointer(Pointer($BAD));
     end
     else  P_here();


     count := 0;
     inc(yypos);
     while (yypos <= length(tib)) and (tib[yypos] <> '"') do
     begin
       HeapifyByte(Byte(tib[yypos]));
       inc(yypos);
       inc(count);
     end;
     inc(yypos);

     if state = compiling then
     begin
             SetHeapCell(pos, hptr);
             EmbedLiteral(pos+sizeof(TCell));
             EmbedLiteral(count);
     end
     else Push(count);
end;

procedure P_type();
var n, i, pos:TCell;
begin
     n := Pop();
     pos := Pop();
     for i := 1 to n do writeptr(char(GetHeapByte(pos+i-1)));
end;

procedure P_cr();
begin
     forthwriteln('');
end;
procedure P_over();
var x1:TCell;
begin
     x1 :=  IntStack[IntStackSize-1];
     Push(x1);
        //IntStackSize:Integer;
end;

procedure P_self();
var hdr:THeaderPtr;
begin
     hdr := execstack[esp-1];
     //Push(TCell(hdr));
     HeapifyHeader(hdr);
end;
procedure P_dot_name();
var h:TheaderPtr;
begin
     //h := THeaderPtr(Pop());
     h := PopHeader();
     writeptr(h^.name^);
end;

procedure P_literal();
begin
     HeapifyWord('LIT');
     HeapifyCell(Pop());
end;


procedure P_drop();
begin
     pop();
end;


procedure P_estack();
var hdr:THeaderPtr;
begin
     hdr := execstack[esp-Pop()];
     //Push(TCell(hdr));
     HeapifyHeader(hdr);
end;

procedure P_to_body();
var hdr:THeaderPtr; offset:TCell;
begin
     //hdr := THeaderPtr(Pop());
     hdr := PopHeader();
     offset := hdr^.hptr;
     Push(offset);

end;

procedure P_bra_does();
var branch_pos, loc_pos, offset, does_loc: Tcell; prior:TheaderPtr;
begin

     does_loc := Pop();
     {* prove that cell before the offset is an exit statement *}
     prior :=  ToHeaderPtr(does_loc - sizeof(TCell));
     assert(prior^.name^ = 'EXIT');

     branch_pos := latest^.hptr + 3*sizeof(TCell);
     SetHeapCell(branch_pos, does_loc);

     loc_pos := latest^.hptr + sizeof(TCell);
     offset := loc_pos + 4*sizeof(TCell); // point to just after the ';'
     SetHeapCell(loc_pos, offset);

end;



procedure P_does();
begin
     EmbedLiteral(hptr + 4* sizeof(TCell)); // point to after the embedded exit
     HeapifyWord('(DOES>)');
     HeapifyWord('EXIT');
end;
procedure P_builds();
begin
     P_word(); // read the name of the word being defined
     CreateHeader(0, yytext, @Docol);
     EmbedLiteral(777);
     HeapifyWord('ABRANCH');
     HeapifyCell(888);
     HeapifyWord(';');
end;

procedure P_l_oto_r();
var newval, pos:TCell;
begin
     pos := rstack[rsp] + sizeof(TCell);
     newval :=  GetHeapCell(pos) -1;
     if newval < 0 then newval := 0;
     SetHeapCell(pos, newval);
end;

procedure P_oto();
begin
     HeapifyWord('(OTO)');
     EmbedLiteral(2);
end;

procedure P_fileexists();
begin
     Push(TCell(FileExists(MakeString())));
end;

procedure P_FileOpen();
var mode:TCell; fname:string;
begin
     mode := Pop();
     fname :=  MakeString();
     Push(FileOpen(fname, mode));
end;

procedure P_FileClose();
begin
     FileClose(pop());
end;

procedure P_FileRead();
var count,buf, handle: TCell; addr:Pointer;
//var i:Integer;
begin
     count := pop();
     buf := pop();
     handle := pop();
     addr := buf + @heap -1 ;
     Push(FileRead(handle, addr^, count));
end;

procedure DefConst(val:TCell; str:string);
begin
     push(val);
     str := 'constant ' + str;
     EvalString(str);
end;

procedure P_prb();
var i:integer;
begin
     for i := 1 to 16 do
     begin
          write(i); // TODO sort this out
          if i < 10 then write(' ');
          if i = bln then write('>') else writeptr(' ');
          forthwriteln(blocks[blk, i]);
     end;
end;

procedure P_slt();
begin
     blocks[blk, bln] := MakeString();
end;
procedure P_savb();
var b, l:integer; f: TextFile;
begin
     AssignFile(f, 'blocks.dat');
     Rewrite(f);
     for b := 1 to 64 do
     for l := 1 to 16 do
     begin
          forthwriteln('P_savb TODO');
          //forthwriteln(f, blocks[b, l]); // TODO
     end;
     CloseFile(f);
end;

procedure  P_lodb();
var b, l:integer; f: TextFile;
begin
     AssignFile(f, 'blocks.dat');
     Reset(f);
     for b := 1 to 64 do
     for l := 1 to 16 do
     begin
          readln(f, blocks[b, l]);
     end;
     CloseFile(f);
end;
procedure P_cat();
var f:File; buf: array[1..2048] of byte; NumRead:SmallInt; i:integer;fname:string;
begin
     NumRead := 0; buf[1] := 0; // dummy initialisation
     fname := MakeString();
     AssignFile(f, fname);
     Reset(f, 1);
     repeat
       BlockRead(f, buf, sizeof(buf), NumRead);
       for i:= 1 to NumRead do writeptr(char(buf[i]));
     until NumRead = 0;
     Close(f);

end;

procedure P_cl();
label again;
var str:string;
begin
     again:
     readln(str);
     if str = '.' then exit;
     blocks[blk, bln] := str;
     if (bln >= 16) then exit;
     inc(bln);
     goto again;
end;

function clamp(v,lo, hi: integer):Integer;
begin
     clamp := v;
     if clamp < lo then clamp := lo;
     if clamp > hi then clamp := hi;
end;

procedure P_sl();
begin
     bln := clamp(pop(), 1, 16);
end;

procedure P_sb();
begin
     blk := clamp(pop(), 1, 64);
end;
procedure P_xl();
begin
     EvalString(blocks[blk, bln]);
end;
procedure P_xb();
var l:integer;
begin
     //str := '';
     for l := 1 to 16 do EvalString(blocks[blk, l]);

end;

procedure P_rot(); // ( a b c -- b c a)
var a,b,c:TCell;
begin
     c := Pop();
     b := Pop();
     a := Pop();
     Push(b);
     Push(c);
     Push(a);
end;


initialization
begin
          hptr := 1;
        using_raspberry := false;
        ReadLinePtr := @StdinReadLn;
        WritePtr := @StdoutWrite;
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
        AddPrim(elit, '0ABRANCH', @P_0abranch);
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


        AddPrim(0, '+', @P_plus);
          AddPrim(0, '-', @P_minus);

          AddPrim(0, '*', @P_mul);
          AddPrim(0, '/', @P_div);
          AddPrim(0, '.', @P_dot);
          AddPrim(0, '>', @P_gt);
          AddPrim(0, '<', @P_lt);
          AddPrim(0, '=', @P_eq);
          AddPrim(0, 'DUP', @P_dup);
          AddPrim(0, '.S',  @P_printstack);
          AddPrim(0, 'INFO',  @P_info);
          AddPrim(0, 'WORDS', @P_words);
          AddPrim(0, '''', @P_tick);
          AddPrim(0, 'EXECUTE', @P_execute);
          AddPrim(0, 'SEE', @P_see);
          AddPrim(1, '[', @P_lsb);
          AddPrim(1, ']', @P_rsb);
          AddPrim(0, 'CELL', @P_cell);
          AddPrim(0, 'CLEARSTACK', @P_clearstack);
          AddPrim(0, 'INCLUDE', @P_include);
          AddPrim(0, 'HERE', @P_here);
          AddPrim(0, 'ALLOT', @P_allot);
          AddPrim(0, 'IMMEDIATE', @P_immediate);
          AddPrim(0, '@', @P_at);
          AddPrim(0, '!', @P_exclaim);
          AddPrim(0, 'LATEST', @P_latest);
          AddPrim(0, '>HPTR', @P_to_hptr);
          AddPrim(0, 'SWAP', @P_swap);
          EvalString(': NEG 0 swap - ;');
          AddPrim(0, 'NOT',  @P_not);
          EvalString(': >= < NOT ;');
          EvalString(': <= > NOT ;');
          EvalString(': != = NOT ;');
          AddPrim(1, 'IF', @P_if);
          AddPrim(1, 'ELSE', @P_else);
          AddPrim(1, 'THEN', @P_then);
          AddPrim(1, 'BEGIN', @P_begin);
          AddPrim(1, 'AGAIN', @P_again);
          AddPrim(1, '`',@P_backtick);
          AddPrim(0, 'COMPILE,',@P_compile_comma);
          AddPrim(1, 'DOES>', @P_does);
          AddPrim(0, '<BUILDS', @P_builds);
          AddPrim(0, '(DOES>)', @P_bra_does);
          EvalString(': CONSTANT <BUILDS , DOES> @ ;');



          //AddPrim(0, '[:', @P_def_anon_begin);
          //AddPrim(0, ';]', @P_def_anon_end);
          AddPrim(0, ':NONAME', @P_colon_noname);
          AddPrim(1, 's"', @P_string);
          AddPrim(0, 'TYPE', @P_type);
          AddPrim(0, 'CR', @P_cr);
          AddPrim(0, 'OVER', @P_over);
          AddPrim(0, 'SELF', @P_self);
          AddPrim(0, '.NAME', @P_dot_name);
          AddPrim(0, 'ESTACK', @P_estack);
          AddPrim(1, 'LITERAL', @P_literal);
          AddPrim(0, 'DROP', @P_drop);
          AddPrim(0, '>BODY', @P_to_body);
          AddPrim(1, 'OTO', @P_oto);
          AddPrim(0, '(OTO)', @P_l_oto_r);

          AddPrim(0, 'FILEEXISTS', @P_fileexists);
          AddPrim(0, 'FILEOPEN', @P_FileOpen);
          AddPrim(0, 'FILECLOSE', @P_FileClose);
          AddPrim(0, 'FILEREAD', @P_FileRead);
          DefConst(fmOpenRead, 'r/o');
          DefConst(fmOpenWrite, 'w/o');
          DefConst(fmOpenReadWrite, 'r/w');

          { blocks }
          blk := 1;
          bln := 1;
          Addprim(0, 'prb', @P_prb);
          AddPrim(0, 'slt', @P_slt);
          AddPrim(0, 'savb', @P_savb);
          AddPrim(0, 'lodb', @P_lodb);
          AddPrim(0, 'cl', @P_cl);
          AddPrim(0, 'sl', @P_sl);
          AddPrim(0, 'sb', @P_sb);
          AddPrim(0, 'xl', @P_xl);

          AddPrim(0, 'cat', @P_cat);
          AddPrim(0, 'ROT', @P_rot);

          EvalString(': VARIABLE      create 0 , ;');
          EvalString(': CELLS         cell * ; \ n1 -- n2');
          EvalString(': 2VARIABLE     create 0 , 0 , ;');
          EvalString(': CELL+         cell + ;');
          EvalString(': 2@            dup cell+ @ swap @ ;');
          EvalString(': 2!            swap over ! cell+ ! ;');
          EvalString(': !0exit ` 0branch 2 cells , ` exit ; immediate');
          EvalString(': 0exit  ` not ` 0branch 2 cells , ` exit ; immediate');
          EvalString(': 1- 1 - ;');

end;

end.

