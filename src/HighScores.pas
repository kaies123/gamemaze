{
 * THighScores class to draw high scores
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

unit HighScores;

interface

uses
  Windows,
  Messages,
  dglOpenGL,
  classes,
  Defines,
  SysUtils,
  Vector3d,
  Keys,
  SceneManager,
  MainMenu,
  TextControls,
  Font,
  BitmapFont,
  OutLineFont,
  FontManager,
  DataFile,
  DialogSystem;

type
  THighScores = class(TScene)
  public
    destructor Destroy();override;     // destruktor
    procedure Initialize(backgroundTexID:GLuint);        // inicializacni fce
    procedure Draw();override;                    // vykreslovaci fce
    procedure ProcessEvent(Keys:TKeys; fps, miliseconds:float);override; // stisky klaves atp.
    procedure Enter(SceneManager:TSceneManager);override;   // vola se kdyz SceneManager zacne tuto scenu vykreslovat
    procedure Leave();override;               // vola se kdyz SceneManager prestane scenu vykreslovat
    class function GetInstance():THighScores;     // class method(c++: static method) ktera ziska instanci tohoto singletonu
  protected
    constructor Create();override;               // konstruktor protected -> jen tak nejde vytvorit instance
  private
    // uloziste pro data o skore
    m_ScoreEasy:array[0..9] of uint32;
    m_ScoreHard:array[0..9] of uint32;

    m_texID:GLuint;        // id textury pozadi

    m_BitFont:TFont;         // bitmapovy font
    m_OLFont:TFont;         // outline font

    m_LabelText:TText3dControl;    // text napisu
  end;

var
  // jelikoz delphi nema (c++: static data tedy napr private: static THighScores* instance; ) tak musime pouzit unit-level promenou :(((
  u_HighScores:THighScores;
implementation

constructor THighScores.Create();
var
  LabelColor:TColor;
  i:int8;
begin
  // nulujeme uloziste dat pro skore
  for i := 0 to 9 do
  begin
    m_ScoreEasy[i] := 0;
    m_ScoreHard[i] := 0;
  end;

  // nastavujeme barvu
  LabelColor.cRed := 0.9;
  LabelColor.cGreen := 0.2;
  LabelColor.cBlue := 0.2;

  inherited Create();       // "dedime" konstruktor

  // vytvarime instance fontu
  m_BitFont := TFontManager.GetInstance().GetFont(TBitmapFont,'Comic Sans MS', -32, FW_HEAVY);
  m_OLFont := TFontManager.GetInstance().GetFont(TOutLineFont,'Comic Sans MS', -10, FW_BOLD);

  // vytvarime instanci napisu predavame outline font, napis, pozici, uhel rotace, vektor rotace a barvu
  m_LabelText := TText3dControl.Create(TOutLineFont(m_OLFont), 'High Scores', TVector3f.Create(0.0, 2.0, -7.0), -20, TVector3f.Create(1.0, 0.0, 0.0), LabelColor);
end;

destructor THighScores.Destroy();
begin
  inherited Destroy();
  m_LabelText.Free();
end;

class function THighScores.GetInstance():THighScores;
begin
  if u_HighScores = nil then                   // kdyz je nase "static" promena nil
  begin                                        // tak
    u_HighScores := THighScores.Create();      // vytvarime instanci
    result := u_HighScores;                    // vratime ji
    exit;
  end
  else                                         // kdyz mame instanci
  begin
    result := u_HighScores;                    // vratime ji
    exit;
  end;
end;

procedure THighScores.Draw();
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

  // vykreslime napisy obtiznost�
  m_BitFont.Print(-0.32, 0.197, -1.0, 'Easy');
  m_BitFont.Print(0.24, 0.197, -1.0, 'Hard');

  // vypis nej. 10 vysledku pro lehkou obt�nost
  m_BitFont.Print(-0.35, 0.12, -1.0, Format('1.   %u', [m_ScoreEasy[0]]));
  m_BitFont.Print(-0.35, 0.07, -1.0, Format('2.   %u', [m_ScoreEasy[1]]));
  m_BitFont.Print(-0.35, 0.02, -1.0, Format('3.   %u', [m_ScoreEasy[2]]));
  m_BitFont.Print(-0.35, -0.03, -1.0, Format('4.   %u', [m_ScoreEasy[3]]));
  m_BitFont.Print(-0.35, -0.08, -1.0, Format('5.   %u', [m_ScoreEasy[4]]));
  m_BitFont.Print(-0.35, -0.13, -1.0, Format('6.   %u', [m_ScoreEasy[5]]));
  m_BitFont.Print(-0.35, -0.17, -1.0, Format('7.   %u', [m_ScoreEasy[6]]));
  m_BitFont.Print(-0.35, -0.22, -1.0, Format('8.   %u', [m_ScoreEasy[7]]));
  m_BitFont.Print(-0.35, -0.27, -1.0, Format('9.   %u', [m_ScoreEasy[8]]));
  m_BitFont.Print(-0.35, -0.32, -1.0, Format('10.  %u', [m_ScoreEasy[9]]));

  // vypis nej. 10 vysledku pro tezkou obt�nost
  m_BitFont.Print(0.21, 0.12, -1.0, Format('1.   %u', [m_ScoreHard[0]]));
  m_BitFont.Print(0.21, 0.07, -1.0, Format('2.   %u', [m_ScoreHard[1]]));
  m_BitFont.Print(0.21, 0.02, -1.0, Format('3.   %u', [m_ScoreHard[2]]));
  m_BitFont.Print(0.21, -0.03, -1.0, Format('4.   %u', [m_ScoreHard[3]]));
  m_BitFont.Print(0.21, -0.08, -1.0, Format('5.   %u', [m_ScoreHard[4]]));
  m_BitFont.Print(0.21, -0.13, -1.0, Format('6.   %u', [m_ScoreHard[5]]));
  m_BitFont.Print(0.21, -0.17, -1.0, Format('7.   %u', [m_ScoreHard[6]]));
  m_BitFont.Print(0.21, -0.22, -1.0, Format('8.   %u', [m_ScoreHard[7]]));
  m_BitFont.Print(0.21, -0.27, -1.0, Format('9.   %u', [m_ScoreHard[8]]));
  m_BitFont.Print(0.21, -0.32, -1.0, Format('10.  %u', [m_ScoreHard[9]]));

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

procedure THighScores.Initialize(backgroundTexID:GLuint);
begin
  m_texID := backgroundTexID;         // naplnime clenskou promenou parametrem
end;

procedure THighScores.ProcessEvent(Keys:TKeys; fps, miliseconds:float);
begin
  if Keys = nil then                    // kdyz jsme nahodou predali do keys nil
    exit;                               // konec

  if Keys.IsPressedOnce(VK_ESCAPE) then      // kdyz se stisklo escape
  begin
    ChangeScene(TMainMenu.GetInstance());  // scenu nastavime na mainmenu
  end;
end;

procedure THighScores.Enter(SceneManager:TSceneManager);
var
  DataFileEasy, DataFileHard:TDataFile;
  filename:string;
  box:TDialogBox;
begin
  inherited Enter(SceneManager);

  { * Nahrajeme highscore pro EASY obtiznost * }

  filename := 'Data\highscoresEasy.dat';     // jmeno souboru
  try
    DataFileEasy := TDataFile.Create(filename);   // otevreme ho
    DataFileEasy.ReadData(@m_ScoreEasy);        // do m_ScoreEasy nacteme data
  except
    on EFileManualyEdited do
    begin
      box := TDialogSystem.GetInstance().AddDialogBox(TDialogBox);
      box.Caption := 'Error';
      box.Text := 'Highscores file was manualy edited and data may be corrupted so highscores was reseted';

      DeleteFile(filename);                    // smazeme soubor
    end;
    on EInvalidFile do
    begin
      box := TDialogSystem.GetInstance().AddDialogBox(TDialogBox);
      box.Caption := 'Error';
      box.Text := 'Highscores file becomes corrupted so highscores was reseted';

      DeleteFile(filename);                    // smazeme soubor
    end;
    on E:EFileCreateError do
    begin
      box := TDialogSystem.GetInstance().AddDialogBox(TDialogBox);
      box.Caption := 'Error';
      box.Text := E.Message;

      DeleteFile(filename);                     // smazeme soubor
    end;
    on E:EReadError do
    begin
      box := TDialogSystem.GetInstance().AddDialogBox(TDialogBox);
      box.Caption := 'Error';
      box.Text := E.Message;

      DeleteFile(filename);                      // smazeme soubor
      DataFileHard.Free();                       // uvolnime ho
    end;
  end;

  { * Nahrajeme highscore pro HARD obtiznost * }

  filename := 'Data\highscoresHard.dat';          // jmeno souboru
  try
    DataFileHard := TDataFile.Create(filename);    // otevreme ho
    DataFileHard.ReadData(@m_ScoreHard);          // nahrajeme do m_ScoreHard data
  except
    on EFileManualyEdited do
    begin
      box := TDialogSystem.GetInstance().AddDialogBox(TDialogBox);
      box.Caption := 'Error';
      box.Text := 'Highscores file was manualy edited and data may be corrupted so highscores was reseted';

      DeleteFile(filename);                    // smazeme soubor
    end;
    on EInvalidFile do
    begin
      box := TDialogSystem.GetInstance().AddDialogBox(TDialogBox);
      box.Caption := 'Error';
      box.Text := 'Highscores file becomes corrupted so highscores was reseted';

      DeleteFile(filename);                    // smazeme soubor
    end;
    on E:EFileCreateError do
    begin
      box := TDialogSystem.GetInstance().AddDialogBox(TDialogBox);
      box.Caption := 'Error';
      box.Text := E.Message;

      DeleteFile(filename);                     // smazeme soubor
    end;
    on E:EReadError do
    begin
      box := TDialogSystem.GetInstance().AddDialogBox(TDialogBox);
      box.Caption := 'Error';
      box.Text := E.Message;

      DeleteFile(filename);                      // smazeme soubor
      DataFileHard.Free();                       // uvolnime ho
    end;
  end;
end;

procedure THighScores.Leave();
begin
end;

end.
