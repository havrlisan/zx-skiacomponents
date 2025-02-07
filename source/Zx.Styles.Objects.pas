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
unit Zx.Styles.Objects;

interface

uses
  System.Types,
  System.Classes,
  System.UITypes,
  System.SysUtils,
{$IFDEF CompilerVersion < 36}
  Skia,
  Skia.FMX,
{$ELSE}
  FMX.Skia,
  System.Skia,
{$ENDIF}
  FMX.Controls,
  FMX.Graphics,
  FMX.Ani,
  FMX.Types,
  FMX.Objects,
  Zx.Ani,
  Zx.Controls,
  Zx.Text,
  FMX.ActnList,
  Zx.TextControl,
  Zx.SvgBrushList;

{$SCOPEDENUMS ON}

type
  TZxStyleTrigger = (MouseOver, Pressed, Selected, Focused, Checked, Active);

  TZxStyleTriggers = set of TZxStyleTrigger;

  TZxStyleTriggerHelper = record helper for TZxStyleTrigger
    function ToProperty: String; overload;
    function ToProperty(const AValue: Boolean): String; overload;
  end;

  TZxCustomStyleObject = class abstract(TZxCustomControl)
  strict protected
    function DoGetUpdateRect: TRectF; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property CanParentFocus;
    property OnKeyDown;
    property OnKeyUp;
    property OnCanFocus;
    property OnEnter;
    property OnExit;
    property OnPaint;
  end;

  /// <summary>
  /// Base class that implements the trigger mechanism for activating animations.
  /// Descend from it and implement custom behavior (see TZxColorActiveStyleObject).
  /// </summary>
  TZxCustomActiveStyleObject = class abstract(TZxCustomStyleObject)
  strict private
    FActive: Boolean;
    FActiveAnimation: TAnimation;
    FTrigger: TZxStyleTrigger;
    FOnTriggered: TNotifyEvent;
    procedure SetTrigger(const Value: TZxStyleTrigger);
    function GetDuration: Single;
    procedure SetDuration(const AValue: Single);
  strict private
    procedure Triggered(Sender: TObject);
  strict protected
    function CreateAnimation: TAnimation; virtual; abstract;
    procedure DoTriggered; virtual;
    procedure SetupAnimations; virtual;
    function DurationStored: Boolean; virtual;
  strict protected
    procedure DoRootChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure StartTriggerAnimation(const AInstance: TFmxObject; const ATrigger: string); override;
    procedure SetNewScene(AScene: IScene); override;
    property ActiveAnimation: TAnimation read FActiveAnimation;
    property Active: Boolean read FActive write FActive;
    property OnTriggered: TNotifyEvent read FOnTriggered write FOnTriggered;
    property Duration: Single read GetDuration write SetDuration stored DurationStored;
  published
    property ActiveTrigger: TZxStyleTrigger read FTrigger write SetTrigger;
  end;

  /// <summary>
  /// Simple color style object that animates the color transition.
  /// </summary>
  [ComponentPlatformsAttribute(SkSupportedPlatformsMask)]
  TZxColorActiveStyleObject = class(TZxCustomActiveStyleObject)
  strict private
    FPaint: ISkPaint;
    FColor: TAlphaColorF;
    FRadiusX: Single;
    FRadiusY: Single;
    function GetActiveAnimation: TZxColorAnimation;
    function GetActiveColor: TAlphaColor;
    function GetSourceColor: TAlphaColor;
    procedure SetActiveColor(const AValue: TAlphaColor);
    procedure SetSourceColor(const AValue: TAlphaColor);
    procedure SetRadiusX(const AValue: Single);
    procedure SetRadiusY(const AValue: Single);
    procedure OnTriggerProcess(Sender: TObject; const AValue: TAlphaColor);
  strict protected
    procedure UpdateColor(const AValue: TAlphaColor); inline;
    property SkPaint: ISkPaint read FPaint;
  strict protected
    function RadiusXStored: Boolean; virtual;
    function RadiusYStored: Boolean; virtual;
  strict protected
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
    function CreateAnimation: TAnimation; override;
    function DurationStored: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property ActiveAnimation: TZxColorAnimation read GetActiveAnimation;
  published
    property Duration;
    property ActiveColor: TAlphaColor read GetActiveColor write SetActiveColor stored True;
    property SourceColor: TAlphaColor read GetSourceColor write SetSourceColor stored True;
    property RadiusX: Single read FRadiusX write SetRadiusX stored RadiusXStored;
    property RadiusY: Single read FRadiusY write SetRadiusY stored RadiusYStored;
  end;

  /// <summary>
  /// Style object with animated image. Transition happens immediately because the
  /// animated image does its own animation.
  /// Two modes are available via <i>AniLoop</i>:
  /// 1) if False, trigger starts animated image (no loop). Inverse trigger starts
  /// animated image in reverse.
  /// 2) if True, trigger starts animated image in loop. Inverse trigger stops
  /// animated image.
  /// </summary>
  [ComponentPlatformsAttribute(SkSupportedPlatformsMask)]
  TZxAnimatedImageActiveStyleObject = class(TZxCustomActiveStyleObject)
  strict private
    FAnimatedImage: TSkAnimatedImage;
    FAniLoop: Boolean;
    function GetAniDelay: Double;
    function GetAniSource: TSkAnimatedImage.TSource;
    function GetAniSpeed: Double;
    procedure SetAniDelay(const AValue: Double);
    procedure SetAnimatedImage(const AValue: TSkAnimatedImage);
    procedure SetAniLoop(const AValue: Boolean);
    procedure SetAniSource(const AValue: TSkAnimatedImage.TSource);
    procedure SetAniSpeed(const AValue: Double);
  strict private
    procedure ReadData(AStream: TStream);
    procedure WriteData(AStream: TStream);
  strict protected
    function AniDelayStored: Boolean; virtual;
    function AniSpeedStored: Boolean; virtual;
  strict protected
    procedure DefineProperties(AFiler: TFiler); override;
    function CreateAnimation: TAnimation; override;
    procedure DoTriggered; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    {
      Setting this property to published may seem like a simpler solution, but for
      some reason it will not be available for editing in the Object Inspector when
      inside the 'Style Designer' window.
    }
    property AnimatedImage: TSkAnimatedImage read FAnimatedImage write SetAnimatedImage;
  published
    property AniLoop: Boolean read FAniLoop write SetAniLoop default False;
    property AniDelay: Double read GetAniDelay write SetAniDelay stored AniDelayStored;
    property AniSource: TSkAnimatedImage.TSource read GetAniSource write SetAniSource;
    property AniSpeed: Double read GetAniSpeed write SetAniSpeed stored AniSpeedStored;
  end;

  TZxButtonTriggerType = (Normal, Hot, Pressed, Focused); // Don't change order for compatibility with TFontColorForState.TIndex

  TZxCustomButtonStyleObject = class abstract(TZxCustomStyleObject)
  strict private
    FCurrent: TZxButtonTriggerType;
    FPrevious: TZxButtonTriggerType;
    FDuration: Single;
    FTriggers: array [TZxButtonTriggerType] of TZxAnimation;
    FTriggerEvents: array [TZxButtonTriggerType] of TNotifyEvent;
    procedure SetDuration(const AValue: Single);
    function GetTrigger(const AIndex: TZxButtonTriggerType): TZxAnimation;
    function GetTriggerEvent(const AIndex: TZxButtonTriggerType): TNotifyEvent;
    procedure SetTriggerEvent(const AIndex: TZxButtonTriggerType; const AValue: TNotifyEvent);
  strict private
    procedure UpdateTriggersDuration;
    procedure Triggered(Sender: TObject);
  strict protected
    function DoCreateAnimation: TZxAnimation; virtual; abstract;
    function CreateAnimation(const ATrigger: TTrigger): TZxAnimation; virtual;
    procedure DoTriggered(const ATriggerType: TZxButtonTriggerType); virtual;
    function DurationStored: Boolean; virtual;
    property Current: TZxButtonTriggerType read FCurrent;
    property Previous: TZxButtonTriggerType read FPrevious;
    property Triggers[const AIndex: TZxButtonTriggerType]: TZxAnimation read GetTrigger;
  strict protected
    procedure DoRootChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure StartTriggerAnimation(const AInstance: TFmxObject; const ATrigger: string); override;
    property OnNormalTriggered: TNotifyEvent index TZxButtonTriggerType.Normal read GetTriggerEvent write SetTriggerEvent;
    property OnHotTriggered: TNotifyEvent index TZxButtonTriggerType.Hot read GetTriggerEvent write SetTriggerEvent;
    property OnPressedTriggered: TNotifyEvent index TZxButtonTriggerType.Pressed read GetTriggerEvent write SetTriggerEvent;
    property OnFocusedTriggered: TNotifyEvent index TZxButtonTriggerType.Focused read GetTriggerEvent write SetTriggerEvent;
  published
    property Duration: Single read FDuration write SetDuration stored DurationStored;
  end;

  [ComponentPlatformsAttribute(SkSupportedPlatformsMask)]
  TZxColorButtonStyleObject = class(TZxCustomButtonStyleObject)
  strict private
    FTriggerColors: array [TZxButtonTriggerType] of TAlphaColor;
    FPaint: ISkPaint;
    FColor: TAlphaColorF;
    FRadiusX: Single;
    FRadiusY: Single;
    function GetTriggerColor(const AIndex: TZxButtonTriggerType): TAlphaColor;
    procedure SetTriggerColor(const AIndex: TZxButtonTriggerType; const AValue: TAlphaColor);
    procedure SetRadiusX(const AValue: Single);
    procedure SetRadiusY(const AValue: Single);
    procedure OnTriggerProcess(Sender: TObject);
  strict protected
    procedure UpdateColor(const AValue: TAlphaColor); inline;
    property SkPaint: ISkPaint read FPaint;
  strict protected
    function RadiusXStored: Boolean; virtual;
    function RadiusYStored: Boolean; virtual;
  strict protected
    function DoCreateAnimation: TZxAnimation; override;
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property NormalColor: TAlphaColor index TZxButtonTriggerType.Normal read GetTriggerColor write SetTriggerColor stored True;
    property HotColor: TAlphaColor index TZxButtonTriggerType.Hot read GetTriggerColor write SetTriggerColor stored True;
    property PressedColor: TAlphaColor index TZxButtonTriggerType.Pressed read GetTriggerColor write SetTriggerColor stored True;
    property FocusedColor: TAlphaColor index TZxButtonTriggerType.Focused read GetTriggerColor write SetTriggerColor stored True;
    property RadiusX: Single read FRadiusX write SetRadiusX stored RadiusXStored;
    property RadiusY: Single read FRadiusY write SetRadiusY stored RadiusYStored;
  end;

  TZxCustomTextButtonStyleObject = class abstract(TZxCustomButtonStyleObject, ISkTextSettings, IObjectState, ICaption,
    IZxPrefixStyle)
  strict private
    FText: TZxText;
    procedure OnTextResized(Sender: TObject);
  strict protected
    procedure OnTriggerProcess(Sender: TObject); virtual; abstract;
  strict protected
    function DoCreateAnimation: TZxAnimation; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Text: TZxText read FText implements ISkTextSettings, IObjectState, ICaption, IZxPrefixStyle;
  end;

  [ComponentPlatformsAttribute(SkSupportedPlatformsMask)]
  TZxTextSettingsButtonStyleObject = class(TZxCustomTextButtonStyleObject)
  strict private
    FTriggerTextSettings: array [TZxButtonTriggerType] of TSkTextSettings;
    function GetTriggerTextSettings(const AIndex: TZxButtonTriggerType): TSkTextSettings;
    procedure SetTriggerTextSettings(const AIndex: TZxButtonTriggerType; const ATextSettings: TSkTextSettings);
    procedure OnTextSettingsChanged(Sender: TObject);
  strict protected
    procedure UpdateTextSettings(const ATriggerType: TZxButtonTriggerType; const AApplyColor: Boolean);
    procedure UpdateFontColor(const AValue: TAlphaColor);
  strict protected
    procedure Loaded; override;
    procedure DoTriggered(const ATriggerType: TZxButtonTriggerType); override;
    procedure OnTriggerProcess(Sender: TObject); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property NormalTextSettings: TSkTextSettings index TZxButtonTriggerType.Normal read GetTriggerTextSettings
      write SetTriggerTextSettings;
    property HotTextSettings: TSkTextSettings index TZxButtonTriggerType.Hot read GetTriggerTextSettings
      write SetTriggerTextSettings;
    property PressedTextSettings: TSkTextSettings index TZxButtonTriggerType.Pressed read GetTriggerTextSettings
      write SetTriggerTextSettings;
    property FocusedTextSettings: TSkTextSettings index TZxButtonTriggerType.Focused read GetTriggerTextSettings
      write SetTriggerTextSettings;
  end;

  TZxCustomSvgGlyphButtonStyleObject = class(TZxCustomButtonStyleObject, IGlyph)
  strict private
    FGlyph: TZxSvgGlyph;
  strict protected
    procedure OnTriggerProcess(Sbender: TObject); virtual; abstract;
  strict protected
    procedure Loaded; override;
    procedure DoRealign; override;
    function DoCreateAnimation: TZxAnimation; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Glyph: TZxSvgGlyph read FGlyph implements IGlyph;
  end;

  [ComponentPlatformsAttribute(SkSupportedPlatformsMask)]
  TZxColorOverrideSvgGlyphButtonStyleObject = class(TZxCustomSvgGlyphButtonStyleObject)
  strict private
    FTriggerColors: array [TZxButtonTriggerType] of TAlphaColor;
    function GetTriggerColor(const AIndex: TZxButtonTriggerType): TAlphaColor;
    procedure SetTriggerColor(const AIndex: TZxButtonTriggerType; const AValue: TAlphaColor);
  strict protected
    procedure UpdateColor(const AValue: TAlphaColor); inline;
  strict protected
    procedure Loaded; override;
    procedure OnTriggerProcess(Sender: TObject); override;
  published
    property NormalColor: TAlphaColor index TZxButtonTriggerType.Normal read GetTriggerColor write SetTriggerColor stored True;
    property HotColor: TAlphaColor index TZxButtonTriggerType.Hot read GetTriggerColor write SetTriggerColor stored True;
    property PressedColor: TAlphaColor index TZxButtonTriggerType.Pressed read GetTriggerColor write SetTriggerColor stored True;
    property FocusedColor: TAlphaColor index TZxButtonTriggerType.Focused read GetTriggerColor write SetTriggerColor stored True;
  end;

