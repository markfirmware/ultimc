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
procedure P_info();
begin
     writeln('Sizeof:Integer: ', sizeof(Integer));
     writeln('Sizeof:Int64:   ', sizeof(Int64));
     writeln('Sizeof:Pointer: ', sizeof(Pointer));
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
var h:THeaderPtr; h64:Int64;
begin
     P_word();
     h := P_find(yytext);
     h64 := Int64(h);
     //HeapifyHeader(h);
     Push(h64);

end;
procedure P_execute();
var ptr:THeaderPtr;
begin
     //writeln('Execute1');
     ptr := THeaderPtr(Pop());
     //writeln('Execute:',  ptr^.name^);
     ExecHeader(ptr);
end;

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

          //writeln('Init:@PrintStack:',  Int64(@P_printstack));
          //P_words();
          //P_find('CREATE');

end;
end.

