{
 * TCamera class for moving around maze
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

unit Camera;

interface

uses
  Windows,
  Math,
  Messages,
  dglOpenGL,
  Vector3D,
  Defines;

type
  TCamera = class
  public
    constructor Create();
    destructor Destroy();override;
    procedure LookAt(x,y,z:float);
    procedure Reset();
    procedure TurnUp(fps:float);
    procedure TurnDown(fps:float);
    procedure TurnLeft(fps:float);
    procedure TurnRight(fps:float);
    procedure ZoomIn(fps:float);
    procedure ZoomOut(fps:float);
  private
    m_vector:TVector3f;       // vektor aby jsme mohli prevest sfericke souradnice na kartezske (!!!momentalne zbytecne)
    m_zenith:float;          // zenith pro sfericke souradnice
    m_azimuth:float;         // azimuth pro sfericke souradnice
    m_r:float;               // vzdalenost mezi pocatkem souradnicovych os a bodem

    m_horz:float;            // horizontalni uhel pro rotaci
    m_vert:float;            // vertikalni uhel pro rotaci
    m_speed:float;           // rychlost rotaci
    m_zoomSpeed:float;       // rychlost zoomu
  end;

implementation

// konstruktor
constructor TCamera.Create();
begin
  m_vector := TVector3f.Create();      // vytvorime vektor
  // inicializace promenych pro zakladni pozici kamery
  m_r := 42.00;
  m_zenith := 0.588238;
  m_azimuth := -2.9694;                

  // inicializace promenych pro rotace
  m_horz := 0.0;
  m_vert := 0.0;
  m_speed := 1.0;
  m_zoomSpeed := 17.0;
end;

// destruktor
destructor TCamera.Destroy();
begin
  inherited Destroy();  // dedime(tj provede se to co v destruktoru tridy TObject)
  m_vector.Free();   // znicime vektor
end;

procedure TCamera.Reset();
begin
   // inicializace promenych pro zakladni pozici kamery
  m_r := 42.00;
  m_zenith := 0.588238;
  m_azimuth := -2.9694;                

  // inicializace promenych pro rotace
  m_horz := 0.0;
  m_vert := 0.0;
end;

procedure TCamera.LookAt(x,y,z:float);
begin
  m_vector.ToCartesian(m_r, m_zenith, m_azimuth);

  gluLookAt(m_vector.X+x, m_vector.Y+y, m_vector.Z, // pozice oci
    x, y, z,                         // pozice bodu na ktery se koukame
    0.0, 1.0, 0.0);                                        // up vektor

  glTranslatef(x, y, z);             // posun na bod kolem ktereho se chceme otacet
  glRotatef(RadToDeg(m_horz), 0.0, 1.0, 0.0);              // rotace o uhel horz kolem osy y
  glRotatef(RadToDeg(m_vert), 1.0, 0.0, 0.0);              // rotace o uhel vert kolem osy x
  glTranslatef(-x, -y, -z);       // posun z5
end;

procedure TCamera.TurnUp(fps:float);
begin
  m_vert := m_vert + m_speed/fps;
end;

procedure TCamera.TurnDown(fps:float);
begin
  m_vert := m_vert - m_speed/fps;
end;

procedure TCamera.TurnLeft(fps:float);
begin
  m_horz := m_horz + m_speed/fps;
end;

procedure TCamera.TurnRight(fps:float);
begin
  m_horz := m_horz - m_speed/fps;
end;

procedure TCamera.ZoomIn(fps:float);
begin
  if m_r > 15.0 then
  begin
    m_r := m_r - m_zoomSpeed/fps;
  end;
end;

procedure TCamera.ZoomOut(fps:float);
begin
  if m_r < 70.0 then
  begin
    m_r := m_r + m_zoomSpeed/fps;
  end;
end;

end.
