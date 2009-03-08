{
 * TPlayer class for moveable player in Maze
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

unit Player;

interface

uses
  Windows,
  Messages,
  Defines,
  Math,
  SysUtils,
  dglOpenGL;

type
  TPlayer = class
  public
    constructor Create(Cells:PCells; numCells:Puint32);
    destructor Destroy();override;
    procedure Draw();
    procedure SetPosition(IndexOfCell:uint32);
    function GetPosition():uint32;
    procedure Initialize();
    function GoUp(fps:float):boolean;
    function GoDown(fps:float):boolean;
    function GoLeft(fps:float):boolean;
    function GoRight(fps:float):boolean;
    function GetPosX():float;
    function GetPosY():float;
  private
    m_pCells:PCells;                                      // ukazatel na bunky bludiste btw PCells v defines
    m_pNumOfCells:Puint32;                                // ukazatel na pocet bunek btw PInt v defines
    m_PlayerQuadric:PGLUquadric;                         // ukazatel na quadric
    m_numOfCellsInRow, m_numOfCellsInCollumn:uint32;     // pocet bunek v radku a ve sloupci
    m_speed:float;                                       // urcuje rychlost pohybu
    m_PosX:float;                                        // pozice na ose X
    m_PosY:float;                                        // pozice na ose Y
    m_CheckPointX:float;                                 // checkpoint na ose X
    m_CheckPointY:float;                                 // checkpoint na ose Y
    m_fps:float;                                         // fps
    m_iCurrentCell:uint32;                               // index bunky na ktere se hrac nachazi
  end;
    
implementation

constructor TPlayer.Create(Cells:PCells; numCells:Puint32);
begin
  // nastaveni promenych
  m_speed := 8.0;
  m_PosX := 0.0;
  m_PosY := 0.0;
  m_CheckPointX := 0.0;
  m_CheckPointY := 0.0;
  m_fps := 0.0;
  m_pCells := Cells;
  m_pNumOfCells := numCells;
end;

destructor TPlayer.Destroy();
begin
  inherited Destroy();
end;

procedure TPlayer.SetPosition(IndexOfCell:uint32);
var
  temp:string;
  temp2:extended;
begin
  m_iCurrentCell := IndexOfCell;

  // pri pokus o (function-style cast) kompilator ohlasil chybu invalid typecast takze jsem to takhle
  // nechutne obesel fuj! :((((
  temp := IntToStr(m_pNumOfCells^);
  temp2 := StrToFloat(temp);
  // jen pokud je to bludiste ctvercove
  m_numOfCellsInRow := round(sqrt(temp2));
  m_numOfCellsInCollumn := round(sqrt(temp2));

  // m_pCells je pointer tedy musime dereferencovat operatorem ^ (ekvivalent v c++ * ale jelikoz v c++ ukazatel a pole jsou zamenitelne nebylo by treba toto v c++ uzivat xD )
  m_PosX := m_pCells^[m_iCurrentCell].Walls[0].Position.x;
  m_PosY := m_pCells^[m_iCurrentCell].Walls[1].Position.y;

  m_CheckPointX := m_PosX;
  m_CheckPointY := m_PosY;
end;

function TPlayer.GetPosition():uint32;
begin
  result := m_iCurrentCell;
end;

function TPlayer.GetPosX():float;
begin
  result := m_PosX;
end;

function TPlayer.GetPosY():float;
begin
  result := m_PosY;
end;

procedure TPlayer.Draw();
begin
  if m_CheckPointX > m_PosX then                // kdyz je chceckpointX vetsi nez PosX
    m_PosX := m_PosX + m_speed/m_fps            // zvetsime PosX
  else if m_CheckPointX < m_PosX then           // kdyz je checkpointX mensi nez PosX
    m_PosX := m_PosX - m_speed/m_fps;           // zmensime PosX

  if m_CheckPointY > m_PosY then                // analogie s predchozim akorat s Y sour.
    m_PosY := m_PosY + m_speed/m_fps
  else if m_CheckPointY < m_PosY then
    m_PosY := m_PosY - m_speed/m_fps;

  // diky deleni poctem fps je miziva pravdepodobnost ze by se nekdy
  // konecne checkpoint rovnal pos takze kdyz jsou dostatecne blizko u sebe tak se srovnaji
  if Abs(m_CheckPointX - m_PosX) < (m_speed/m_fps) then
    m_PosX := m_CheckPointX;
  if Abs(m_CheckPointY - m_PosY) < (m_speed/m_fps) then
    m_PosY := m_CheckPointY;

  glTranslatef(m_PosX, m_PosY, 0.22);            // pohyb

  glColor3f(1,1,0);                              // zluta barva
  gluSphere(m_PlayerQuadric, 0.22, 32, 32);      // vykreslime kouli
end;

procedure TPlayer.Initialize();
begin
  m_PlayerQuadric := gluNewQuadric();
  gluQuadricNormals(m_PlayerQuadric, GLU_SMOOTH);
  gluQuadricTexture(m_PlayerQuadric, true);
end;

function TPlayer.GoUp(fps:float):boolean;
begin
  m_fps := fps;                                  // nastaveni clenske promene
  result := false;                               // vyhodi false

  if m_pCells^[m_iCurrentCell].Walls[0].Visible then    // kdyz je ve smeru pohybu stena
  begin
    exit;                                               // konec
  end;

  if (m_iCurrentCell div m_numOfCellsInCollumn) = m_numOfCellsInCollumn-1 then     // kdyz je tato bunka nahore u kraje a neni tam stena(z predchoziho ifu)
  begin
    // player have won
    result := true;                                                       // vyhodime true
    exit;                                                                 // konec
  end;

  if (m_CheckPointX = m_PosX) and (m_CheckPointY = m_PosY) then           // kdyz checkpoint == pos
  begin
    m_iCurrentCell := m_iCurrentCell + m_numOfCellsInRow;                 // posun nahoru tedy do indexu soucasne bunky se pricte pocet bunek v radku -> bunka o radek vyse
    // vypocet checkpointu
    m_CheckPointX := m_pCells^[m_iCurrentCell].Walls[0].Position.x;
    m_CheckPointY := m_pCells^[m_iCurrentCell].Walls[1].Position.y;
  end;
end;

function TPlayer.GoDown(fps:float):boolean;
var
  temp:int32;
begin
  m_fps := fps;
  result := false;

  if m_pCells^[m_iCurrentCell].Walls[2].Visible then
  begin
    exit;
  end;

  temp := m_iCurrentCell - m_numOfCellsInRow;
  if temp < 0 then
  begin
    // player have won
    result := true;
    exit;
  end;
  
  if (m_CheckPointX = m_PosX) and (m_CheckPointY = m_PosY) then
  begin
    m_iCurrentCell := m_iCurrentCell - m_numOfCellsInRow;
    m_CheckPointX := m_pCells^[m_iCurrentCell].Walls[0].Position.x;
    m_CheckPointY := m_pCells^[m_iCurrentCell].Walls[1].Position.y;
  end;
end;

function TPlayer.GoLeft(fps:float):boolean;
begin
  m_fps := fps;
  result := false;

  if m_pCells^[m_iCurrentCell].Walls[3].Visible then
  begin
    exit;
  end;

  if (m_iCurrentCell mod m_numOfCellsInRow) = 0 then
  begin
    // player have won
    result := true;
    exit;
  end;

  if (m_CheckPointX = m_PosX) and (m_CheckPointY = m_PosY) then
  begin
    dec(m_iCurrentCell);
    m_CheckPointX := m_pCells^[m_iCurrentCell].Walls[0].Position.x;
    m_CheckPointY := m_pCells^[m_iCurrentCell].Walls[1].Position.y;
  end;
end;

function TPlayer.GoRight(fps:float):boolean;
begin
  m_fps := fps;
  result := false;

  if m_pCells^[m_iCurrentCell].Walls[1].Visible then
  begin
    exit;
  end;

  if (m_iCurrentCell mod m_numOfCellsInRow) = m_numOfCellsInRow-1 then
  begin
    // player have won
    result := true;
    exit;
  end;
  
  if (m_CheckPointX = m_PosX) and (m_CheckPointY = m_PosY) then
  begin
    inc(m_iCurrentCell);
    m_CheckPointX := m_pCells^[m_iCurrentCell].Walls[0].Position.x;
    m_CheckPointY := m_pCells^[m_iCurrentCell].Walls[1].Position.y;
  end;
end;

end.
 