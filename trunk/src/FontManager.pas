{
 * TFontManager singleton class to manage all fonts used in this game(prevents wasting cpu time on building more than once one font)
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

unit FontManager;

interface

uses
  Windows,
  Messages,
  dglOpenGL,
  defines,
  Classes,
  Font;

type
  TFontClass = class of TFont;         // class reference tj. promena typu TFontClass ponese nejakou tridu(NE JEJI INSTANCI!!!!) zdedenou od TFont

  TFontManager = class
  public
    destructor Destroy();override;     // destructor
    class function GetInstance():TFontManager;    // class fce pro singleton(vrati instanci teto tridy)
    procedure RebuildFonts(hDC:HDC);             // vytvori fonty ve fontmanageru
    function GetFont(FontClass:TFontClass; fontName:string; fontHeight, fontWeight:int32):TFont;     // ziska ci vytvori novy font dle zadanych parametru
  protected
    constructor Create();     // konstuktor protected -> jen tak nejde vytvorit instance teto tridy
  private
    m_Fonts:TList;            // TList(c++: std::vector<void*> ze STL)
    m_hDC:HDC;                // handle device kontextu
  end;

var
  // jelikoz delphi nema (c++: static data tedy napr private: static TFontManager* instance; ) tak musime pouzit unit-level promenou :(((
  u_FontManager:TFontManager;
implementation

constructor TFontManager.Create();
begin
  m_Fonts := TList.Create();        // vytvari instanci tridy TList
  m_hDC := 0;
end;

destructor TFontManager.Destroy();
var
  i:int8;
begin
  inherited Destroy();
  m_Fonts.Pack();                  // vyhodime z listu vsechny nil pointery
  for i := 0 to m_Fonts.Count - 1 do          // prochazime jednotlive fonty v listu
  begin
    TFont(m_Fonts[i]).Free();       // uvolnime font
  end;
  m_Fonts.Free();                   // uvolnime samotny list
end;

class function TFontManager.GetInstance():TFontManager;
begin
  if u_FontManager = nil then           // kdyz je unit-level promena nil
  begin
    u_FontManager := TFontManager.Create();     // vytvorime instanci fontmanageru
    result := u_FontManager;                    // vratime ho
    exit;
  end
  else                           // kdyz uz tedy fontmanager mame
  begin
    result := u_FontManager;     // tak ho vratime 
    exit;
  end;
end;

procedure TFontManager.RebuildFonts(hDC:HDC);
var
  i:int8;
begin
  m_hDC := hDC;
  for i := 0 to m_Fonts.Count -1 do     // prochazime fonty
  begin
    if not glIsList(TFont(m_Fonts[i]).DisplayListBase) then   // kdyz neexistuji display listu daneho fontu
      TFont(m_Fonts[i]).Build(m_hDC);          // tak je vytvorime
  end;
end;

function TFontManager.GetFont(FontClass:TFontClass; fontName:string; fontHeight, fontWeight:int32):TFont;
var
  NewFontPos:int32;
  i:int8;
begin
  for i := 0 to m_Fonts.Count -1 do           // prochazime stavajici fonty aby jsme zjistili zda uz tento font nemame vytvoreny
  begin
    // kdyz je nejaky stejny
    if (TFont(m_Fonts[i]).FontName = fontName) and (TFont(m_Fonts[i]).FontHeight = fontHeight)
      and (TFont(m_Fonts[i]).FontWeight = fontWeight) and (TFont(m_Fonts[i]) is FontClass) then
    begin
      result := TFont(m_Fonts[i]);       // tak ho vratime 
      exit;                              // konec
    end;
  end;
  // kdyz ho jeste nemame vytvoreny tak ho vytvorime a pridame to listu
  NewFontPos := m_Fonts.Add(FontClass.Create(fontName, fontHeight, fontWeight));

  if m_hDC <> 0 then
  begin
    if not glIsList(TFont(m_Fonts[NewFontPos]).DisplayListBase) then   // kdyz neexistuji display listu daneho fontu
      TFont(m_Fonts[NewFontPos]).Build(m_hDC);          // tak je vytvorime
  end;

  result := m_Fonts[NewFontPos];     // vratime vytvoreny font
end;

end.
