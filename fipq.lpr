program fipq;

{$mode objfpc}{$H+}

{ QEMU VersatilePB Application                                                 }


uses
  QEMUVersatilePB
  , armall // , parser, secondary
  {*
  GlobalConfig,
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  SysUtils,
  Classes,
  Ultibo
  *}
;

begin
  //c_drive_required := False;
  StartArmAll();
end.

