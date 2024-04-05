program FullDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Skia,
  uFullDemo in 'source\uFullDemo.pas' {frmFullDemo};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  GlobalUseSkia := True;
  Application.Initialize;
  Application.CreateForm(TfrmFullDemo, frmFullDemo);
  Application.Run;
end.
