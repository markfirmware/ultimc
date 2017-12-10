unit EdiGlute;

{$mode objfpc}{$H+}

interface

uses
	Classes, SysUtils
	, Glute
	, Edi
	;


implementation

function DoSayFile(vs:TVariantList):Variant;
{$push}{$warn 5024 off}
begin
        DoSayFile := Null;
	yylex(yytext);
	sayfile(yytext);
end;
{$pop}

initialization
begin
	AddGluteProc('sayfile', @DoSayFile);
end;


end.

