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
unit Zx.Controls;

interface

{$I Zx.SkiaComponents.inc}

uses
  System.Types,
{$IFDEF CompilerVersion < 36}
  Skia.FMX
{$ELSE}
  FMX.Skia
{$ENDIF}
    ;

type
  TZxCustomControl = class(TSkCustomControl)
  strict private
{$IFDEF ZX_FIXMOBILECLICK}
    FManualClick: Boolean;
{$ENDIF}
  protected
    procedure DoClick; virtual;
    procedure DoTap(const Point: TPointF); virtual;
  protected
    procedure Click; override; final;
    procedure Tap(const Point: TPointF); override; final;
  end;

  TZxStyledControl = class(TSkStyledControl)
  strict private
{$IFDEF ZX_FIXMOBILECLICK}
    FManualClick: Boolean;
{$ENDIF}
  protected
    procedure DoClick; virtual;
    procedure DoTap(const Point: TPointF); virtual;
  protected
    procedure Click; override; final;
    procedure Tap(const Point: TPointF); override; final;
  end;

implementation

{ TZxCustomControl }

procedure TZxCustomControl.Click;
begin
{$IFDEF ZX_FIXMOBILECLICK}
  if FManualClick then
{$ENDIF}
    inherited;
  DoClick;
end;

procedure TZxCustomControl.Tap(const Point: TPointF);
begin
{$IFDEF ZX_FIXMOBILECLICK}
  FManualClick := True;
  Click;
  FManualClick := False;
{$ENDIF}
  inherited;
  DoTap(Point);
end;

procedure TZxCustomControl.DoClick;
begin

end;

procedure TZxCustomControl.DoTap(const Point: TPointF);
begin

end;

{ TZxStyledControl }

procedure TZxStyledControl.Click;
begin
{$IFDEF ZX_FIXMOBILECLICK}
  if FManualClick then
{$ENDIF}
    inherited;
  DoClick;
end;

procedure TZxStyledControl.Tap(const Point: TPointF);
begin
{$IFDEF ZX_FIXMOBILECLICK}
  FManualClick := True;
  Click;
  FManualClick := False;
{$ENDIF}
  inherited;
  DoTap(Point);
end;

procedure TZxStyledControl.DoClick;
begin

end;

procedure TZxStyledControl.DoTap(const Point: TPointF);
begin

end;

end.
