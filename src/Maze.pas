{
 * TMaze class for randomly generated Maze using recursive backtracker algoritm
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

unit Maze;

interface

uses
  Windows,
  Messages,
  Sysutils,
  Player,
  Defines,
  Camera,
  Keys,
  SceneManager,
  Font,
  dglOpenGL,
  ChildForm;

type
  TMaze = class
  public
    destructor Destroy();override;                // destruktor
    procedure Draw();                   // vykreslovaci fce
    procedure Initialize(wallTexID, terrainTexID:GLuint);
    procedure Deinitialize();           // pred znicenim gl kontextu si musime nahrat data z vbo do ram
    constructor Create(difficulty:TDifficulty = Easy);overload;
    constructor Create(width:uint32; height:uint32; difficulty:TDifficulty = Easy);overload;
    procedure Build(width:uint32; height:uint32; difficulty:TDifficulty);   // vytvori plne bludiste
    procedure Regenerate();                  // znovuvygenerovani bludiste
    function GetPlayer():TPlayer;            // vrati playera
    function GetCamera():TCamera;            // vrati kameru
  private
    m_Vertices:array of Vertex;              // pole vertexu pro VA
    m_TexCoords:array of TexCoord;           // pole texturovych koordinatu pro VA
    m_Normals:array of Vertex;               // pole normal pro VA
    m_Cells:array of Cell;                   // pole bunek bludiste
    m_iStack:array of uint32;                // stack obsahujici indexy na bludiste(pro algoritmus generace)
    m_Player:TPlayer;                        // player
    m_Camera:TCamera;                        // kamera
    m_numOfVertices:uint32;                  // pocet vertexu pro VA
    m_numOfCellsInStack:uint32;              // pocet bunek ve stacku
    m_numOfCells:uint32;                     // pocet bunek
    m_numOfCellsInRow:uint32;                // pocet bunek v radku
    m_numOfCellsInCollumn:uint32;            // pocet bunek ve sloupci

    m_width:float;                           // sirka bludiste v ogl j
    m_height:float;                          // vyska bludiste v ogl j

    m_terrainTexID:GLuint;                   // id textury podlahy pod bludiste
    m_wallTexID:GLuint;                      // id textury steny bludiste
    m_nVBOVertices:GLuint;                   // id VBO vertexu
    m_nVBOTexCoords:GLuint;                  // id VBO texturovych koordinatu
    m_nVBONormals:GLuint;                    // id VBO normal

    m_VBOSupported:boolean;                  // urcuje zda je VBO podporovano ci nikoliv

    m_Difficulty:TDifficulty;                // obtiznost bludiste

    procedure BuildVBOs();                            // vytvori VBO
    procedure GenerateByRecursiveBacktracker();       // generace pomoci algoritmu "Recursive Backtracker"
    procedure RecursiveBacktrack(iCurrent:uint32);   // vlastni rekurzivni fce
    procedure ResetWallVisibility();                  // resetuje bludiste tak ze budou videt vsechny steny
    procedure MarkAllCellsNotVisited();               // pro vsechny bunky nastavi ze jimy jeste algoritmus tvorby neprosel
    function AreNeighboursVisited(iNeighbours:array of int32):boolean;   // zjisti zda byli bunky zadane v parametru jiz navstiveny
  end;

implementation

constructor TMaze.Create(difficulty:TDifficulty = Easy);
begin
  // kdyz gpu nepodporuje rozsireni GL_ARB_vertex_buffer_object
  if Pos('GL_ARB_vertex_buffer_object', Form1.GetOpenGLExtensions()) = 0 then
    m_VBOSupported := false      // bool promene priradime false
  else      // kdyz podporuje
    m_VBOSupported := true;    // priradime true
  m_numOfCells := 0;
  SetLength(m_Cells, m_numOfCells);
  m_Player := TPlayer.Create(@m_Cells, @m_numOfCells);  // pres ukazatele bude mit trida TPlayer pristup k poli bunek
  m_Camera := TCamera.Create();           // vytvori instanci kamery
  Build(MAZE_START_SIZE, MAZE_START_SIZE, difficulty);            // vytvori bludiste a hrace
end;

constructor TMaze.Create(width:uint32; height:uint32; difficulty:TDifficulty = Easy);
begin
  // kdyz gpu nepodporuje rozsireni GL_ARB_vertex_buffer_object
  if Pos('GL_ARB_vertex_buffer_object', Form1.GetOpenGLExtensions()) = 0 then
    m_VBOSupported := false      // bool promene priradime false
  else      // kdyz podporuje
    m_VBOSupported := true;    // priradime true
  m_numOfCells := 0;
  SetLength(m_Cells, m_numOfCells);
  m_Player := TPlayer.Create(@m_Cells, @m_numOfCells);  // pres ukazatele bude mit trida TPlayer pristup k poli bunek
  m_Camera := TCamera.Create();           // vytvori instanci kamery
  Build(width, height, difficulty);            // vytvori bludiste a hrace
end;

procedure TMaze.Initialize(wallTexID, terrainTexID:GLuint);
begin
  // naplnime clenske promene parametry
  m_wallTexID := wallTexID;
  m_terrainTexID := terrainTexID;
  m_Player.Initialize();

  // po ztrate ogl kontextu musime znovu vytvorit vbo za normalnich okolnosti
  // data v ram uz nebudou takze nemuzeme vbo vytvorit ale pokud menime treba display mod
  // tak jsme si z nich jeste pred ztratou vbo data ziskali a ted jsou v ram
  if (m_VBOSupported) and (not(m_Vertices = nil)) then
    BuildVBOs();
end;

procedure TMaze.Deinitialize();
begin
  if m_VBOSupported then
  begin
    // alokujeme nase dynamicka pole vertexu, normal a texturovych koordinatu
    SetLength(m_Vertices, m_numOfVertices+4);
    SetLength(m_Normals, m_numOfVertices+4);
    SetLength(m_TexCoords, m_numOfVertices+4);

    glBindBufferARB(GL_ARRAY_BUFFER_ARB, m_nVBOVertices);         // zvolime vbo vertexu
    glGetBufferSubDataARB(GL_ARRAY_BUFFER_ARB, 0, (m_numOfVertices+4) * 3 * sizeof(float), @m_Vertices[0]); // ziskame data z vbo

    glBindBufferARB(GL_ARRAY_BUFFER_ARB, m_nVBONormals);          // zvolime vbo normal
    glGetBufferSubDataARB(GL_ARRAY_BUFFER_ARB, 0, (m_numOfVertices+4) * 3 * sizeof(float), @m_Normals[0]); // ziskame data z vbo

    glBindBufferARB(GL_ARRAY_BUFFER_ARB, m_nVBOTexCoords);        // zvolime vbo texturovych koordinatu
    glGetBufferSubDataARB(GL_ARRAY_BUFFER_ARB, 0, (m_numOfVertices+4) * 2 * sizeof(float), @m_TexCoords[0]); // ziskame data z vbo
  end;
end;

procedure TMaze.Build(width:uint32; height:uint32; difficulty:TDifficulty);
var
  nRow, nCollumn :uint32;
begin
  // nulujeme stavajici bunky
  m_numOfCells := 0;
  SetLength(m_Cells, m_numOfCells);

  // nulujeme stavajici vertexi texturove koordinaty a normaly
  m_numOfVertices := 0;
  SetLength(m_Vertices, m_numOfVertices);
  SetLength(m_TexCoords, m_numOfVertices);
  SetLength(m_Normals, m_numOfVertices);

  // nastaveni clenskych pomenych   btw CellSize je v defines
  m_width := width * CellSize;
  m_height := height * CellSize;
  m_numOfCellsInStack := 0;
  m_Difficulty := difficulty;

  m_numOfCells := round((m_width / CellSize) * (m_height / CellSize));   // vypocteme pocet bunek
  m_numOfCellsInRow := round(m_width / CellSize);            // vypocteme pocet bunek v radku
  m_numOfCellsInCollumn := round(m_height / CellSize);       // Vypoceteme pocet bunek ve sloupku

  SetLength(m_Cells, m_numOfCells);                   // nastavime velikost dynamickeho pole

  // nastavime plne bludiste
  for nRow := 0 to m_numOfCellsInRow-1 do
  begin
    for nCollumn := 0 to m_numOfCellsInCollumn-1 do
    begin
      m_Cells[nRow * m_numOfCellsInRow + nCollumn].Visited := false;

      // prvni stena v bunce

      m_Cells[nRow * m_numOfCellsInRow + nCollumn].Walls[0].Position.x := (nCollumn * CellSize)+CellSize/2;
      m_Cells[nRow * m_numOfCellsInRow + nCollumn].Walls[0].Position.y := (nRow + 1) * CellSize;
      m_Cells[nRow * m_numOfCellsInRow + nCollumn].Walls[0].Position.z := 0;

      // druha stena v bunce

      m_Cells[nRow * m_numOfCellsInRow + nCollumn].Walls[1].Position.x := (nCollumn+1) * CellSize;
      m_Cells[nRow * m_numOfCellsInRow + nCollumn].Walls[1].Position.y := (nRow * CellSize) + CellSize/2;
      m_Cells[nRow * m_numOfCellsInRow + nCollumn].Walls[1].Position.z := 0;

      // treti stena v bunce

      m_Cells[nRow * m_numOfCellsInRow + nCollumn].Walls[2].Position.x := (nCollumn * CellSize)+CellSize/2;
      m_Cells[nRow * m_numOfCellsInRow + nCollumn].Walls[2].Position.y := nRow * CellSize;
      m_Cells[nRow * m_numOfCellsInRow + nCollumn].Walls[2].Position.z := 0;

      // ctvrta stena v bunce

      m_Cells[nRow * m_numOfCellsInRow + nCollumn].Walls[3].Position.x := nCollumn * CellSize;
      m_Cells[nRow * m_numOfCellsInRow + nCollumn].Walls[3].Position.y := (nRow * CellSize) + CellSize/2;
      m_Cells[nRow * m_numOfCellsInRow + nCollumn].Walls[3].Position.z := 0;
    end;
  end;

  Regenerate();
  
end;

destructor TMaze.Destroy();
begin
  inherited Destroy();
  
  // musime uvolnit vbo
  glDeleteBuffersARB(1, @m_nVBOVertices);
  glDeleteBuffersARB(1, @m_nVBOTexCoords);
  glDeleteBuffersARB(1, @m_nVBONormals);

  m_Player.Free();
  m_Camera.Free();
end;

function TMaze.GetPlayer():TPlayer;
begin
  result := m_Player;   // vrati instanci playera
end;

function TMaze.GetCamera():TCamera;
begin
  result := m_Camera;     // vrati instanci kamery
end;

procedure TMaze.ResetWallVisibility();
var
  nWalls:uint32;
begin
  for nWalls := 0 to m_numOfCells * 4 do         // prochazime vsechny steny
  begin
    m_Cells[nWalls div 4].Walls[nWalls mod 4].Visible := true;  // zviditelnime je
  end;
end;

procedure TMaze.MarkAllCellsNotVisited();
var
  nCells:uint32;
begin
  for nCells := 0 to m_numOfCells do   // prochazime vsechny bunky
  begin
    m_Cells[nCells].Visited := false;   // nastavime je na nenavstivene
  end;
end;

procedure TMaze.Regenerate();
var
  nCell, iVert :uint32;
  numOfSkippedWalls :uint32;
  WallPos:Vertex;
begin
  ResetWallVisibility();                            // nastavi vsechny steny viditelne

  MarkAllCellsNotVisited();                         // nastavi vsechny bunky nenavstivene

  // Zacatek
  //m_Cells[m_numOfCellsInCollumn * (m_numOfCellsInRow -1)].Walls[0].Visible := false;
  // Konec
  m_Cells[m_numOfCellsInRow-1].Walls[2].Visible := false;

  GenerateByRecursiveBacktracker();                     // vlastni generace

  m_Player.SetPosition(m_numOfCellsInCollumn * (m_numOfCellsInRow -1));      // resetujeme pozici hrace

  numOfSkippedWalls := 0;                             // inicializace pomocne promene ktera bude urcovat kolik jsme vynechaali sten
  m_numOfVertices := m_numOfCells *4*6*4;               // pocet vertexu = kazda bunka ma 4 steny a kazda stena je kvadr se 6 stenami a kazda stena 4 vrcholy
  SetLength(m_Vertices, m_numOfVertices);               // urcime velikost dynamickeho pole
  SetLength(m_TexCoords, m_numOfVertices);
  SetLength(m_Normals, m_numOfVertices);

  iVert := 0;                                           // inicializace pomocne promenne k prochazeni vertexu
  // prochazime bunky
  for nCell := 0 to m_numOfCells -1 do
  begin
    if m_Cells[nCell].Walls[0].Visible then        // kdyz je prvni stena viditelna
    begin
      WallPos := m_Cells[nCell].Walls[0].Position;
      // Spodni stena
      m_Normals[iVert].x := 0.0; m_Normals[iVert].y := 1.0; m_Normals[iVert].z := 0.0;
      m_Normals[iVert+1] := m_Normals[iVert]; m_Normals[iVert+2] := m_Normals[iVert]; m_Normals[iVert+3] := m_Normals[iVert];
      m_TexCoords[iVert].s := 1.0; m_TexCoords[iVert].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+1].s := 0.0; m_TexCoords[iVert+1].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+2].s := 0.0; m_TexCoords[iVert+2].t := 0.0;
      m_TexCoords[iVert+3].s := 1.0; m_TexCoords[iVert+3].t := 0.0;
      m_Vertices[iVert].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert].y := WallPos.y-MAZE_WALL_WIDTH; m_Vertices[iVert].z := WallPos.z+0.0;
      m_Vertices[iVert+1].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+1].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+1].z := WallPos.z+0.0;
      m_Vertices[iVert+2].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+2].y := WallPos.y-MAZE_WALL_WIDTH; m_Vertices[iVert+2].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+3].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+3].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+3].z := WallPos.z+MAZE_WALL_HEIGHT;

      // horni stena
      m_Normals[iVert+4].x := 0.0; m_Normals[iVert+4].y := -1.0; m_Normals[iVert+4].z := 0.0;
      m_Normals[iVert+5] := m_Normals[iVert+4]; m_Normals[iVert+6] := m_Normals[iVert+4]; m_Normals[iVert+7] := m_Normals[iVert+4];
      m_TexCoords[iVert+4].s := 1.0; m_TexCoords[iVert+4].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+5].s := 0.0; m_TexCoords[iVert+5].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+6].s := 0.0; m_TexCoords[iVert+6].t := 0.0;
      m_TexCoords[iVert+7].s := 1.0; m_TexCoords[iVert+7].t := 0.0;
      m_Vertices[iVert+4].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+4].y := WallPos.y+MAZE_WALL_WIDTH; m_Vertices[iVert+4].z := WallPos.z+0.0;
      m_Vertices[iVert+5].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+5].y := WallPos.y+MAZE_WALL_WIDTH; m_Vertices[iVert+5].z := WallPos.z+0.0;
      m_Vertices[iVert+6].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+6].y := WallPos.y+MAZE_WALL_WIDTH; m_Vertices[iVert+6].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+7].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+7].y := WallPos.y+MAZE_WALL_WIDTH; m_Vertices[iVert+7].z := WallPos.z+MAZE_WALL_HEIGHT;

      // predni stena
      m_Normals[iVert+8].x := 0.0; m_Normals[iVert+8].y := 0.0; m_Normals[iVert+8].z := -1.0;
      m_Normals[iVert+9] := m_Normals[iVert+8]; m_Normals[iVert+10] := m_Normals[iVert+8]; m_Normals[iVert+11] := m_Normals[iVert+8];
      m_TexCoords[iVert+8].s := 0.0; m_TexCoords[iVert+8].t := 0.0;
      m_TexCoords[iVert+9].s := 1.0; m_TexCoords[iVert+9].t := 0.0;
      m_TexCoords[iVert+10].s := 1.0; m_TexCoords[iVert+10].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+11].s := 0.0; m_TexCoords[iVert+11].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_Vertices[iVert+8].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+8].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+8].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+9].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+9].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+9].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+10].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+10].y := WallPos.y+ MAZE_WALL_WIDTH; m_Vertices[iVert+10].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+11].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+11].y := WallPos.y+ MAZE_WALL_WIDTH; m_Vertices[iVert+11].z := WallPos.z+MAZE_WALL_HEIGHT;

      // zadni stena
      m_Normals[iVert+12].x := 0.0; m_Normals[iVert+12].y := 0.0; m_Normals[iVert+12].z := 1.0;
      m_Normals[iVert+13] := m_Normals[iVert+12]; m_Normals[iVert+14] := m_Normals[iVert+12]; m_Normals[iVert+15] := m_Normals[iVert+12];
      m_TexCoords[iVert+12].s := 1.0; m_TexCoords[iVert+12].t := 0.0;
      m_TexCoords[iVert+13].s := 1.0; m_TexCoords[iVert+13].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+14].s := 0.0; m_TexCoords[iVert+14].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+15].s := 0.0; m_TexCoords[iVert+15].t := 0.0;
      m_Vertices[iVert+12].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+12].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+12].z := WallPos.z+0.0;
      m_Vertices[iVert+13].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+13].y := WallPos.y+ MAZE_WALL_WIDTH; m_Vertices[iVert+13].z := WallPos.z+0.0;
      m_Vertices[iVert+14].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+14].y := WallPos.y+ MAZE_WALL_WIDTH; m_Vertices[iVert+14].z := WallPos.z+0.0;
      m_Vertices[iVert+15].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+15].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+15].z := WallPos.z+0.0;

      // prava stena
      m_Normals[iVert+16].x := -1.0; m_Normals[iVert+16].y := 0.0; m_Normals[iVert+16].z := 0.0;
      m_Normals[iVert+17] := m_Normals[iVert+16]; m_Normals[iVert+18] := m_Normals[iVert+16]; m_Normals[iVert+19] := m_Normals[iVert+16];
      m_TexCoords[iVert+16].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+16].t := 0.0;
      m_TexCoords[iVert+17].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+17].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+18].s := 0.0; m_TexCoords[iVert+18].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+19].s := 0.0; m_TexCoords[iVert+19].t := 0.0;
      m_Vertices[iVert+16].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+16].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+16].z := WallPos.z+0.0;
      m_Vertices[iVert+17].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+17].y := WallPos.y+ MAZE_WALL_WIDTH; m_Vertices[iVert+17].z := WallPos.z+0.0;
      m_Vertices[iVert+18].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+18].y := WallPos.y+ MAZE_WALL_WIDTH; m_Vertices[iVert+18].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+19].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+19].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+19].z := WallPos.z+MAZE_WALL_HEIGHT;

      // leva stena
      m_Normals[iVert+20].x := 1.0; m_Normals[iVert+20].y := 0.0; m_Normals[iVert+20].z := 0.0;
      m_Normals[iVert+21] := m_Normals[iVert+20]; m_Normals[iVert+22] := m_Normals[iVert+20]; m_Normals[iVert+23] := m_Normals[iVert+20];
      m_TexCoords[iVert+20].s := 0.0; m_TexCoords[iVert+20].t := 0.0;
      m_TexCoords[iVert+21].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+21].t := 0.0;
      m_TexCoords[iVert+22].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+22].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+23].s := 0.0; m_TexCoords[iVert+23].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_Vertices[iVert+20].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+20].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+20].z := WallPos.z+0.0;
      m_Vertices[iVert+21].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+21].y := WallPos.y - MAZE_WALL_WIDTH; m_Vertices[iVert+21].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+22].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+22].y := WallPos.y + MAZE_WALL_WIDTH; m_Vertices[iVert+22].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+23].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+23].y := WallPos.y + MAZE_WALL_WIDTH; m_Vertices[iVert+23].z := WallPos.z+0.0;

      inc(iVert, 24);
    end
    else
      inc(numOfSkippedWalls);

    if m_Cells[nCell].Walls[1].Visible then               // kdyz je druha stena viditelna
    begin
      WallPos := m_Cells[nCell].Walls[1].Position;
      // Spodni stena
      m_Normals[iVert].x := 0.0; m_Normals[iVert].y := 1.0; m_Normals[iVert].z := 0.0;
      m_Normals[iVert+1] := m_Normals[iVert]; m_Normals[iVert+2] := m_Normals[iVert]; m_Normals[iVert+3] := m_Normals[iVert];
      m_TexCoords[iVert].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+1].s := 0.0; m_TexCoords[iVert+1].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+2].s := 0.0; m_TexCoords[iVert+2].t := 0.0;
      m_TexCoords[iVert+3].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+3].t := 0.0;
      m_Vertices[iVert].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert].z := WallPos.z+0.0;
      m_Vertices[iVert+1].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+1].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+1].z := WallPos.z+0.0;
      m_Vertices[iVert+2].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+2].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+2].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+3].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+3].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+3].z := WallPos.z+MAZE_WALL_HEIGHT;

      // horni stena
      m_Normals[iVert+4].x := 0.0; m_Normals[iVert+4].y := -1.0; m_Normals[iVert+4].z := 0.0;
      m_Normals[iVert+5] := m_Normals[iVert+4]; m_Normals[iVert+6] := m_Normals[iVert+4]; m_Normals[iVert+7] := m_Normals[iVert+4];
      m_TexCoords[iVert+4].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+4].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+5].s := 0.0; m_TexCoords[iVert+5].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+6].s := 0.0; m_TexCoords[iVert+6].t := 0.0;
      m_TexCoords[iVert+7].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+7].t := 0.0;
      m_Vertices[iVert+4].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+4].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+4].z := WallPos.z+0.0;
      m_Vertices[iVert+5].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+5].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+5].z := WallPos.z+0.0;
      m_Vertices[iVert+6].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+6].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+6].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+7].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+7].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+7].z := WallPos.z+MAZE_WALL_HEIGHT;

      // predni stena
      m_Normals[iVert+8].x := 0.0; m_Normals[iVert+8].y := 0.0; m_Normals[iVert+8].z := -1.0;
      m_Normals[iVert+9] := m_Normals[iVert+8]; m_Normals[iVert+10] := m_Normals[iVert+8]; m_Normals[iVert+11] := m_Normals[iVert+8];
      m_TexCoords[iVert+8].s := 0.0; m_TexCoords[iVert+8].t := 0.0;
      m_TexCoords[iVert+9].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+9].t := 0.0;
      m_TexCoords[iVert+10].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+10].t := 1.0;
      m_TexCoords[iVert+11].s := 0.0; m_TexCoords[iVert+11].t := 1.0;
      m_Vertices[iVert+8].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+8].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+8].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+9].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+9].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+9].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+10].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+10].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+10].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+11].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+11].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+11].z := WallPos.z+MAZE_WALL_HEIGHT;

      // zadni stena
      m_Normals[iVert+12].x := 0.0; m_Normals[iVert+12].y := 0.0; m_Normals[iVert+12].z := 1.0;
      m_Normals[iVert+13] := m_Normals[iVert+12]; m_Normals[iVert+14] := m_Normals[iVert+12]; m_Normals[iVert+15] := m_Normals[iVert+12];
      m_TexCoords[iVert+12].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+12].t := 0.0;
      m_TexCoords[iVert+13].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+13].t := 1.0;
      m_TexCoords[iVert+14].s := 0.0; m_TexCoords[iVert+14].t := 1.0;
      m_TexCoords[iVert+15].s := 0.0; m_TexCoords[iVert+15].t := 0.0;
      m_Vertices[iVert+12].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+12].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+12].z := WallPos.z+0.0;
      m_Vertices[iVert+13].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+13].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+13].z := WallPos.z+0.0;
      m_Vertices[iVert+14].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+14].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+14].z := WallPos.z+0.0;
      m_Vertices[iVert+15].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+15].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+15].z := WallPos.z+0.0;

      // prava stena
      m_Normals[iVert+16].x := -1.0; m_Normals[iVert+16].y := 0.0; m_Normals[iVert+16].z := 0.0;
      m_Normals[iVert+17] := m_Normals[iVert+16]; m_Normals[iVert+18] := m_Normals[iVert+16]; m_Normals[iVert+19] := m_Normals[iVert+16];
      m_TexCoords[iVert+16].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+16].t := 0.0;
      m_TexCoords[iVert+17].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+17].t := 1.0;
      m_TexCoords[iVert+18].s := 0.0; m_TexCoords[iVert+18].t := 1.0;
      m_TexCoords[iVert+19].s := 0.0; m_TexCoords[iVert+19].t := 0.0;
      m_Vertices[iVert+16].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+16].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+16].z := WallPos.z+0.0;
      m_Vertices[iVert+17].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+17].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+17].z := WallPos.z+0.0;
      m_Vertices[iVert+18].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+18].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+18].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+19].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+19].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+19].z := WallPos.z+MAZE_WALL_HEIGHT;

      // leva stena
      m_Normals[iVert+20].x := 1.0; m_Normals[iVert+20].y := 0.0; m_Normals[iVert+20].z := 0.0;
      m_Normals[iVert+21] := m_Normals[iVert+20]; m_Normals[iVert+22] := m_Normals[iVert+20]; m_Normals[iVert+23] := m_Normals[iVert+20];
      m_TexCoords[iVert+20].s := 0.0; m_TexCoords[iVert+20].t := 0.0;
      m_TexCoords[iVert+21].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+21].t := 0.0;
      m_TexCoords[iVert+22].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+22].t := 1.0;
      m_TexCoords[iVert+23].s := 0.0; m_TexCoords[iVert+23].t := 1.0;
      m_Vertices[iVert+20].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+20].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+20].z := WallPos.z+0.0;
      m_Vertices[iVert+21].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+21].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+21].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+22].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+22].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+22].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+23].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+23].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+23].z := WallPos.z+0.0;

      inc(iVert, 24);
    end
    else
      inc(numOfSkippedWalls);

    // kdyz je treti stena viditelna a bunka je dole u kraje
    if (m_Cells[nCell].Walls[2].Visible) and (nCell < m_numOfCellsInRow) then
    begin
      WallPos := m_Cells[nCell].Walls[2].Position;
      // Spodni stena
      m_Normals[iVert].x := 0.0; m_Normals[iVert].y := 1.0; m_Normals[iVert].z := 0.0;
      m_Normals[iVert+1] := m_Normals[iVert]; m_Normals[iVert+2] := m_Normals[iVert]; m_Normals[iVert+3] := m_Normals[iVert];
      m_TexCoords[iVert].s := 1.0; m_TexCoords[iVert].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+1].s := 0.0; m_TexCoords[iVert+1].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+2].s := 0.0; m_TexCoords[iVert+2].t := 0.0;
      m_TexCoords[iVert+3].s := 1.0; m_TexCoords[iVert+3].t := 0.0;
      m_Vertices[iVert].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert].y := WallPos.y-MAZE_WALL_WIDTH; m_Vertices[iVert].z := WallPos.z+0.0;
      m_Vertices[iVert+1].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+1].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+1].z := WallPos.z+0.0;
      m_Vertices[iVert+2].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+2].y := WallPos.y-MAZE_WALL_WIDTH; m_Vertices[iVert+2].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+3].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+3].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+3].z := WallPos.z+MAZE_WALL_HEIGHT;

      // horni stena
      m_Normals[iVert+4].x := 0.0; m_Normals[iVert+4].y := -1.0; m_Normals[iVert+4].z := 0.0;
      m_Normals[iVert+5] := m_Normals[iVert+4]; m_Normals[iVert+6] := m_Normals[iVert+4]; m_Normals[iVert+7] := m_Normals[iVert+4];
      m_TexCoords[iVert+4].s := 1.0; m_TexCoords[iVert+4].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+5].s := 0.0; m_TexCoords[iVert+5].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+6].s := 0.0; m_TexCoords[iVert+6].t := 0.0;
      m_TexCoords[iVert+7].s := 1.0; m_TexCoords[iVert+7].t := 0.0;
      m_Vertices[iVert+4].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+4].y := WallPos.y+MAZE_WALL_WIDTH; m_Vertices[iVert+4].z := WallPos.z+0.0;
      m_Vertices[iVert+5].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+5].y := WallPos.y+MAZE_WALL_WIDTH; m_Vertices[iVert+5].z := WallPos.z+0.0;
      m_Vertices[iVert+6].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+6].y := WallPos.y+MAZE_WALL_WIDTH; m_Vertices[iVert+6].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+7].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+7].y := WallPos.y+MAZE_WALL_WIDTH; m_Vertices[iVert+7].z := WallPos.z+MAZE_WALL_HEIGHT;

      // predni stena
      m_Normals[iVert+8].x := 0.0; m_Normals[iVert+8].y := 0.0; m_Normals[iVert+8].z := -1.0;
      m_Normals[iVert+9] := m_Normals[iVert+8]; m_Normals[iVert+10] := m_Normals[iVert+8]; m_Normals[iVert+11] := m_Normals[iVert+8];
      m_TexCoords[iVert+8].s := 0.0; m_TexCoords[iVert+8].t := 0.0;
      m_TexCoords[iVert+9].s := 1.0; m_TexCoords[iVert+9].t := 0.0;
      m_TexCoords[iVert+10].s := 1.0; m_TexCoords[iVert+10].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+11].s := 0.0; m_TexCoords[iVert+11].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_Vertices[iVert+8].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+8].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+8].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+9].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+9].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+9].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+10].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+10].y := WallPos.y+ MAZE_WALL_WIDTH; m_Vertices[iVert+10].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+11].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+11].y := WallPos.y+ MAZE_WALL_WIDTH; m_Vertices[iVert+11].z := WallPos.z+MAZE_WALL_HEIGHT;

      // zadni stena
      m_Normals[iVert+12].x := 0.0; m_Normals[iVert+12].y := 0.0; m_Normals[iVert+12].z := 1.0;
      m_Normals[iVert+13] := m_Normals[iVert+12]; m_Normals[iVert+14] := m_Normals[iVert+12]; m_Normals[iVert+15] := m_Normals[iVert+12];
      m_TexCoords[iVert+12].s := 1.0; m_TexCoords[iVert+12].t := 0.0;
      m_TexCoords[iVert+13].s := 1.0; m_TexCoords[iVert+13].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+14].s := 0.0; m_TexCoords[iVert+14].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+15].s := 0.0; m_TexCoords[iVert+15].t := 0.0;
      m_Vertices[iVert+12].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+12].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+12].z := WallPos.z+0.0;
      m_Vertices[iVert+13].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+13].y := WallPos.y+ MAZE_WALL_WIDTH; m_Vertices[iVert+13].z := WallPos.z+0.0;
      m_Vertices[iVert+14].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+14].y := WallPos.y+ MAZE_WALL_WIDTH; m_Vertices[iVert+14].z := WallPos.z+0.0;
      m_Vertices[iVert+15].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+15].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+15].z := WallPos.z+0.0;

      // prava stena
      m_Normals[iVert+16].x := -1.0; m_Normals[iVert+16].y := 0.0; m_Normals[iVert+16].z := 0.0;
      m_Normals[iVert+17] := m_Normals[iVert+16]; m_Normals[iVert+18] := m_Normals[iVert+16]; m_Normals[iVert+19] := m_Normals[iVert+16];
      m_TexCoords[iVert+16].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+16].t := 0.0;
      m_TexCoords[iVert+17].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+17].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+18].s := 0.0; m_TexCoords[iVert+18].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+19].s := 0.0; m_TexCoords[iVert+19].t := 0.0;
      m_Vertices[iVert+16].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+16].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+16].z := WallPos.z+0.0;
      m_Vertices[iVert+17].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+17].y := WallPos.y+ MAZE_WALL_WIDTH; m_Vertices[iVert+17].z := WallPos.z+0.0;
      m_Vertices[iVert+18].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+18].y := WallPos.y+ MAZE_WALL_WIDTH; m_Vertices[iVert+18].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+19].x := WallPos.x+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+19].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+19].z := WallPos.z+MAZE_WALL_HEIGHT;

      // leva stena
      m_Normals[iVert+20].x := 1.0; m_Normals[iVert+20].y := 0.0; m_Normals[iVert+20].z := 0.0;
      m_Normals[iVert+21] := m_Normals[iVert+20]; m_Normals[iVert+22] := m_Normals[iVert+20]; m_Normals[iVert+23] := m_Normals[iVert+20];
      m_TexCoords[iVert+20].s := 0.0; m_TexCoords[iVert+20].t := 0.0;
      m_TexCoords[iVert+21].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+21].t := 0.0;
      m_TexCoords[iVert+22].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+22].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+23].s := 0.0; m_TexCoords[iVert+23].t := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_Vertices[iVert+20].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+20].y := WallPos.y- MAZE_WALL_WIDTH; m_Vertices[iVert+20].z := WallPos.z+0.0;
      m_Vertices[iVert+21].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+21].y := WallPos.y - MAZE_WALL_WIDTH; m_Vertices[iVert+21].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+22].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+22].y := WallPos.y + MAZE_WALL_WIDTH; m_Vertices[iVert+22].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+23].x := WallPos.x-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+23].y := WallPos.y + MAZE_WALL_WIDTH; m_Vertices[iVert+23].z := WallPos.z+0.0;

      inc(iVert, 24);
    end
    else
      inc(numOfSkippedWalls);

    // kdyz je treti stena viditelna a bunka na levem okraji bludiste
    if (m_Cells[nCell].Walls[3].Visible) and ((nCell mod m_numOfCellsInRow) = 0) then
    begin
      WallPos := m_Cells[nCell].Walls[3].Position;
      // Spodni stena
      m_Normals[iVert].x := 0.0; m_Normals[iVert].y := 1.0; m_Normals[iVert].z := 0.0;
      m_Normals[iVert+1] := m_Normals[iVert]; m_Normals[iVert+2] := m_Normals[iVert]; m_Normals[iVert+3] := m_Normals[iVert];
      m_TexCoords[iVert].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+1].s := 0.0; m_TexCoords[iVert+1].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+2].s := 0.0; m_TexCoords[iVert+2].t := 0.0;
      m_TexCoords[iVert+3].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+3].t := 0.0;
      m_Vertices[iVert].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert].z := WallPos.z+0.0;
      m_Vertices[iVert+1].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+1].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+1].z := WallPos.z+0.0;
      m_Vertices[iVert+2].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+2].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+2].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+3].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+3].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+3].z := WallPos.z+MAZE_WALL_HEIGHT;

      // horni stena
      m_Normals[iVert+4].x := 0.0; m_Normals[iVert+4].y := -1.0; m_Normals[iVert+4].z := 0.0;
      m_Normals[iVert+5] := m_Normals[iVert+4]; m_Normals[iVert+6] := m_Normals[iVert+4]; m_Normals[iVert+7] := m_Normals[iVert+4];
      m_TexCoords[iVert+4].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+4].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+5].s := 0.0; m_TexCoords[iVert+5].t := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2);
      m_TexCoords[iVert+6].s := 0.0; m_TexCoords[iVert+6].t := 0.0;
      m_TexCoords[iVert+7].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+7].t := 0.0;
      m_Vertices[iVert+4].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+4].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+4].z := WallPos.z+0.0;
      m_Vertices[iVert+5].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+5].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+5].z := WallPos.z+0.0;
      m_Vertices[iVert+6].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+6].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+6].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+7].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+7].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+7].z := WallPos.z+MAZE_WALL_HEIGHT;

      // predni stena
      m_Normals[iVert+8].x := 0.0; m_Normals[iVert+8].y := 0.0; m_Normals[iVert+8].z := -1.0;
      m_Normals[iVert+9] := m_Normals[iVert+8]; m_Normals[iVert+10] := m_Normals[iVert+8]; m_Normals[iVert+11] := m_Normals[iVert+8];
      m_TexCoords[iVert+8].s := 0.0; m_TexCoords[iVert+8].t := 0.0;
      m_TexCoords[iVert+9].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+9].t := 0.0;
      m_TexCoords[iVert+10].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+10].t := 1.0;
      m_TexCoords[iVert+11].s := 0.0; m_TexCoords[iVert+11].t := 1.0;
      m_Vertices[iVert+8].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+8].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+8].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+9].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+9].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+9].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+10].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+10].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+10].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+11].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+11].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+11].z := WallPos.z+MAZE_WALL_HEIGHT;

      // zadni stena
      m_Normals[iVert+12].x := 0.0; m_Normals[iVert+12].y := 0.0; m_Normals[iVert+12].z := 1.0;
      m_Normals[iVert+13] := m_Normals[iVert+12]; m_Normals[iVert+14] := m_Normals[iVert+12]; m_Normals[iVert+15] := m_Normals[iVert+12];
      m_TexCoords[iVert+12].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+12].t := 0.0;
      m_TexCoords[iVert+13].s := (MAZE_WALL_WIDTH*2)/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+13].t := 1.0;
      m_TexCoords[iVert+14].s := 0.0; m_TexCoords[iVert+14].t := 1.0;
      m_TexCoords[iVert+15].s := 0.0; m_TexCoords[iVert+15].t := 0.0;
      m_Vertices[iVert+12].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+12].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+12].z := WallPos.z+0.0;
      m_Vertices[iVert+13].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+13].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+13].z := WallPos.z+0.0;
      m_Vertices[iVert+14].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+14].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+14].z := WallPos.z+0.0;
      m_Vertices[iVert+15].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+15].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+15].z := WallPos.z+0.0;

      // prava stena
      m_Normals[iVert+16].x := -1.0; m_Normals[iVert+16].y := 0.0; m_Normals[iVert+16].z := 0.0;
      m_Normals[iVert+17] := m_Normals[iVert+16]; m_Normals[iVert+18] := m_Normals[iVert+16]; m_Normals[iVert+19] := m_Normals[iVert+16];
      m_TexCoords[iVert+16].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+16].t := 0.0;
      m_TexCoords[iVert+17].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+17].t := 1.0;
      m_TexCoords[iVert+18].s := 0.0; m_TexCoords[iVert+18].t := 1.0;
      m_TexCoords[iVert+19].s := 0.0; m_TexCoords[iVert+19].t := 0.0;
      m_Vertices[iVert+16].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+16].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+16].z := WallPos.z+0.0;
      m_Vertices[iVert+17].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+17].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+17].z := WallPos.z+0.0;
      m_Vertices[iVert+18].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+18].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+18].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+19].x := WallPos.x+MAZE_WALL_WIDTH; m_Vertices[iVert+19].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+19].z := WallPos.z+MAZE_WALL_HEIGHT;

      // leva stena
      m_Normals[iVert+20].x := 1.0; m_Normals[iVert+20].y := 0.0; m_Normals[iVert+20].z := 0.0;
      m_Normals[iVert+21] := m_Normals[iVert+20]; m_Normals[iVert+22] := m_Normals[iVert+20]; m_Normals[iVert+23] := m_Normals[iVert+20];
      m_TexCoords[iVert+20].s := 0.0; m_TexCoords[iVert+20].t := 0.0;
      m_TexCoords[iVert+21].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+21].t := 0.0;
      m_TexCoords[iVert+22].s := MAZE_WALL_HEIGHT/((CellSize/2 + MAZE_WALL_WIDTH)*2); m_TexCoords[iVert+22].t := 1.0;
      m_TexCoords[iVert+23].s := 0.0; m_TexCoords[iVert+23].t := 1.0;
      m_Vertices[iVert+20].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+20].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+20].z := WallPos.z+0.0;
      m_Vertices[iVert+21].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+21].y := WallPos.y-CellSize/2 - MAZE_WALL_WIDTH; m_Vertices[iVert+21].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+22].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+22].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+22].z := WallPos.z+MAZE_WALL_HEIGHT;
      m_Vertices[iVert+23].x := WallPos.x-MAZE_WALL_WIDTH; m_Vertices[iVert+23].y := WallPos.y+CellSize/2 + MAZE_WALL_WIDTH; m_Vertices[iVert+23].z := WallPos.z+0.0;

      inc(iVert, 24);
    end
    else
      inc(numOfSkippedWalls);
  end;

  m_numOfVertices := m_numOfVertices - numOfSkippedWalls *24;      // upravime pocet vertexu o ty steny ktere jsou neviditelne

  m_Normals[m_numOfVertices].x := 0.0; m_Normals[m_numOfVertices].y := 1.0; m_Normals[m_numOfVertices].z := 0.0;
  m_Normals[m_numOfVertices+1] := m_Normals[m_numOfVertices]; m_Normals[m_numOfVertices+2] := m_Normals[m_numOfVertices]; m_Normals[m_numOfVertices+3] := m_Normals[m_numOfVertices];
  m_TexCoords[m_numOfVertices].s := 0.0; m_TexCoords[m_numOfVertices].t := 0.0;
  m_TexCoords[m_numOfVertices+1].s := 5.0; m_TexCoords[m_numOfVertices+1].t := 0.0;
  m_TexCoords[m_numOfVertices+2].s := 5.0; m_TexCoords[m_numOfVertices+2].t := 5.0;
  m_TexCoords[m_numOfVertices+3].s := 0.0; m_TexCoords[m_numOfVertices+3].t := 5.0;
  m_Vertices[m_numOfVertices].x := -5.0; m_Vertices[m_numOfVertices].y := -5.0; m_Vertices[m_numOfVertices].z := 0.0;
  m_Vertices[m_numOfVertices+1].x := m_width+5.0; m_Vertices[m_numOfVertices+1].y := -5.0; m_Vertices[m_numOfVertices+1].z := 0.0;
  m_Vertices[m_numOfVertices+2].x := m_width+5.0; m_Vertices[m_numOfVertices+2].y := m_height +5.0; m_Vertices[m_numOfVertices+2].z := 0.0;
  m_Vertices[m_numOfVertices+3].x := -5.0; m_Vertices[m_numOfVertices+3].y := m_height+5.0; m_Vertices[m_numOfVertices+3].z := 0.0;

  SetLength(m_Vertices, m_numOfVertices+4);                           // zmenime velikost dynamickeho pole
  SetLength(m_TexCoords, m_numOfVertices+4);
  SetLength(m_Normals, m_numOfVertices+4);

  if m_VBOSupported then      // kdyz je VBO podporavno
    BuildVBOs();              // tak je vytvorime
