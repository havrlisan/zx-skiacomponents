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
unit Zx.Text;

interface

uses
  System.Types,
  System.UITypes,
  System.Classes,
  System.Rtti,
  System.SysUtils,
{$IFDEF CompilerVersion < 36}
  Skia,
  Skia.FMX,
{$ELSE}
  FMX.Skia,
  System.Skia,
{$ENDIF}
  FMX.Types,
  FMX.ActnList,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  Zx.TextControl,
  Zx.Controls;

type
  IZxText = interface
    ['{01E418E5-7EB2-4604-9F41-89E904B845A3}']
    function GetParagraphBounds: TRectF;
    function FillTextFlags: TFillTextFlags;
    property ParagraphBounds: TRectF read GetParagraphBounds;
  end;

  [ComponentPlatformsAttribute(SkSupportedPlatformsMask)]
  TZxText = class(TZxStyledControl, IZxText, ISkTextSettings, IObjectState, ICaption, IZxPrefixStyle)
    // protected type
    // TAcceleratorInfo = class
    // private
    // FBrush: TStrokeBrush;
    // function GetBrush: TStrokeBrush;
    // strict private
    // FKeyIndex: Integer;
    // FIsUnderlineValid: Boolean;
    // FUnderlineBeginPoint: TPointF;
    // FUnderlineEndPoint: TPointF;
    // procedure SetKeyIndex(const Value: Integer);
    // function ValidateUnderlinePoints(const AnOwnerControl: TControl; const ACanvas: TCanvas;
    // const ALayout: TTextLayout): Boolean;
    // public
    // destructor Destroy; override;
    // /// <summary>Method to indicate that the underline needs to be redrawn.</summary>
    // procedure InvalidateUnderline;
    // /// <summary>Draws the underline unside the character that holds the accelerator.</summary>
    // function DrawUnderline(const AnOwnerControl: TControl; const ACanvas: TCanvas; const ALayout: TTextLayout;
    // const AColor: TAlphaColor; const AnOpacity: Single): Boolean;
    // /// <summary>Index of the accelerator key.</summary>
    // property KeyIndex: Integer read FKeyIndex write SetKeyIndex;
    // /// <summary>True if the underline is already generated.</summary>
    // property IsUnderlineValid: Boolean read FIsUnderlineValid;
    // /// <summary>This brush is used to draw the underline down the accelerator key character.</summary>
    // property Brush: TStrokeBrush read GetBrush;
    // end;

  private
    FTextSettingsInfo: TSkTextSettingsInfo;
    FSavedTextSettings: TSkTextSettings;
    FSavedStyledSettings: TStyledSettings;
    FStyleText: ISkStyleTextObject;
    FObjectState: IObjectState;
    FText: String;
    FAutoSize: Boolean;
    FPrefixStyle: TPrefixStyle;
    // FAcceleratorKeyInfo: TAcceleratorInfo;
    procedure SetAutoSize(const Value: Boolean);
    { ISkTextSettings }
    function GetDefaultTextSettings: TSkTextSettings;
    function GetResultingTextSettings: TSkTextSettings;
    function GetStyledSettings: TStyledSettings;
    function GetTextSettings: TSkTextSettings;
    procedure SetDefaultTextSettings(const Value: TSkTextSettings);
    procedure SetStyledSettings(const AValue: TStyledSettings);
    procedure SetTextSettings(const AValue: TSkTextSettings);
    { ICaption }
    function GetText: string;
    procedure SetText(const Value: string);
    { IZxPrefixStyle }
    function GetPrefixStyle: TPrefixStyle;
    procedure SetPrefixStyle(const Value: TPrefixStyle);
  private
    FParagraph: ISkParagraph;
    FParagraphBounds: TRectF;
    FParagraphLayoutWidth: Single;
    FParagraphStroked: ISkParagraph;
    FLastFillTextFlags: TFillTextFlags;
    function GetParagraph: ISkParagraph;
    function GetParagraphBounds: TRectF;
    procedure DeleteParagraph;
    procedure GetFitSize(var AWidth, AHeight: Single);
    function HasFitSizeChanged: Boolean;
    procedure ParagraphLayout(AMaxWidth: Single);
  protected
    procedure DoSetText(const Value: string);
    procedure DoAutoSize;
    property Paragraph: ISkParagraph read GetParagraph;
  protected
    function CustomTextSettingsClass: TSkTextSettingsInfo.TCustomTextSettingsClass; virtual;
    function TextStored: Boolean; virtual;
    procedure TextSettingsChanged(Sender: TObject); virtual;
    function ConvertText(const Value: string): string; virtual;
    function IsStyledSettingsStored: Boolean; virtual;
    { IObjectState }
    function SaveState: Boolean; virtual;
    function RestoreState: Boolean; virtual;
  protected
    procedure Loaded; override;
    function GetData: TValue; override;
    procedure SetData(const Value: TValue); override;
    procedure SetName(const AValue: TComponentName); override;
    function SupportsPaintStage(const Stage: TPaintStage): Boolean; override;
    procedure ApplyStyle; override;
    procedure FreeStyle; override;
    procedure DoStyleChanged; override;
    function FillTextFlags: TFillTextFlags; override;
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
    procedure DoEndUpdate; override;
    function NeedsRedraw: Boolean; override;
    procedure SetAlign(const AValue: TAlignLayout); override;
    function DoSetSize(const ASize: TControlSize; const ANewPlatformDefault: Boolean; ANewWidth, ANewHeight: Single;
      var ALastWidth, ALastHeight: Single): Boolean; override;
    // procedure RemoveAcceleratorKeyInfo;
    // property AcceleratorKeyInfo: TAcceleratorInfo read FAcceleratorKeyInfo;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(X, Y, AWidth, AHeight: Single); override;
{$IF CompilerVersion > 36}
{$MESSAGE WARN 'Check if FMX.Skia.TSkTextSettingsInfo.OnChange event fires on ResultingTextSettings change'}
{$ENDIF}
    procedure Recreate;
    property DefaultTextSettings: TSkTextSettings read GetDefaultTextSettings write SetDefaultTextSettings;
    property ResultingTextSettings: TSkTextSettings read GetResultingTextSettings;
    property ParagraphBounds: TRectF read GetParagraphBounds;
  published
    property Align;
    property Anchors;
    property AutoSize: Boolean read FAutoSize write SetAutoSize default False;
    property ClipChildren default False;
    property ClipParent default False;
    property Cursor default crDefault;
    property DragMode default TDragMode.dmManual;
    property EnableDragHighlight default True;
    property Enabled default True;
    property Locked default False;
    property Height;
    property Hint;
    property HitTest default False;
    property Padding;
    property Opacity;
    property Margins;
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property Size;
    property Text: string read GetText write SetText stored TextStored;
    property TextSettings: TSkTextSettings read GetTextSettings write SetTextSettings;
    property PrefixStyle: TPrefixStyle read FPrefixStyle write SetPrefixStyle default TPrefixStyle.HidePrefix;
    property Visible default True;
    property Width;
    property ParentShowHint;
    property ShowHint;
    property TouchTargetExpansion;

    property StyledSettings: TStyledSettings read GetStyledSettings write SetStyledSettings stored IsStyledSettingsStored;
    property StyleLookup;

    property OnApplyStyleLookup;
    property OnDraw;

    property OnDragEnter;
    property OnDragLeave;
    property OnDragOver;
    property OnDragDrop;
    property OnDragEnd;

    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnTap;

    property OnPainting;
    property OnPaint;
    property OnResize;
    property OnResized;
  end;

