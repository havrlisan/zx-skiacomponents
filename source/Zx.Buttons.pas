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
unit Zx.Buttons;

{$IF CompilerVersion > 36}
{$MESSAGE WARN 'Check changes in FMX.StdCtrls TCustomButton, TButton, TSpeedButton implementation'}
{$ENDIF}

interface

uses
  System.UITypes,
  System.Types,
  System.ImageList,
  System.Classes,
  System.Rtti,
  System.SysUtils,
  System.Messaging,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Types,
  FMX.ActnList,
  FMX.ImgList,
  Zx.TextControl,
  Zx.Styles,
  FMX.Skia;

type
  TZxCustomButton = class(TZxTextControl, IGlyph)
  private
    FPressing: Boolean;
    FIsPressed: Boolean;
    FModalResult: TModalResult;
    FStaysPressed: Boolean;
    FRepeatTimer: TTimer;
    FRepeat: Boolean;
    FTintColor: TAlphaColor;
    FTintObject: ITintedObject;
    FIconTintColor: TAlphaColor;
    FIconTintObject: ITintedObject;
    FIcon: TControl;
    FOldIconVisible: Boolean;
    FGlyph: IGlyph;
    FImageLink: TGlyphImageLink;
    procedure SetTintColor(const Value: TAlphaColor);
    function IsTintColorStored: Boolean;
    function IsIconTintColorStored: Boolean;
    procedure SetIconTintColor(const Value: TAlphaColor);
    { IGlyph }
    function GetImageIndex: TImageIndex;
    procedure SetImageIndex(const Value: TImageIndex);
    function GetImages: TBaseImageList; inline;
    procedure SetImages(const Value: TBaseImageList);
  protected
    function GetFitWidth: Single; override;
  protected
    procedure ActionChange(Sender: TBasicAction; CheckDefaults: Boolean); override;
    function IsPressedStored: Boolean; virtual;
    procedure RestoreButtonState; virtual;
    procedure ApplyTriggers; virtual;
    procedure SetIsPressed(const Value: Boolean); virtual;
    procedure SetStaysPressed(const Value: Boolean); virtual;
    procedure Click; override;
    procedure DblClick; override;
    procedure ApplyStyle; override;
    procedure FreeStyle; override;
    procedure ToggleStaysPressed; virtual;
    procedure DoRepeatTimer(Sender: TObject);
    procedure DoRepeatDelayTimer(Sender: TObject);
    function GetData: TValue; override;
    procedure SetData(const Value: TValue); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState); override;
    function GetDefaultSize: TSizeF; override;
    function GetDefaultTouchTargetExpansion: TRectF; override;
    property TintColor: TAlphaColor read FTintColor write SetTintColor stored IsTintColorStored;
    property TintObject: ITintedObject read FTintObject;
    property IconTintColor: TAlphaColor read FIconTintColor write SetIconTintColor stored IsIconTintColorStored;
    property IconTintObject: ITintedObject read FIconTintObject;
    procedure ImagesChanged; virtual;
    /// <summary> Determines whether the <b>ImageIndex</b> property needs to be stored in the fmx-file</summary>
    /// <returns> <c>True</c> if the <b>ImageIndex</b> property needs to be stored in the fmx-file</returns>
    function ImageIndexStored: Boolean; virtual;
    { IAcceleratorKeyReceiver }
    /// <summary>Overrides the TPresentedTextControl.TriggerAcceleratorKey</summary>
    procedure TriggerAcceleratorKey; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetNewScene(AScene: IScene); override;
    property Action;
    property StaysPressed: Boolean read FStaysPressed write SetStaysPressed stored IsPressedStored default False;
    { triggers }
    property IsPressed: Boolean read FIsPressed write SetIsPressed default False;
    property ModalResult: TModalResult read FModalResult write FModalResult default mrNone;
    property RepeatClick: Boolean read FRepeat write FRepeat default False;
    /// <summary> The list of images. Can be <c>nil</c>. <para>See also <b>FMX.ActnList.IGlyph</b></para></summary>
    property Images: TBaseImageList read GetImages write SetImages;
    /// <summary> Zero based index of an image. The default is <c>-1</c>.
    /// <para> See also <b>FMX.ActnList.IGlyph</b></para></summary>
    /// <remarks> If non-existing index is specified, an image is not drawn and no exception is raised</remarks>
    property ImageIndex: TImageIndex read GetImageIndex write SetImageIndex stored ImageIndexStored;
  end;

  [ComponentPlatformsAttribute(pidAllPlatforms)]
  TZxButton = class(TZxCustomButton)
  private
    FDefault: Boolean;
    FCancel: Boolean;
  public
    property TintObject;
    property IconTintObject;
  protected
    procedure AfterDialogKey(var Key: Word; Shift: TShiftState); override;
  published
    property StaysPressed default False;
    property Action;
    property Align default TAlignLayout.None;
    property Anchors;
    property AutoSize default False;
    property AutoTranslate default True;
    property Cancel: Boolean read FCancel write FCancel default False;
    property CanFocus default True;
    property CanParentFocus;
    property ClipChildren default False;
    property ClipParent default False;
    property Cursor default crDefault;
    property Default: Boolean read FDefault write FDefault default False;
    property DisableFocusEffect;
    property DragMode default TDragMode.dmManual;
    property EnableDragHighlight default True;
    property Enabled;
    property StyledSettings;
    property Height;
    property HelpContext;
    property HelpKeyword;
    property HelpType;
    property Hint;
    property HitTest default True;
    property IconTintColor;
    property Images;
    property ImageIndex;
    property IsPressed default False;
    property Locked default False;
    property Padding;
    property ModalResult default mrNone;
    property Opacity;
    property Margins;
    property PopupMenu;
    property Position;
    property RepeatClick default False;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property Size;
    property StyleLookup;
    property TabOrder;
    property TabStop;
    property Text;
    property TextSettings;
    property TintColor;
    property TouchTargetExpansion;
    property Visible;
    property Width;
    property ParentShowHint;
    property ShowHint;
    property OnApplyStyleLookup;
    property OnFreeStyle;
    property OnDragEnter;
    property OnDragLeave;
    property OnDragOver;
    property OnDragDrop;
    property OnDragEnd;
    property OnKeyDown;
    property OnKeyUp;
    property OnCanFocus;
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnPainting;
    property OnPaint;
    property OnResize;
    property OnResized;
  end;

  [ComponentPlatformsAttribute(pidAllPlatforms)]
  TZxSpeedButton = class(TZxCustomButton, IGroupName, IIsChecked)
  private
    FGroupName: string;
    { IIsChecked }
    function GetIsChecked: Boolean;
    procedure SetIsChecked(const Value: Boolean);
    function IsCheckedStored: Boolean;
    procedure GroupMessageCall(const Sender: TObject; const M: TMessage);
    { IGroupName }
    function GetGroupName: string;
    function GroupNameStored: Boolean;
    procedure SetGroupName(const Value: string);
  protected
    function IsPressedStored: Boolean; override;
    procedure ToggleStaysPressed; override;
    procedure SetIsPressed(const Value: Boolean); override;
    procedure ActionChange(Sender: TBasicAction; CheckDefaults: Boolean); override;
    procedure RestoreButtonState; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property IconTintObject;
    property TintObject;
  published
    // do not move this line
    property StaysPressed default False;
    property Action;
    property Align default TAlignLayout.None;
    property Anchors;
    property AutoSize default False;
    property AutoTranslate default True;
    property CanFocus default False;
    property CanParentFocus;
    property ClipChildren default False;
    property ClipParent default False;
    property Cursor default crDefault;
    property DragMode default TDragMode.dmManual;
    property EnableDragHighlight default True;
    property Enabled;
    property GroupName: string read GetGroupName write SetGroupName stored GroupNameStored nodefault;
    property StyledSettings;
    property Height;
    property HelpContext;
    property HelpKeyword;
    property HelpType;
    property Hint;
    property HitTest default True;
    property IsPressed default False;
    property IconTintColor;
    property Images;
    property ImageIndex;
    property Locked default False;
    property Padding;
    property ModalResult default mrNone;
    property Opacity;
    property Margins;
    property PopupMenu;
    property Position;
    property RepeatClick default False;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property Size;
    property ParentShowHint;
    property ShowHint;
    property StyleLookup;
    property Text;
    property TextSettings;
    property TintColor;
    property TouchTargetExpansion;
    property Visible;
    property Width;
    property OnApplyStyleLookup;
    property OnFreeStyle;
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
    property OnPainting;
    property OnPaint;
    property OnResize;
    property OnResized;
  end;

