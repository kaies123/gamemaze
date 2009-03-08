{
 * TGameScene singleton class to draw main game scene
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

unit GameScene;

interface

uses
  Windows,
  Messages,
  SysUtils,
  classes,
  dglOpenGL,
  defines,
  Vector3d,
  SceneManager,
  MainMenu,
  Player,
  Camera,
  Maze,
  ScoreGainedPanel,
  FontManager,
  Font,
  OutLineFont,
  BitmapFont,
  TextControls,
  DataFile,
  IniFiles,
  Keys,
  DialogSystem;

type
  TGameLevel = class
  private
    fNumber:uint32;            // cislo levelu
    fMazeSize:uint32;          // velikost bludiste
    fDifficulty:TDifficulty;   // obtížnost(easy || hard)
    m_Maze:TMaze;              // pointer na bludiste

    fScore:uint32;             // skore
    fTimeLeft:float;           // zbyvajici cas
  public
    constructor Create(Maze:TMaze; Difficulty:TDifficulty = Easy);         // konstruktor
    procedure Reset();                      // resetujeme hru
    procedure Next();                       // postup do dalsiho levelu
    property Difficulty:TDifficulty read fDifficulty write fDifficulty;
    property MazeSize:uint32 read fMazeSize;      // property velikosti bludiste
    property Number:uint32 read fNumber;          // property cisla levelu
    property Score:uint32 read fScore write fScore;     // property skore
    property TimeLeft:float read fTimeLeft write fTimeLeft;     // property zbyvajiciho casu
  end;

  TGameScene = class(TScene)              // dedime z TScene(abstraktni trida)
  public
    destructor Destroy();override;                     // destruktor
    procedure Initialize(wallTexID, terrainTexID, ScorePanelTexID, backgroundTexID:GLuint);       // inicializace tj. nastaveni textur a handle Device kvuli fontum
    procedure Deinitialize();
    procedure Draw();override;               // vykreslovaci fce
    procedure ProcessEvent(Keys:TKeys; fps, miliseconds:float);override; // stisky klaves atp.
    procedure Enter(SceneManager:TSceneManager);override;   // vola se kdyz SceneManager zacne tuto scenu vykreslovat
    procedure Leave();override;               // vola se kdyz SceneManager prestane scenu vykreslovat
    class function GetInstance():TGameScene;  // class method(c++: static method) ktera ziska instanci tohoto singletonu
  protected
    constructor Create();override;            // konstruktor protected -> jen tak nejde vytvorit instance
  private
    m_Maze:TMaze;                             // bludiste
    m_Font:TFont;                       // Bitmap font
    m_OLFont:TFont;                    // outline font

    m_GameLevel:TGameLevel;                   // gamelevel ovlada nastaveni bludiste skore atd.

    m_GameOverText:TText3dControl;            // text ktery se zobrazi kdyz skonci hra
    m_HighScoreInfoText:TText3dControl;       // text po skonceni hry ktery bude informovat o tom zda se hrac dostal do highscores

    m_PausedText:TText3dControl;              // text ktery se zobrazi kdyz zapauzujeme hru

    m_ScoreGainedPanel:TScoreGainedPanel;

    m_texID:GLuint;                   // ID textury pozadi

    procedure SaveScore();
    function GetScoreEstimatedPos(Data:array of uint32):int8;
  end;

var
  // jelikoz delphi nema (c++: static data tedy napr private: static TGameScene* instance; ) tak musime pouzit unit-level promenou :(((
  u_GameScene:TGameScene;
  
implementation

constructor TGameLevel.Create(Maze:TMaze; Difficulty:TDifficulty = Easy);
begin
  // nastaveni promenych
  m_Maze := Maze;
  fDifficulty := Difficulty;
  fNumber := 1;      // prvni level
  fMazeSize := MAZE_START_SIZE;       // velikost zacina na 30 bunkach
  fTimeLeft := 120;                   // cas zacina na 2min
  fScore := 0;                        // skore je zezacatku pochopitelne 0
end;

procedure TGameLevel.Reset();
begin
  fNumber := 1;      // prvni level
  fMazeSize := MAZE_START_SIZE;   // velikost zacina na 30 bunkach
  m_Maze.Build(fMazeSize, fMazeSize, fDifficulty);      // znovuvytvorime bludiste o pacatecni velikosti
  fTimeLeft := 120;                        // cas zacina na 2min
  fScore := 0;                             // skore je zezacatku pochopitelne 0
end;

procedure TGameLevel.Next();
begin
  // vypocteme skore
  fScore := fScore + fNumber * SCORE_BY_LEVEL_MULTIPLIER + round(fTimeLeft) * SCORE_BY_TIMELEFT_MULTIPLIER;

  fNumber := fNumber +1;      // dalsi level
  fMazeSize := fMazeSize +2;  // pocet bunek zvetsime o 2
  fTimeLeft := 120 + (fNumber-1)*20;     // cas na level zvetsime o 20sec
  m_Maze.Build(fMazeSize, fMazeSize, fDifficulty);    // znovuvytvorime bludiste
end;

constructor TGameScene.Create();
var
  Color:TColor;
  Ini:TIniFile;
  Difficulty:TDifficulty;
begin
  // z ini souboru si precteme obtiznost
  Ini := TIniFile.Create('cfg\conf.ini');
  Difficulty := TDifficulty(Ini.ReadInteger('Game', 'Difficulty', ord(Easy)));
  Ini.Free();

  // nastavime barvu pro textcontrols
  Color.cRed := 0.8;
  Color.cGreen := 0.8;
  Color.cBlue := 0.2;

  m_Maze := TMaze.Create(Difficulty);                  // vytvarime instanci bludiste
  m_GameLevel := TGameLevel.Create(m_Maze, Difficulty); // vytvarime instanci gamelevelu a passujeme bludiste
  
  m_Font := TFontManager.GetInstance().GetFont(TBitmapFont,'Visitor TT2 BRK', -25, FW_NORMAL);      // vytvarime font z 2d textury
  m_OLFont := TFontManager.GetInstance().GetFont(TOutLineFont,'Angelina', -12, FW_NORMAL);            // vytvarime outlinefont pro textcontrols

  m_ScoreGainedPanel := TScoreGainedPanel.Create();    // vytvarime panel kde se bude zobrazovat obdrzene skore za level
  m_ScoreGainedPanel.Hide();                           // ze zacatku bude skryty

  // vytvarime textcontrols predavame font, text co na nich bude napsan, pozici, uhel rotace, vektor rotace a barvu dale budou ze zacatku neviditelne
  m_GameOverText := TText3dControl.Create(TOutLineFont(m_OLFont), 'Game Over', TVector3f.Create(0.0, 0.3, -4.0), -20, TVector3f.Create(1.0, 0.0, 0.0), Color);
  m_GameOverText.Hide();
  m_HighScoreInfoText := TText3dControl.Create(TOutLineFont(m_OLFont), 'Sorry your score is too low to get into highscores', TVector3f.Create(0.0, -1.0, -14.0), -20, TVector3f.Create(1.0, 0.0, 0.0), Color);
  m_HighScoreInfoText.Hide();
  m_PausedText := TText3dControl.Create(TOutLineFont(m_OLFont), 'Pause', TVector3f.Create(0.0, 0.0, -4.0), -20, TVector3f.Create(1.0, 0.0, 0.0), Color);
  m_PausedText.Hide();
end;

destructor TGameScene.Destroy();
begin
  inherited Destroy();
  // uvolnujeme instance trid
  m_GameLevel.Free();
  m_Maze.Free();
  m_GameOverText.Free();
  m_PausedText.Free();
  m_HighScoreInfoText.Free();
  m_ScoreGainedPanel.Free();
end;

class function TGameScene.GetInstance():TGameScene;      // class fce vracejici instanci tohoto singletonu
begin
  if u_GameScene = nil then                              // kdyz je instance nil
  begin
    u_GameScene := TGameScene.Create();                  // vytvorime ji
    result := u_GameScene;                               // vratime ji
    exit;
  end
  else                                                   // kdyz neni nil
  begin
    result := u_GameScene;                               // vratime ji
    exit;
  end;
end;

procedure TGameScene.Initialize(wallTexID, terrainTexID, ScorePanelTexID, backgroundTexID:GLuint);
begin
  m_texID := backgroundTexID;
  m_Maze.Initialize(wallTexID, terrainTexID);     // do bludiste predame textury
  m_ScoreGainedPanel.Initialize(ScorePanelTexID);     // panel pro skore predavame hDC pro bitmap font a texturu pozadi
end;

procedure TGameScene.Deinitialize();
begin
  m_Maze.Deinitialize();
end;

procedure TGameScene.Draw();
const
  // konstantni pole pro svetlo
  lightDir:array [0..3] of GLfloat = (0, 0, 1, 0);
  lightDifuse:array [0..3] of GLfloat = (0.8, 0.8, 0.8, 1.0);
  lightAmb:array [0..3] of GLfloat = (0.2, 0.2, 0.2, 1.0);
begin
  // nastavime svetlo
  glLightfv(GL_LIGHT1, GL_AMBIENT, @lightAmb);
  glLightfv(GL_LIGHT1, GL_DIFFUSE, @lightDifuse);
  glLightfv(GL_LIGHT1, GL_POSITION, @lightDir);

  { * TEXTURA NA POZADÍ *  }
  glEnable(GL_TEXTURE_2D);                       // zapneme texturovani
  
  glAlphaFunc(GL_GREATER, 0.5);// Nastavení alfa testingu: zobrazi se jen ty pixely ktera maji alfu vetsi nez 0.5 textura je totiz 32bit tga obrazek s alfou na krajich 0.0 a tim ho orizneme od bilych okraju
  glEnable(GL_ALPHA_TEST);// Zapne alfa testing

  glMatrixMode(GL_MODELVIEW);                 // zvolime modelview matici
  glPushMatrix();                             // ulozime ji

  glTranslatef(0.0, 0.0, -1.0);

  glColor4f(1, 1, 1, 1);
  glBindTexture(GL_TEXTURE_2D, m_texID);         // zvolime texturu
  glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0); glVertex3f(-0.555, -0.415, 0.0);
    glTexCoord2f(1.0, 0.0); glVertex3f( 0.555, -0.415, 0.0);
    glTexCoord2f(1.0, 1.0); glVertex3f( 0.555, 0.415, 0.0);
    glTexCoord2f(0.0, 1.0); glVertex3f(-0.555, 0.415, 0.0);
  glEnd();

  glMatrixMode(GL_MODELVIEW);                                  // vybereme modelview matici
  glPopMatrix();                                               // nahrajeme ji

  glDisable(GL_ALPHA_TEST);
  glDisable(GL_TEXTURE_2D);                      // vypneme texturovani

  glColor4f(1.0, 0.8, 0.5, 0.8);             // nastavujeme barvu
  m_Font.Print(-0.5, 0.37, -1.0, 'Level:  '+IntToStr(m_GameLevel.Number));    // cislo levelu
  m_Font.Print(-0.35, 0.37, -1.0, Format('Time Left:  %d:%2.2d', [round(m_GameLevel.TimeLeft) div 60, round(m_GameLevel.TimeLeft) mod 60]));       // Format fce ekvivalent k sprintf ze crt(C runtime library)
  m_Font.Print(-0.1, 0.37, -1.0, 'Score: '+IntToStr(m_GameLevel.Score));     // skore
  if m_GameLevel.Difficulty = Easy then
    m_Font.Print(0.1, 0.37, -1.0, 'Difficulty:  Easy')     //lehka obtiznost
  else
    m_Font.Print(0.1, 0.37, -1.0, 'Difficulty:  Hard');     // tezka
  glColor4f(1, 1, 1, 1);
  glEnable(GL_TEXTURE_2D);

  glEnable(GL_MULTISAMPLE_ARB);

  glEnable(GL_LIGHTING);                      // zapneme svetla
  // vykreslime texcontrols pokud nejsou visible pochopitelne nevykreslujeme nic ale to si ridi objekty sami
  m_GameOverText.Render();
  m_HighScoreInfoText.Render();
  m_PausedText.Render();
  glDisable(GL_LIGHTING);                    // vypneme svetla

  m_ScoreGainedPanel.Draw();                 // vykreslime panel pro skore o5 jako u textcontrols zda se vykresli si ridi panel sam

  if not m_PausedText.Visible then           // kdyz neni pausedtext visible(kdyby toto nebylo hrac by si mohl zapauzovat hru a promyslet postup dal aniz by mu ubihal cas)
    m_Maze.Draw();                           // vykreslime bludiste

  glDisable(GL_MULTISAMPLE_ARB);
