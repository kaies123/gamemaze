{
 * This form is used to prompt user to choose display settings
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

unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, jpeg, ExtCtrls, StdCtrls, XPMan, dglOpenGL, IniFiles, ChildForm, AboutGraficCard;

type
  DisplaySetting = record
    Width:Cardinal;
    Height:Cardinal;
    DisplayFrequency:Cardinal;
    BitsPerPixel:Cardinal;
  end;

  TMForm = class(TForm)
    OGLLogo: TImage;
    XPManifest1: TXPManifest;
    ExitBtn: TButton;
    RunBtn: TButton;
    DispSettings: TComboBox;
    FullScreen: TCheckBox;
    CardInfo: TLabel;
    GrapSett: TGroupBox;
    VSync: TCheckBox;
    FSAA: TGroupBox;
    NoFSAA: TRadioButton;
    Multi2x: TRadioButton;
    Multi4x: TRadioButton;
    info: TButton;
    About: TButton;
    procedure ExitBtnClick(Sender: TObject);
    procedure RunBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure infoClick(Sender: TObject);
    procedure AboutClick(Sender: TObject);
  private
    m_DisplaySettings:array of DisplaySetting;                  // dyn. pole grafickych nastaveni
    m_numOfDisplaySettings:Cardinal;                            // velikost dyn. pole
    m_Ini:TIniFile;                                             // ukazatel na instanci tridy TIniFile

    fRun:boolean;
  public
    Multisample:integer;
    property RunClicked:boolean read fRun;                      // urcuje zda pobezi hlavni okno
    constructor Create(AOwner:TComponent);override;             // konstruktor (TForm ho ma virtualni takze ho musime prepsat)
    destructor Destroy();override;                              // destruktor (TForm ho ma virtualni takze ho prepiseme)
    function GetDisplaySetting():DisplaySetting;                // ziska v comboBoxu vybrane graf. nastaveni
  end;

var
  MForm: TMForm;

implementation

uses AboutProgram;

{$R *.dfm}

constructor TMForm.Create(AOwner:TComponent);
var
  dmScreenSettings:DEVMODE;
  i, fsaaTemp, itemIndex:integer;
  list:TStringList;
begin
  // c++: TMform(TComponent AOwnder) : TForm(AOwnder) {}   tedy "dedime" konstruktor
  inherited Create(AOwner);
  list := TStringList.Create();
  m_Ini := TIniFile.Create('cfg\conf.ini');                                // vytvarime instanci tridy ini souboru

  dmScreenSettings.dmSize := sizeof(DEVMODE);                              // velikost struktury
  dmScreenSettings.dmDriverExtra := 5*sizeof(Cardinal);                    // budeme pridavat 5*cardinal
  // for (int i=0; EnumDisplaySettings(NULL, i, dmScreenSettings); i++) {} musime opsat while cyklem
  i:=0;
  while EnumDisplaySettings(nil, i, dmScreenSettings) do
  begin
    SetLength(m_DisplaySettings, i+1);                                     // nastavime velikost dyn. pole
    // nastavovani hodnot pole
    m_DisplaySettings[i].Width := dmScreenSettings.dmPelsWidth;
    m_DisplaySettings[i].Height := dmScreenSettings.dmPelsHeight;
    m_DisplaySettings[i].BitsPerPixel := dmScreenSettings.dmBitsPerPel;
    m_DisplaySettings[i].DisplayFrequency := dmScreenSettings.dmDisplayFrequency;
    // do comboBoxu pridame hodnoty
    list.Add(Format('%d x %d x %d; %d Hz',
      [m_DisplaySettings[i].Width, m_DisplaySettings[i].Height, m_DisplaySettings[i].BitsPerPixel, m_DisplaySettings[i].DisplayFrequency]));
    inc(i);                                                               // i++
  end;

  m_numOfDisplaySettings := i;                                            // nastavime clensku promenou( ted nam to k nicemu neni ale nekdy mozna ... :DDD)
  FullScreen.Checked := m_Ini.ReadBool('application', 'FullScreen', false);   // cteme ini soubor a nastavime podle toho checkBox
  VSync.Checked := m_Ini.ReadBool('application', 'VSync', true);  // cteme ini a nastavime checkbox
  itemIndex := m_Ini.ReadInteger('application', 'ComboItemIndex', 0);  // cteme ini a nastavime podle toho defaultni vybranou hodnotu v comboBoxu

  DispSettings.Items.AddStrings(list);

  if (itemIndex < DispSettings.Items.Count) and (itemIndex > -1) then
    DispSettings.ItemIndex := itemIndex
  else
    DispSettings.ItemIndex := 0;

  fsaaTemp := m_Ini.ReadInteger('application', 'fsaa', 0);
  case fsaaTemp of
    0:
    begin
      NoFSAA.Checked := true;
    end;
    1:
    begin
      Multi2x.Checked := true;
    end;
    2:
    begin
      Multi4x.Checked := true;
    end;
    else
    begin
      NoFSAA.Checked := true;
    end;
  end;
  
  list.Free();
end;

destructor TMForm.Destroy();
begin
  inherited Destroy();                                          // TForm ma virtualni destruktor takze provedeme to co je v base class destruktoru
  m_Ini.Free();                                     // destruktor ini souboru
end;

function TMForm.GetDisplaySetting():DisplaySetting;
var
  ComboItemIndex:integer;
begin
  ComboItemIndex := DispSettings.ItemIndex;                     // do pomocne promene dame index prave vybrane polozky v comboBoxu
  result := m_DisplaySettings[ComboItemIndex];                  // vratime pozadovane zobrazeni
end;

procedure TMForm.ExitBtnClick(Sender: TObject);
begin
  fRun := false;                                                  // nebudeme poustet hlavni okno
  self.Hide();                                                   // schovame nynejsi
  self.Close();                                                  // zavreme ho
end;

procedure TMForm.RunBtnClick(Sender: TObject);
begin
  m_Ini.WriteInteger('application', 'ComboItemIndex', DispSettings.ItemIndex);    // zapisujeme do ini souboru vybranou polozku v comboBoxu
  m_Ini.WriteBool('application', 'FullScreen', FullScreen.Checked);               // zapisujeme do ini souboru zda pobezime ve fullscreenu
  m_Ini.WriteBool('application', 'VSync', VSync.Checked);                         // zapis do ini zda bude VSync zapnuto

  if NoFSAA.Checked then
  begin
    m_Ini.WriteInteger('application', 'fsaa', 0);
    Multisample := 0;
  end
  else
  if Multi2x.Checked then
  begin
    m_Ini.WriteInteger('application', 'fsaa', 1);
    Multisample := 2;
  end
  else
  if Multi4x.Checked then
  begin
    m_Ini.WriteInteger('application', 'fsaa', 2);
    Multisample := 4;
  end;
  
  fRun := true;                                                   // pobezime hlavni okno
  self.Hide();                                                   // schovame nynejsi okno
  self.Close();                                                  // zavreme ho
end;

// info o graf. karte nemuze byt v konstruktoru jelikoz ten se vola PRED konstruktorem naseho
// detskeho okna(jen v prazdnem formu se ziskaji korektni info pres glGetString() ) takze
// musime nastavovat v udalosti OnShow ktera probehne po vsech form konstruktorech :)
procedure TMForm.FormShow(Sender: TObject);
var
  extensions:string;
begin
  extensions := Form1.GetOpenGLExtensions();                 // nacteme podporovane extensiony
  if Pos('WGL_EXT_swap_control', extensions) = 0 then        // pokud jsme nenasli pozadovany extension
  begin
    VSync.Enabled := false;                                  // Deaktivujeme volbu VSyncu
    VSync.Hint := 'Your graphic card does NOT support openGL extension WGL_EXT_swap_control so that you are not able to enable or disable vertical synchronization';
  end;

  if Pos('GL_ARB_multisample', extensions) = 0 then
  begin
    Multi2x.Enabled := false;
    Multi4x.Enabled := false;
    NoFSAA.Checked := true;
    NoFSAA.Hint := 'Your graphic card does NOT support openGL extension GL_ARB_multisample so that you are not able to enable fullscreen antialliasing';
  end;

end;

procedure TMForm.infoClick(Sender: TObject);
begin
  AboutBox.ShowModal();
end;

procedure TMForm.AboutClick(Sender: TObject);
begin
  AboutBox1.ShowModal();
end;

end.