implementation

uses
  System.Math,
  System.Math.Vectors,
  System.UIConsts,
  System.Actions,
  System.RTLConsts,
  FMX.Platform.Metrics,
  FMX.Platform,
  FMX.BehaviorManager,
  FMX.Forms,
  FMX.Graphics,
  FMX.Utils,
  FMX.Styles;

{ TZxCustomButton }

constructor TZxCustomButton.Create(AOwner: TComponent);
var
  PropertiesService: IFMXPlatformPropertiesService;
begin
  inherited Create(AOwner);
  AutoTranslate := True;
  TextSettings.MaxLines := 1;
  TextSettings.HorzAlign := TSkTextHorzAlign.Center;
  FImageLink := TGlyphImageLink.Create(Self);
  if SupportsPlatformService(IFMXPlatformPropertiesService, PropertiesService) then
    TextSettings.Trimming := PropertiesService.GetValue('Trimming', TValue.From<TTextTrimming>(TTextTrimming.None))
      .AsType<TTextTrimming>
  else
    TextSettings.Trimming := TTextTrimming.None;

  HitTest := True;
  AutoCapture := True;
  CanFocus := True;
  SetAcceptsControls(False);
end;

destructor TZxCustomButton.Destroy;
begin
  FreeAndNil(FImageLink);
  inherited;