implementation

uses
  System.Rtti,
  System.Math.Vectors,
  System.Math,
  FMX.Utils,
  FMX.Platform.Metrics;

{ TZxStyleTriggerHelper }

function TZxStyleTriggerHelper.ToProperty: String;
begin
  Result := 'Is' + TRttiEnumerationType.GetName<TZxStyleTrigger>(Self);
end;

function TZxStyleTriggerHelper.ToProperty(const AValue: Boolean): String;
begin
  if AValue then
    Result := ToProperty + '=True'
  else
    Result := ToProperty + '=False';
end;

{ TZxCustomStyleObject }

constructor TZxCustomStyleObject.Create(AOwner: TComponent);
begin
  inherited;
  SetAcceptsControls(False);
  HitTest := False;
  DrawCacheKind := TSkDrawCacheKind.Always;
end;

function TZxCustomStyleObject.DoGetUpdateRect: TRectF;
begin
  Result := inherited;
  if (Canvas <> nil) and not Canvas.IsScaleInteger then
    Result := Canvas.AlignToPixel(Result);
end;

{ TZxCustomActiveStyleObject }

constructor TZxCustomActiveStyleObject.Create(AOwner: TComponent);
begin
  inherited;
  FActiveAnimation := CreateAnimation;
  FActiveAnimation.OnFinish := Triggered;
  FActiveAnimation.Duration := 0;
