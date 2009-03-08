{
 * TOutLineFont class used to draw 3d text with depth
 *
 * Based on NeheGL tutorials lesson 14 by Jeff Molofee - NeHe
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

unit OutLineFont;

interface

uses
  Windows,
  Messages,
  defines,
  dglOpenGL,
  Font;

type
  TOutLineFont = class(TFont)
  public
    constructor Create(fontName:string; fontHeight, fontWeight:int32);override;
    destructor Destroy();override;
    procedure Build(hDC:HDC);override;
    procedure Print(text:string);overload;override;
    procedure Print(x,y,z:float; text:string);overload;override;
  private
    m_gmf:array[0..255] of GLYPHMETRICSFLOAT;
    m_hDC:HDC;
  end;

implementation

constructor TOutLineFont.Create(fontName:string; fontHeight, fontWeight:int32);
begin
  inherited Create(fontName, fontHeight, fontWeight);
  m_hDC := 0;
end;

destructor TOutLineFont.Destroy();
begin
  inherited Destroy();
end;

procedure TOutLineFont.Build(hDC:HDC);
var
  font:HFONT;
begin
  m_hDC := hDC;

  m_base := glGenLists(256);       // vygenerujeme si 256 display listu a ukazatel na ne si dame do base

  // vytvorime font
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

  SelectObject(m_hDC, font);            // vybereme font do Device kontextu

  // vytvorime samotny outline font a info si ulozime do gmf
  wglUseFontOutLines(m_hDC,// DC
    0,// Po��te�n� znak
    255,// Koncov� znak
    m_base,// Adresa prvn�ho znaku
    0.0,// Hranatost
    0.2,// Hloubka v ose z
    WGL_FONT_POLYGONS,// Polygony ne dr�t�n� model
    @m_gmf);// Adresa bufferu pro ulo�en� informac�.
end;

procedure TOutLineFont.Print(x,y,z:float; text:string);
var
  length:float;                // D�lka znaku
  i:int32;
begin
  glTranslatef(x, y, z);

  length := 0;

  // aby nebyli znaky na sobe tak si je posuneme
  i:=0;                         // nastaveni ridici promene cyklu
  while i < System.Length(text) do     // kdyz i je mensi jak delka textu
  begin
    length := length + m_gmf[ord(text[i])].gmfCellIncX;
    inc(i);
  end;

  glTranslatef(-length/2, 0.0, 0.0);// Zarovn�n� na st�ed

  glPushAttrib(GL_LIST_BIT);// Ulo�� sou�asn� stav display list�
  glListBase(m_base);// Nastav� prvn� display list na base

  glCallLists(System.Length(text), GL_UNSIGNED_BYTE, PChar(text));// Vykresl� display listy
  glPopAttrib();// Obnov� p�vodn� stav display list�

  glTranslatef(-x, -y, -z);
end;

procedure TOutLineFont.Print(text:string);
var
  length:float;                // D�lka znaku
  i:int32;
begin
  length := 0;

  // aby nebyli znaky na sobe tak si je posuneme
  i:=0;                         // nastaveni ridici promene cyklu
  while i < System.Length(text) do     // kdyz i je mensi jak delka textu
  begin
    length := length + m_gmf[ord(text[i])].gmfCellIncX;
    inc(i);
  end;

  glTranslatef(-length/2, 0.0, 0.0);// Zarovn�n� na st�ed

  glPushAttrib(GL_LIST_BIT);// Ulo�� sou�asn� stav display list�
  glListBase(m_base);// Nastav� prvn� display list na base

  glCallLists(System.Length(text), GL_UNSIGNED_BYTE, PChar(text));// Vykresl� display listy
  glPopAttrib();// Obnov� p�vodn� stav display list�
end;

end.
