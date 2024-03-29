{
 * TKeys class which handles keystates
 *
 *  based on
 *     Object Orientated NeHeGL Using Base Class
 *     Author: Andreas Oberdorfer           2004
 *
 *     ported from c++ to Delphi by: Jan Du�ek
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

unit Keys;

interface

uses
  Windows,
  Messages,
  Defines;

type

TKeys = class
  public
    constructor Init();                  // konstruktor
    procedure Clear();                   // resetuje nastaveni pole(vsechno false)
    function IsPressed(Key:Word):boolean;// zda je stisknuta klavesa
    function IsPressedOnce(Key:Word):boolean;// zda je stisknuta nevyhodi true opakovane pro stisknuti jedne klavesy tj. kdyz uzivatel stiskne na klavesu tak tato fce vyhodi true pouze 1x
    procedure SetPressed(Key:Word);      // nastavi urcitou klavesu na stisknutou
    procedure SetReleased(Key:Word);     // klavesa byla pustena
  private
    m_KeyDown : boolKeyArray;
  end;

implementation

constructor TKeys.Init();
begin
  Clear();
end;

procedure TKeys.Clear();
var
  i:integer;
begin
  for i:=0 to 255 do                    // prochazi klavesy
  begin
    m_KeyDown[i] := false;              // nastavi ji na nestisknutou
  end;
  //ZeroMemory(@m_KeyDown, sizeof(m_KeyDown));
end;

function TKeys.IsPressed(Key:Word):boolean;
begin
  if Key < 256 then                      // ujisti se ze jsme nepredali klavesu ktera neexistuje :)
  begin
    if m_KeyDown[Key] = true then
    begin
      result := true;
      exit;
    end
    else
    begin
      result := false;
      exit;
    end;
  end
  else
    result:= false;
end;

function TKeys.IsPressedOnce(Key:Word):boolean;
begin
  if Key < 256 then                      // ujisti se ze jsme nepredali klavesu ktera neexistuje :)
  begin
    if m_KeyDown[Key] = true then        // kdyz je stisknuta
    begin
      self.SetReleased(Key);             // nastavime ji na nestisknutou
      result := true;
      exit;
    end
    else
    begin
      result := false;
      exit;
    end;
  end
  else
    result:= false;
end;

procedure TKeys.SetPressed(Key:Word);
begin
  if Key < 256 then
    m_KeyDown[Key] := true;
end;

procedure TKeys.SetReleased(Key:Word);
begin
  if Key < 256 then
    m_KeyDown[Key] := false;
end;

end.
