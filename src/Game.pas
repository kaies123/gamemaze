{
 * TGame class provides base openGL initialization, rendering and keystate handling
 *
 *  based on
 *     Object Orientated NeHeGL Using Base Class
 *     Author: Andreas Oberdorfer           2004
 *
 *     Glaux replacement LoadBMP() function by Jeff Molofee - NeHe
 *     LoadTGA() function by Jeff Molofee - NeHe
 *
 *     ported from c++ to Delphi by: Jan Dušek
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
  
unit Game;

interface

uses
  windows,
  messages,
  SysUtils,
  dglOpenGL,
  OpenIL,
  Font,
  BitmapFont,
  Defines,
  GameScene,
  MainMenu,
  HighScores,
  HowToPlayScene,
  SceneManager,
  Vector3D,
  MainAppl,
  FontManager,
  DialogSystem,
  DifficultyMenu;

type
  TGame = class(TApplication)
  public
    // HACK: !!!!
    // tenhle konstruktor by mel byt private ale jelikoz nejde mit 2 friend classy mimo 1 unitu(proto jsem TGame od TApplication oddelil aby nebyli ve stejny unite a bylo to trochu logiccteji rozdeleny)
    // nebo definovat metodu mimo unitu ve ktere byla deklarovana tak jsem se na to vykvajznul jsem jedinej developer tak to nemusi bejt tak tiptop nejakej háèek se snese xD
    constructor Create(ClassName:LPCSTR);override;
    
    destructor Destroy();override;
    function Initialize():boolean;override;                 // Inicializace OpenGL
    procedure Deinitialize();override;                      // Deinicializace OpenGL
    procedure Update();override;                            // Stisky klaves atp. co se nehodi do Draw()
    procedure Draw();override;                              // vykreslovaci fce
  private
    m_Font:TFont;                                           // font

    m_SceneManager:TSceneManager;                           // instance manageru sceny

    m_Textures: array [0..5] of GLuint;                      // pole ID na textury

    function LoadTexture(filename:string; var texID:GLuint):boolean;
  end;

implementation

constructor TGame.Create(ClassName:LPCSTR);
begin
  inherited Create(ClassName);

  // pridame potrebne fonty do Windows fonty tabulky
  AddFontResource('Data\angelina.ttf');
  AddFontResource('Data\visitor2.ttf');

  // ziskame font
  m_Font := TFontManager.GetInstance().GetFont(TBitmapFont, 'Visitor TT2 BRK', -25, FW_NORMAL);

  m_SceneManager := TSceneManager.Create();                   // vytvarime instanci
  m_SceneManager.ChangeScene(TMainMenu.GetInstance());        // a nastavime scenu ktera se ma zobrazit jako uvitaci :)
end;

destructor TGame.Destroy();
begin
  inherited Destroy();

  // uklidime po sobe a vymazeme fonty z windows font tabulky
  RemoveFontResource('Data\visitor2.ttf');
  RemoveFontResource('Data\angelina.ttf');
  
  m_SceneManager.Free();
end;

procedure TGame.Deinitialize();
begin
  TGameScene.GetInstance().Deinitialize();
end;

procedure TGame.Update();
begin
  // F1
  if m_Keys.IsPressedOnce(VK_F1) then                           // je stisknuto F1?
  begin
    ToggleFullscreen();                                     // Prepneme do fullscreenu
  end;


  if not TDialogSystem.GetInstance().HandleEvents(m_Keys) then   // volame handler udalosti dialogoveho systemu ten vraci true pokud mame aktivni dialog box
    // osetruje stisky klaves atp.
    m_SceneManager.UpdateCurrentScene(m_Keys, GetFPS(), GetMilliseconds());

end;

function TGame.Initialize():boolean;
begin
  glShadeModel(GL_SMOOTH);                                // hladke stinovani(musi byt normaly per vertex pokud budou per face tak bude flat stinovani)
  glClearColor(0.1, 0.1, 0.1, 1.0);                       // Barva pozadi
  glClearDepth(1.0);                                      // Nastavení hloubkového bufferu
  glEnable(GL_DEPTH_TEST);                                // Povolí hloubkové testování
  glDepthFunc(GL_LEQUAL);                                 // Typ hloubkového testování
  glBlendFunc(GL_SRC_ALPHA, GL_ONE);							        // Blending zalozen na hodnote alpha
  glEnable(GL_LIGHT1);                                    // Zapne svìtlo
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);			// Perspektivni korekce na nejlepsi

  // nacteme textury
  if(not LoadTexture('Data\MainBackground.png', m_textures[0])) or
    (not LoadTexture('Data\ScorePanelBackground.png', m_textures[1])) or
    (not LoadTexture('Data\GameBackground.png', m_textures[2])) or
    (not LoadTexture('Data\wall.png', m_textures[3])) or
    (not LoadTexture('Data\grass.png', m_textures[4])) then
  begin
    result := false;
    exit;
  end;

  // inicializujeme jednotlive sceny a posleme do nich textury
  TGameScene.GetInstance().Initialize(m_textures[3] ,m_textures[4], m_textures[1], m_textures[2]);
  THighScores.GetInstance().Initialize(m_textures[0]);
  THowToPlayScene.GetInstance().Initialize(m_textures[0]);
  TMainMenu.GetInstance().Initialize(m_Window.Handle, m_textures[0]);
  TDifficultyMenu.GetInstance().Initialize(m_textures[0]);

  // font manager vytvori fonty
  TFontManager.GetInstance().RebuildFonts(m_Window.HandleDevice);

  // zapne prekreslovani pri zmene velikosti(momentalne nejde memit velikost okna runtime xDDD)
  ResizeDraw(true);

  result := true;