end;

procedure TMaze.BuildVBOs();
begin
  // musime uvolnit predchazejici vbo
  glDeleteBuffersARB(1, @m_nVBOVertices);
  glDeleteBuffersARB(1, @m_nVBOTexCoords);
  glDeleteBuffersARB(1, @m_nVBONormals);

  // VBO pro vertexy
  glGenBuffersARB(1, @m_nVBOVertices);
  glBindBufferARB(GL_ARRAY_BUFFER_ARB, m_nVBOVertices);
  glBufferDataARB(GL_ARRAY_BUFFER_ARB, (m_numOfVertices+4) * 3 * sizeof(float), @m_Vertices[0], GL_STATIC_DRAW_ARB);

  // VBO pro texturove koordinaty
  glGenBuffersARB(1, @m_nVBOTexCoords);
  glBindBufferARB(GL_ARRAY_BUFFER_ARB, m_nVBOTexCoords);
  glBufferDataARB(GL_ARRAY_BUFFER_ARB, (m_numOfVertices+4) * 2 * sizeof(float), @m_TexCoords[0], GL_STATIC_DRAW_ARB);

  // VBO pro normaly
  glGenBuffersARB(1, @m_nVBONormals);
  glBindBufferARB(GL_ARRAY_BUFFER_ARB, m_nVBONormals);
  glBufferDataARB(GL_ARRAY_BUFFER_ARB,(m_numOfVertices+4) * 3 * sizeof(float), @m_Normals[0], GL_STATIC_DRAW_ARB);

  // data v ram uz jsou zbytecna
  Finalize(m_Vertices);
  Finalize(m_TexCoords);
  Finalize(m_Normals);
