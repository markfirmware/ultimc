unit secondary;

{* useful words that are not fundamental to the core of forth *}

{$mode objfpc}{$H+}

interface



uses
  Classes, SysUtils
  ,parser
  ;


var
        blocks: array [1..64, 1..16] of string;
        blk, bln:Integer;




implementation
//uses
 //ultiboapi;

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
        //writeln('PrintStack called');
        for i := 1 to IntStackSize do
                write(IntStack[i], ' ');
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
        //t3 := t1/t2;
        Push(t2 div t1);
end;
procedure P_dot();
begin
        write(Pop(), ' ');
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
        write(TypeName, '(', TypeSize, '), ');
end;

procedure P_info();
begin
        write('sizes: ');
        PrintSize('cell', sizeof(TCell));
        PrintSize('int', sizeof(Integer));
        PrintSize('int64', sizeof(Int64));
        PrintSize('pointer', sizeof(Pointer));
        writeln('Require sizes cell = pointer');
end;

procedure P_words();
var d:THeaderPtr;
begin
     d := latest;
     while d <> Nil do
     begin
       writeln(d^.name^);
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
             write(Uppercase(yytext), ' is primitive ');
             if (is_imm  = 1) then write('IMMEDIATE ');
             writeln();
             exit;
     end;

     ip := hdr^.hptr;
again:
     hdr := ToHeaderPtr(ip);
     name := hdr^.name^;
     write(name, ' ');
     if (hdr^.flags and elit) > 0 then
     begin
             inc(ip, sizeof(Pointer));
             write(GetHeapCell(ip), ' ');
     end;
     inc(ip, sizeof(Pointer));

     if name <> ';' then goto again;
     if (is_imm  = 1) then write('IMMEDIATE ');

     //writeln('seeing ', h^.name^);
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
     HeapPointer(P_find('0BRANCH'));
     P_here();
     HeapPointer(Pointer($BAD)); // this is backpatched later by THEN ($BAD = 2989)
end;
procedure P_then();
var  backpatch, offset:TCell;
begin
     backpatch := Pop();
     offset := hptr - backpatch;
     SetHeapCell(backpatch, offset);
end;
procedure P_begin();
begin
     //HeapifyWord('BRANCH');
     P_here();
     //HeapPointer(Pointer($BAD));
end;
procedure P_again();
begin
     HeapifyWord('ABRANCH');
     //HeapPointer(Pointer(Pop()));
     HeapifyCell(Pop());
end;

procedure P_compile_comma();
begin
     //writeln('compile, TODO');
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
     //writeln('string:<',
end;

procedure P_type();
var n, i, pos:TCell;
begin
     n := Pop();
     pos := Pop();
     for i := 1 to n do write(char(GetHeapByte(pos+i-1)));
end;

procedure P_cr();
begin
     writeln();
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
     write(h^.name^);
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
     //prior :=  THeaderPtr(GetHeapCell(does_loc - sizeof(TCell)));
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
     //writeln('builds created docol:', yytext);
end;

procedure P_l_oto_r();
var newval, pos:TCell;
begin
     pos := rstack[rsp] + sizeof(TCell);
     newval :=  GetHeapCell(pos) -1;
     if newval < 0 then newval := 0;
     SetHeapCell(pos, newval);
     //if GetHeapCell(pos) = 1 then SetHeapCell(pos, 0);
     //writeln(' oto value is:', pos, ' ', GetHeapCell(pos));
end;

procedure P_oto();
begin
     //writeln('oto info:', hptr);
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

     //write('contents:');
     //for i := 1 to 10 do write(char(heap[buf +i-1]));
     //writeln();

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
          write(i);
          if i < 10 then write(' ');
          if i = bln then write('>') else write(' ');
          writeln(blocks[blk, i]);
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
          writeln(f, blocks[b, l]);
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
     //writeln('File name is:', fname);
     AssignFile(f, fname);
     Reset(f, 1);
     repeat
       BlockRead(f, buf, sizeof(buf), NumRead);
       //writeln('Bytes REad:', NumRead);
       for i:= 1 to NumRead do write(char(buf[i]));
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

initialization
begin
          AddPrim(0, '+', @P_plus);
          AddPrim(0, '-', @P_minus);
          AddPrim(0, '*', @P_mul);
          AddPrim(0, '/', @P_div);
          AddPrim(0, '.', @P_dot);
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
          AddPrim(0, 'NOT',  @P_not);
          AddPrim(1, 'IF', @P_if);
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

          EvalString(': VARIABLE      create 0 , ;');
          EvalString(': CELLS         cell * ; \ n1 -- n2');
          EvalString(': 2VARIABLE     create 0 , 0 , ;');
          EvalString(': CELL+         cell + ;');
          EvalString(': 2@            dup cell+ @ swap @ ;');
          EvalString(': 2!            swap over ! cell+ ! ;');
          EvalString(': !0exit ` 0branch 2 cells , ` exit ; immediate');
          EvalString(': 0exit  ` not ` 0branch 2 cells , ` exit ; immediate');

          //UltiboApiAddPrimitives;

          //writeln('Init:@PrintStack:',  Int64(@P_printstack));
          //P_words();
          //P_find('CREATE');

end;
end.

