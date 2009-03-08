{
 * TVector3f class for mathematical 3 dimensional vector
 *
 * original CVector<> template class by Michal Turek
 *    ToCartesian method by Jan Dušek
 *
 *    ported from c++ to Delphi by: Jan Dušek
 *
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

unit Vector3D;

interface

uses
  defines;

type
  TVector3f = class
  private
    m_x:float;
    m_y:float;
    m_z:float;
    procedure SetX(x:float);
    procedure SetY(y:float);
    procedure SetZ(z:float);

    function GetX():float;
    function GetY():float;
    function GetZ():float;
  public
    constructor Create();overload;
    constructor Create(x,y,z:float); overload;
    constructor Create(const v:TVector3f);overload;
    // vektor jde utvorit ze dvou bodu
    constructor Create(const startPoint,endPoint:TVector3f);overload;
    destructor Destroy();override;

    procedure SetCoords(x:float=0; y:float=0; z:float=0);
    procedure GetCoords(var x,y,z:float);

    function IsZero():boolean;

    // skalarni soucin
    function Dot(const v:TVector3f):float;

    // vektorovy soucin ze 2 vektoru
    function Cross(const v:TVector3f):TVector3f; overload;
    // vektorovy soucin ze 3 bodu
    function Cross(const p1,p2:TVector3f):TVector3f; overload;

    // inverzni vektor
    function Invert():TVector3f;

    // velikost
    function Magnitude():float;
    // normalizace
    function Normalize():TVector3f;

    // vzdalenost 2 bodu
    function Distance(const v:TVector3f):double;

    // ze sferickych souradnic do kartezskych
    procedure ToCartesian(r, zenith, azimuth:float);

    // Delphi neumi pretezovat operatory(free pascal to umi :((( ) takze pouzijeme fce
    function Plus(const v:TVector3f):TVector3f;       // priklad: v.Plus(u) == v + u
    function Minus(const v:TVector3f):TVector3f;

    function Multiply(n:float):TVector3f;
    function Divide(n:float):TVector3f;

    property X:float read GetX write SetX;
    property Y:float read GetY write SetY;
    property Z:float read GetZ write SetZ;
  end;

implementation

// bezparametricky konstruktor
constructor TVector3f.Create();
begin
  m_x := 0;
  m_y := 0;
  m_z := 0;
end;

// vector z kartezskych souradnic
constructor TVector3f.Create(x,y,z:float);
begin
  m_x := x;
  m_y := y;
  m_z := z;
end;

// vector z jíneho vectoru(c++: kopirovaci konstruktor)
constructor TVector3f.Create(const v:TVector3f);
begin
  m_x := v.m_x;
  m_y := v.m_y;
  m_z := v.m_z;
end;

// vector ze dvou bodu
constructor TVector3f.Create(const startPoint, endPoint:TVector3f);
begin
  m_x := endPoint.m_x - startPoint.m_x;
  m_y := endPoint.m_y - startPoint.m_y;
  m_z := endPoint.m_z - startPoint.m_z;
end;

// destruktor
destructor TVector3f.Destroy();
begin
  inherited Destroy();
end;

// nastavi souradnice v jedne metode(defautni hodnoty 0)
procedure TVector3f.SetCoords(x:float=0; y:float=0; z:float=0 );
begin
  m_x := x;
  m_y := y;
  m_z := z;
end;

procedure TVector3f.GetCoords(var x,y,z:float);
begin
  x := m_x;
  y := m_y;
  z := m_z;
end;

procedure TVector3f.SetX(x:float);
begin
  m_x := x;
end;

procedure TVector3f.SetY(y:float);
begin
  m_y := y;
end;

procedure TVector3f.SetZ(z:float);
begin
  m_z := z;
end;

function TVector3f.GetX():float;
begin
  result := m_x;
end;

function TVector3f.GetY():float;
begin
  result := m_y;
end;

function TVector3f.GetZ():float;
begin
  result := m_z;
end;

// vrati zda je vector nulovy
function TVector3f.IsZero():boolean;
begin
  if (m_x=0) and (m_y=0) and (m_z=0) then
  begin
    result:=true;
    exit;
  end
  else
  begin
    result := false;
  end;
end;

// skalarni soucin
function TVector3f.Dot(const v:TVector3f):float;
begin
  result := m_x*v.m_x + m_y*v.m_y + m_z*v.m_z;
end;

// vektorovy soucin ze 2 vektoru
function TVector3f.Cross(const v:TVector3f):TVector3f;
begin
  result := TVector3f.Create();

  result.m_x := m_y*v.m_z - m_z*v.m_y;
  result.m_y := m_z*v.m_x - m_x*v.m_z;
  result.m_z := m_x*v.m_y - m_y*v.m_x;
end;

// vektorovy soucin ze 3 bodu
function TVector3f.Cross(const p1,p2:TVector3f):TVector3f;
var
  v1,v2:TVector3f;        // pomocne vektory
begin
  v1 := TVector3f.Create(self, p1);
  v2 := TVector3f.Create(self, p2);
  result := v1.Cross(v2);
end;

// vrati opacny vektor
function TVector3f.Invert():TVector3f;
begin
  result := TVector3f.Create(-self.m_x, -self.m_y, -self.m_z);
end;

// spocita velikost vektoru
function TVector3f.Magnitude():float;
begin
  result := sqrt(m_x*m_x + m_y*m_y + m_z*m_z);      // pythagorova veta
end;

// normalizace vektoru -> vektor se stane jednotkovym
function TVector3f.Normalize():TVector3f;
begin
  result := self.Divide(self.Magnitude());
end;

// vzdalenost dvou bodu
function TVector3f.Distance(const v:TVector3f):double;
begin
  result := sqrt((m_x - v.m_x)*(m_x - v.m_x) + (m_y - v.m_y)*(m_y - v.m_y) + (m_z - v.m_z)*(m_z - v.m_z));
end;

// z danych sferickych souradnic vytvori kartezske
procedure TVector3f.ToCartesian(r, zenith, azimuth:float);
begin
  m_x := r*sin(zenith)*sin(azimuth);
  m_y := r*sin(zenith)*cos(azimuth);
  m_z := r*cos(zenith);
end;

function TVector3f.Plus(const v:TVector3f):TVector3f;
begin
  result := TVector3f.Create(m_x+v.m_x, m_y+v.m_y, m_z+v.m_z);
end;

function TVector3f.Minus(const v:TVector3f):TVector3f;
begin
  result := TVector3f.Create(m_x-v.m_x, m_y-v.m_y, m_z-v.m_z);
end;

function TVector3f.Multiply(n:float):TVector3f;
begin
  result := TVector3f.Create(m_x*n, m_y*n, m_z*n);
end;

function TVector3f.Divide(n:float):TVector3f;
begin
  result := TVector3f.Create(self);
  if n<>0 then
  begin
    result.SetCoords(m_x/n, m_y/n, m_z/n);
  end;
end;

end.
