{ kvuli tomu ze delphi je ujety na moduly a jaksi "Error: Circular unit reference to X"
  tak jsem musel tyhle dve tridy ktery pouzivaji sebe navzajem strcit do jedny unity}

{
 * TScene abstract class used as ancestor for GameScene,MainMenu,HighScore and HowToPlay
 * TSceneManager manages scenes using State pattern(one from basic oop patterns)
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
unit SceneManager;

interface

uses
  Keys,
  defines;

type
  TSceneManager = class;           // forward declaration pro scene manager

  TScene = class                  // "abstraktni trida" je zakladem pro menu bludiste atp.
  public
    destructor Destroy();override;
    procedure Draw();virtual;abstract;      // vykresli scenu
    procedure ProcessEvent(Keys:TKeys; fps, miliseconds:float);virtual;abstract;   // stisky klaves atp.
    procedure Leave();virtual;abstract;     // provede se kdyz prestaneme zobrazovat scenu
    procedure Enter(SceneManager:TSceneManager);virtual;     // kdyz zacneme zobrazovat scenu
  protected
    m_SceneManager:TSceneManager;           // instance scene manageru
    constructor Create();virtual;   // konstruktor protected -> jen tak nevytvorite instanci pokud ano tak mozna nejakou metodou TObjectu ale to ja ovlivnit nemuzu :(((
    procedure ChangeScene(NewScene:TScene);   // zmenime scenu
  end;

  TSceneManager = class
  public
    constructor Create();             // bezparametricky konstruktor

    destructor Destroy();override;            // destruktor

    procedure ChangeScene(NewScene:TScene);    // zmenime scenu
    function GetCurrentScene():TScene;         // ziska soucasnou scenu

    procedure RenderCurrentScene();            // vykresli soucasnou scenu
    procedure UpdateCurrentScene(Keys:TKeys; fps, miliseconds:float);      // stisky klaves soucasne sceny
  private
    m_CurrentScene:TScene;                  // soucasna scena
  end;

implementation

constructor TSceneManager.Create();
begin
  m_CurrentScene := nil;
end;

destructor TSceneManager.Destroy();
begin
  inherited Destroy();
end;

procedure TSceneManager.ChangeScene(NewScene:TScene);
begin
  if m_CurrentScene <> nil then
  begin
    m_CurrentScene.Leave();
  end;
  m_CurrentScene := NewScene;
  m_CurrentScene.Enter(self);
end;

function TSceneManager.GetCurrentScene():TScene;
begin
  result := m_CurrentScene;
end;

procedure TSceneManager.RenderCurrentScene();
begin
  if m_CurrentScene = nil then
  begin
    exit;
  end;
    
  m_CurrentScene.Draw();
end;

procedure TSceneManager.UpdateCurrentScene(Keys:TKeys; fps, miliseconds:float);
begin
  if m_CurrentScene = nil then
  begin
    exit;
  end;
  m_CurrentScene.ProcessEvent(Keys, fps, miliseconds);
end;

constructor TScene.Create();
begin
end;

destructor TScene.Destroy();
begin
  inherited Destroy();
end;

procedure TScene.Enter(SceneManager:TSceneManager);
begin
  m_SceneManager := SceneManager;
end;

procedure TScene.ChangeScene(NewScene:TScene);
begin
  m_SceneManager.ChangeScene(NewScene);
end;

end.