end;

destructor TZxCustomActiveStyleObject.Destroy;
begin
  FActiveAnimation.Free;
  inherited;
end;

procedure TZxCustomActiveStyleObject.DoRootChanged;
begin
  inherited;
  { necessary because TAnimation.Start will not start the ani thread if Root = nil }
  FActiveAnimation.SetRoot(Root);
end;

procedure TZxCustomActiveStyleObject.Triggered(Sender: TObject);
begin
  FActive := not FActiveAnimation.Inverse;
  DoTriggered;
end;

procedure TZxCustomActiveStyleObject.DoTriggered;
begin
  if Assigned(FOnTriggered) then
    FOnTriggered(Self);
end;

function TZxCustomActiveStyleObject.DurationStored: Boolean;
begin
  Result := not SameValue(Duration, 0, TEpsilon.Vector);
end;

function TZxCustomActiveStyleObject.GetDuration: Single;
begin
  Result := FActiveAnimation.Duration;
end;

procedure TZxCustomActiveStyleObject.SetDuration(const AValue: Single);
begin
  FActiveAnimation.Duration := AValue;
end;

procedure TZxCustomActiveStyleObject.SetNewScene(AScene: IScene);
begin
  inherited;
  if AScene = nil then
    Active := False;
end;

procedure TZxCustomActiveStyleObject.SetTrigger(const Value: TZxStyleTrigger);
begin
  FTrigger := Value;
  SetupAnimations;
