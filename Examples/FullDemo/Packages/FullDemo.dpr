program FullDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  FullDemo.Startup in '..\source\FullDemo.Startup.pas',
  FullDemo.Styles in '..\source\FullDemo.Styles.pas' {dmFullDemoStyles: TDataModule},
  FullDemo.Main in '..\source\FullDemo.Main.pas' {frmFullDemo};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.CreateForm(TfrmFullDemo, frmFullDemo);
  Application.Run;
end.
