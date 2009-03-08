{
 * This form is used to display info about program
 * Copyright (C) 2008  Jan Dušek <GhostJO@seznam.cz>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}

unit AboutProgram;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls;

type
  TAppVersion = record
    MajorVersion:Word;
    MinorVersion:Word;
    Release:Word;
    Build:Word;
  end;

  TAboutBox1 = class(TForm)
    Panel1: TPanel;
    ProgramIcon: TImage;
    ProductName: TLabel;
    Version: TLabel;
    Copyright: TLabel;
    Comments: TLabel;
    OKButton: TButton;
    procedure OKButtonClick(Sender: TObject);
  private
    function GetAppVersion(out AppVersion:TAppVersion):boolean;
  public
    constructor Create(AOwner:TComponent);override;
  end;

var
  AboutBox1: TAboutBox1;

implementation

{$R *.dfm}

constructor TAboutBox1.Create(AOwner:TComponent);
var
  AppVersion:TAppVersion;
begin
  inherited Create(AOwner);
  GetAppVersion(AppVersion);

  Version.Caption := Version.Caption + '    ' + Format('%u.%u.%u (Build %u)', [AppVersion.MajorVersion, AppVersion.MinorVersion, AppVersion.Release, AppVersion.Build]);
end;

procedure TAboutBox1.OKButtonClick(Sender: TObject);
begin
  self.Close();
end;

function TAboutBox1.GetAppVersion(out AppVersion:TAppVersion):boolean;
var
  dwHandle, dwLen:DWORD;       // dwHandle obdzi 0 a je ingnorovano
  BufLen:UINT;
  pFileInfo:^VS_FIXEDFILEINFO;
  lpData:LPTSTR;
begin
  // ziska velikost informace o verzi souboru
  dwLen := GetFileVersionInfoSize(PAnsiChar(Application.ExeName), dwHandle);
  if dwLen = 0 then                     // pokud je 0 nelze info ziskat
  begin
    result := false;                    // vrati false
    exit;
  end;

  GetMem(lpData, dwLen);                // alokujeme data
  if lpData = nil then                  // kdyz se alokace nepodarila
  begin
    result := false;                    // vratime false
    exit;
  end;

  // do lpData ziskame informace o verzi souboru
  if not GetFileVersionInfo(PAnsiChar(Application.ExeName), dwHandle, dwLen, lpData) then
  begin                                 // kdyz se je nepodarilo ziskat
    FreeMem(lpData, dwLen);             // uvolnime pamet
    result := false;                    // vratime false
    exit;
  end;

  // tato fce udela z lpData samotne VS_FIXEDFILEINFO
  if VerQueryValue(lpData, '\\', pointer(pFileInfo), BufLen) then
  begin
    // ziskame samotnou verzi programu (c++: (*pFileInfo).neco || pFileInfo->neco)
    AppVersion.MajorVersion := HIWORD(pFileInfo^.dwFileVersionMS);
    AppVersion.MinorVersion := LOWORD(pFIleInfo^.dwFileVersionMS);
    AppVersion.Release := HIWORD(pFileInfo^.dwFileVersionLS);
    AppVersion.Build := LOWORD(pFileInfo^.dwFileVersionLS);
    FreeMem(lpData, dwLen);                  // uvolnime pamet
    result := true;                          // vratime true
    exit;
  end;

  FreeMem(lpData, dwLen);                   // uvolnime pamet
  result := false;                          // vratime false
end;

end.
 
