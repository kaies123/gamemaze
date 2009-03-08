{
 * TMainMenu class for Main menu
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

unit MainMenu;

interface

uses
  Windows,
  Messages,
  dglOpenGl,
  Keys,
  OutLineFont,
  SceneManager,
  TextControls,
  Vector3D,
  defines,
  IniFiles,
  Classes,
  FontManager,
  Menu;

type
  // singleton
  TMainMenu = class(TMenu)
  public
    destructor Destroy();override;                // destruktor
    procedure Initialize(hWnd:HWND; backgroundTexID:GLuint);       // inicializacni fce volejte vzdy kdyz vytvarite novy ogl kontext
    procedure Draw();override;                    // vykreslovaci fce
    procedure ProcessEvent(Keys:TKeys; fps, miliseconds:float);override; // stisky klaves atp.
    procedure Enter(SceneManager:TSceneManager);override;   // vola se kdyz SceneManager zacne tuto scenu vykreslovat
    procedure Leave();override;               // vola se kdyz SceneManager prestane scenu vykreslovat
    class function GetInstance():TMainMenu;     // class method(c++: static method) ktera ziska instanci tohoto singletonu
  protected
    constructor Create();override;             // konstruktor protected -> jen tak nejde vytvorit instance
  private
    m_Font:TOutLineFont;

    m_texID:GLuint;                            // ID textury

    // texty v menu
    m_LabelText:TText3dControl;
    m_StartGameText:TText3dControl;
    m_HighScoreText:TText3dControl;
    m_HowToText:TText3dControl;
    m_ExitGameText:TText3dControl;

    m_hWnd:HWND;                               // handle okna aby jsme mu pak mohli poslat zpravu na ukonceni
  end;

var
  // jelikoz delphi nema (c++: static data tedy napr private: static TMainMenu* instance; ) tak musime pouzit unit-level promenou :((( 
  u_MainMenu:TMainMenu;  
implementation

uses
  DifficultyMenu,
  HighScores,
  HowToPlayScene;

constructor TMainMenu.Create();
var
  LabelColor,MenuColor:TColor;
begin
  // nastavime lokalni promene barev
  LabelColor.cRed := 0.9;
  LabelColor.cGreen := 0.2;
  LabelColor.cBlue := 0.2;

  MenuColor.cRed := 0.4;
  MenuColor.cGreen := 0.8;
  MenuColor.cBlue := 0.2;

  inherited Create();                                           // "dìdíme konstruktor"
  m_Font := TOutLineFont(TFontManager.GetInstance().GetFont(TOutLineFont, 'Comic Sans MS', -10, FW_BOLD));

  // vytvarime instance menu itemù
  m_LabelText := TText3dControl.Create(m_Font, 'Maze Game', TVector3f.Create(0.0, 2.0, -7.0), -20, TVector3f.Create(1.0, 0.0, 0.0), LabelColor);
  m_StartGameText := TText3dControl.Create(m_Font, 'New Game', TVector3f.Create(0.0, 1.1, -10.0), -20, TVector3f.Create(1.0, 0.0, 0.0), MenuColor);
  m_HighScoreText := TText3dControl.Create(m_Font, 'High Score', TVector3f.Create(0.0, 0.1, -10.0), -22.5, TVector3f.Create(1.0, 0.0, 0.0), MenuColor);
  m_HowToText := TText3dControl.Create(m_Font, 'How To Play', TVector3f.Create(0.0, -0.9, -10.0), -25, TVector3f.Create(1.0, 0.0, 0.0), MenuColor);
  m_ExitGameText := TText3dControl.Create(m_Font, 'Exit Game', TVector3f.Create(0.0, -1.9, -10.0), -30, TVector3f.Create(1.0, 0.0, 0.0), MenuColor);

  m_MenuItems.Add(m_StartGameText);
  m_MenuItems.Add(m_HighScoreText);
  m_MenuItems.Add(m_HowToText);
  m_MenuItems.Add(m_ExitGameText);

  m_iSelectedItem := 0;
  m_SelectedItem := m_MenuItems.Items[m_iSelectedItem];
end;

destructor TMainMenu.Destroy();
begin
  inherited Destroy();
  // uvolnujeme instance
  m_LabelText.Free();
  m_StartGameText.Free();
  m_HighScoreText.Free();
  m_HowToText.Free();
  m_ExitGameText.Free();
end;

procedure TMainMenu.Initialize(hWnd:HWND; backgroundTexID:GLuint);
begin
  m_hWnd := hWnd;           // nastavime clenskou promenou
  m_texID := backgroundTexID;
end;

class function TMainMenu.GetInstance():TMainMenu;
begin
  if u_MainMenu = nil then                         // kdyz nase staticka promene este nebyla vytvorena( pointer na nic neukazuje)
  begin
    u_MainMenu := TMainMenu.Create();              // vytvorime instanci
    result := u_MainMenu;                          // vratime ji
    exit;
  end
  else                                             // instance jiz byla vytvorena
  begin
    result := u_MainMenu;                          // vratime ji
    exit;
  end;
end;

procedure TMainMenu.Draw();
const
  // konstantni pole pro svetlo
  lightDir:array [0..3] of GLfloat = (0, 0, 1, 0);
  lightDifuse:array [0..3] of GLfloat = (0.8, 0.8, 0.8, 1.0);
  lightAmb:array [0..3] of GLfloat = (0.2, 0.2, 0.2, 1.0);
begin
  glEnable(GL_MULTISAMPLE_ARB);                               // zapneme fsaa

  // nastavime svetlo
  glLightfv(GL_LIGHT1, GL_AMBIENT, @lightAmb);
  glLightfv(GL_LIGHT1, GL_DIFFUSE, @lightDifuse);
  glLightfv(GL_LIGHT1, GL_POSITION, @lightDir);

  { * TEXTURA NA POZADÍ *  }
  glEnable(GL_TEXTURE_2D);                       // zapneme texturovani

  glMatrixMode(GL_MODELVIEW);                 // zvolime modelview matici
  glPushMatrix();                             // ulozime ji

  glTranslatef(0.0, 0.0, -24.0);

  glColor4f(1, 1, 1, 1);
  glBindTexture(GL_TEXTURE_2D, m_texID);         // zvolime texturu
  glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0); glVertex3f(-13.3, -10.0, 0.0);
    glTexCoord2f(1.0, 0.0); glVertex3f( 13.3, -10.0, 0.0);
    glTexCoord2f(1.0, 1.0); glVertex3f( 13.3, 10.0, 0.0);
    glTexCoord2f(0.0, 1.0); glVertex3f(-13.3, 10.0, 0.0);
  glEnd();

  glMatrixMode(GL_MODELVIEW);                                  // vybereme modelview matici
  glPopMatrix();                                               // nahrajeme ji

  glDisable(GL_TEXTURE_2D);                      // vypneme texturovani


  glEnable(GL_LIGHTING);                      // zapneme svetla

  m_SelectedItem.Position.Z := -8.0;         // timto vybrana bunka "vystoupi" nahoru

  // napis
  m_LabelText.Render();

  // polozka start hry
  m_StartGameText.Render();

  // polozka high score
  m_HighScoreText.Render();

  // polozka options
  m_HowToText.Render();

  // polozka exit
  m_ExitGameText.Render();

  glDisable(GL_LIGHTING);                                      // vypneme svetla
  glDisable(GL_MULTISAMPLE_ARB);                               // vypneme fsaa
