program TelnetDemo;
{mode objfpc}{$h+}

uses
 {$ifdef BUILD_MODE_QEMUVPB} QEMUVersatilePB,  {$endif}
 {$ifdef BUILD_MODE_RPI    } BCM2835, BCM2708, {$endif}
 {$ifdef BUILD_MODE_RPI2   } BCM2836, BCM2709, {$endif}
 {$ifdef BUILD_MODE_RPI3   } BCM2837, BCM2710, {$endif}
 Threads, RemoteShell;

begin
 ThreadHalt(0);
end.