end;

procedure TGameScene.ProcessEvent(Keys:TKeys; fps, miliseconds:float);
begin
  if Keys = nil then                    // kdyz se nahodu predalo keys nil
    exit;                               // konec

  if Keys.IsPressedOnce(VK_ESCAPE) then      // kdyz se stisklo escape
  begin
    if m_GameLevel.Score > 0 then
        SaveScore();
    m_GameLevel.Reset();                 // resetujeme gamelevel
    m_GameOverText.Hide();               // zneviditelnime gameovertext
    m_HighScoreInfoText.Hide();
    m_Maze.GetCamera().Reset();          // resetujeme kameru bludiste
    ChangeScene(TMainMenu.GetInstance());  // scenu nastavime na mainmenu
  end;

  if m_GameOverText.Visible then          // kdyz je videt game over
  begin
    if Keys.IsPressedOnce(VK_RETURN) then      // kdyz se stisklo enter
    begin
      m_GameLevel.Reset();                 // resetujeme gamelevel
      m_GameOverText.Hide();               // zneviditelnime gameovertext
      m_HighScoreInfoText.Hide();
      m_Maze.GetCamera().Reset();          // resetujeme kameru bludiste
    end;
  end;

  if m_ScoreGainedPanel.Visible then       // kdyz je panel skore viditelny
  begin
    if keys.IsPressedOnce(VK_RETURN) then         // kdyz byl stisknut enter
    begin
      m_ScoreGainedPanel.Hide();              // zneviditelnime panel
      m_GameLevel.Next();                     // postoupime do dalsiho levelu
    end;
  end;

  if not (m_GameOverText.Visible or m_ScoreGainedPanel.Visible) then     // kdyz neni viditelny gameovertext ani scoregained panel
  begin

    if keys.IsPressedOnce(ord('P')) then              // po stisku klavesy P jen jednou po stisku
    begin
      m_PausedText.Visible := not m_PausedText.Visible;            // negujeme viditelnost paused textu tedy kdyz byl videt nebude videt a kdyz nebyl videt bude videt
    end;

  end;

  if not(m_GameOverText.Visible or m_PausedText.Visible or m_ScoreGainedPanel.Visible) then     // kdyz neni viditelny ani gameover text ani paused text ani scoregained panel tak
  begin

    // snizujeme cas
    m_GameLevel.TimeLeft := m_GameLevel.TimeLeft - miliseconds/1000;   // miliseconds je cas ktery uplnul od posledniho pruchodu touto fci
    if round(m_GameLevel.TimeLeft) <= 0 then     // kdyz cas vyprsel
    begin
      m_HighScoreInfoText.Caption := 'Sorry your score is too low to get into highscores';
      if m_GameLevel.Score > 0 then
        SaveScore();

      m_HighScoreInfoText.Show();  
      m_GameOverText.Show();                    // ukazeme gameover text
    end;

    // sipka nahoru
    if keys.IsPressed(VK_UP) then
    begin
      if m_Maze.GetPlayer().GoUp(fps) then        // kdyz jsme sli nahoru a hrac vyhral
      begin
        // ukazeme scoregained panel a posleme mu hodnoty ktere ma zobrazit
        m_ScoreGainedPanel.Show(m_GameLevel.Number * SCORE_BY_LEVEL_MULTIPLIER,
          round(m_GameLevel.TimeLeft) * SCORE_BY_TIMELEFT_MULTIPLIER,
          m_GameLevel.Score + m_GameLevel.Number * SCORE_BY_LEVEL_MULTIPLIER + round(m_GameLevel.TimeLeft) * SCORE_BY_TIMELEFT_MULTIPLIER );
      end;
    end;

    // sipka dolu
    if keys.IsPressed(VK_DOWN) then
    begin
      if m_Maze.GetPlayer().GoDown(fps) then
      begin
        // ukazeme scoregained panel a posleme mu hodnoty ktere ma zobrazit
        m_ScoreGainedPanel.Show(m_GameLevel.Number * SCORE_BY_LEVEL_MULTIPLIER,
          round(m_GameLevel.TimeLeft) * SCORE_BY_TIMELEFT_MULTIPLIER,
          m_GameLevel.Score + m_GameLevel.Number * SCORE_BY_LEVEL_MULTIPLIER + round(m_GameLevel.TimeLeft) * SCORE_BY_TIMELEFT_MULTIPLIER );
      end;
    end;

    // sipka vlevo
    if keys.IsPressed(VK_LEFT) then
    begin
      if m_Maze.GetPlayer().GoLeft(fps) then
      begin
        // ukazeme scoregained panel a posleme mu hodnoty ktere ma zobrazit
        m_ScoreGainedPanel.Show(m_GameLevel.Number * SCORE_BY_LEVEL_MULTIPLIER,
          round(m_GameLevel.TimeLeft) * SCORE_BY_TIMELEFT_MULTIPLIER,
          m_GameLevel.Score + m_GameLevel.Number * SCORE_BY_LEVEL_MULTIPLIER + round(m_GameLevel.TimeLeft) * SCORE_BY_TIMELEFT_MULTIPLIER );
      end;
    end;

    // sipka vpravo
    if keys.IsPressed(VK_RIGHT) then
    begin
      if m_Maze.GetPlayer().GoRight(fps) then
      begin
        // ukazeme scoregained panel a posleme mu hodnoty ktere ma zobrazit
        m_ScoreGainedPanel.Show(m_GameLevel.Number * SCORE_BY_LEVEL_MULTIPLIER,
          round(m_GameLevel.TimeLeft) * SCORE_BY_TIMELEFT_MULTIPLIER,
          m_GameLevel.Score + m_GameLevel.Number * SCORE_BY_LEVEL_MULTIPLIER + round(m_GameLevel.TimeLeft) * SCORE_BY_TIMELEFT_MULTIPLIER );
      end;
    end;

    // kamera se ovlada wsad a pageup a pagedown

    if keys.IsPressed(ord('W')) then
    begin
      m_Maze.GetCamera().TurnUp(fps);
    end;

    if keys.IsPressed(ord('S')) then
    begin
      m_Maze.GetCamera().TurnDown(fps);
    end;

    if keys.IsPressed(ord('A')) then
    begin
      m_Maze.GetCamera().TurnLeft(fps);
    end;

    if keys.IsPressed(ord('D')) then
    begin
      m_Maze.GetCamera().TurnRight(fps);
    end;

    if keys.IsPressed(VK_SUBTRACT) then            // - numericka klavesa
    begin
      m_Maze.GetCamera().ZoomOut(fps);         // priblizeni kamery
    end;

    if keys.IsPressed(VK_ADD) then           // + numericka klavesa
    begin
      m_Maze.GetCamera().ZoomIn(fps);          // oddaleni kamery
    end;

    if keys.IsPressedOnce(ord('R')) then
    begin
      m_Maze.Regenerate();           // znovu vygenerujeme bludiste
    end;
  end;