end;

procedure TZxCustomButton.ApplyTriggers;
var
  SaveIsMouseOver: Boolean;
begin
  SaveIsMouseOver := IsMouseOver;
  if IsPressed and StaysPressed then
    FIsMouseOver := True;
  StartTriggerAnimation(Self, 'IsPressed');
  ApplyTriggerEffect(Self, 'IsPressed');
  FIsMouseOver := SaveIsMouseOver;
end;

function TZxCustomButton.GetDefaultTouchTargetExpansion: TRectF;
var
  DeviceSrv: IFMXDeviceService;
begin
  if SupportsPlatformService(IFMXDeviceService, DeviceSrv) and (TDeviceFeature.HasTouchScreen in DeviceSrv.GetFeatures) then
    Result := TRectF.Create(DefaultTouchTargetExpansion, DefaultTouchTargetExpansion, DefaultTouchTargetExpansion,
      DefaultTouchTargetExpansion)
  else
    Result := inherited;
end;

function TZxCustomButton.GetFitWidth: Single;
begin
  Result := inherited;
  if Assigned(FGlyph) and (FGlyph is TControl) then
  begin
    var
    LGlyph := TControl(FGlyph);
    if LGlyph.Visible then
      Result := Result + LGlyph.Margins.Left + LGlyph.Width + LGlyph.Margins.Right;
  end;
end;

procedure TZxCustomButton.ActionChange(Sender: TBasicAction; CheckDefaults: Boolean);
begin
  if (Sender is TCustomAction) and not CheckDefaults then
  begin
    ImageIndex := TCustomAction(Sender).ImageIndex;
    if TCustomAction(Sender).ActionList <> nil then
      Images := TCustomAction(Sender).ActionList.Images
    else
      Images := nil;
  end;
  inherited;
end;

procedure TZxCustomButton.ApplyStyle;
var
  StyleObject: TFmxObject;
begin
  if FindStyleResource<TFmxObject>('background', StyleObject) and Supports(StyleObject, ITintedObject, FTintObject) then
    FTintObject.TintColor := FTintColor;
  if FindStyleResource<TFmxObject>('glyphstyle', StyleObject) and Supports(StyleObject, IGlyph, FGlyph) then
  begin
    FGlyph.Images := FImageLink.Images;
    FGlyph.ImageIndex := FImageLink.ImageIndex;
  end;
  StyleObject := nil;
  if FindStyleResource<TFmxObject>('icon', StyleObject) and Supports(StyleObject, ITintedObject) then
  begin
    FIconTintObject := StyleObject as ITintedObject;
    FIconTintObject.TintColor := FIconTintColor;
  end;
  if StyleObject is TControl then
  begin
    FIcon := TControl(StyleObject);
    FOldIconVisible := FIcon.Visible;
  end;
  ImagesChanged;
  inherited;
  if IsPressed then
    ApplyTriggers;
