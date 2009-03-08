{
 * Main project file inits openGL function runs vcl dialog and then main application
 * Copyright (C) 2008-2009  Jan Dušek <GhostJO@seznam.cz>
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


program MazeGame;

uses
  Forms,
  Windows,
  Messages,
  dglOpenGL in 'include\dglOpenGL.pas',
  OpenIL in 'include\OpenIL.pas',
  MainForm in 'MainForm.pas' {MForm},
  MainAppl in 'MainAppl.pas',
  Player in 'Player.pas',
  Font in 'Font.pas',
  Maze in 'Maze.pas',
  Defines in 'Defines.pas',
  Window in 'Window.pas',
  Camera in 'Camera.pas',
  Keys in 'Keys.pas',
  Vector3D in 'Vector3D.pas',
  ChildForm in 'ChildForm.pas' {Form1},
  AboutGraficCard in 'AboutGraficCard.pas' {AboutBox},
  Game in 'Game.pas',
  OutLineFont in 'OutLineFont.pas',
  SceneManager in 'SceneManager.pas',
  MainMenu in 'MainMenu.pas',
  TextControls in 'TextControls.pas',
  GameScene in 'GameScene.pas',
  ScoreGainedPanel in 'ScoreGainedPanel.pas',
  BitmapFont in 'BitmapFont.pas',
  DataFile in 'DataFile.pas',
  HighScores in 'HighScores.pas',
  HowToPlayScene in 'HowToPlayScene.pas',
  FontManager in 'FontManager.pas',
  AboutProgram in 'AboutProgram.pas' {AboutBox1},
  DialogSystem in 'DialogSystem.pas',
  Menu in 'Menu.pas',
  DifficultyMenu in 'DifficultyMenu.pas';

{$R *.res}
begin
  // jelikoz pouzivam openGL.pas od dgl tak se musi zavolat tato procedura ktera nahraje openGL fce pres wglGetProcAddress()
  InitOpenGL();
  // inicializujeme knihovnu na nahravani obrazku DevIL
  ilInit();
	ilOriginFunc(IL_ORIGIN_LOWER_LEFT);
	ilEnable(IL_ORIGIN_SET);

  // VCL formular slouzici jako uvitaci dialog pro volbu grafickeho nastaveni
  Application.Initialize;
  Application.CreateForm(TMForm, MForm);
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TAboutBox1, AboutBox1);
  Application.Run;

  // kdyz se ma hlavni okno spustit
  if MForm.RunClicked then
  begin
    // WinApi entry (parametry predava OS : handle instance aplikace,
    // handle predchozi instance(pro Win32 aplikace vzdy NULL), info z prikazove radky,
    // jak se ma okno zobrazit jestli minimalizovane atd.)
    WinMain(hInstance, hPrevInst, CmdLine, CmdShow);
  end;
end.
