{
 * VCL dialog used to display info about openGL
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


unit AboutGraficCard;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, jpeg, ChildForm, StrUtils;

type
  TAboutBox = class(TForm)
    Panel1: TPanel;
    OKButton: TButton;
    RendererLabel: TLabel;
    VersionLabel: TLabel;
    VendorLabel: TLabel;
    Renderer: TLabel;
    Vendor: TLabel;
    Version: TLabel;
    ExtensionsLabel: TLabel;
    Extensions: TListBox;
  private
    { Private declarations }
  public
    constructor Create(AOwner:TComponent);override;
  end;

var
  AboutBox: TAboutBox;

implementation

{$R *.dfm}

constructor TAboutBox.Create(AOwner:TComponent);
var
  ext,temp:string;
  iSpace:integer;   // index mezery
begin
  inherited Create(AOwner);
  Renderer.Caption := Form1.GetOpenGLRenderer();
  Vendor.Caption := Form1.GetOpenGLVendor();
  Version.Caption := Form1.GetOpenGLVersion();

  ext := Form1.GetOpenGLExtensions();   // ziskame extensiony rozdelene mezi sebou mezerou
  ext := ext + ' ';                     // nakonec pridame mezeru

  iSpace := Pos(' ', ext);              // zjistime index mezery
  while iSpace <> 0 do                  // kdyz mame este mezeru
  begin
    temp := Copy(ext, 1, iSpace - 1);   // do pomocneho stringu si zkopirujeme jednu extenzi(bez mezery na konci)
    Delete(ext, 1, iSpace);             // vymazeme ze stringu extenzi zkopirovanou extenzi
    if temp = '' then                   // pokud jsme si zkopirovali jen mezeru
      break;                            // tak preskocime
    Extensions.Items.Append(temp);      // do listboxu pridame extenzi z pomocneho stringu
    iSpace := Pos(' ', ext);            // opet hledame mezeru
  end;
end;

end.
 
