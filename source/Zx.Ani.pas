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
unit Zx.Ani;

interface

uses
  System.Classes,
  System.UITypes,
  FMX.Ani;

const
  CZxAnimationLowestDuration = 0.0001;

type
  TZxAnimationProcessEvent<T> = procedure(Sender: TObject; const AValue: T) of object;

{$IF CompilerVersion > 36}
{$MESSAGE WARN 'Check changes in FMX.Ani TAnimation implementation'}
{$ENDIF}

  TZxAnimation = class(TAnimation)
  strict private
    { FirstFrame is not called if animation executes immediately }
    FManualFirstFrame: Boolean;
    FOnFirstFrame: TNotifyEvent;
  protected
    procedure FirstFrame; override;
    procedure ProcessAnimation; override;
  public
    procedure Start; override;
    property OnFirstFrame: TNotifyEvent read FOnFirstFrame write FOnFirstFrame;
  end;

  TZxAnimation<T> = class(TZxAnimation)
  strict private
    FStartValue: T;
    FStopValue: T;
    FOnProcessValue: TZxAnimationProcessEvent<T>;
  protected
    function InterpolateValue: T; virtual; abstract;
  protected
    procedure ProcessAnimation; override;
  public
    property OnProcessValue: TZxAnimationProcessEvent<T> read FOnProcessValue write FOnProcessValue;
  published
    property StartValue: T read FStartValue write FStartValue stored True nodefault;
    property StopValue: T read FStopValue write FStopValue stored True nodefault;
  end;

  TZxColorAnimation = class(TZxAnimation<TAlphaColor>)
  protected
    function InterpolateValue: TAlphaColor; override;
  end;

implementation

uses
  FMX.Utils,
  FMX.Types;

{ TZxAnimation }

procedure TZxAnimation.Start;
begin
  if (Abs(Duration) < 0.001) or (Root = nil) or (csDesigning in ComponentState) then
    FManualFirstFrame := True;
  inherited;
  FManualFirstFrame := False;
end;

procedure TZxAnimation.FirstFrame;
begin
  inherited;
  if Assigned(FOnFirstFrame) then
    FOnFirstFrame(Self);
end;

procedure TZxAnimation.ProcessAnimation;
begin
  if FManualFirstFrame then
    FirstFrame;
end;

{ TZxAnimation<T> }

procedure TZxAnimation<T>.ProcessAnimation;
begin
  if Assigned(FOnProcessValue) then
    FOnProcessValue(Self, InterpolateValue);
end;

{ TZxColorAnimation }

function TZxColorAnimation.InterpolateValue: TAlphaColor;
begin
  Result := InterpolateColor(StartValue, StopValue, NormalizedTime);
end;

initialization

RegisterFmxClasses([TZxColorAnimation]);

end.