end;

procedure TZxCustomActiveStyleObject.SetupAnimations;
begin
  FActiveAnimation.Trigger := FTrigger.ToProperty(True);
  FActiveAnimation.TriggerInverse := FTrigger.ToProperty(False);
end;

procedure TZxCustomActiveStyleObject.StartTriggerAnimation(const AInstance: TFmxObject; const ATrigger: string);
begin
  inherited;
  FActiveAnimation.StartTrigger(AInstance, ATrigger);
end;

{ TZxColorActiveStyleObject }

constructor TZxColorActiveStyleObject.Create(AOwner: TComponent);
begin
  inherited;
  ActiveAnimation.Duration := 0.1;
  ActiveAnimation.OnProcessValue := OnTriggerProcess;
  FPaint := TSkPaint.Create;
  FPaint.AntiAlias := True;
  UpdateColor(TAlphaColors.Null);
end;

destructor TZxColorActiveStyleObject.Destroy;
begin

  inherited;
end;

function TZxColorActiveStyleObject.CreateAnimation: TAnimation;
begin
  Result := TZxColorAnimation.Create(nil);
end;

procedure TZxColorActiveStyleObject.UpdateColor(const AValue: TAlphaColor);
begin
  FColor := TAlphaColorF.Create(AValue);
  FPaint.Color := AValue;
  Redraw;
end;

procedure TZxColorActiveStyleObject.OnTriggerProcess(Sender: TObject; const AValue: TAlphaColor);
begin
  UpdateColor(AValue);
end;

function TZxColorActiveStyleObject.RadiusXStored: Boolean;
begin
  Result := not SameValue(FRadiusX, 0, TEpsilon.Position);
end;

function TZxColorActiveStyleObject.RadiusYStored: Boolean;
begin
  Result := not SameValue(FRadiusY, 0, TEpsilon.Position);
end;

procedure TZxColorActiveStyleObject.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
begin
  inherited;
  FPaint.AlphaF := FColor.A * AOpacity;
  if (FRadiusX <> 0) or (FRadiusY <> 0) then
    ACanvas.DrawRoundRect(ADest, FRadiusX, FRadiusY, FPaint)
  else
    ACanvas.DrawRect(ADest, FPaint);
end;

