{
 * TMenu base abstract class for menus
 * Copyright (C) 2009  Jan Dušek <GhostJO@seznam.cz>
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

unit Menu;

interface

uses
  windows,
  messages,
  SceneManager,
  defines,
  Keys,
  TextControls,
  Classes;

type
  TMenu = class(TScene)
  public
    destructor Destroy();override;
  protected
    m_SelectedItem:TText3dControl;            // pointer na vybranou bunku
    m_iSelectedItem:int32;                    // index vybrane bunky

    m_MenuItems:TList;                         // neco jako (c++: std::vector<void*> ze STL) obsahuje pointery na instance objeku

    constructor Create();override;

    procedure GoUp();                          // posune se menem naharu
    procedure GoDown();                        // posune se menem dolu
  end;

implementation

constructor TMenu.Create();
begin
  inherited Create();

  m_MenuItems := TList.Create();

  m_iSelectedItem := -1;
  m_SelectedItem := nil;
end;


destructor TMenu.Destroy();
begin
  inherited Destroy();

  m_MenuItems.Free();
end;

procedure TMenu.GoUp();
begin
  if (m_iSelectedItem-1) >= 0 then                 // kdyz se neposuneme mimo
  begin
    dec(m_iSelectedItem);                          // zmensime index o 1
  end
  else
  begin
    m_iSelectedItem := m_MenuItems.Count -1;
  end;

  m_SelectedItem.Position.Z := -10.0;           // vybrane bunce nastavime z-souradnici jak byla

  m_SelectedItem := m_MenuItems.Items[m_iSelectedItem];    // nastavime vybranou bunku
end;

procedure TMenu.GoDown();
begin
  if (m_iSelectedItem +1) < m_MenuItems.Count then         // kdyz se neposuneme mimo
  begin
    inc(m_iSelectedItem);                                  // zmensime index o 1
  end
  else
  begin
    m_iSelectedItem := 0;
  end;

  m_SelectedItem.Position.Z := -10.0;                   // vybrane bunce nastavime z-souradnici jak byla

  m_SelectedItem := m_MenuItems.Items[m_iSelectedItem];    // nastavime vybranou bunku
end;

end.
