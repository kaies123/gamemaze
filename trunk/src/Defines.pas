{
 * Some helpful constants and types
 * Copyright (C) 2008  Jan Duöek <GhostJO@seznam.cz>
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

unit Defines;

interface

uses
  Windows,
  Messages,
  dglOpenGL;

const
  CellSize = 1;                                         // velikost bunky bludiste v ogl jednotkach
  MAZE_START_SIZE = 30;                                 // kolik bunek bude ve ctvercovem bludisti ze zacatku
  MAZE_WALL_HEIGHT = 0.5;                              // vyska sten 3d bludiste
  MAZE_WALL_WIDTH = 0.15;                                // sirka sten 3d bludiste

  SCORE_BY_LEVEL_MULTIPLIER = 500;
  SCORE_BY_TIMELEFT_MULTIPLIER = 10;
  
type
  // nvm proc je tohle tady zrejme nejaky rozmar kdyz me to neslo
  // a naivne jsem doufam ze kdyz typedefnu pole tak to neslo ale ted to jde a slo by to i bez toho
  boolKeyArray = array [0..255] of boolean;

  float = single;
  int = Integer;
  uint = Cardinal;
  int32 = Integer;
  int16 = Smallint;
  int8 = ShortInt;
  uint32 = Cardinal;
  uint16 = Word;
  uint8 = Byte;

  TextureImage = record             // Struktura textury
    imageData: pointer;             // Data obrazku
    bpp: GLuint;                    // Barevna hloubka obrazku
    width: GLuint;                  // Sirka obrﬂzku
    height: GLuint;                 // Vyska obrﬂzku
    textID: GLuint;                 // Vytvorena textura
    end;

  TColor = record
    cRed:float;
    cGreen:float;
    cBlue:float;
  end;

  TDifficulty = (Easy, Hard);

  // struktury pro bludiste

  // vertex ma 3 souradnice
  Vertex = record
    x:float;
    y:float;
    z:float;
  end;

  TexCoord = record
    s:float;
    t:float;  
  end;

  // stena
  Wall = record
    Position:Vertex;                    // pozice
    Visible:boolean;                    // zda je viditelna
  end;

  // bunka bludiste
  Cell = record
    Walls:array [0..3] of Wall;         // ma 4 steny
    Visited:boolean;                    // pro algoritmus(recursive backtracker) zda byla jiz navstivena
  end;
  TCells = array of Cell;
  PCells = ^TCells;

  Puint32 = ^uint32;

  PCREATESTRUCT = ^CREATESTRUCT;

implementation

end.