function TZxColorActiveStyleObject.DurationStored: Boolean;
begin
  Result := not SameValue(Duration, 0.1, TEpsilon.Vector);
end;

function TZxColorActiveStyleObject.GetActiveAnimation: TZxColorAnimation;
begin
  Result := inherited ActiveAnimation as TZxColorAnimation;
end;

function TZxColorActiveStyleObject.GetActiveColor: TAlphaColor;
begin
  Result := ActiveAnimation.StopValue;
end;

function TZxColorActiveStyleObject.GetSourceColor: TAlphaColor;
begin
  Result := ActiveAnimation.StartValue;
end;

procedure TZxColorActiveStyleObject.SetActiveColor(const AValue: TAlphaColor);
begin
  ActiveAnimation.StopValue := AValue;
  if Active then
    UpdateColor(AValue);
end;

procedure TZxColorActiveStyleObject.SetRadiusX(const AValue: Single);
begin
  if FRadiusX <> AValue then
  begin
    FRadiusX := AValue;
    Redraw;
  end;
end;

procedure TZxColorActiveStyleObject.SetRadiusY(const AValue: Single);
begin
  if FRadiusY <> AValue then
  begin
    FRadiusY := AValue;
    Redraw;
  end;
end;

procedure TZxColorActiveStyleObject.SetSourceColor(const AValue: TAlphaColor);
begin
  ActiveAnimation.StartValue := AValue;
  if not Active then
    UpdateColor(AValue);
end;

{ TZxAnimatedImageActiveStyleObject }

constructor TZxAnimatedImageActiveStyleObject.Create(AOwner: TComponent);
begin
  inherited;
  FAnimatedImage := TSkAnimatedImage.Create(Self);
  FAnimatedImage.Name := String.Empty;
  FAnimatedImage.Stored := False;
  FAnimatedImage.SetSubComponent(True);
  FAnimatedImage.Animation.Enabled := False;
  FAnimatedImage.Animation.Loop := False;
  FAnimatedImage.Align := TAlignLayout.Client;
  FAnimatedImage.Parent := Self;
end;

procedure TZxAnimatedImageActiveStyleObject.DefineProperties(AFiler: TFiler);

  function DoWrite: Boolean;
  begin
    if AFiler.Ancestor <> nil then
      Result := not(AFiler.Ancestor is TZxAnimatedImageActiveStyleObject) or
        not TZxAnimatedImageActiveStyleObject(AFiler.Ancestor).AnimatedImage.Source.Equals(FAnimatedImage.Source)
    else
      Result := FAnimatedImage.Source.Data <> nil;
  end;

begin
  inherited;
  AFiler.DefineBinaryProperty('AniSourceData', ReadData, WriteData, DoWrite);
end;

destructor TZxAnimatedImageActiveStyleObject.Destroy;
begin
  FAnimatedImage.Free;
  inherited;
end;

procedure TZxAnimatedImageActiveStyleObject.ReadData(AStream: TStream);
begin
  if AStream.Size = 0 then
    FAnimatedImage.Source.Data := nil
  else
    FAnimatedImage.LoadFromStream(AStream);
end;

procedure TZxAnimatedImageActiveStyleObject.WriteData(AStream: TStream);
begin
  if FAnimatedImage.Source.Data <> nil then
    AStream.WriteBuffer(FAnimatedImage.Source.Data, Length(FAnimatedImage.Source.Data));
end;

procedure TZxAnimatedImageActiveStyleObject.DoTriggered;
begin
  inherited;
  if FAniLoop then
  begin
    FAnimatedImage.Animation.Enabled := Active;
    if not Active then
      FAnimatedImage.Animation.Progress := 0;
  end
  else
  begin
    FAnimatedImage.Animation.Inverse := ActiveAnimation.Inverse;
    FAnimatedImage.Animation.Start;
  end;
end;

function TZxAnimatedImageActiveStyleObject.CreateAnimation: TAnimation;
begin
  Result := TZxAnimation.Create(nil);
end;

function TZxAnimatedImageActiveStyleObject.AniDelayStored: Boolean;
begin
  Result := not SameValue(AniDelay, 0, TEpsilon.Vector);
end;

function TZxAnimatedImageActiveStyleObject.AniSpeedStored: Boolean;
begin
  Result := not SameValue(AniSpeed, 1, TEpsilon.Vector);
end;

function TZxAnimatedImageActiveStyleObject.GetAniDelay: Double;
begin
  Result := FAnimatedImage.Animation.Delay;
end;

function TZxAnimatedImageActiveStyleObject.GetAniSource: TSkAnimatedImage.TSource;
begin
  Result := FAnimatedImage.Source;
end;

function TZxAnimatedImageActiveStyleObject.GetAniSpeed: Double;
begin
  Result := FAnimatedImage.Animation.Speed;
end;

procedure TZxAnimatedImageActiveStyleObject.SetAniDelay(const AValue: Double);
begin
  FAnimatedImage.Animation.Delay := AValue;
end;