end;

procedure TZxCustomButton.FreeStyle;
var
  SavePressed: Boolean;
  SaveFocused: Boolean;
  SaveMouseOver: Boolean;
begin
  SavePressed := IsPressed;
  SaveFocused := IsFocused;
  SaveMouseOver := IsMouseOver;
  try
    if SavePressed or SaveFocused or SaveMouseOver then
    begin
      FIsFocused := False;
      FIsPressed := False;
      FIsMouseOver := False;
      ApplyTriggers;
    end
  finally
    FIsFocused := SaveFocused;
    FIsPressed := SavePressed;
    FIsMouseOver := SaveMouseOver;
  end;
  if FGlyph <> nil then
  begin
    FGlyph.ImageIndex := -1;
    FGlyph.Images := nil;
    FGlyph := nil;
  end;
  FTintObject := nil;
  FIconTintObject := nil;
  if FIcon <> nil then
  begin
    FIcon.Visible := FOldIconVisible;
    FIcon := nil;
  end;
  inherited;
end;

procedure TZxCustomButton.RestoreButtonState;
begin
  FIsPressed := False;
  ApplyTriggers;
end;

function TZxCustomButton.GetData: TValue;
begin
  Result := TValue.From<TNotifyEvent>(OnClick);
end;

function TZxCustomButton.GetDefaultSize: TSizeF;
var
  DeviceInfo: IDeviceBehavior;
begin
  if TBehaviorServices.Current.SupportsBehaviorService(IDeviceBehavior, DeviceInfo, Self) then
    case DeviceInfo.GetOSPlatform(Self) of
      TOSPlatform.Windows:
        Result := TSizeF.Create(80, 22);
      TOSPlatform.OSX:
        Result := TSizeF.Create(80, 22);
      TOSPlatform.iOS:
        Result := TSizeF.Create(73, 44);
      TOSPlatform.Android:
        Result := TSizeF.Create(73, 44);
      TOSPlatform.Linux:
        Result := TSizeF.Create(80, 27);
    end
  else
    Result := TSizeF.Create(80, 22);
end;

function TZxCustomButton.IsIconTintColorStored: Boolean;
begin
  Result := FIconTintColor <> claNull;
end;

function TZxCustomButton.IsPressedStored: Boolean;
begin
  Result := True;
end;

function TZxCustomButton.IsTintColorStored: Boolean;
begin
  Result := FTintColor <> claNull;
end;

procedure TZxCustomButton.SetData(const Value: TValue);
begin
  if Value.IsType<TNotifyEvent> then
    OnClick := Value.AsType<TNotifyEvent>();
end;

procedure TZxCustomButton.KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState);
begin
  inherited;
  if ((Key = vkReturn) or (KeyChar = ' ')) and (Shift = []) then
  begin
    Click;
    Key := 0;
    KeyChar := #0;
  end;
end;

procedure TZxCustomButton.DoRepeatTimer(Sender: TObject);
begin
  if (Root <> nil) and (Root.Captured <> nil) and (Root.Captured.GetObject = Self) then
    Click
  else
    FRepeatTimer.Enabled := False;
end;

procedure TZxCustomButton.DoRepeatDelayTimer(Sender: TObject);
begin
  FRepeatTimer.OnTimer := DoRepeatTimer;
  FRepeatTimer.Interval := 100;
end;

procedure TZxCustomButton.DblClick;
begin
  inherited;
  Click;
end;

procedure TZxCustomButton.Click;
var
  O: TComponent;
begin
  inherited;
  if (Self <> nil) and (ModalResult <> mrNone) then
  begin
    O := Scene.GetObject;
    while O <> nil do
    begin
      if (O is TCommonCustomForm) then
      begin
        TCommonCustomForm(O).ModalResult := FModalResult;
        Break;
      end;
      O := O.Owner;
    end;
  end;
end;

procedure TZxCustomButton.ToggleStaysPressed;
begin
  IsPressed := not FIsPressed;
end;

procedure TZxCustomButton.TriggerAcceleratorKey;
begin
  inherited;
  Click;
end;

