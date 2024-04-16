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
unit Zx.Helpers;

interface

uses
  System.Classes,
  System.Types,
  System.Generics.Collections,
  FMX.Types,
{$IFDEF CompilerVersion < 36}
  Skia.FMX,
{$ELSE}
  FMX.Skia,
{$ENDIF}
  FMX.StdCtrls,
  FMX.Controls;

type
  TSkLabelHelper = class helper for TSkLabel
  public
{$IF CompilerVersion > 36}
{$MESSAGE WARN 'Check if issue was fixed'}
    { https://github.com/skia4delphi/skia4delphi/issues/250 }
{$ENDIF}
    function FitBounds: TRectF;
  end;

implementation

uses
{$IFDEF CompilerVersion < 36}
  Skia,
{$ELSE}
  System.Skia,
{$ENDIF}
  System.Math,
  FMX.Objects,
  FMX.Styles;

{ TSkLabelHelper }

function TSkLabelHelper.FitBounds: TRectF;
begin
  Result := ParagraphBounds;
end;

end.
