{ ************************************************************************** }
{ *                                                                        * }
{ *                           Zx-SkiaComponents                            * }
{ *                                                                        * }
{ *           Copyright (c) 2025 Zx-SkiaComponents Project.                * }
{ *                                                                        * }
{ * Use of this source code is governed by the MIT license that can be     * }
{ * found in the LICENSE file.                                             * }
{ *                                                                        * }
{ ************************************************************************** }
unit FullDemo.Main;

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
{$IFDEF CompilerVersion < 36}
  Skia,
  Skia.FMX,
{$ELSE}
  FMX.Skia,
  System.Skia,
{$ENDIF}
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
  FMX.Objects,
  Zx.Controls;

type
  TfrmFullDemo = class(TForm)
    sblExamples: TZxSvgBrushList;
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
    btnAniLoopTrigger: TZxButton;
    layStylesExample3: TLayout;
    btnTextStyle: TZxButton;
    btnCombined: TZxButton;
    procedure btnGlyphClick(Sender: TObject);
    procedure btnMultilineClick(Sender: TObject);
  private const
    CMultilineText1 = 'A button can also be multiline!';
    CMultilineText2 = 'Autosize';
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
    btnMultiline.Text := CMultilineText1;
  end
  else
  begin
    btnMultiline.ImageIndex := 0;
    btnMultiline.Text := CMultilineText2;
  end;
end;

end.
