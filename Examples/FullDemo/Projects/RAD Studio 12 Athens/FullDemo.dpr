program FullDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  {$IFDEF CompilerVersion < 36}
  Skia.FMX,
  {$ELSE}
  FMX.Skia,
  {$ENDIF }
  uFullDemo in '..\..\source\uFullDemo.pas' {frmFullDemo};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  GlobalUseSkia := True;
  Application.Initialize;
  Application.CreateForm(TfrmFullDemo, frmFullDemo);
  Application.Run;
end.
