unit secondary;

{* useful words that are not fundamental to the core of forth *}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils
  ,parser
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
var hdr:THeaderPtr; ip:Integer;name:String;
label again;
begin
     P_word();
     hdr := P_find(yytext);

     if(hdr^.codeptr <> @Docol) then
     begin
             writeln(Uppercase(yytext), ' is primitive');
             exit;
     end;

     ip := hdr^.hptr;
again:
     hdr := ToHeaderPtr(ip);
     name := hdr^.name^;
     write(name, ' ');
     inc(ip, sizeof(Pointer));
     if name <> ';' then goto again;

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

initialization
begin
          AddPrim(0, '+',  @P_plus);
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

          //writeln('Init:@PrintStack:',  Int64(@P_printstack));
          //P_words();
          //P_find('CREATE');

end;
end.

