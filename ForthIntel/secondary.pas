unit secondary;

{* useful words that are not fundamental to the core of forth *}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils
  ,parser
  , heapfuncs
  ;

implementation

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
     Push(TCell(h));

end;
procedure P_execute();
var ptr:THeaderPtr;
begin
     //writeln('Execute1');
     ptr := THeaderPtr(Pop());
     //writeln('Execute:',  ptr^.name^);
     ExecHeader(ptr);
end;


{* TODO fix case that word is literal, or ip++ is just plain wrong *}
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
     if (name = 'LIT') or (name = '0BRANCH') or (name = 'BRANCH') then
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
procedure P_compile_comma();
begin
     //writeln('compile, TODO');
     HeapifyCell(Pop());
end;

procedure P_backtick();
begin
     P_word();
     //writeln('backtick word:', yytext);
     HeapPointer(P_find('LIT'));
     //HeapifyCell(val)
     //HeapPointer(P_find(''''));
     HeapPointer(P_find(yytext));
     HeapPointer(P_find('compile,'));
      // val :=  GetHeapCell(rstack[rsp]);
     //rstack[rsp] += sizeof(TCell);
     //Push(val);
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
          AddPrim(0, 'IMMEDIATE', @P_immediate);
          AddPrim(0, '@', @P_at);
          AddPrim(0, '!', @P_exclaim);
          AddPrim(0, 'SWAP', @P_swap);
          AddPrim(0, 'NOT',  @P_not);
          AddPrim(1, 'IF', @P_if);
          AddPrim(1, 'THEN', @P_then);
          AddPrim(1, '`',@P_backtick);
          AddPrim(0, 'COMPILE,',@P_compile_comma);


          //writeln('Init:@PrintStack:',  Int64(@P_printstack));
          //P_words();
          //P_find('CREATE');

end;
end.