end;

procedure TGame.Draw();
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);    // Smaže obrazovku a hloubkový buffer
  glLoadIdentity();                                       // Reset matice

  TDialogSystem.GetInstance().Render();                   // vykreslime dialogovy system

  m_SceneManager.RenderCurrentScene();                    // vykresli soucasnou scenu

  glDisable(GL_TEXTURE_2D);
  glColor4f(1.0, 0.8, 0.5, 0.8);                          // barva
  m_Font.Print(0.37, 0.37, -1.0, 'FPS: '+ IntToStr(GetAverageFpsPerSec()));  // vypis fps

  glFlush();                                             // Vyprázdní renderovací pipeline
end;

function TGame.LoadTexture(filename:string; var texID:GLuint):boolean;
var
  imgID:TILuint;
  texture:TextureImage;
  typeMode:TILenum;
begin
  typeMode := IL_RGB;                                             // implicitni typ bude rgb

  ilGenImages(1, @imgID);                                         // vytvori obrazek
  ilBindImage(imgID);                                             // zvoli obrazek

  if ilLoadImage(PAnsiChar(filename)) = IL_FALSE then             // pokusi se nahrat obrazek ze souboru
  begin
    result := false;                                              // vrati false
    exit;
  end;

  // ziska informace o obrazku a ulozime si je do nasi struktury
  texture.height := ilGetInteger(IL_IMAGE_HEIGHT);
  texture.width := ilGetInteger(IL_IMAGE_WIDTH);
  texture.bpp := ilGetInteger(IL_IMAGE_BPP);

  if texture.bpp = 4 then                                          // kdyz je obrazek 32 bitovy
    typeMode := IL_RGBA;                                           // typ nastavime na rgba

  GetMem(texture.imageData, texture.height * texture.width * texture.bpp);  // alokujeme pamet pro data

  // ziskame data
  ilCopyPixels(0, 0, 0, texture.width, texture.height, 1, typeMode, IL_UNSIGNED_BYTE, texture.imageData);

  ilDeleteImages(1, @imgId);                                       // uz muzeme deletnou obrazek uz ho totiz nepotrebujeme

  glGenTextures(1,@texture.textID);                                    // Generuje texturu
  glBindTexture(GL_TEXTURE_2D, texture.textID);                       // Zvolí texturu
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );   // Lineární filtrování
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );   // Lineární filtrování
  glTexImage2D(GL_TEXTURE_2D, 0, texture.bpp, texture.width, texture.height, 0, TypeMode, GL_UNSIGNED_BYTE, texture.imageData);// Vytvoøí texturu
  texID := texture.textID;                                         // nastavime vracejici parametr

  FreeMem(texture.imageData);                                      // uvolnime pamet dat textury uz je totiz nepotrebujeme, jsou na VRAM gpu

  result := true;                                                  // vratime true
end;

end.