implementation

uses
  System.Math,
  System.Math.Vectors,
  FMX.AcceleratorKey,
  FMX.Platform,
  FMX.BehaviorManager;

function CeilFloat(const X: Single): Single;
begin
  Result := Int(X);
  if Frac(X) > 0 then
    Result := Result + 1;
end;

{ TZxText }

constructor TZxText.Create(AOwner: TComponent);
begin
  inherited;
  AutoTranslate := True;
  FTextSettingsInfo := TSkTextSettingsInfo.Create(Self, CustomTextSettingsClass);
  FTextSettingsInfo.Design := csDesigning in ComponentState;
  FTextSettingsInfo.OnChange := TextSettingsChanged;
  FPrefixStyle := TPrefixStyle.HidePrefix;
end;

destructor TZxText.Destroy;
begin
  FreeAndNil(FTextSettingsInfo);
  FreeAndNil(FSavedTextSettings);
  // FreeAndNil(FAcceleratorKeyInfo);
  inherited;
end;

procedure TZxText.Loaded;
begin
  inherited;
  if not IsUpdating and FAutoSize and HasFitSizeChanged then
    SetSize(Width, Height);
end;

function TZxText.NeedsRedraw: Boolean;
begin
  Result := inherited or (FLastFillTextFlags <> FillTextFlags);
