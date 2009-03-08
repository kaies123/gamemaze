{
 * cos only form without any components can have proper rendering context this clear form is
 *  used to get informations about openGL through glGetString() function
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

unit ChildForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, dglOpenGL;

type
  TForm1 = class(TForm)
  private
    m_hDC:HDC;
    m_hRC:HGLRC;
    m_hWnd:HWND;

    m_Renderer:string;
    m_Version:string;
    m_Vendor:string;
    m_Extensions:string;
  public
    constructor Create(AOwner:TComponent);override;
    destructor Destroy();override;
    function GetOpenGLRenderer():string;
    function GetOpenGLVersion():string;
    function GetOpenGLVendor():string;
    function GetOpenGLExtensions():string;
  end;

var
  Form1: TForm1;

implementation

uses MainForm;

{$R *.dfm}

constructor TForm1.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  // vytvorime ogl kontext
  m_hWnd := self.Handle;   // ulozime si handle okna
  m_hDC := GetDC(m_hWnd);  // ziskame device kontext okna
  m_hRC := CreateRenderingContext(m_hDC, [opDoubleBuffered, opStereo], 32, 24, 0, 0, 0, 0);  // vytvorime ogl rendering kontext
  ActivateRenderingContext(m_hDC, m_hRC); // zaktivujeme ho

  // ziskame info o ogl a ulozime do promenych
  m_Renderer := glGetString(GL_RENDERER);
  m_Version := glGetString(GL_VERSION);
  m_Vendor := glGetString(GL_VENDOR);
  m_Extensions := glGetString(GL_EXTENSIONS);
end;

destructor TForm1.Destroy();
begin
  inherited Destroy();
  DeactivateRenderingContext;    
  wglDeleteContext(m_hRC);
  ReleaseDC(m_hWnd, m_hDC);
end;

function TForm1.GetOpenGLRenderer():string;
begin
  result := m_Renderer;
end;

function TForm1.GetOpenGLVersion():string;
begin
  result := m_Version;
end;

function TForm1.GetOpenGLVendor():string;
begin
  result := m_Vendor;
end;

function TForm1.GetOpenGLExtensions():string;
begin
  result := m_Extensions;
end;

end.
