{ ************************************************************************** }
{ *                                                                        * }
{ *                           Zx-SkiaComponents                            * }
{ *                                                                        * }
{ *           Copyright (c) 2026 Zx-SkiaComponents Project.                * }
{ *                                                                        * }
{ * Use of this source code is governed by the MIT license that can be     * }
{ * found in the LICENSE file.                                             * }
{ *                                                                        * }
{ ************************************************************************** }
unit Zx.Designtime;

interface

procedure Register;

implementation

uses
  System.Classes,
  System.SysUtils,
  System.IOUtils,
  System.UITypes,
  FMX.Forms,
  FMX.Controls,
  FMX.Styles,
  FMX.Types,
  FMX.DialogService,
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
  ToolsAPI,
  Zx.SvgBrushList,
  Zx.Text,
  Zx.Buttons,
  Zx.Styles.Objects,
  Zx.StyleBook,
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

  { TZxStyleBookEditor }

  {
    Component editor that brings FMX's native Style Designer back to our
    TZxStyleBook (which is intentionally not a TStyleBook descendant, so the
    built-in editor wouldn't apply to it on its own).

    Flow: clone our TZxStyleBook's state into a temporary TStyleBook, ask the
    IDE for the editor registered against TStyleBook, invoke its Edit, and
    hook FreeNotification on the Style Designer window. When the user closes
    the designer, we asynchronously pop a "apply / discard" prompt and then
    copy the edited state back. This keeps the Style Designer fully usable
    (no competing modal) while it is open.
  }
  TZxStyleBookEditor = class(TComponentEditor)
  public
    procedure Edit; override;
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

  TZxStyleBookEditSession = class(TComponent)
  private
    FTempBook: TStyleBook;
    [Weak] FTargetBook: TZxStyleBook;
    FDesigner: IDesigner;
    FDesignerForm: TComponent;
    FFinished: Boolean;
    procedure Finish;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(const ATargetBook: TZxStyleBook;
      const ADesigner: IDesigner); reintroduce;
    destructor Destroy; override;
    function Start: Boolean;
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

{ TZxStyleBookEditor / TZxStyleBookEditSession }

const
  SStyleDesignerFormClassName = 'TStyleDesignerForm';

procedure CopyZxToStyleBook(const ASrc: TZxStyleBook; const ADst: TStyleBook);
var
  I: Integer;
  ZxItem: TZxStyleCollectionItem;
  FmxItem: TStyleCollectionItem;
  Buf: TMemoryStream;
begin
  ADst.Clear;
  for I := 0 to ASrc.Styles.Count - 1 do
  begin
    ZxItem := ASrc.Styles[I];
    FmxItem := ADst.Styles.Add;
    FmxItem.Platform := ZxItem.Platform;
    if (ZxItem.Style <> nil) and (ZxItem.Style.ChildrenCount > 0) then
    begin
      Buf := TMemoryStream.Create;
      try
        TStyleStreaming.SaveToStream(ZxItem.Style, Buf);
        Buf.Position := 0;
        FmxItem.LoadFromStream(Buf);
      finally
        Buf.Free;
      end;
    end;
  end;
end;

procedure CopyStyleBookToZx(const ASrc: TStyleBook; const ADst: TZxStyleBook);
var
  I: Integer;
  ZxItem: TZxStyleCollectionItem;
  FmxItem: TStyleCollectionItem;
  Buf: TMemoryStream;
begin
  ADst.Clear;
  for I := 0 to ASrc.Styles.Count - 1 do
  begin
    FmxItem := ASrc.Styles[I];
    ZxItem := ADst.Styles.Add;
    ZxItem.Platform := FmxItem.Platform;
    if (FmxItem.Style <> nil) and (FmxItem.Style.ChildrenCount > 0) then
    begin
      Buf := TMemoryStream.Create;
      try
        TStyleStreaming.SaveToStream(FmxItem.Style, Buf);
        Buf.Position := 0;
        ZxItem.LoadFromStream(Buf);
      finally
        Buf.Free;
      end;
    end;
  end;
end;

function FindStyleDesignerForm: TComponent;
var
  I: Integer;
  Form: FMX.Forms.TCommonCustomForm;
begin
  Result := nil;
  // The FMX Style Designer is an FMX form (observed via Delphi IDE Explorer);
  // it does not appear in Vcl.Forms.Screen, so enumerate FMX.Forms.Screen.
  for I := 0 to FMX.Forms.Screen.FormCount - 1 do
  begin
    Form := FMX.Forms.Screen.Forms[I];
    if SameText(Form.ClassName, SStyleDesignerFormClassName) then
      Exit(Form);
  end;
end;

{ TZxStyleBookEditSession }

constructor TZxStyleBookEditSession.Create(const ATargetBook: TZxStyleBook;
  const ADesigner: IDesigner);
begin
  inherited Create(FMX.Forms.Application);
  FTargetBook := ATargetBook;
  FDesigner := ADesigner;
  FTempBook := TStyleBook.Create(nil);
  CopyZxToStyleBook(FTargetBook, FTempBook);
  if FTargetBook <> nil then
    FTargetBook.FreeNotification(Self);
end;

destructor TZxStyleBookEditSession.Destroy;
begin
  FDesigner := nil;
  FTempBook.Free;
  inherited;
end;

procedure TZxStyleBookEditSession.Finish;
var
  Resolved: string;
  FS: TFileStream;
begin
  if FFinished then
    Exit;
  FFinished := True;
  try
    // The FMX Style Designer's own "Apply changes?" prompt already decides
    // the user's intent. If they cancelled, the temp TStyleBook's final state
    // matches our initial snapshot and this copy is a no-op.
    if FTargetBook = nil then
      Exit;
    if FTargetBook.StyleFile <> '' then
    begin
      // Extracted-file path: write .style next to the form and reload into
      // the live book. DFM is unchanged, so no Designer.Modified here.
      if Assigned(ZxStyleBookDesignTimeResolver) then
        Resolved := ZxStyleBookDesignTimeResolver(FTargetBook, FTargetBook.StyleFile)
      else
        Resolved := FTargetBook.StyleFile;
      if Resolved = '' then
        Exit;
      ForceDirectories(ExtractFilePath(Resolved));
      FS := TFileStream.Create(Resolved, fmCreate);
      try
        if (FTempBook.Style <> nil) and (FTempBook.Style.ChildrenCount > 0) then
          TStyleStreaming.SaveToStream(FTempBook.Style, FS, TStyleFormat.Text);
      finally
        FS.Free;
      end;
      FTargetBook.LoadStyleFromFile;
    end
    else
    begin
      CopyStyleBookToZx(FTempBook, FTargetBook);
      if FDesigner <> nil then
        FDesigner.Modified;
    end;
  finally
    Free;
  end;
end;

procedure TZxStyleBookEditSession.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation <> opRemove then
    Exit;
  if AComponent = FTargetBook then
  begin
    FTargetBook := nil;
    Exit;
  end;
  if (AComponent = FDesignerForm) and not FFinished then
  begin
    FDesignerForm := nil;
    // Defer: the designer form's destruction is still in progress, and we
    // may want to show a modal dialog. Run Finish on the next message loop.
    TThread.ForceQueue(nil, Finish);
  end;
end;

function TZxStyleBookEditSession.Start: Boolean;
var
  FmxEd: IComponentEditor;
begin
  Result := False;
  FmxEd := GetComponentEditor(FTempBook, FDesigner);
  if FmxEd = nil then
  begin
    TDialogService.MessageDialog(
      'FMX Style Designer is not available. Ensure the design-time package ' +
      '"fmxstyledesigner" is installed in the IDE.',
      TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
    Exit;
  end;
  FmxEd.Edit;
  FmxEd := nil;
  FDesignerForm := FindStyleDesignerForm;
  if FDesignerForm = nil then
  begin
    TDialogService.MessageDialog(
      'Style Designer did not appear in FMX.Forms.Screen after Edit. The ' +
      'changes will not be applied automatically on close.',
      TMsgDlgType.mtWarning, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
    Exit;
  end;
  FDesignerForm.FreeNotification(Self);
  Result := True;
end;

{ TZxStyleBookEditor }

procedure TZxStyleBookEditor.Edit;
var
  Session: TZxStyleBookEditSession;
begin
  if not (Component is TZxStyleBook) then
    Exit;
  Session := TZxStyleBookEditSession.Create(TZxStyleBook(Component), Designer);
  if not Session.Start then
    Session.Free;
end;

procedure TZxStyleBookEditor.ExecuteVerb(Index: Integer);
begin
  if Index = 0 then
    Edit
  else
    inherited;
end;

function TZxStyleBookEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Edit...';
  else
    Result := inherited GetVerb(Index);
  end;
end;

function TZxStyleBookEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function ZxResolveDesignTimeStyleFile(const ABook: TComponent;
  const ARelativePath: string): string;
var
  Services: IOTAModuleServices;
  Module: IOTAModule;
  Base: string;
begin
  Result := '';
  if ARelativePath = '' then
    Exit;
  if TPath.IsPathRooted(ARelativePath) then
    Exit(ARelativePath);
  if not Supports(BorlandIDEServices, IOTAModuleServices, Services) then
    Exit;
  Module := Services.CurrentModule;
  if Module = nil then
    Exit;
  Base := ExtractFilePath(Module.FileName);
  if Base = '' then
    Exit;
  Result := TPath.Combine(Base, ARelativePath);
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
  RegisterComponents('ZxSkia', [TZxColorActiveStyleObject, TZxAnimatedImageActiveStyleObject, TZxColorButtonStyleObject,
    TZxTextSettingsButtonStyleObject, TZxColorOverrideSvgGlyphButtonStyleObject]);
  RegisterPropertyEditor(TypeInfo(TSkAnimatedImage.TSource), TZxAnimatedImageActiveStyleObject, 'AniSource',
    TZxAnimatedImageSourcePropertyEditor);
  // Zx.StyleBook
  RegisterComponents('ZxSkia', [TZxStyleBook]);
  RegisterComponentEditor(TZxStyleBook, TZxStyleBookEditor);
  // Install the design-time path resolver so TZxStyleBook.StyleFile values
  // can be anchored relative to the .fmx/.dfm file currently being edited.
  Zx.StyleBook.ZxStyleBookDesignTimeResolver := ZxResolveDesignTimeStyleFile;
end;

end.
