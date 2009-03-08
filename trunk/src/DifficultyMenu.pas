{
 * TDifficultyMenu class for Difficulty choose
 * Copyright (C) 2009  Jan Dušek <GhostJO@seznam.cz>
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

unit DifficultyMenu;

interface

uses
  windows,
  messages,
  defines,
  dglOpenGL,
  keys,
  TextControls,
  Vector3D,
  IniFiles,
  Classes,
  SceneManager,
  FontManager,
  Font,
  OutLineFont,
  Menu;

type
  TDifficultyMenu = class(TMenu)
  public
    destructor Destroy();override;                // destruktor
    procedure Initialize(backgroundTexID:GLuint);       // inicializacni fce volejte vzdy kdyz vytvarite novy ogl kontext
    procedure Draw();override;                    // vykreslovaci fce
    procedure ProcessEvent(Keys:TKeys; fps, miliseconds:float);override; // stisky klaves atp.
    procedure Enter(SceneManager:TSceneManager);override;   // vola se kdyz SceneManager zacne tuto scenu vykreslovat
    procedure Leave();override;               // vola se kdyz SceneManager prestane scenu vykreslovat
    class function GetInstance():TDifficultyMenu;     // class method(c++: static method) ktera ziska instanci tohoto singletonu
  protected
    constructor Create();override;             // konstruktor protected -> jen tak nejde vytvorit instance
  private
    m_Font:TOutLineFont;

    m_texID:GLuint;                            // ID textury

    m_LabelText:TText3dControl;
    m_ChooseDiffLabel:TText3dControl;
    m_EasyText:TText3dControl;
    m_HardText:TText3dControl;
  end;

var
  // jelikoz delphi nema (c++: static data tedy napr private: static TDifficultyMenu* instance; ) tak musime pouzit unit-level promenou :(((
  u_DifficultyMenu:TDifficultyMenu;
implementation

uses
  MainMenu,
  GameScene;

constructor TDifficultyMenu.Create();
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

  inherited Create();

  m_Font := TOutLineFont(TFontManager.GetInstance().GetFont(TOutLineFont, 'Comic Sans MS', -10, FW_BOLD));

  m_LabelText := TText3dControl.Create(m_Font, 'Maze Game', TVector3f.Create(0.0, 2.0, -7.0), -20, TVector3f.Create(1.0, 0.0, 0.0), LabelColor);
  m_ChooseDiffLabel := TText3dControl.Create(m_Font, 'Choose Difficulty', TVector3f.Create(0.0, 1.2, -12.0), -20, TVector3f.Create(1.0, 0.0, 0.0), MenuColor);
  m_EasyText := TText3dControl.Create(m_Font, 'Easy', TVector3f.Create(0.0, -0.2, -10.0), -22.5, TVector3f.Create(1.0, 0.0, 0.0), MenuColor);
  m_HardText := TText3dControl.Create(m_Font, 'Hard', TVector3f.Create(0.0, -1.2, -10.0), -25, TVector3f.Create(1.0, 0.0, 0.0), MenuColor);

  m_MenuItems.Add(m_EasyText);
  m_MenuItems.Add(m_HardText);

  m_iSelectedItem := 0;
  m_SelectedItem := m_MenuItems.Items[m_iSelectedItem];
end;

destructor TDifficultyMenu.Destroy();
begin
  inherited Destroy();
  m_LabelText.Free();
  m_ChooseDiffLabel.Free();
  m_EasyText.Free();
  m_HardText.Free();
end;

class function TDifficultyMenu.GetInstance():TDifficultyMenu;
begin
  if u_DifficultyMenu = nil then
  begin
    u_DifficultyMenu := TDifficultyMenu.Create();
  end;
  result := u_DifficultyMenu;
end;

procedure TDifficultyMenu.Initialize(backgroundTexID:GLuint);
begin
  m_texID := backgroundTexID;
end;

procedure TDifficultyMenu.Draw();
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
  // vyber obtížnosti
  m_ChooseDiffLabel.Render();
  m_EasyText.Render();
  m_HardText.Render();

  glDisable(GL_LIGHTING);                                      // vypneme svetla
  glDisable(GL_MULTISAMPLE_ARB);                               // vypneme fsaa
end;

procedure TDifficultyMenu.ProcessEvent(Keys:TKeys; fps, miliseconds:float);
begin
  if keys = nil then
    exit;

  if keys.IsPressedOnce(VK_UP) then
  begin
    GoUp();
  end;

  if keys.IsPressedOnce(VK_DOWN) then
  begin
    GoDown();
  end;

  if keys.IsPressedOnce(VK_ESCAPE) then
  begin
    ChangeScene(TMainMenu.GetInstance());
  end;

  if keys.IsPressedOnce(VK_RETURN) then
  begin
    ChangeScene(TGameScene.GetInstance());
  end;

end;

procedure TDifficultyMenu.Enter(SceneManager:TSceneManager);
var
  Ini:TIniFile;
begin
  inherited Enter(SceneManager);                 // udelame to co v TScene.Enter

  Ini := TIniFile.Create('cfg\conf.ini');

  m_iSelectedItem := Ini.ReadInteger('Game', 'Difficulty', 0);
  m_SelectedItem := m_MenuItems[m_iSelectedItem];

  Ini.Free();
end;

procedure TDifficultyMenu.Leave();
var
  Ini:TIniFile;
begin
  Ini := TIniFile.Create('cfg\conf.ini');
  Ini.WriteInteger('Game', 'Difficulty', m_iSelectedItem);
  Ini.Free();
end;

end.
