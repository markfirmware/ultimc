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
var h:THeaderPtr;
begin
     P_word();
     h := P_find(yytext);
     if h = Nil then
     begin
             writeln(Uppercase(yytext), ' undefined');
             exit;
     end;

     Push(Int64(h));
//     Push(TCell(Pointer(h)));
     //Push(Int64(h^.codeptr));
     {*
     if iloc <> 0 then
     begin
             loc := iloc;
             loc1 := WordCodeptr(loc);
             Push(loc1);
     end;
     *}
end;
procedure P_execute();
var ptr:THeaderPtr;
begin
     ptr := THeaderPtr(Pop());
     ExecPointer(ptr);
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

          writeln('Init:@PrintStack:',  Int64(@P_printstack));
          P_words();
          P_find('CREATE');

end;
end.