procedure TZxAnimatedImageActiveStyleObject.SetAnimatedImage(const AValue: TSkAnimatedImage);
begin
  FAnimatedImage.Assign(AValue);
end;

procedure TZxAnimatedImageActiveStyleObject.SetAniLoop(const AValue: Boolean);
begin
  if FAniLoop <> AValue then
  begin
    FAniLoop := AValue;
    FAnimatedImage.Animation.Loop := FAniLoop;
    if FAniLoop then
      FAnimatedImage.Animation.Inverse := False;
  end;
end;

procedure TZxAnimatedImageActiveStyleObject.SetAniSource(const AValue: TSkAnimatedImage.TSource);
begin
  FAnimatedImage.Source := AValue;
end;

procedure TZxAnimatedImageActiveStyleObject.SetAniSpeed(const AValue: Double);
begin
  FAnimatedImage.Animation.Speed := AValue;
end;

{ TZxCustomButtonStyleObject }

constructor TZxCustomButtonStyleObject.Create(AOwner: TComponent);
begin
  inherited;
  FCurrent := TZxButtonTriggerType.Normal;
  FPrevious := TZxButtonTriggerType.Normal;
  FTriggers[TZxButtonTriggerType.Normal] := CreateAnimation('IsMouseOver=False;IsPressed=False;IsFocused=False');
  FTriggers[TZxButtonTriggerType.Hot] := CreateAnimation('IsMouseOver=True;IsPressed=False');
  FTriggers[TZxButtonTriggerType.Focused] := CreateAnimation('IsMouseOver=False;IsFocused=True;IsPressed=False');
  FTriggers[TZxButtonTriggerType.Pressed] := CreateAnimation('IsMouseOver=True;IsPressed=True');
  Duration := 0.1;
end;

destructor TZxCustomButtonStyleObject.Destroy;
begin
  for var LTrigger in FTriggers do
    LTrigger.Free;
  inherited;
end;

procedure TZxCustomButtonStyleObject.DoRootChanged;
begin
  inherited;
  for var LTrigger in FTriggers do
    LTrigger.SetRoot(Root);
end;

function TZxCustomButtonStyleObject.CreateAnimation(const ATrigger: TTrigger): TZxAnimation;
begin
  Result := DoCreateAnimation;
  Result.Duration := FDuration;
  Result.Trigger := ATrigger;
  Result.OnFirstFrame := Triggered;
end;

procedure TZxCustomButtonStyleObject.UpdateTriggersDuration;
begin
  for var LTrigger in FTriggers do
    LTrigger.Duration := FDuration;
end;

procedure TZxCustomButtonStyleObject.StartTriggerAnimation(const AInstance: TFmxObject; const ATrigger: string);
begin
  inherited;
  for var LTrigger in FTriggers do
    LTrigger.StartTrigger(AInstance, ATrigger);
end;

procedure TZxCustomButtonStyleObject.Triggered(Sender: TObject);
begin
  var
  LNew := TZxButtonTriggerType.Normal;
  for var LTriggerType := Low(FTriggers) to High(FTriggers) do
  begin
    if FTriggers[LTriggerType] = Sender then
      LNew := LTriggerType
    else
      FTriggers[LTriggerType].StopAtCurrent;
  end;
  FPrevious := FCurrent;
  FCurrent := LNew;
  DoTriggered(FCurrent);
end;

procedure TZxCustomButtonStyleObject.DoTriggered(const ATriggerType: TZxButtonTriggerType);
begin
  if Assigned(FTriggerEvents[ATriggerType]) then
    FTriggerEvents[ATriggerType](Self);
end;

function TZxCustomButtonStyleObject.DurationStored: Boolean;
begin
  Result := not SameValue(FDuration, 0.1, TEpsilon.Vector);
end;

function TZxCustomButtonStyleObject.GetTrigger(const AIndex: TZxButtonTriggerType): TZxAnimation;
begin
  Result := FTriggers[AIndex];
end;

function TZxCustomButtonStyleObject.GetTriggerEvent(const AIndex: TZxButtonTriggerType): TNotifyEvent;
begin
  Result := FTriggerEvents[AIndex];
end;

procedure TZxCustomButtonStyleObject.SetDuration(const AValue: Single);
begin
  if FDuration <> AValue then
  begin
    FDuration := AValue;
    UpdateTriggersDuration;
  end;
end;

procedure TZxCustomButtonStyleObject.SetTriggerEvent(const AIndex: TZxButtonTriggerType; const AValue: TNotifyEvent);
begin
  FTriggerEvents[AIndex] := AValue;
end;

{ TZxColorButtonStyleObject }

constructor TZxColorButtonStyleObject.Create(AOwner: TComponent);
begin
  inherited;
  FPaint := TSkPaint.Create;
  FPaint.AntiAlias := True;
  UpdateColor(TAlphaColors.Null);
end;

function TZxColorButtonStyleObject.DoCreateAnimation: TZxAnimation;
begin
  Result := TZxAnimation.Create(nil);
  Result.OnProcess := OnTriggerProcess;
end;