end;

procedure TGameScene.Enter(SceneManager:TSceneManager);
var
  Ini:TIniFile;
  prevDifficulty:TDifficulty;
begin
  inherited Enter(SceneManager);
  prevDifficulty := m_GameLevel.Difficulty;
  // ini souboru precteme obtiznost
  Ini := TIniFile.Create('cfg\conf.ini');
  m_GameLevel.Difficulty := TDifficulty(Ini.ReadInteger('Game', 'Difficulty', ord(Easy)));
  Ini.Free();

  if prevDifficulty <> m_GameLevel.Difficulty then
    m_GameLevel.Reset();
end;

procedure TGameScene.Leave();
begin
end;

procedure TGameScene.SaveScore();
var
  DataFile:TDataFile;
  Data:array [0..9] of uint32;
  i,ScorePos:int8;
  filename:string;
  box:TDialogBox;
begin
  // nulujeme pole pro data
  for i:=0 to 9 do
    Data[i] := 0;

  try
    // podle obtiznosti rozhodneme do ktereho souboru budeme zapisovat
    if m_GameLevel.Difficulty = Easy then
      filename := 'Data\highscoresEasy.dat'
    else
      filename := 'Data\highscoresHard.dat';

    DataFile := TDataFile.Create(filename);      // otevreme soubor
    DataFile.ReadData(@Data);                    // precteme data
    ScorePos := GetScoreEstimatedPos(Data);      // ziskame kolikate nejlepsi skore ted mame
    if ScorePos > -1 then                        // kdyz je pozice vetsi nez -1 ( -1 znaci ze soucasne skore neni top 10)
    begin
      // do text ktery bude hrace informovat o tom kolikate highscore udelal si ulozime kolikate udelal :)
      m_HighScoreInfoText.Caption := 'Congratulations you have made ' + IntToStr(ScorePos+1) + ' highest score';

      // veskera highscores ktera jsou mensi nez soucasne highscores posuneme dolu
      for i:= 8 downto ScorePos do
      begin
        Data[i+1] := Data[i];
      end;
      Data[ScorePos] := m_GameLevel.Score;

      DataFile.WriteData(10, 4, @Data);      // zapiseme do souboru data
    end;
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
      DataFile.Free();                       // uvolnime ho
    end;
    on E:EWriteError do
    begin
      box := TDialogSystem.GetInstance().AddDialogBox(TDialogBox);
      box.Caption := 'Error';
      box.Text := E.Message;

      DeleteFile(filename);
      DataFile.Free();
    end;
  end;
end;

function TGameScene.GetScoreEstimatedPos(Data:array of uint32):int8;
var
  length:uint8;
  i:int8;
begin
  length := High(Data)+1;                // lokalni promena velikosti pole
  if m_GameLevel.Score <= Data[length-1] then          // kdyz se soucasne skore nevejde do top10
  begin
    result := -1;                        // vyhodime -1
    exit;                                // konec
  end
  else
  begin
    // postupne zjistujeme pozici v top10
    for i:=0 to length-1 do
    begin
      if m_GameLevel.Score > Data[i] then
      begin
        result := i;            // vratime zjistenou pozici v top10
        exit;                   // konec
      end;
    end;
  end;
  result := -1;                // vyhodime -1
end;

end.
