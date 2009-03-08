{
 * Base abstract class for fonts
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

unit Font;

interface

uses
  Windows,
  Messages,
  defines,
  dglOpenGL;

type
  TFont = class
  private
    m_fontName:string;
    m_fontHeight:int32;
    m_fontWeight:int32;
  protected
    m_base:GLuint;                                // ukazatel na prvni display list
  public
    constructor Create(fontName:string; fontHeight, fontWeight:int32);virtual;
    destructor Destroy();override;
    procedure Build(hDC:HDC);virtual;abstract;
    procedure Print(text:string);overload;virtual;abstract;
    procedure Print(x,y,z:float; text:string);overload;virtual;abstract;

    property FontName:string read m_fontName;
    property FontHeight:int32 read m_fontHeight;
    property FontWeight:int32 read m_fontWeight;
    property DisplayListBase:GLuint read m_base;
  end;

implementation

constructor TFont.Create(fontName:string; fontHeight, fontWeight:int32);
begin
  m_base := 0;
  m_fontName := fontName;
  m_fontHeight := fontHeight;
  m_fontWeight := fontWeight;
end;

destructor TFont.Destroy();
begin
  inherited Destroy();
  glDeleteLists(m_base, 256);         // znicime display listy
end;

end.