procedure TZxColorButtonStyleObject.OnTriggerProcess(Sender: TObject);
begin
  UpdateColor(InterpolateColor(FTriggerColors[Previous], FTriggerColors[Current], TAnimation(Sender).NormalizedTime));
end;

procedure TZxColorButtonStyleObject.UpdateColor(const AValue: TAlphaColor);
begin
  FColor := TAlphaColorF.Create(AValue);
  FPaint.Color := AValue;
  Redraw;
end;

procedure TZxColorButtonStyleObject.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
begin
  inherited;
  FPaint.AlphaF := FColor.A * AOpacity;
  if (FRadiusX <> 0) or (FRadiusY <> 0) then
    ACanvas.DrawRoundRect(ADest, FRadiusX, FRadiusY, FPaint)
  else
    ACanvas.DrawRect(ADest, FPaint);
end;

function TZxColorButtonStyleObject.GetTriggerColor(const AIndex: TZxButtonTriggerType): TAlphaColor;
begin
  Result := FTriggerColors[AIndex];
end;

function TZxColorButtonStyleObject.RadiusXStored: Boolean;
begin
  Result := not SameValue(FRadiusX, 0, TEpsilon.Position);
end;

function TZxColorButtonStyleObject.RadiusYStored: Boolean;
begin
  Result := not SameValue(FRadiusY, 0, TEpsilon.Position);
end;

procedure TZxColorButtonStyleObject.SetRadiusX(const AValue: Single);
begin
  if FRadiusX <> AValue then
  begin
    FRadiusX := AValue;
    Redraw;
  end;
end;

procedure TZxColorButtonStyleObject.SetRadiusY(const AValue: Single);
begin
  if FRadiusY <> AValue then
  begin
    FRadiusY := AValue;
    Redraw;
  end;
end;

procedure TZxColorButtonStyleObject.SetTriggerColor(const AIndex: TZxButtonTriggerType; const AValue: TAlphaColor);
begin
  if FTriggerColors[AIndex] <> AValue then
  begin
    FTriggerColors[AIndex] := AValue;
    if (AIndex = Current) and not Triggers[AIndex].Running then
      UpdateColor(AValue);
  end;
end;

{ TZxCustomTextButtonStyleObject }

constructor TZxCustomTextButtonStyleObject.Create(AOwner: TComponent);
begin
  inherited;
  FText := TZxText.Create(Self);
  FText.Stored := False;
  FText.SetSubComponent(True);
  FText.Name := String.Empty;
  FText.Text := 'Text';
  FText.Align := TAlignLayout.Client;
  FText.Parent := Self;
  FText.OnResized := OnTextResized;
end;

destructor TZxCustomTextButtonStyleObject.Destroy;
begin
  FText.Free;
  inherited;
end;

function TZxCustomTextButtonStyleObject.DoCreateAnimation: TZxAnimation;
begin
  Result := TZxAnimation.Create(nil);
  Result.OnProcess := OnTriggerProcess;
end;

procedure TZxCustomTextButtonStyleObject.OnTextResized(Sender: TObject);
begin
  if csLoading in ComponentState then
    Exit;
  SetSize(FText.Size);
end;

{ TZxTextSettingsButtonStyleObject }

constructor TZxTextSettingsButtonStyleObject.Create(AOwner: TComponent);
var
  PropertiesService: IFMXPlatformPropertiesService;
begin
  inherited;
  var
  LRefTextSettings := TSkTextSettings.Create(nil);
  try
    { copied from Zx.Buttons.TZxCustomButton.Create }
    LRefTextSettings.MaxLines := 1;
    LRefTextSettings.HorzAlign := TSkTextHorzAlign.Center;
    if SupportsPlatformService(IFMXPlatformPropertiesService, PropertiesService) then
      LRefTextSettings.Trimming := PropertiesService.GetValue('Trimming', TValue.From<TTextTrimming>(TTextTrimming.None))
        .AsType<TTextTrimming>
    else
      LRefTextSettings.Trimming := TTextTrimming.None;

    for var LTriggerType := Low(TZxButtonTriggerType) to High(TZxButtonTriggerType) do
    begin
      FTriggerTextSettings[LTriggerType] := TSkTextSettings.Create(Self);
      FTriggerTextSettings[LTriggerType].Assign(LRefTextSettings);
      FTriggerTextSettings[LTriggerType].OnChange := OnTextSettingsChanged;
    end;
  finally
    LRefTextSettings.Free;
  end;
end;

destructor TZxTextSettingsButtonStyleObject.Destroy;
begin
  for var LTriggerType := High(TZxButtonTriggerType) downto Low(TZxButtonTriggerType) do
    FTriggerTextSettings[LTriggerType].Free;
  inherited;
end;

procedure TZxTextSettingsButtonStyleObject.Loaded;
begin
  inherited;
  UpdateTextSettings(TZxButtonTriggerType.Normal, True);
end;

procedure TZxTextSettingsButtonStyleObject.UpdateTextSettings(const ATriggerType: TZxButtonTriggerType;
  const AApplyColor: Boolean);
