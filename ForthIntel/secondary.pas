unit secondary;

{* useful words that are not fundamental to the core of forth *}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils
  ,parser
  ;

implementation

procedure PrintStack();
var
        i:Integer;
begin
        //writeln('PrintStack called');
        for i := 1 to IntStackSize do
                write(IntStack[i], ' ');
end;


initialization
begin
          AddAtomic(0, '.S',  @PrintStack);
          writeln('Init:@PrintStack:',  Int64(@PrintStack));

end;
end.

