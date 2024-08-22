unit FullDemo.Styles;

interface

uses
  System.SysUtils,
  System.Classes,
  FMX.Types,
  FMX.Controls,
  Zx.StyleManager;

type
  TdmFullDemoStyles = class(TDataModule)
    sbMain: TStyleBook;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}
{$R *.dfm}

initialization

TZxStyleManager.AddStyles(TdmFullDemoStyles);

end.
