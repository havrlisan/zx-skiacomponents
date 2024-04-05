unit uFullDemo;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  System.Skia,
  FMX.Skia,
  Zx.SvgBrushList,
  System.ImageList,
  FMX.Edit,
  FMX.Layouts,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  Zx.Buttons,
  System.Actions,
  FMX.ActnList,
  Zx.TextControl,
  Zx.Text,
  FMX.Objects;

type
  TfrmFullDemo = class(TForm)
    sblExamples: TZxSvgBrushList;
    sbMain: TStyleBook;
    vsbMain: TVertScrollBox;
    txtExample: TZxText;
    txtSection1: TZxText;
    txtSection2: TZxText;
    Line1: TLine;
    btnGlyph: TZxButton;
    btnMultiline: TZxSpeedButton;
    layButtonExample1: TLayout;
    layButtonExample2: TLayout;
    alMain: TActionList;
    Action1: TAction;
    txtButtonsClickFeature: TZxText;
    Line2: TLine;
    txtSection3: TZxText;
    layStylesExample1: TLayout;
    btnColorActive: TZxButton;
    txtButtonsActionCompatible: TZxText;
    layStylesExample2: TLayout;
    btnAnimatedImageActive: TZxButton;
    btnButtonStyle: TZxButton;
    lblTitle: TSkLabel;
    Line3: TLine;
    ZxButton1: TZxButton;
    procedure btnGlyphClick(Sender: TObject);
    procedure btnMultilineClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmFullDemo: TfrmFullDemo;

implementation

{$R *.fmx}

procedure TfrmFullDemo.btnGlyphClick(Sender: TObject);
begin
  if btnGlyph.ImageIndex < sblExamples.Count - 1 then
    btnGlyph.ImageIndex := btnGlyph.ImageIndex + 1
  else
    btnGlyph.ImageIndex := 0;
end;

procedure TfrmFullDemo.btnMultilineClick(Sender: TObject);
begin
  if btnMultiline.ImageIndex = 0 then
  begin
    btnMultiline.ImageIndex := 3;
    btnMultiline.Text := 'A button can also be multiline!';
  end
  else
  begin
    btnMultiline.ImageIndex := 0;
    btnMultiline.Text := 'Autosize FTW';
  end;
end;

end.