begin
  var
  LCurrentTextSettings := FTriggerTextSettings[ATriggerType];
  var
  LPreviousTextSettings := FTriggerTextSettings[Previous];
  Text.TextSettings.BeginUpdate;
  try
    Text.TextSettings := LCurrentTextSettings;
    if not AApplyColor then
      Text.TextSettings.FontColor := LPreviousTextSettings.FontColor;
  finally
    Text.TextSettings.EndUpdate;
  end;
end;

procedure TZxTextSettingsButtonStyleObject.UpdateFontColor(const AValue: TAlphaColor);
begin
  Text.TextSettings.FontColor := AValue;
  Redraw;
end;

procedure TZxTextSettingsButtonStyleObject.DoTriggered(const ATriggerType: TZxButtonTriggerType);
begin
  inherited;
  UpdateTextSettings(ATriggerType, False);
end;

procedure TZxTextSettingsButtonStyleObject.OnTextSettingsChanged(Sender: TObject);
begin
  if Sender = FTriggerTextSettings[Current] then
    UpdateTextSettings(Current, True);
end;

procedure TZxTextSettingsButtonStyleObject.OnTriggerProcess(Sender: TObject);
begin
  var
  LPreviousFontColor := FTriggerTextSettings[Previous].FontColor;
  var
  LCurrentFontColor := FTriggerTextSettings[Current].FontColor;
  var
  LFontColor := InterpolateColor(LPreviousFontColor, LCurrentFontColor, TAnimation(Sender).NormalizedTime);
  UpdateFontColor(LFontColor);
end;

function TZxTextSettingsButtonStyleObject.GetTriggerTextSettings(const AIndex: TZxButtonTriggerType): TSkTextSettings;
begin
  Result := FTriggerTextSettings[AIndex];
end;

procedure TZxTextSettingsButtonStyleObject.SetTriggerTextSettings(const AIndex: TZxButtonTriggerType;
  const ATextSettings: TSkTextSettings);
begin
  FTriggerTextSettings[AIndex].Assign(ATextSettings);
  if (AIndex = Current) and not Triggers[AIndex].Running then
    UpdateTextSettings(AIndex, True);
end;

{ TZxCustomSvgGlyphButtonStyleObject }

constructor TZxCustomSvgGlyphButtonStyleObject.Create(AOwner: TComponent);
begin
  inherited;
  FGlyph := TZxSvgGlyph.Create(Self);
  FGlyph.Stored := False;
  FGlyph.SetSubComponent(True);
  FGlyph.Name := String.Empty;
  FGlyph.Align := TAlignLayout.Client;
  FGlyph.Parent := Self;
end;

destructor TZxCustomSvgGlyphButtonStyleObject.Destroy;
begin
  FGlyph.Free;
  inherited;
end;

procedure TZxCustomSvgGlyphButtonStyleObject.Loaded;
begin
  inherited;
  Visible := FGlyph.Visible;
end;

procedure TZxCustomSvgGlyphButtonStyleObject.DoRealign;
begin
  inherited;
  Visible := FGlyph.Visible;
end;

function TZxCustomSvgGlyphButtonStyleObject.DoCreateAnimation: TZxAnimation;
begin
  Result := TZxAnimation.Create(nil);
  Result.OnProcess := OnTriggerProcess;
end;

{ TZxColorOverrideSvgGlyphButtonStyleObject }

procedure TZxColorOverrideSvgGlyphButtonStyleObject.Loaded;
begin
  inherited;
  UpdateColor(FTriggerColors[Current]);
end;

function TZxColorOverrideSvgGlyphButtonStyleObject.GetTriggerColor(const AIndex: TZxButtonTriggerType): TAlphaColor;
begin
  Result := FTriggerColors[AIndex];
end;

procedure TZxColorOverrideSvgGlyphButtonStyleObject.OnTriggerProcess(Sender: TObject);
begin
  UpdateColor(InterpolateColor(FTriggerColors[Previous], FTriggerColors[Current], TAnimation(Sender).NormalizedTime));
end;

procedure TZxColorOverrideSvgGlyphButtonStyleObject.SetTriggerColor(const AIndex: TZxButtonTriggerType;
  const AValue: TAlphaColor);
begin
  if FTriggerColors[AIndex] <> AValue then
  begin
    FTriggerColors[AIndex] := AValue;
    if (AIndex = Current) and not Triggers[AIndex].Running then
      UpdateColor(AValue);
  end;
end;

procedure TZxColorOverrideSvgGlyphButtonStyleObject.UpdateColor(const AValue: TAlphaColor);
begin
  Glyph.OverrideColor := AValue;
end;

initialization

RegisterFmxClasses([TZxColorActiveStyleObject, TZxAnimatedImageActiveStyleObject, TZxColorButtonStyleObject,
  TZxTextSettingsButtonStyleObject, TZxColorOverrideSvgGlyphButtonStyleObject]);

end.
