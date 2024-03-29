{
 * Handles Dialogs in OpenGL (classic MessageBox() function is useless in fullscreen mode)
 *      Currently unfortunately supports only MB_OK mode cos in this game i need only MB_OK :D
 * Copyright (C) 2009  Jan Du�ek <GhostJO@seznam.cz>
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

unit DialogSystem;

interface

uses
  windows,
  messages,
  SysUtils,
  classes,
  dglOpenGL,
  keys,
  Defines,
  Font,
  BitmapFont,
  FontManager;

type

  // trida zakladniho dialog boxu
  TDialogBox = class
  private
    fCaption:string;               // nadpis
    fText:string;                  // text
  protected
    constructor Create();virtual;   // konstruktor protected
    // procedury udalosti umozni aby slo overridnout tyto metody a pripadne definovat nove chovani
    procedure OnClose();virtual;
    procedure OnShow();virtual;
    procedure OnOK();virtual;
  public
    destructor Destroy();override;    // destruktor
    property Caption:string read fCaption write fCaption;
    property Text:string read fText write fText;
  end;

  TDialogBoxClass = class of TDialogBox;        // class reference

  TDialogSystem = class                         // trida dialog systemu
  public
    class function GetInstance():TDialogSystem;    // je implementovana jako singleton
    destructor Destroy();override;                 // destruktor
    procedure Render();                        // vykreslovaci fce
    function HandleEvents(keys:TKeys):boolean;    // usetri udalosti klaves vraci true pokud mame aktivni okno
    function AddDialogBox(BoxClass:TDialogBoxClass):TDialogBox;   // prida dialog box do dialogoveho system vraci pointer na tento box
  protected
    constructor Create();               // trida je implementovana jako singleton -> konstuktor protected
  private
    m_Dialogs:TList;                    // list dialog boxu
    m_ActiveBox:TDialogBox;             // aktivni box
    m_ActiveBoxPos:int32;               // index aktivniho boxu v TListu
    m_Font:TFont;                       // font nadpisu
    m_TextFont:TFont;                   // font kterym bude napsan text
  end;

var
  // jelikoz delphi nema (c++: static data tedy napr private: static TDialogSystem* instance; ) tak musime pouzit unit-level promenou :(((
  u_DialogSystem:TDialogSystem;

implementation

class function TDialogSystem.GetInstance():TDialogSystem;
begin
  if u_DialogSystem = nil then           // kdyz je "static" promena nil
  begin
    u_DialogSystem := TDialogSystem.Create();    // vytvorime instanci
  end;
  result := u_DialogSystem;              // vratime "static promenou"
end;

constructor TDialogSystem.Create();
begin
  m_Dialogs := TList.Create();           // vytvarime list
  m_ActiveBox := nil;                    // aktive box je nil
  m_ActiveBoxPos := -1;                  // pozice na -1

  // pozadame fontmanager o fonty
  m_Font := TFontManager.GetInstance().GetFont(TBitmapFont, 'Visitor TT2 BRK', -34, FW_BOLD);
  m_TextFont := TFontManager.GetInstance().GetFont(TBitmapFont, 'Visitor TT2 BRK', -22, FW_NORMAL);
end;

destructor TDialogSystem.Destroy();
begin
  inherited Destroy();
  m_Dialogs.Free();             // uvolnime TList
end;

procedure TDialogSystem.Render();
var
  lines:TStringList;
  iLine, iDel:int32;
  tempStr:string;
begin
  if  m_ActiveBox <> nil then             // kdyz mame aktivni box
  begin
    lines := TStringList.Create();        // vytvarime stringlist

    glDisable(GL_TEXTURE_2D);             // pro jistotu vypiname texturovani

    glMatrixMode(GL_MODELVIEW);           // zvolime projekcni matici
    glPushMatrix();                       // ulozime matici

    glLoadIdentity();                     // nacitame jednotkovou matici

    if length(m_ActiveBox.Text) > 32 then  // kdyz delka textu presahuje povolenou mez
    begin
      // do pomocneho stringu si ulozime rozdeleny text viz. delphi help
      tempStr := WrapText(m_ActiveBox.Text, #13#10, [' '], 32) + #13#10;
      // c++: for(int iDel = Pos(#13#10, tempStr); iDel != 0; iDel := Pos(#13#10, tempStr)) {}
      iDel := Pos(#13#10, tempStr);      // do ridici promene cyklu priradime pozici delimiteru
      while iDel <> 0 do                 // kdyz ve stringu je delimiter
      begin
        lines.Add(Copy(tempStr, 1, iDel-1));   // do string listu priradime radek odeleny delimiterem
        delete(tempStr, 1, iDel+1);      // ze stringu smazeme to co jsme si pridali do stringlistu + delimiter
        iDel := Pos(#13#10, tempStr);    // aktualizujeme ridici promenou cyklu
      end;
    end
    else                                 // kdyz delka textu nepresahuje povolenou mez
    begin
      lines.Add(m_ActiveBox.Text);       // pridame radek do string listu
    end;

    glColor4f(1.0, 0.8, 0.5, 0.8);       // barva textu
    m_Font.Print(-0.15, 0.075, -1.0, m_ActiveBox.Caption);       // piseme nadpis
    for iLine := 0 to lines.Count -1 do       // prochazime radky
    begin
      m_TextFont.Print(-0.15, 0.03-(iLine*0.02), -1.0, lines.Strings[iLine]); // vykreslime radky a zaroven kazdy dalsi radek posuneme o kus na ose y
    end;
    m_Font.Print(-0.02, -0.008-(iLine*0.02), -1.09, 'OK');     // vykreslime napis na "tlacitku"

    glTranslatef(0.0, 0.0, -1.1);             // posun do obrazovky
    glBegin(GL_QUADS);                        // kreslime ctyruhelniky

      // hlavni okno
      glColor3f(0.6, 0.6, 0.0);
      glVertex2f(-0.18, -0.05-(iLine*0.02));      // levy dolni
      glVertex2f(-0.18, 0.07);       // levy horni
      glVertex2f(0.18, 0.07);        // pravy horni
      glVertex2f(0.18, -0.05-(iLine*0.02));       // pravy dolni

      // prouzek jako napdpis okna
      glColor3f(1.0, 0.6, 0.0);
      glVertex2f(-0.18, 0.07);      // levy dolni
      glVertex2f(-0.18, 0.11);       // levy horni
      glVertex2f(0.18, 0.11);        // pravy horni
      glVertex2f(0.18, 0.07);       // pravy dolni

      // tlacitko
      glColor3f(1.0, 0.6, 0.0);
      glVertex2f(-0.06, -0.02-(iLine*0.02));      // levy dolni
      glVertex2f(-0.06, 0.02-(iLine*0.02));       // levy horni
      glVertex2f(0.06, 0.02-(iLine*0.02));        // pravy horni
      glVertex2f(0.06, -0.02-(iLine*0.02));       // pravy dolni
    glEnd();

    glMatrixMode(GL_MODELVIEW);                 // zvolime projekcni matici
    glPopMatrix();                              // nahrajeme matici

    lines.Free();                               // uvolnime stringlist
  end;
end;

function TDialogSystem.HandleEvents(keys:TKeys):boolean;
begin
  result := false;
  if keys = nil then              // kdyz se za keys predalo nil
    exit;                         // konec

  if m_ActiveBox <> nil then      // kdyz mame aktivni box
  begin
    result := true;
    if keys.IsPressedOnce(VK_ESCAPE) then      // kdyz stiskneme esc
    begin
      m_ActiveBox.OnClose();        // udalost close
      m_Dialogs.Delete(m_ActiveBoxPos);  // vymazeme dialog box z listu
      m_ActiveBox.Free();          // uvolnime dialog box
      if (m_ActiveBoxPos -1) > -1 then
        m_ActiveBox := TDialogBox(m_Dialogs.Items[m_ActiveBoxPos -1])
      else
        m_ActiveBox := nil;
      dec(m_ActiveBoxPos);
      exit;                        // konec
    end;

    if keys.IsPressedOnce(VK_RETURN) then     // kdyz stiskneme enter jakoby zmackneme OK
    begin
      m_ActiveBox.OnOK();                    // udalost OK
      m_Dialogs.Delete(m_ActiveBoxPos);      // vymazeme dialog box z listu
      m_ActiveBox.Free();          // uvolnime dialog box
      if (m_ActiveBoxPos -1) > -1 then
        m_ActiveBox := TDialogBox(m_Dialogs.Items[m_ActiveBoxPos -1])
      else
        m_ActiveBox := nil;
      dec(m_ActiveBoxPos);
      exit;                        // konec
    end;

  end;
end;

function TDialogSystem.AddDialogBox(BoxClass:TDialogBoxClass):TDialogBox;
begin
  m_ActiveBoxPos := m_Dialogs.Add(BoxClass.Create());     // do TListu vytvorime novou instanci tridy obsazene v promene BoxClass
  m_ActiveBox := TDialogBox(m_Dialogs[m_ActiveBoxPos]);   // nastavime aktivni box
  m_ActiveBox.OnShow();                                   // udalost show
  result := m_ActiveBox;                                  // vratime ho
end;

constructor TDialogBox.Create();
begin
  // nastavime zakladni promene
  fCaption := 'Caption';
  fText := 'Text';
end;

destructor TDialogBox.Destroy();
begin
  inherited Destroy();
end;

procedure TDialogBox.OnClose();
begin
end;

procedure TDialogBox.OnShow();
begin
end;

procedure TDialogBox.OnOK();
begin
end;

end.