end;

procedure TZxText.DoEndUpdate;
begin
  if (not(csLoading in ComponentState)) and FAutoSize and HasFitSizeChanged then
    SetSize(Width, Height)
  else
    inherited;
end;

function TZxText.CustomTextSettingsClass: TSkTextSettingsInfo.TCustomTextSettingsClass;
begin
  Result := nil;
end;

function TZxText.ConvertText(const Value: string): string;
begin
  Result := Value;
end;

function TZxText.DoSetSize(const ASize: TControlSize; const ANewPlatformDefault: Boolean; ANewWidth, ANewHeight: Single;
  var ALastWidth, ALastHeight: Single): Boolean;
begin
  if FAutoSize and not(csLoading in ComponentState) then
    GetFitSize(ANewWidth, ANewHeight);
  Result := inherited;
end;

procedure TZxText.DoSetText(const Value: string);
var
  NewText: string;
  // LKey: Char;
  // LKeyIndex: Integer;
  // AccelKeyService: IFMXAcceleratorKeyRegistryService;
begin
  if FPrefixStyle = TPrefixStyle.HidePrefix then
    NewText := DelAmp(Value)
  else
    NewText := Value;
  NewText := ConvertText(NewText);

  // if (FPrefixStyle = TPrefixStyle.HidePrefix) and TPlatformServices.Current.SupportsPlatformService
  // (IFMXAcceleratorKeyRegistryService, AccelKeyService) then
  // begin
  // AccelKeyService.ExtractAcceleratorKey(ConvertText(Value), LKey, LKeyIndex);
  // if LKeyIndex >= 0 then
  // begin
  // if FAcceleratorKeyInfo = nil then
  // FAcceleratorKeyInfo := TAcceleratorInfo.Create;
  // FAcceleratorKeyInfo.KeyIndex := LKeyIndex;
  // end
  // else
  // RemoveAcceleratorKeyInfo;
  // end
  // else
  // RemoveAcceleratorKeyInfo;
  if Text <> NewText then
  begin
    FText := NewText;
    DeleteParagraph;
    NeedUpdateEffects;
    DoAutoSize;
    Redraw;
  end;
end;

procedure TZxText.DoStyleChanged;
var
  LNewText: string;
begin
  inherited;
  if AutoTranslate and not Text.IsEmpty then
  begin
    LNewText := Translate(Text); // need for collection texts
    if not(csDesigning in ComponentState) then
      Text := LNewText;
  end;
end;

procedure TZxText.TextSettingsChanged(Sender: TObject);
begin
  DeleteParagraph;
  if not(csLoading in ComponentState) then
  begin
    if not IsUpdating and FAutoSize and HasFitSizeChanged then
      SetSize(Width, Height)
    else
      Redraw;
  end;
end;

procedure TZxText.DoAutoSize;
var
  AlignRoot: IAlignRoot;
