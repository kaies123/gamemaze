{
 * THowToPlayScene class to draw help for players
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

unit HowToPlayScene;

interface

uses
  Windows,
  Messages,
  dglOpenGL,
  Defines,
  Vector3d,
  Keys,
  SceneManager,
  MainMenu,
  TextControls,
  FontManager,
  Font,
  BitmapFont,
  OutLineFont;

type
  THowToPlayScene = class(TScene)
  public
    destructor Destroy();override;     // destruktor
    procedure Initialize(backgroundTexID:GLuint);        // inicializacni fce
    procedure Draw();override;                    // vykreslovaci fce
    procedure ProcessEvent(Keys:TKeys; fps, miliseconds:float);override; // stisky klaves atp.
    procedure Enter(SceneManager:TSceneManager);override;   // vola se kdyz SceneManager zacne tuto scenu vykreslovat
    procedure Leave();override;               // vola se kdyz SceneManager prestane scenu vykreslovat
    class function GetInstance():THowToPlayScene;     // class method(c++: static method) ktera ziska instanci tohoto singletonu
  protected
    constructor Create();override;               // konstruktor protected -> jen tak nejde vytvorit instance
  private
    m_texID:GLuint;        // id textury pozadi

    m_BitFont:TFont;         // bitmapovy font
    m_OLFont:TFont;         // outline font

    m_LabelText:TText3dControl;    // text napisu
  end;

var
  // jelikoz delphi nema (c++: static data tedy napr private: static THowToPlayScene* instance; ) tak musime pouzit unit-level promenou :(((
  u_HowToPlayScene:THowToPlayScene;

implementation

constructor THowToPlayScene.Create();
var
  LabelColor:TColor;
begin
  // nastavujeme barvu
  LabelColor.cRed := 0.9;
  LabelColor.cGreen := 0.2;
  LabelColor.cBlue := 0.2;

  inherited Create();
  m_BitFont := TFontManager.GetInstance().GetFont(TBitmapFont,'Comic Sans MS', -32, FW_HEAVY);
  m_OLFont := TFontManager.GetInstance().GetFont(TOutLineFont,'Comic Sans MS', -10, FW_BOLD);

  // vytvarime instanci napisu predavame outline font, napis, pozici, uhel rotace, vektor rotace a barvu
  m_LabelText := TText3dControl.Create(TOutLineFont(m_OLFont), 'How To Play', TVector3f.Create(0.0, 2.0, -7.0), -20, TVector3f.Create(1.0, 0.0, 0.0), LabelColor);
end;

destructor THowToPlayScene.Destroy();
begin
  inherited Destroy();
  m_LabelText.Free();
end;

class function THowToPlayScene.GetInstance():THowToPlayScene;
begin
  if u_HowToPlayScene = nil then                   // kdyz je nase "static" promena nil
  begin                                        // tak
    u_HowToPlayScene := THowToPlayScene.Create();      // vytvarime instanci
    result := u_HowToPlayScene;                    // vratime ji
    exit;
  end
  else                                         // kdyz mame instanci
  begin
    result := u_HowToPlayScene;                    // vratime ji
    exit;
  end;
end;

procedure THowToPlayScene.Initialize(backgroundTexID:GLuint);
begin
  m_texID := backgroundTexID;         // naplnime clenskou promenou parametrem
end;

procedure THowToPlayScene.Draw();
const
  // konstantni pole pro svetlo
  lightDir:array [0..3] of GLfloat = (0, 0, 1, 0);
  lightDifuse:array [0..3] of GLfloat = (0.8, 0.8, 0.8, 1.0);
  lightAmb:array [0..3] of GLfloat = (0.2, 0.2, 0.2, 1.0);
begin
  glEnable(GL_MULTISAMPLE_ARB);                  // zapiname multisampling

  // nastavime svetlo
  glLightfv(GL_LIGHT1, GL_AMBIENT, @lightAmb);
  glLightfv(GL_LIGHT1, GL_DIFFUSE, @lightDifuse);
  glLightfv(GL_LIGHT1, GL_POSITION, @lightDir);

  glDisable(GL_TEXTURE_2D);           // vypneme texturovani

  glColor4f(1.0, 1.0, 0.0, 1.0);                    // nastavujeme zlutou barvu

  // vypiseme text
  m_BitFont.Print(-0.5, 0.175, -1.0, 'Get out of maze before the time runs out. Sooner you get');
  m_BitFont.Print(-0.5, 0.125, -1.0, 'out you get more score.');

  m_BitFont.Print(-0.5, 0.04, -1.0, 'CONTROLS:');
  m_BitFont.Print(-0.45, -0.01, -1.0, 'Arrow keys:    player move');
  m_BitFont.Print(-0.45, -0.06, -1.0, 'W,S,A,D:      camera move');
  m_BitFont.Print(-0.45, -0.11, -1.0, 'Numeric +, -: camera zoom');
  m_BitFont.Print(-0.45, -0.16, -1.0, 'P:               pause game');
  m_BitFont.Print(-0.45, -0.21, -1.0, 'R:               regenerate level without any penalty');

  { * TEXTURA NA POZAD� *  }
  glEnable(GL_TEXTURE_2D);                       // zapneme texturovani

  glMatrixMode(GL_MODELVIEW);                 // zvolime modelview matici
  glPushMatrix();                             // ulozime ji

  glTranslatef(0.0, 0.0, -24.0);              // posun o 24j do obrazovky

  glColor4f(1, 1, 1, 1);                       // neutralni barva
  glBindTexture(GL_TEXTURE_2D, m_texID);         // zvolime texturu
  // vykreslime otexturovany ctverec priblizne o velikosti obrazovky
  // * Driv jsem pouzival ortogonalni projekci pres glOrtho() ale nejak se mi
  // * pres to nechtel vykreslit bitmapovy font :((((
  glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0); glVertex3f(-13.3, -10.0, 0.0);
    glTexCoord2f(1.0, 0.0); glVertex3f( 13.3, -10.0, 0.0);
    glTexCoord2f(1.0, 1.0); glVertex3f( 13.3, 10.0, 0.0);
    glTexCoord2f(0.0, 1.0); glVertex3f(-13.3, 10.0, 0.0);
  glEnd();

  glMatrixMode(GL_MODELVIEW);                                  // vybereme modelview matici
  glPopMatrix();                                               // nahrajeme ji

  glDisable(GL_TEXTURE_2D);                      // vypneme texturovani

  glEnable(GL_LIGHTING);                         // zapneme svetla

  m_LabelText.Render();                          // vykreslime nadpis

  glDisable(GL_LIGHTING);                        // vypneme svetla

  glDisable(GL_MULTISAMPLE_ARB);                 // vypneme multisampling
end;

procedure THowToPlayScene.ProcessEvent(Keys:TKeys; fps, miliseconds:float);
begin
  if Keys = nil then                    // kdyz jsme nahodou predali do keys nil
    exit;                               // konec

  if Keys.IsPressedOnce(VK_ESCAPE) then      // kdyz se stisklo escape
  begin
    ChangeScene(TMainMenu.GetInstance());  // scenu nastavime na mainmenu
  end;
end;

procedure THowToPlayScene.Enter(SceneManager:TSceneManager);
begin
  inherited Enter(SceneManager);
end;

procedure THowToPlayScene.Leave();
begin
end;

end.
