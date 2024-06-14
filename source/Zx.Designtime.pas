{************************************************************************}
{                                                                        }
{                           Zx-SkiaComponents                            }
{                                                                        }
{ Copyright (c) 2024 Zx-SkiaComponents Project.                          }
{                                                                        }
{ Use of this source code is governed by the MIT license that can be     }
{ found in the LICENSE file.                                             }
{                                                                        }
{************************************************************************}
unit Zx.Designtime;

interface

procedure Register;

implementation

uses
  System.Classes,
  System.SysUtils,
  System.UITypes,
  FMX.Forms,
  FmxImageListEditors,
{$IFDEF CompilerVersion < 36}
  Skia.FMX,
  Skia.FMX.Designtime.Editor.AnimatedImage,
{$ELSE}
  FMX.Skia,
  FMX.Skia.Designtime.Editor.AnimatedImage,
{$ENDIF}
  DesignEditors,
  DesignIntf,
  Zx.SvgBrushList,
  Zx.Text,
  Zx.Buttons,
  Zx.Styles.Objects,
  Zx.Designtime.SvgBrushList,
  Zx.AnimatedImageSourceList,
  Zx.Designtime.AnimatedImageSourceList;

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

  { TZxSvgBrushListComponentEditor }

  TZxSvgBrushListComponentEditor = class(TDefaultEditor)
  public
    procedure Edit; override;
    class function TryEdit(const ABrushList: TZxSvgBrushList): Boolean; static;
  end;

  { TZxAnimatedImageSourceListComponentEditor }

  TZxAnimatedImageSourceListComponentEditor = class(TDefaultEditor)
  public
    procedure Edit; override;
    class function TryEdit(const ASourceList: TZxAnimatedImageSourceList): Boolean; static;
  end;

  { TZxAnimatedImageSourcePropertyEditor }

procedure TZxAnimatedImageSourcePropertyEditor.Edit;
begin
  var
  LSource := AniSource;
  if LSource = nil then
    Exit;
  var
  LData := LSource.Data;
  if TryEdit(LData) then
  begin
    LSource.Data := LData;
    Modified;
  end;
end;

function TZxAnimatedImageSourcePropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog];
end;

function TZxAnimatedImageSourcePropertyEditor.GetIsDefault: Boolean;
begin
  var
  LSource := AniSource;
  Result := (LSource = nil) or (LSource.Data <> nil);
end;

function TZxAnimatedImageSourcePropertyEditor.GetAniSource: TSkAnimatedImage.TSource;
begin
  var
  LObject := GetComponent(0);
  if LObject is TZxAnimatedImageActiveStyleObject then
    Result := TZxAnimatedImageActiveStyleObject(LObject).AnimatedImage.Source
  else if LObject is TZxAnimatedImageSourceItem then
    Result := TZxAnimatedImageSourceItem(LObject).Source
  else
    Result := nil;
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

{ TZxSvgBrushListComponentEditor }

procedure TZxSvgBrushListComponentEditor.Edit;
begin
  if TryEdit(TZxSvgBrushList(Component)) then
    if Designer <> nil then
      Designer.Modified;
end;

class function TZxSvgBrushListComponentEditor.TryEdit(const ABrushList: TZxSvgBrushList): Boolean;
begin
  var
  LSvgBrushListEditorForm := TZxSvgBrushListEditorForm.Create(Application);
  try
    Result := LSvgBrushListEditorForm.ShowModal(ABrushList) = mrOk;
  finally
    LSvgBrushListEditorForm.Free;
  end;
end;

{ TZxAnimatedImageSourceListComponentEditor }

procedure TZxAnimatedImageSourceListComponentEditor.Edit;
begin
  if TryEdit(TZxAnimatedImageSourceList(Component)) then
    if Designer <> nil then
      Designer.Modified;
end;

class function TZxAnimatedImageSourceListComponentEditor.TryEdit(const ASourceList: TZxAnimatedImageSourceList): Boolean;
begin
  var
  LEditorForm := TZxAnimatedImageSourceListEditorForm.Create(Application);
  try
    Result := LEditorForm.ShowModal(ASourceList) = mrOk;
  finally
    LEditorForm.Free;
  end;
end;

procedure Register;
begin
  // Zx.SvgBrushList
  RegisterComponents('ZxSkia', [TZxSvgBrushList, TZxSvgGlyph]);
  RegisterComponentEditor(TZxSvgBrushList, TZxSvgBrushListComponentEditor);
  // Zx.AnimatedImageSourceList
  RegisterComponents('ZxSkia', [TZxAnimatedImageSourceList]);
  RegisterComponentEditor(TZxAnimatedImageSourceList, TZxAnimatedImageSourceListComponentEditor);
  RegisterPropertyEditor(TypeInfo(TSkAnimatedImage.TSource), TZxAnimatedImageSourceItem, 'Source',
    TZxAnimatedImageSourcePropertyEditor);
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