procedure TZxCustomButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited;
  if Button = TMouseButton.mbLeft then
  begin
    FPressing := True;
    if FStaysPressed then
      ToggleStaysPressed
    else
    begin
      FIsPressed := True;
      if FRepeat then
      begin
        if FRepeatTimer = nil then
        begin
          FRepeatTimer := TTimer.Create(Self);
          FRepeatTimer.Interval := 500;
        end;
        FRepeatTimer.OnTimer := DoRepeatDelayTimer;
        FRepeatTimer.Enabled := True;
      end;
      ApplyTriggers;
    end;
  end;
end;

procedure TZxCustomButton.MouseMove(Shift: TShiftState; X, Y: Single);
var
  Inside: Boolean;
begin
  inherited;
  if (ssLeft in Shift) and FPressing then
  begin
    Inside := LocalRect.Contains(TPointF.Create(X, Y));
    if FIsPressed <> Inside then
    begin
      if not FStaysPressed then
      begin
        FIsPressed := Inside;
        ApplyTriggers;
      end;
    end;
  end;
end;

procedure TZxCustomButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if FPressing then
  begin
    if FRepeatTimer <> nil then
      FRepeatTimer.Enabled := False;
    FPressing := False;
    if not FStaysPressed or not LocalRect.Contains(TPointF.Create(X, Y)) then
      RestoreButtonState;
  end;
  inherited;
end;

procedure TZxCustomButton.SetIconTintColor(const Value: TAlphaColor);
begin
  if FIconTintColor <> Value then
  begin
    FIconTintColor := Value;
    if FIconTintObject <> nil then
      FIconTintObject.TintColor := FIconTintColor;
  end;
end;

procedure TZxCustomButton.SetIsPressed(const Value: Boolean);
begin
  if FStaysPressed then
  begin
    if Value <> FIsPressed then
    begin
      FIsPressed := Value;
      ApplyTriggers;
    end;
  end;
end;

procedure TZxCustomButton.SetNewScene(AScene: IScene);
begin
  if FIsPressed and (Scene <> nil) then
  begin
    if not FStaysPressed then
      FIsPressed := False;
    if AScene <> nil then
      StartTriggerAnimation(Self, 'IsPressed');
  end;
  inherited;
end;

procedure TZxCustomButton.SetStaysPressed(const Value: Boolean);
begin
  if not Value and FIsPressed then
    SetIsPressed(False);
  if FStaysPressed <> Value then
    FStaysPressed := Value;
end;

procedure TZxCustomButton.SetTintColor(const Value: TAlphaColor);
begin
  if FTintColor <> Value then
  begin
    FTintColor := Value;
    if FTintObject <> nil then
      FTintObject.TintColor := FTintColor;
  end;
end;

procedure TZxCustomButton.ImagesChanged;
begin
  if FGlyph <> nil then
  begin
    TControl(FGlyph).BeginUpdate;
    try
      FGlyph.ImageIndex := FImageLink.ImageIndex;
      FGlyph.Images := FImageLink.Images;
    finally
      TControl(FGlyph).EndUpdate;
    end;
    if FIcon <> nil then
      FIcon.Visible := not TControl(FGlyph).Visible;
    if not TryAutoResize then
      Redraw;
  end;
end;

function TZxCustomButton.ImageIndexStored: Boolean;
begin
  Result := ActionClient or (ImageIndex <> -1);
end;

function TZxCustomButton.GetImageIndex: TImageIndex;
begin
  Result := FImageLink.ImageIndex;
end;

procedure TZxCustomButton.SetImageIndex(const Value: TImageIndex);
begin
  FImageLink.ImageIndex := Value;
end;

function TZxCustomButton.GetImages: TBaseImageList;
begin
  Result := FImageLink.Images;
end;

procedure TZxCustomButton.SetImages(const Value: TBaseImageList);
begin
  FImageLink.Images := Value;
end;

{ TZxButton }

procedure TZxButton.AfterDialogKey(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Default and (Key = vkReturn)) or (Cancel and (Key = vkEscape)) then
  begin
    Click;
    Key := 0;
  end;
end;

{ TZxSpeedButton }

constructor TZxSpeedButton.Create(AOwner: TComponent);
begin
  inherited;
  CanFocus := False;
  TMessageManager.DefaultManager.SubscribeToMessage(TSpeedButtonGroupMessage, GroupMessageCall);