begin
  if csLoading in ComponentState then
    Exit;
  if not FAutoSize or Text.IsEmpty then
    Exit;
  if FDisableAlign then
    Exit;
  FDisableAlign := True;
  try
    var
    LParagraphBounds := ParagraphBounds;
    if not LParagraphBounds.IsEmpty then
    begin
      SetBounds(Position.X, Position.Y, LParagraphBounds.Width, LParagraphBounds.Height);
      if Supports(Parent, IAlignRoot, AlignRoot) then
        AlignRoot.Realign;
    end;
  finally
    FDisableAlign := False;
  end;
end;

procedure TZxText.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
var
  LParagraph: ISkParagraph;
  LPositionY: Single;
begin
  if FLastFillTextFlags <> FillTextFlags then
    DeleteParagraph;
  LParagraph := Paragraph;
  if Assigned(LParagraph) then
  begin
    ParagraphLayout(ADest.Width);
    LPositionY := ADest.Top;
    case ResultingTextSettings.VertAlign of
      TTextAlign.Center:
        LPositionY := LPositionY + ((ADest.Height - ParagraphBounds.Height) / 2);
      TTextAlign.Leading:
        ;
      TTextAlign.Trailing:
        LPositionY := LPositionY + (ADest.Height - ParagraphBounds.Height);
    end;

    if SameValue(AOpacity, 1, TEpsilon.Position) then
      ACanvas.Save
    else
      ACanvas.SaveLayerAlpha(Round(AOpacity * 255));
    try
      ACanvas.ClipRect(ADest);
      ACanvas.Translate(ADest.Left, LPositionY);
      LParagraph.Paint(ACanvas, 0, 0);
      if Assigned(FParagraphStroked) then
        FParagraphStroked.Paint(ACanvas, 0, 0);
    finally
      ACanvas.Restore;
    end;
  end;
end;

procedure TZxText.ApplyStyle;
var
  LFontBehavior: IFontBehavior;

  procedure SetupDefaultTextSetting(const AObject: TFmxObject; const ADefaultTextSettings: TSkTextSettings);
  var
    LFMXTextSettings: ITextSettings;
    LNewFamily: string;
    LNewSize: Single;
  begin
    if (AObject <> nil) and AObject.GetInterface(IObjectState, FObjectState) then
      FObjectState.SaveState
    else
      FObjectState := nil;

    FStyleText := nil;
    if ADefaultTextSettings <> nil then
    begin
      if Supports(AObject, ISkStyleTextObject, FStyleText) then
        ADefaultTextSettings.Assign(FStyleText.TextSettings)
      else if Supports(AObject, ITextSettings, LFMXTextSettings) then
        ADefaultTextSettings.Assign(LFMXTextSettings.TextSettings)
      else
        ADefaultTextSettings.Assign(nil);

      if LFontBehavior <> nil then
      begin
        LNewFamily := '';
        LFontBehavior.GetDefaultFontFamily(Scene.GetObject, LNewFamily);
        if not LNewFamily.IsEmpty then
          ADefaultTextSettings.Font.Families := LNewFamily;

        LNewSize := 0;
        LFontBehavior.GetDefaultFontSize(Scene.GetObject, LNewSize);
        if not SameValue(LNewSize, 0, TEpsilon.FontSize) then
          ADefaultTextSettings.Font.Size := LNewSize;
      end;
    end;
  end;

var
  LInterface: IInterface;
  LNewText: string;
  LTextResource: TFmxObject;
begin
  LFontBehavior := nil;
  BeginUpdate;
  try
    ResultingTextSettings.BeginUpdate;
    try
      FTextSettingsInfo.Design := False;
      { behavior }
      if (Scene <> nil) and TBehaviorServices.Current.SupportsBehaviorService(IFontBehavior, LInterface, Scene.GetObject) then
        Supports(LInterface, IFontBehavior, LFontBehavior);

      if Supports(ResourceLink, ISkStyleTextObject) then
        LTextResource := ResourceLink
      else
        LTextResource := FindStyleResource('text');

      { from text }
      SetupDefaultTextSetting(LTextResource, FTextSettingsInfo.DefaultTextSettings);
      inherited;
    finally
      ResultingTextSettings.EndUpdate;
      FTextSettingsInfo.Design := True; // csDesigning in ComponentState;
    end;
    if AutoTranslate and not Text.IsEmpty then
    begin
      LNewText := Translate(Text); // need for collection texts
      if not(csDesigning in ComponentState) then
        Text := LNewText;
    end;
    DeleteParagraph;
  finally
    EndUpdate;
    Redraw;
  end;
