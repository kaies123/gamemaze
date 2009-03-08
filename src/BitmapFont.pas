{
 * TBitmapFont class used to draw 2d text
 *
 * Based on NeheGL tutorials lesson 13 by Jeff Molofee - NeHe
 *
 *   ported from c++ to Delphi by: Jan Du�ek
 *
 * Copyright (C) 2008  Jan Du�ek <GhostJO@seznam.cz>
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

unit BitmapFont;

interface

uses
  Windows,
  Messages,
  defines,
  dglOpenGL,
  Font;

type
  TBitmapFont = class(TFont)
  public
    constructor Create(fontName:string; fontHeight, fontWeight:int32);override;
    destructor Destroy();override;
    procedure Build(hDC:HDC);override;
    procedure Print(x,y,z:float; text:string);overload;override;
    procedure Print(text:string);overload;override;
  end;

implementation

constructor TBitmapFont.Create(fontName:string; fontHeight, fontWeight:int32);
begin
  inherited Create(fontName, fontHeight, fontWeight);
end;

destructor TBitmapFont.Destroy();
begin
  inherited Destroy();
end;

procedure TBitmapFont.Build(hDC:HDC);
var
  font:HFONT;
begin
  m_base := glGenLists(256);             // generujeme 256 display listu

  font := CreateFont(FontHeight,// V��ka
    0,// ���ka
    0,// �hel escapement
    0,// �hel orientace
    FontWeight,// Tu�nost   // FW_BOLD atp.
    0,// Kurz�va
    0,// Podtr�en�
    0,// P�e�krtnut�
    ANSI_CHARSET,// Znakov� sada
    OUT_TT_PRECIS,// P�esnost v�stupu (TrueType)
    CLIP_DEFAULT_PRECIS,// P�esnost o�ez�n�
    ANTIALIASED_QUALITY,// V�stupn� kvalita
    FF_DONTCARE or DEFAULT_PITCH,// Rodina a pitch
    PChar(FontName));// Jm�no fontu

  SelectObject(hDC, font);          // vybereme font do DC

  wglUseFontBitmaps(hDC, 0, 255, m_base);    // tato fce vytvori z fontu v dc display listy obsahujici jednotliva pismena jako bitmapy
end;

procedure TBitmapFont.Print(x,y,z:float; text:string);
begin
  glTranslatef(0.0, 0.0, z);                   // translace
  glRasterPos2f(x, y);                         // nastavime pozici bitmap

  glPushAttrib(GL_LIST_BIT);// Ulo�� sou�asn� stav display list�
  glListBase(m_base);// Nastav� prvn� display list na base

  glCallLists(System.Length(text), GL_UNSIGNED_BYTE, PChar(text));// Vykresl� display listy
  glPopAttrib();// Obnov� p�vodn� stav display list�

  glTranslatef(0.0, 0.0, -z);                  // translace z5
end;

procedure TBitmapFont.Print(text:string);
begin
  glPushAttrib(GL_LIST_BIT);// Ulo�� sou�asn� stav display list�
  glListBase(m_base);// Nastav� prvn� display list na base

  glCallLists(System.Length(text), GL_UNSIGNED_BYTE, PChar(text));// Vykresl� display listy
  glPopAttrib();// Obnov� p�vodn� stav display list�
end;

end.