end;

destructor TZxSpeedButton.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TSpeedButtonGroupMessage, GroupMessageCall);
  inherited;
end;

function TZxSpeedButton.GetGroupName: string;
begin
  Result := FGroupName;
end;

procedure TZxSpeedButton.GroupMessageCall(const Sender: TObject; const M: TMessage);
begin
  if (GroupName <> '') and SameText(TSpeedButtonGroupMessage(M).Value, GroupName) and (Sender <> Self) and (Scene <> nil) and
    (not(Sender is TControl) or ((Sender as TControl).Scene = Scene)) then
    IsPressed := False;
end;

procedure TZxSpeedButton.ActionChange(Sender: TBasicAction; CheckDefaults: Boolean);
begin
  inherited;
  if Sender is TCustomAction then
  begin
    if (not CheckDefaults) or (not GetIsChecked) then
      SetIsChecked(TCustomAction(Sender).Checked);
    if (not CheckDefaults) or (GroupName = '') or (GroupName = '0') then
      GroupName := IntToStr(TCustomAction(Sender).GroupIndex);
  end;
end;

function GroupNameIsSet(AGroupName: string): Boolean;
begin
  AGroupName := AGroupName.Trim;
  Result := (not AGroupName.IsEmpty) and (AGroupName <> '0') and (AGroupName <> '-1');
end;

function TZxSpeedButton.GroupNameStored: Boolean;
begin
  if ActionClient and (ActionLink <> nil) and (Action is TContainedAction) then
    Result := False
  else
    Result := GroupNameIsSet(FGroupName);
end;

procedure TZxSpeedButton.SetGroupName(const Value: string);
var
  I: Integer;
  S: string;
begin
  S := Value.Trim;
  if FGroupName <> S then
  begin
    I := 0;
    if S.IsEmpty or TryStrToInt(S, I) then
    begin
      FGroupName := S;
      if ActionClient and (ActionLink <> nil) and (Action is TContainedAction) then
        TContainedAction(Action).GroupIndex := I;
    end
    else
    begin
      if ActionClient and (ActionLink <> nil) and (Action is TContainedAction) then
        raise EComponentError.Create(SInvalidPropertyValue);
      FGroupName := Value;
    end;
    if ([csLoading, csDesigning] * ComponentState = [csDesigning]) and GroupNameIsSet(FGroupName) then
      StaysPressed := True;
  end;
end;

function TZxSpeedButton.GetIsChecked: Boolean;
begin
  Result := IsPressed;
end;

function TZxSpeedButton.IsCheckedStored: Boolean;
begin
  Result := IsPressedStored;
end;

function TZxSpeedButton.IsPressedStored: Boolean;
begin
  Result := not(ActionClient and (ActionLink <> nil) and ActionLink.CheckedLinked and (Action is TContainedAction));
end;

procedure TZxSpeedButton.RestoreButtonState;
begin
  if GroupName.IsEmpty or not StaysPressed then
    inherited;
end;

procedure TZxSpeedButton.SetIsChecked(const Value: Boolean);
begin
  IsPressed := Value;
end;

procedure TZxSpeedButton.SetIsPressed(const Value: Boolean);
var
  M: TSpeedButtonGroupMessage;
begin
  if FStaysPressed then
  begin
    if FIsPressed <> Value then
    begin
      if not IsPressedStored then
      begin
        FIsPressed := Value;
        TContainedAction(Action).Checked := FIsPressed;
      end
      else
      begin
        // allows check/uncheck in design-mode
        if (csDesigning in ComponentState) and FIsPressed then
          FIsPressed := Value
        else
        begin
          FIsPressed := Value;
          { all group uncheck }
          if Value then
          begin
            M := TSpeedButtonGroupMessage.Create(GroupName);
            TMessageManager.DefaultManager.SendMessage(Self, M, True);
          end;
        end;
      end;
      // visual feedback
      ApplyTriggers;
    end;
  end;
end;

procedure TZxSpeedButton.ToggleStaysPressed;
begin
  if GroupName <> '' then
    IsPressed := True
  else
    IsPressed := not FIsPressed;
end;

initialization

RegisterFmxClasses([TZxButton, TZxSpeedButton]);

end.