end;

function TZxText.FillTextFlags: TFillTextFlags;
begin
  Result := inherited;
  if (Root = nil) and (Application.BiDiMode = TBiDiMode.bdRightToLeft) then
    Result := Result + [TFillTextFlag.RightToLeft];
end;

procedure TZxText.FreeStyle;
begin
  if FObjectState <> nil then
  begin
    FObjectState.RestoreState;
    FObjectState := nil;
  end;
  FStyleText := nil;
  inherited;
end;

procedure TZxText.DeleteParagraph;
begin
  FParagraph := nil;
  FParagraphStroked := nil;
  FParagraphBounds := TRectF.Empty;
  FParagraphLayoutWidth := 0;
end;

procedure TZxText.ParagraphLayout(AMaxWidth: Single);

  function DoParagraphLayout(const AParagraph: ISkParagraph; const AMaxWidth: Single): Single;
  begin
    if CompareValue(AMaxWidth, 0, TEpsilon.Position) = GreaterThanValue then
    begin
      if IsInfinite(AMaxWidth) then
        Result := AMaxWidth
      else
        // The SkParagraph.Layout calls a floor for the MaxWidth, so we should ceil it to force the original AMaxWidth
        Result := CeilFloat(AMaxWidth + TEpsilon.Matrix);
    end
    else
      Result := 0;
    AParagraph.Layout(Result);
  end;

var
  LMaxWidthUsed: Single;
  LParagraph: ISkParagraph;
begin
  AMaxWidth := Max(AMaxWidth, 0);
  if not SameValue(FParagraphLayoutWidth, AMaxWidth, TEpsilon.Position) then
  begin
    LParagraph := Paragraph;
    if Assigned(LParagraph) then
    begin
      LMaxWidthUsed := DoParagraphLayout(LParagraph, AMaxWidth);
      if Assigned(FParagraphStroked) then
        FParagraphStroked.Layout(LMaxWidthUsed);
      FParagraphLayoutWidth := AMaxWidth;
      FParagraphBounds := TRectF.Empty;
    end;
  end;
end;

procedure TZxText.Recreate;
begin
  DeleteParagraph;
  NeedUpdateEffects;
  DoAutoSize;
  Redraw;
end;

function TZxText.RestoreState: Boolean;
begin
  Result := False;
  if (FSavedTextSettings <> nil) and (FTextSettingsInfo <> nil) then
  begin
    ResultingTextSettings.BeginUpdate;
    try
      StyledSettings := FSavedStyledSettings;
      TextSettings := FSavedTextSettings;
    finally
      ResultingTextSettings.EndUpdate;
    end;
    FreeAndNil(FSavedTextSettings);
    Result := True;
  end;
end;

function TZxText.SaveState: Boolean;
begin
  Result := False;
  if FTextSettingsInfo <> nil then
  begin
    if FSavedTextSettings = nil then
      FSavedTextSettings := TSkTextSettings.Create(nil);
    FSavedTextSettings.Assign(FTextSettingsInfo.TextSettings);
    FSavedStyledSettings := StyledSettings;
    Result := True;
  end;
end;

function TZxText.GetData: TValue;
begin
  Result := Text;
end;

function TZxText.GetDefaultTextSettings: TSkTextSettings;
begin
  Result := FTextSettingsInfo.DefaultTextSettings;
end;

