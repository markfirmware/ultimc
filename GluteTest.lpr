program GluteTest;

{$mode objfpc}{$H+}
uses
        Glute
        , EdiGlute
        ;


{
procedure LexInput(input:string);
begin


        InitLexer(input);
        while yylex(yytext) <> Eof do
                writeln('yytext is:' + yytext);
end;
}

{
procedure GluteTest1();
begin
        LexInput('    hello123 ''this is a string'' world  ');

end;
}

function hi(vs:TVariantList):Variant;
{$push}{$warn 5024 off}
begin
        {writeln('hello world');}
        hi := 'hello world';
end;
{$pop}

procedure GluteRepl1();
begin
        AddGluteProc('hi', @hi);
        GluteRepl();
end;

begin
        {GluteTest1();}
        GluteRepl1();
end.

