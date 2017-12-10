unit GimpPpmGlute;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Framebuffer, GimpPpm, Glute;

var
  m_fb :PFramebufferDevice;

procedure SetGimpPpmGluteFb(Fb:PFramebufferDevice);

implementation

procedure SetGimpPpmGluteFb(Fb:PFramebufferDevice);
begin
  m_fb := fb;
end;

function display(vs:TVariantList):variant;
{$push}{$warn 5024 off}
begin
  yylex(yytext);
  LoadPpm(yytext);
  FramebufferDevicePutRect(m_fb, 0, 0, PpmBuffer, PpmWidth, PpmHeight, 0,  FRAMEBUFFER_TRANSFER_DMA);
  FreeMem(PpmBuffer);
  display := Null;
end;
{$pop}

initialization
begin
  AddGluteProc('display', @display);
end;

end.

