program fipq;

{$mode objfpc}{$H+}

{ QEMU VersatilePB Application                                                 }


uses
    {$ifdef BUILD_MODE_QEMUVPB} QEMUVersatilePB,  {$endif}
  {$ifdef BUILD_MODE_RPI    } BCM2835, BCM2708, {$endif}
  {$ifdef BUILD_MODE_RPI2   } BCM2836, BCM2709, {$endif}
  {$ifdef BUILD_MODE_RPI3   } BCM2837, BCM2710, {$endif}
  //QEMUVersatilePB
  armall

;

begin
  //c_drive_required := False;
  StartArmAll();
end.