procedure TZxText.GetFitSize(var AWidth, AHeight: Single);

  function GetFitHeight: Single;
  begin
    case Align of
      TAlignLayout.Client, TAlignLayout.Contents, TAlignLayout.Left, TAlignLayout.MostLeft, TAlignLayout.Right,
        TAlignLayout.MostRight, TAlignLayout.FitLeft, TAlignLayout.FitRight, TAlignLayout.HorzCenter, TAlignLayout.Vertical:
        Result := AHeight;
    else
      Result := ParagraphBounds.Height;
    end;
  end;

  function GetFitWidth: Single;
  begin
    case Align of
      TAlignLayout.Client, TAlignLayout.Contents, TAlignLayout.Top, TAlignLayout.MostTop, TAlignLayout.Bottom,
        TAlignLayout.MostBottom, TAlignLayout.VertCenter, TAlignLayout.Horizontal:
        Result := AWidth;
    else
      Result := ParagraphBounds.Width;
    end;
  end;

var
  LParagraph: ISkParagraph;
begin
  LParagraph := Paragraph;
  if Assigned(LParagraph) then
  begin
    if Align in [TAlignLayout.Top, TAlignLayout.MostTop, TAlignLayout.Bottom, TAlignLayout.MostBottom, TAlignLayout.VertCenter,
      TAlignLayout.Horizontal] then
    begin
      ParagraphLayout(AWidth);
    end
    else
      ParagraphLayout(Infinity);
  end;
  try
    AWidth := GetFitWidth;
    AHeight := GetFitHeight;
  finally
    if Assigned(LParagraph) then
      ParagraphLayout(AWidth);
  end;
end;

const
  SkFontSlant: array [TFontSlant] of TSkFontSlant = (TSkFontSlant.Upright, TSkFontSlant.Italic, TSkFontSlant.Oblique);
  SkFontWeightValue: array [TFontWeight] of Integer = (100, 200, 300, 350, 400, 500, 600, 700, 800, 900, 950);
  SkFontWidthValue: array [TFontStretch] of Integer = (1, 2, 3, 4, 5, 6, 7, 8, 9);

function TZxText.GetParagraph: ISkParagraph;
type
  TDrawKind = (Fill, Stroke);
