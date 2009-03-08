{
 * 3d Text control used in menu
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

unit TextControls;

interface

uses
  Windows,
  Messages,
  dglOpenGL,
  OutLineFont,
  Vector3D,
  Defines;

type
  TText3dControl = class
  private
    m_Font:TOutLineFont;

    fCaption:string;
    fPosition:TVector3f;
    fRotationAngle:float;
    fRotationVector:TVector3f;
    fColor:TColor;
    fVisible:boolean;
  public
    // pretizene konstruktory
    constructor Create(Font:TOutLineFont);overload;
    constructor Create(Font:TOutLineFont; Caption:string; Position:TVector3f);overload;
    constructor Create(Font:TOutLineFont; Caption:string; Position:TVector3f; RotatingAngle:float; RotatingVector:TVector3f);overload;
    constructor Create(Font:TOutLineFont; Caption:string; Position:TVector3f; RotatingAngle:float; RotatingVector:TVector3f; Color:TColor);overload;
    destructor Destroy();override;                     // destruktor
    procedure Render();                                // vykresleni
    procedure SetColor(red,green,blue:float);         // nastavi barvu
    procedure Hide();                                 // visible := false
    procedure Show();                                 // visible := true

    // properties
    property Caption:string read fCaption write fCaption;
    property Position:TVector3f read fPosition write fPosition;
    property RotationAngle:float read fRotationAngle write fRotationAngle;
    property RotationVector:TVector3f read fRotationVector write fRotationVector;
    property Color:TColor read fColor write fColor;
    property Visible:boolean read fVisible write fVisible;
  end;

implementation

constructor TText3dControl.Create(Font:TOutLineFont);
begin
  m_Font := Font;                                // nastavime font

  // nastavime fields pro properties
  fCaption := '';
  fPosition := TVector3f.Create();
  fRotationAngle := 0;
  fRotationVector := TVector3f.Create();

  fColor.cRed := 1.0;
  fColor.cGreen := 1.0;
  fColor.cBlue := 1.0;

  fVisible := true;
end;

constructor TText3dControl.Create(Font:TOutLineFont; Caption:string; Position:TVector3f);
begin
  m_Font := Font;

  fCaption := Caption;
  fPosition := Position;
  fRotationAngle := 0;
  fRotationVector := TVector3f.Create();

  fColor.cRed := 1.0;
  fColor.cGreen := 1.0;
  fColor.cBlue := 1.0;

  fVisible := true;
end;

constructor TText3dControl.Create(Font:TOutLineFont; Caption:string; Position:TVector3f; RotatingAngle:float; RotatingVector:TVector3f);
begin
  m_Font := Font;

  fCaption := Caption;
  fPosition := Position;
  fRotationAngle := RotatingAngle;
  fRotationVector := RotatingVector;

  fColor.cRed := 1.0;
  fColor.cGreen := 1.0;
  fColor.cBlue := 1.0;

  fVisible := true;
end;

constructor TText3dControl.Create(Font:TOutLineFont; Caption:string; Position:TVector3f; RotatingAngle:float; RotatingVector:TVector3f; Color:TColor);
begin
  m_Font := Font;

  fCaption := Caption;
  fPosition := Position;
  fRotationAngle := RotatingAngle;
  fRotationVector := RotatingVector;

  fColor := Color;
  
  fVisible := true;
end;

destructor TText3dControl.Destroy();
begin
  inherited Destroy();
  // uvolnime instance vektoru pozice a rotace
  fPosition.Free();
  fRotationVector.Free();
end;

procedure TText3dControl.Hide();
begin
  fVisible := false;
end;

procedure TText3dControl.Show();
begin
  fVisible := true;
end;

procedure TText3dControl.Render();
var
  text, mateColor:boolean;
begin
  if fVisible then
  begin
    // ulozime si do pom. promenych zda je zapnuto texturovani a vybarvovani materialu
    text := glIsEnabled(GL_TEXTURE_2D);
    mateColor := glIsEnabled(GL_COLOR_MATERIAL);

    // bez vypleho texturovani a zapleho vybarvovani materialu by glColor() nemelo zadny efekt
    glDisable(GL_TEXTURE_2D);
    glEnable(GL_COLOR_MATERIAL);

    glMatrixMode(GL_MODELVIEW);                 // zvolime modelview matici
    glPushMatrix();                             // ulozime ji

    // posun a rotace podle ulozenych clenskych promenych
    glTranslatef(fPosition.X, fPosition.Y, fPosition.Z);
    glRotatef(fRotationAngle, fRotationVector.X, fRotationVector.Y, fRotationVector.Z);

    glColor3f(fColor.cRed, fColor.cGreen, fColor.cBlue);         // barva
    m_Font.Print(fCaption);                                      // vykreslime text

    glMatrixMode(GL_MODELVIEW);                                  // vybereme modelview matici
    glPopMatrix();                                               // nahrajeme ji

    // pokud pred zacatkem teto fce nebylo zapnuto vybarvovani materialu
    if not mateColor then
      glDisable(GL_COLOR_MATERIAL);         // tak ho vypneme

    // pokud pred zacatkem teto fce bylo zapnuto texturovani
    if text then
      glEnable(GL_TEXTURE_2D);              // tak ho zapneme
  end;
end;

procedure TText3dControl.SetColor(red,green,blue:float);
begin
  // nastavime barvu podle parametru
  fColor.cRed := red;
  fColor.cGreen := green;
  fColor.cBlue := blue;
end;

end.
