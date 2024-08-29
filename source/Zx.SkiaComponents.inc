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
{$IF Defined(MSWINDOWS) OR Defined(OSX) OR Defined(LINUX)}
  {$DEFINE DESKTOPPLATFORM}
{$ENDIF}

{$IF Defined(ANDROID) OR Defined(IOS)}
  {$DEFINE MOBILEPLATFORM}
{$ENDIF}

{$IFNDEF MOBILEPLATFORM}
  {$UNDEF ZX_FIXMOBILECLICK}
{$ENDIF}