var
  LFontBehavior: IFontBehavior;
  LHasTextStroked: Boolean;

  function GetFontFamilies(const AValue: string): TArray<string>;
  var
    LInterface: IInterface;
  begin
    Result := AValue.Split([', ', ','], TStringSplitOptions.ExcludeEmpty);
    if Result = nil then
    begin
      if (LFontBehavior = nil) and (Scene <> nil) and TBehaviorServices.Current.SupportsBehaviorService(IFontBehavior, LInterface,
        Scene.GetObject) then
        Supports(LInterface, IFontBehavior, LFontBehavior);
      if Assigned(LFontBehavior) then
      begin
        SetLength(Result, 1);
        Result[0] := '';
        LFontBehavior.GetDefaultFontFamily(Scene.GetObject, Result[0]);
        if Result[0].IsEmpty then
          Result := [];
      end;
    end;
{$IFDEF MACOS}
    Result := Result + ['Helvetica Neue'];
{$ELSEIF DEFINED(LINUX)}
    Result := Result + ['Ubuntu'];
{$ENDIF}
  end;

  function GetFontSize(const AValue: Single): Single;
  var
    LInterface: IInterface;
  begin
    Result := AValue;
    if SameValue(AValue, 0, TEpsilon.FontSize) then
    begin
      if (LFontBehavior = nil) and (Scene <> nil) and TBehaviorServices.Current.SupportsBehaviorService(IFontBehavior, LInterface,
        Scene.GetObject) then
        Supports(LInterface, IFontBehavior, LFontBehavior);
      if Assigned(LFontBehavior) then
        LFontBehavior.GetDefaultFontSize(Scene.GetObject, Result);
    end;
  end;

  procedure SetTextStyleDecorations(var ATextStyle: ISkTextStyle; const ADecorations: TSkTextSettings.TDecorations;
    const ADrawKind: TDrawKind);
  var
    LPaint: ISkPaint;
  begin
    if ADecorations.Decorations <> [] then
    begin
      if ADecorations.Color = TAlphaColors.Null then
        ATextStyle.DecorationColor := ATextStyle.Color
      else
        ATextStyle.DecorationColor := ADecorations.Color;
      ATextStyle.Decorations := ADecorations.Decorations;
      ATextStyle.DecorationStyle := ADecorations.Style;
      ATextStyle.DecorationThickness := ADecorations.Thickness;
    end;
    if ADrawKind = TDrawKind.Stroke then
    begin
      if (ADecorations.StrokeColor <> TAlphaColors.Null) and not SameValue(ADecorations.Thickness, 0, TEpsilon.Position) then
      begin
        LPaint := TSkPaint.Create(TSkPaintStyle.Stroke);
        LPaint.Color := ADecorations.StrokeColor;
        LPaint.StrokeWidth := (ADecorations.Thickness / 2) * (ATextStyle.FontSize / 14);
        ATextStyle.SetForegroundColor(LPaint);
      end
      else
        ATextStyle.Color := TAlphaColors.Null;
    end
    else
      LHasTextStroked := LHasTextStroked or ((ADecorations.StrokeColor <> TAlphaColors.Null) and
        not SameValue(ADecorations.Thickness, 0, TEpsilon.Position));
  end;

  function CreateDefaultTextStyle(const ADrawKind: TDrawKind): ISkTextStyle;
  begin
    Result := TSkTextStyle.Create;
    Result.Color := ResultingTextSettings.FontColor;
    Result.FontFamilies := GetFontFamilies(ResultingTextSettings.Font.Families);
    Result.FontSize := GetFontSize(ResultingTextSettings.Font.Size);
    Result.FontStyle := TSkFontStyle.Create(SkFontWeightValue[ResultingTextSettings.Font.Weight],
      SkFontWidthValue[ResultingTextSettings.Font.Stretch], SkFontSlant[ResultingTextSettings.Font.Slant]);
    Result.HeightMultiplier := ResultingTextSettings.HeightMultiplier;
    Result.LetterSpacing := ResultingTextSettings.LetterSpacing;
    SetTextStyleDecorations(Result, ResultingTextSettings.Decorations, ADrawKind);
    if GlobalSkiaTextLocale <> '' then
      Result.Locale := GlobalSkiaTextLocale;
  end;

  function CreateParagraphStyle(const ADefaultTextStyle: ISkTextStyle): ISkParagraphStyle;
  const
    SkTextAlign: array [TSkTextHorzAlign] of TSkTextAlign = (TSkTextAlign.Center, TSkTextAlign.Start, TSkTextAlign.Terminate,
      TSkTextAlign.Justify);
  begin
    Result := TSkParagraphStyle.Create;
    FLastFillTextFlags := FillTextFlags;
    if TFillTextFlag.RightToLeft in FLastFillTextFlags then
      Result.TextDirection := TSkTextDirection.RightToLeft;
    if ResultingTextSettings.Trimming in [TTextTrimming.Character, TTextTrimming.Word] then
      Result.Ellipsis := '...';
    if ResultingTextSettings.MaxLines <= 0 then
      Result.MaxLines := High(NativeUInt)
    else
      Result.MaxLines := ResultingTextSettings.MaxLines;
    Result.TextAlign := SkTextAlign[ResultingTextSettings.HorzAlign];
    Result.TextStyle := ADefaultTextStyle;
  end;

  function CreateParagraph(const ADrawKind: TDrawKind): ISkParagraph;
  var
    LBuilder: ISkParagraphBuilder;
    LDefaultTextStyle: ISkTextStyle;
  begin
    LFontBehavior := nil;
    LDefaultTextStyle := CreateDefaultTextStyle(ADrawKind);
    LBuilder := TSkParagraphBuilder.Create(CreateParagraphStyle(LDefaultTextStyle), TSkDefaultProviders.TypefaceFont);
    LBuilder.AddText(Text);
    Result := LBuilder.Build;
  end;

begin
  if (FParagraph = nil) and (Text <> '') then
  begin
    LHasTextStroked := False;
    FParagraph := CreateParagraph(TDrawKind.Fill);
    if LHasTextStroked then
      FParagraphStroked := CreateParagraph(TDrawKind.Stroke);
    ParagraphLayout(Width);
  end;
  Result := FParagraph;
