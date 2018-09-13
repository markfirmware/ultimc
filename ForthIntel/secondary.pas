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

procedure words();
//var d:Integer;
begin
     //d := latest;
     writeln();
end;

procedure P_tick();
var loc, loc1: TCell; iloc:Integer;
begin
     P_word();
     iloc := P_find(yytext);
     if iloc <> 0 then
     begin
             loc := iloc;
             loc1 := WordCodeptr(loc);
             Push(loc1);
     end;
end;
procedure P_execute();
var ptr:TCell;
begin
     ptr := Pop();
     ExecPointer(Pointer(ptr));
end;

initialization
begin
          AddAtomic(0, '+',  @P_plus);
          AddAtomic(0, '.', @P_dot);
          AddAtomic(0, 'DUP', @P_dup);
          AddAtomic(0, '.S',  @P_printstack);
          AddAtomic(0, 'INFO',  @P_info);
          AddAtomic(0, 'WORDS', @Words);
          AddAtomic(0, '''', @P_tick);
          AddAtomic(0, 'EXECUTE', @P_execute);

          writeln('Init:@PrintStack:',  Int64(@P_printstack));

end;
end.

