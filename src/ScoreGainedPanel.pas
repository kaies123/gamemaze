{
 * TScoreGainedPanel class to draw panel which shows gained score after level complete
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

unit ScoreGainedPanel;

interface

uses
  Windows,
  Messages,
  SysUtils,
  defines,
  dglOpenGL,
  FontManager,
  Font,
  BitmapFont;

type

  TScoreGainedPanel = class
  private
    m_BitmapFont:TFont;            // font

    m_texID:GLuint;                      // id textury pozadi

    m_ScoreGained:uint32;                // obsahuje score obdrzene za level
    m_TimeBonus:uint32;                  // bonus za zbyvajici cas
    m_TotalScore:uint32;                 // celkove skore

    fVisible:boolean;                    // indikuje zda bude panel viditelny tj. zda se bude vykreslovat ci nikoliv
  public
    property Visible:boolean read fVisible write fVisible;        // poperty viditelnosti
    procedure Hide();                                             // skryje panel
    procedure Show();overload;                                    // zobrazi panel
    procedure Show(ScoreGained, TimeBonus, TotalScore:uint32);overload;    // zobrazi panel a predame mu hodnoty ktere ma zobrazit
    constructor Create();                                         // konstuktor
    destructor Destroy();override;                                // destruktor
    procedure Initialize(backGroundTexID:GLuint);        // inicializacni procedura vola se vzdy po vytvoreni ogl kontextu nemuze byt v konstruktoru protoze ogl kontext se ztraci napr pri prechodu do fulscreenu
    procedure Draw();                                             // renderovaci fce
  end;

implementation

constructor TScoreGainedPanel.Create();
begin
  m_BitmapFont := TFontManager.GetInstance().GetFont(TBitmapFont,'Visitor TT2 BRK', -34, FW_BOLD);    // vytvarime instanci bitmapoveho fontu

  fVisible := true;                                              // viditelnost nastavime na zacatku na true
  // nulovani clenskych promenych
  m_ScoreGained := 0;
  m_TimeBonus := 0;
  m_TotalScore := 0;
end;

destructor TScoreGainedPanel.Destroy();
begin
  inherited Destroy();
end;

procedure TScoreGainedPanel.Initialize(backGroundTexID:GLuint);
begin
  m_texID := backGroundTexID;                                 // nastavime ID textury pozadi
end;

procedure TScoreGainedPanel.Hide();
begin
  fVisible := false;                                          // visible na false
end;

procedure TScoreGainedPanel.Show();
begin
  fVisible := true;                                          // visible na true
end;

procedure TScoreGainedPanel.Show(ScoreGained, TimeBonus, TotalScore:uint32);
begin
  // nastavime nase promene
  m_ScoreGained := ScoreGained;
  m_TimeBonus := TimeBonus;
  m_TotalScore := TotalScore;
  fVisible := true;
end;

procedure TScoreGainedPanel.Draw();
begin
  if fVisible then                      // kdyz ma byt panel viditelny
  begin                                 // vykreslime ho
    glMatrixMode(GL_MODELVIEW);         // zvolime medelview matic
    glPushMatrix();                     // ulozime ji

    glLoadIdentity();                   // nahrajeme jednotkovou matici

    // pro jistotu
    glDisable(GL_TEXTURE_2D);           // vypneme texturovani
    glDisable(GL_LIGHTING);             // a svetla

    glColor4f(0.2, 0.2, 0.2, 1.0);      // barva do cerna
    m_BitmapFont.Print(-0.27, 0.22, -1.0, 'CONGRATULATIONS LEVEL COMPLETE!!!');    // nadpis

    m_BitmapFont.Print(-0.40, 0.12, -1.0, Format('Score Gained:     %u', [m_ScoreGained]));  // skore obdrzene za level
    m_BitmapFont.Print(-0.40, 0.04, -1.0, Format('Time Bonus:     %u',[m_TimeBonus]));       // skore obdrzene za zbyvajici cas
    m_BitmapFont.Print(-0.40, -0.04, -1.0, Format('Total Score Gained:      %u',[m_ScoreGained + m_TimeBonus]));       // celkove obdrzene skore
    m_BitmapFont.Print(-0.20, -0.15, -1.0, Format('Total Score:     %u',[m_TotalScore]));     // celkove skore

    m_BitmapFont.Print(0.0, -0.22, -1.0, 'Press ENTER to continue...');   // informace pro uzivatele aby stiskl enter

    glTranslatef(0.0, 0.0, -3.0);       // posun o 3j do obrazovky
    glEnable(GL_TEXTURE_2D);            // zapneme texturovani

    glAlphaFunc(GL_GREATER, 0.5);// Nastaven� alfa testingu: zobrazi se jen ty pixely ktera maji alfu vetsi nez 0.5 textura je totiz 32bit tga obrazek s alfou na krajich 0.0 a tim ho orizneme od bilych okraju
    glEnable(GL_ALPHA_TEST);// Zapne alfa testing

    glBindTexture(GL_TEXTURE_2D, m_texID);     // zvolime texturu
    glColor4f(1.0, 1.0, 1.0, 1.0);             // neutralni barva
    glBegin(GL_QUADS);                         // kresleni ctvercu
      glTexCoord2f(1.0, 0.0); glVertex3f(1.5, -1.0, 0.0);       // pravy dolni
      glTexCoord2f(1.0, 1.0); glVertex3f(1.5, 1.0, 0.0);        // pravy horni
      glTexCoord2f(0.0, 1.0); glVertex3f(-1.5, 1.0, 0.0);       // levy horni
      glTexCoord2f(0.0, 0.0); glVertex3f(-1.5, -1.0, 0.0);      // levy dolni
    glEnd();                                   // konec kresleni

    glDisable(GL_ALPHA_TEST);                  // vypiname alfa testing

    glMatrixMode(GL_MODELVIEW);                // zvolime modelview matici
    glPopMatrix();                             // nahrajeme ji
  end;
end;

end.