end;

procedure TMainMenu.ProcessEvent(Keys:TKeys; fps, miliseconds:float);
begin
  if Keys = nil then                              // kdyz pointer nikam neukazuje(instance nebyla vytvorena)
    exit;                                         // konec

  if keys.IsPressedOnce(VK_UP) then
  begin
    GoUp();
  end;

  if keys.IsPressedOnce(VK_DOWN) then
  begin
    GoDown();
  end;

  if keys.IsPressedOnce(VK_RETURN) then
  begin
    case m_iSelectedItem of
      0:ChangeScene(TDifficultyMenu.GetInstance());// pokud bylo vybrano StartGame tak vyvolame volbu obtiznosti
      1:ChangeScene(THighScores.GetInstance());// pokud bylo vybrano HighScores tak vymenime scenu na HighScores
      2:ChangeScene(THowToPlayScene.GetInstance());// pokud bylo vybrano How To Play tak vymenime scenu na HowToPlayScene
      3:PostMessage(m_hWnd, WM_CLOSE, 0, 0); // kdyz bylo vybrano ExitGame tak posleme oknu zpravu WM_CLOSE, TApplication na ni zareaguje ukoncenim aplikace
    end;                                 // end case
  end;                                   // end if
end;          // end procedure

procedure TMainMenu.Enter(SceneManager:TSceneManager);
begin
  inherited Enter(SceneManager);                 // udelame to co v TScene.Enter
end;

procedure TMainMenu.Leave();
begin
end;

end.