end;

procedure TMaze.Draw();
const
  // konstantni pole pro svetlo
  lightDifuse:array [0..3] of GLfloat = (0.7, 0.7, 0.7, 1.0);
  lightAmb:array [0..3] of GLfloat = (0.2, 0.2, 0.2, 1.0);
  lightDir:array [0..3] of GLfloat = (-1, 0, -1, 0);
begin

  glMatrixMode(GL_MODELVIEW);                                 // vybereme modelview matici
  glPushMatrix();                                             // ulozime si ji

  m_Camera.LookAt(m_width/2, m_height/2, 0.0);                // kamera modifikuje modelView matici

  // nastavime svetlo
  glLightfv(GL_LIGHT1, GL_AMBIENT, @lightAmb);
  glLightfv(GL_LIGHT1, GL_DIFFUSE, @lightDifuse);
  glLightfv(GL_LIGHT1, GL_POSITION, @lightDir);

  glTranslatef(0.0, 3.0, -6.0);                               // presun - muzete mi nekdo rict proc tu je ten presun ?!
  //glDisable(GL_TEXTURE_2D);                                 // odkomentovanim tohoto radku zvysite fps o 250%(u me ve fullscreenu ze 180 na 570 ale zhorsite kvalitu obrazu :)
  glBindTexture(GL_TEXTURE_2D, m_wallTexID);                  // zvolime texturu steny
  glEnable(GL_COLOR_MATERIAL);                                // povolime barveni materialu
  glColor4f(1, 1, 1, 1);                                      // reset barvy
  glEnable(GL_LIGHTING);                                      // zapneme svetla

  if m_VBOSupported then            // kdyz je VBO podporovano pouzijeme VBO
  begin
    glBindBufferARB(GL_ARRAY_BUFFER_ARB, m_nVBONormals);   // zvolime buffer normal
    glNormalPointer(GL_FLOAT, 0, nil);                     // predame nil
    glBindBufferARB(GL_ARRAY_BUFFER_ARB, m_nVBOTexCoords); // zvolime buffer texturovych koordinatu
    glTexCoordPointer(2, GL_FLOAT, 0, nil);                // predame nil
    glBindBufferARB(GL_ARRAY_BUFFER_ARB, m_nVBOVertices);  // zvolime buffer vertexu
    glVertexPointer(3, GL_FLOAT, 0, nil);                  // predame nil
  end
  else                            // kdyz neni podporovano pouzijeme klasicke vertex arrays
  begin
    glNormalPointer(GL_FLOAT, 0, @m_Normals[0]);            // predame normaly
    glTexCoordPointer(2, GL_FLOAT, 0, @m_TexCoords[0]);     // predame texturove koordinaty
    glVertexPointer(3, GL_FLOAT, 0, @m_Vertices[0]);        // predame vertexy
  end;

  // zapneme vertex arrays
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glEnableClientState(GL_NORMAL_ARRAY);

  glDrawArrays(GL_QUADS, 0, m_numOfVertices);              // vykreslime ctyruhelniky
  
  glBindTexture(GL_TEXTURE_2D, m_terrainTexID);        // zvolime texturu podlahy
  glDrawArrays(GL_QUADS, m_numOfVertices, 4);           // vykreslime podlahu

  // vypneme vertex arrays
  glDisableClientState(GL_NORMAL_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisableClientState(GL_VERTEX_ARRAY);

  glDisable(GL_COLOR_MATERIAL);                         // vypneme barveni materialu
  glDisable(GL_LIGHTING);                               // vypneme svetla
  glDisable(GL_TEXTURE_2D);                             // vypneme texturovani

  m_Player.Draw();                                            // vykreslime hrace  

  glMatrixMode(GL_MODELVIEW);                                 // vybereme modelview matici
  glPopMatrix();                                              // nacteme ji
end;

procedure TMaze.GenerateByRecursiveBacktracker();
begin
  randomize();                                                 // nastavi seed pro random fci podle casu

  // podle obtiznosti rozhodneme o tom kde zacne algoritmus na generaci bludiste( to kde algoritmus zacne znacne ovlivni obtiznost vygenerovaneho bludiste)
  case m_Difficulty of
    Easy: begin RecursiveBacktrack(m_numOfCellsInCollumn * (m_numOfCellsInRow -1)); end;
    Hard: begin RecursiveBacktrack(m_numOfCellsInRow -1); end;
  end;
  //m_Cells[m_numOfCells-1].Walls[3].Visible := true;
end;

// zjistuje zda byly sousede jiz navstiveny
function TMaze.AreNeighboursVisited(iNeighbours:array of int32):boolean;
var
  loop1,loop2,loop3, nonexisted, sizeOfTemp, temp:uint32;
  tempNeighbours:array of int32;
begin
  SetLength(tempNeighbours, High(iNeighbours)+1);            // velikost naseho pomocneho dyn. pole nastavime na velikost pole v parametru
  // nulovani
  loop2:=0;
  nonexisted:=0;
  // prvni for cyklus proch�zi sousedy a do pomocneho pole uklada jen ty ktere existuji
  for loop1:= 0  to High(iNeighbours) do
  begin
    if iNeighbours[loop1] > -1 then                          // kdyz soused existuje ( -1 == ze soused neexistuje)
    begin
      tempNeighbours[loop2] := iNeighbours[loop1];           // do pomocneho pole zkopiruje data z org. pole
      inc(loop2);                                            // zvyssi promenou
    end
    else
      inc(nonexisted);                                       // pro pozdejsi oriznuti pole potrebujeme znat kolik sousedu bylo vynechano
  end;
  sizeOfTemp := (uint32(High(iNeighbours)+1))-nonexisted;    // vypocteme velikost pom. pole
  SetLength(tempNeighbours, sizeOfTemp);                     // nastavime jeho velikost
  temp:=0;                                                   // nulovani pom. promene
  for loop3:=0 to sizeOfTemp-1 do                            // prochazime pomocne pole
  begin
    if m_Cells[tempNeighbours[loop3]].Visited then           // kdyz byla bunka navstivena
      inc(temp);                                             // zvysime pom. promenou
  end;

  if temp = sizeOfTemp then                                  // kdyz pomocna promena == velikost pom. pole( tedy vsechny bunky byli jiz navstiveny)
  begin
    result:= true;                                           // vrati true
    exit;
  end
  else                                                       // jinak
  begin
    result := false;                                         // vrati false
    exit;
  end;
end;

procedure TMaze.RecursiveBacktrack(iCurrent:uint32);
var
  indexOfCellInRow, indexOfCellInCollumn, iChosenCell, temp:uint32;
  iNeighbours:array [0..3] of int32;
  infLoop:uint8;
begin
  m_Cells[iCurrent].Visited := true;                         // oznacime soucasnou bunku za navstivenou
  indexOfCellInRow := iCurrent mod m_numOfCellsInCollumn;    // index bunky v radku
  indexOfCellInCollumn := iCurrent div m_numOfCellsInCollumn; // index bunky ve sloupecku

  // zjistime a naplnime sousedy soucasne bunky, osetrime pripady kdy je bunka na kraji; -1 znaci ze zadna takova bunka neexistuje
  if indexOfCellInCollumn < m_numOfCellsInCollumn-1 then
    iNeighbours[0] := iCurrent + m_numOfCellsInCollumn
  else
    iNeighbours[0] := -1;

  if indexOfCellInRow < m_numOfCellsInRow-1 then
    iNeighbours[1] := iCurrent +1
  else
    iNeighbours[1] := -1;

  if indexOfCellInCollumn > 0 then
    iNeighbours[2] := iCurrent - m_numOfCellsInCollumn
  else
    iNeighbours[2] := -1;

  if indexOfCellInRow > 0 then
    iNeighbours[3] := iCurrent -1
  else
    iNeighbours[3] := -1;

  // kdyz byli vsichni sousedi jiz navstiveni
  if AreNeighboursVisited(iNeighbours) then
  begin
    // odstranime posledni bunku ze stacku
    dec(m_numOfCellsInStack);         // snizime pomocnou promenou ktera urcuje velikost dyn. pole stacku
    if m_numOfCellsInStack = 0 then   // kdyz je stack prazdny
      exit;                           // konec
    SetLength(m_iStack, m_numOfCellsInStack); // nastavime velikost stacku
    RecursiveBacktrack(m_iStack[m_numOfCellsInStack-1]);   // rekurze s poslednim soucasnou bunkou
  end
  // jinak
  else
  begin
    infLoop := 0;                       // inicializujeme promenou pro nekonecny cyklus
    while infLoop = 0 do                // infLoop je 0 a furt bude tedy toto je nekonecny cyklus for(;;) {} se mi ale libi v�c :DDDD
    begin
    case round(random(4)) of            // vygenerujeme cislo od 0 do 3
    0:
    begin
      if (not m_Cells[iNeighbours[0]].Visited) and (iNeighbours[0] <> -1) then     // kdyz soused jeste nebyl navstiven
      begin
        iChosenCell := iNeighbours[0];                // Vybereme ho
        temp := 0;
        break;                                        // vyskocime z nekonecneho cyklu
      end;
    end;
    1:
    begin
      if (not m_Cells[iNeighbours[1]].Visited) and (iNeighbours[1] <> -1) then     // kdyz soused jeste nebyl navstiven
      begin
        iChosenCell := iNeighbours[1];                // Vybereme ho
        temp:= 1;
        break;                                        // vyskocime z nekonecneho cyklu
      end;
    end;
    2:
    begin
      if (not m_Cells[iNeighbours[2]].Visited) and (iNeighbours[2] <> -1) then    // kdyz soused jeste nebyl navstiven
      begin
        iChosenCell := iNeighbours[2];                // Vybereme ho
        temp := 2;
        break;                                       // vyskocime z nekonecneho cyklu
      end;
    end;
    3:
    begin
      if (not m_Cells[iNeighbours[3]].Visited) and (iNeighbours[3] <> -1) then    // kdyz soused jeste nebyl navstiven
      begin
        iChosenCell := iNeighbours[3];               // Vybereme ho
        temp := 3;
        break;                                       // vyskocime z nekonecneho cyklu
      end;
    end;  // end 3:
    end;  // end case
    end;  // end while

    // pridame soucasnou bunku do stacku
    inc(m_numOfCellsInStack);                        // zvysime pomocnou promenou ktera urcuje velikost dyn. pole stacku
    SetLength(m_iStack, m_numOfCellsInStack);        // nastavime velikost dyn. pole
    m_iStack[m_numOfCellsInStack-1] := iCurrent;     // na posledni misto stacku pridame soucasnou bunku

    // odstranime stenu mezi soucasnou a vybranou bunkou
    m_Cells[iCurrent].Walls[temp].Visible := false;  // stena soucasne bunky
    case temp of
    0: m_Cells[iChosenCell].Walls[2].Visible := false;
    1: m_Cells[iChosenCell].Walls[3].Visible := false;
    2: m_Cells[iChosenCell].Walls[0].Visible := false;
    3: m_Cells[iChosenCell].Walls[1].Visible := false;
    end;

    RecursiveBacktrack(iChosenCell);                 // Rekurze s vybranou bunkou
  end;
end;

end.
 