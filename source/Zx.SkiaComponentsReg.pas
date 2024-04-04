unit Zx.SkiaComponentsReg;

interface

procedure Register;

implementation

uses
  System.Classes,
  System.SysUtils,
  System.UITypes,
  FMX.Forms,
  FMX.Skia,
  FMX.Skia.Designtime.Editor.AnimatedImage,
  DesignEditors,
  DesignIntf,
  Zx.SvgBrushList,
  Zx.Text,
  Zx.Buttons,
  Zx.Styles.Objects;

type
  { copied from FMX.Skia.Designtime - TSkAnimatedImageSourcePropertyEditor }
  TZxAnimatedImageSourcePropertyEditor = class(TPropertyEditor)
  private
    function GetAniSource: TSkAnimatedImage.TSource;
  protected
    property AniSource: TSkAnimatedImage.TSource read GetAniSource;
  protected
    function GetIsDefault: Boolean; override;
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    class function TryEdit(var AData: TBytes): Boolean; static;
  end;

  { TZxAnimatedImageSourcePropertyEditor }

procedure TZxAnimatedImageSourcePropertyEditor.Edit;
var
  LData: TBytes;
begin
  LData := AniSource.Data;
  if TryEdit(LData) then
  begin
    AniSource.Data := LData;
    Modified;
  end;
end;

function TZxAnimatedImageSourcePropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog];
end;

function TZxAnimatedImageSourcePropertyEditor.GetIsDefault: Boolean;
begin
  Result := AniSource.Data <> nil;
end;

function TZxAnimatedImageSourcePropertyEditor.GetAniSource: TSkAnimatedImage.TSource;
begin
  Result := TZxAnimatedImageActiveStyleObject(GetComponent(0)).AnimatedImage.Source;
end;

function TZxAnimatedImageSourcePropertyEditor.GetValue: string;
begin
  Result := 'TSkAnimatedImage.TSource';
end;

class function TZxAnimatedImageSourcePropertyEditor.TryEdit(var AData: TBytes): Boolean;
var
  LAnimatedImageEditorForm: TSkAnimatedImageEditorForm;
begin
  LAnimatedImageEditorForm := TSkAnimatedImageEditorForm.Create(Application);
  try
    Result := LAnimatedImageEditorForm.ShowModal(AData) = mrOk;
  finally
    LAnimatedImageEditorForm.Free;
  end;
end;

procedure Register;
begin
  // Zx.SvgBrushList
  RegisterComponents('ZxSkia', [TZxSvgBrushList, TZxSvgGlyph]);
  // Zx.Text
  RegisterComponents('ZxSkia', [TZxText]);
  // Zx.Buttons
  RegisterComponents('ZxSkia', [TZxButton, TZxSpeedButton]);
  // Zx.Styles.Objects
  RegisterComponents('ZxSkia', [TZxColorActiveStyleObject, TZxAnimatedImageActiveStyleObject, TZxColorButtonStyleObject]);
  RegisterPropertyEditor(TypeInfo(TSkAnimatedImage.TSource), TZxAnimatedImageActiveStyleObject, 'AniSource',
    TZxAnimatedImageSourcePropertyEditor);
end;

end.