end;

function TZxText.GetParagraphBounds: TRectF;

  function CalculateParagraphBounds: TRectF;
  var
    LParagraph: ISkParagraph;
  begin
    LParagraph := Paragraph;
    if Assigned(LParagraph) then
      Result := RectF(0, 0, LParagraph.MaxIntrinsicWidth, LParagraph.Height)
    else
      Result := TRectF.Empty;
  end;

begin
  if FParagraphBounds.IsEmpty then
    FParagraphBounds := CalculateParagraphBounds;
  Result := FParagraphBounds;
end;

function TZxText.GetPrefixStyle: TPrefixStyle;
begin
  Result := FPrefixStyle;
end;

function TZxText.GetResultingTextSettings: TSkTextSettings;
begin
  Result := FTextSettingsInfo.ResultingTextSettings;
end;

function TZxText.GetStyledSettings: TStyledSettings;
begin
  Result := FTextSettingsInfo.StyledSettings;
end;

function TZxText.GetText: string;
begin
  Result := FText;
end;

function TZxText.GetTextSettings: TSkTextSettings;
begin
  Result := FTextSettingsInfo.TextSettings;
end;

function TZxText.HasFitSizeChanged: Boolean;
var
  LNewWidth: Single;
  LNewHeight: Single;
begin
  LNewWidth := Width;
  LNewHeight := Height;
  GetFitSize(LNewWidth, LNewHeight);
  Result := (not SameValue(LNewWidth, Width, TEpsilon.Position)) or (not SameValue(LNewHeight, Height, TEpsilon.Position));
end;

function TZxText.IsStyledSettingsStored: Boolean;
begin
  Result := StyledSettings <> DefaultStyledSettings;
end;

procedure TZxText.SetAlign(const AValue: TAlignLayout);
begin
  if (Align <> AValue) and AutoSize then
  begin
    inherited;
    SetSize(Width, Height);
  end
  else
    inherited;
end;

procedure TZxText.SetAutoSize(const Value: Boolean);
begin
  if FAutoSize <> Value then
  begin
    FAutoSize := Value;
    SetSize(Width, Height);
  end;
end;

procedure TZxText.SetBounds(X, Y, AWidth, AHeight: Single);
begin
  inherited;
  // if FAcceleratorKeyInfo <> nil then
  // FAcceleratorKeyInfo.InvalidateUnderline;
end;

procedure TZxText.SetData(const Value: TValue);
begin
  Text := Value.ToString;
end;

procedure TZxText.SetDefaultTextSettings(const Value: TSkTextSettings);
begin
  FTextSettingsInfo.DefaultTextSettings := Value;
end;

procedure TZxText.SetName(const AValue: TComponentName);
var
  LChangeText: Boolean;
begin
  LChangeText := not(csLoading in ComponentState) and (Name = Text) and
    ((Owner = nil) or not(csLoading in TComponent(Owner).ComponentState));
  inherited SetName(AValue);
  if LChangeText then
    Text := AValue;
end;

procedure TZxText.SetPrefixStyle(const Value: TPrefixStyle);
begin
  if FPrefixStyle <> Value then
  begin
    FPrefixStyle := Value;
    DoSetText(Text);
  end;
end;

procedure TZxText.SetStyledSettings(const AValue: TStyledSettings);
begin
  FTextSettingsInfo.StyledSettings := AValue;
end;

procedure TZxText.SetText(const Value: string);
begin
  if Text <> Value then
    DoSetText(Value);
end;

procedure TZxText.SetTextSettings(const AValue: TSkTextSettings);
begin
  FTextSettingsInfo.TextSettings := AValue;
end;

function TZxText.SupportsPaintStage(const Stage: TPaintStage): Boolean;
begin
  Result := Stage in [TPaintStage.All, TPaintStage.Text];
end;

function TZxText.TextStored: Boolean;
begin
  Result := not Text.IsEmpty;
end;

initialization

RegisterFMXClasses([TZxText]);

end.
