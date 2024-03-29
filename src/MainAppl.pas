{
 * Main Application class provides message loop and message handling
 *
 *  based on
 *     Object Orientated NeHeGL Using Base Class
 *     Author: Andreas Oberdorfer           2004
 *
 *     ported from c++ to Delphi by: Jan Du�ek
 *
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

unit MainAppl;

interface

uses
  Windows,
  Messages,
  dglOpenGL,
  Defines,
  Window,
  Keys,
  MainForm,
  MMSystem;

const
  WM_TOGGLEFULLSCREEN = WM_USER + 1;                                 // definujeme novou zpravu ktera prepina mezi mody zobrazeni fullscreen a windowed
type

  TApplication = class                                               // Trida aplikace
  public
    class function Init(ClassName:LPCSTR):TApplication;             // (c++: static method)
    procedure TerminateApplication();                               // Ukonci aplikaci
    destructor Destroy();override;                                      // destructor
  protected
    m_Keys:TKeys;                                                   // instance tridy klaves
    m_Window:TWindow;                                               // instance tridy okna
    
    procedure ToggleFullscreen();                                   // Zmeni mod zobrazeni
    procedure ResizeDraw(enable:boolean);                           // Dovoluje prekreslovat behem meneni velikosti okna
    function GetFPS():float;                                        // ziska FPS
    function GetMilliseconds():float;                               // ziska pocet milisekund od posledniho pruchodu vykreslovaci fci
    function GetAverageFPSperSec():uint32;                          // ziska prumerny FPS za 1sec
    function GetCenterX():GLuint;                                   // vrati X sour stredu okna
    function GetCenterY():GLuint;                                   // vrati Y sour stredu okna
    function GetTime():float;                                      // vrati cas od startu
    constructor Create(ClassName:LPCSTR);virtual;                   // konstruktor

    function Initialize():boolean;virtual;abstract;                 // Inicializace OpenGL
    procedure Deinitialize();virtual;abstract;                      // Deinicializace
    procedure Update();virtual;abstract;                            // Stisky klaves atp. co se nehodi do Draw()
    procedure Draw();virtual;abstract;                              // vykreslovaci fce
  private

    m_ClassName:LPCSTR;                                             // jmeno WindowClass
    m_IsProgramLooping:boolean;                                     // urcuje zda bezi program
    m_CreateFullscreen:boolean;                                     // urcuje zda okno bobezi ve fullscreenu
    m_IsVisible:boolean;                                            // viditelnost
    m_ResizeDraw:boolean;                                           // zda se bude prekreslovat behem meneni okna

    // promene pro vypocet fps
    m_LastTickCount:float;
    m_Milliseconds:float;
    m_AverageFps:uint32;
    m_fps:float;

    m_CenterX:GLuint;                                               // X souradnice stredu okna
    m_CenterY:GLuint;                                               // Y souradnice stredu okna

    // hlavni smycka programu
    function Run(hInstance:HINST; hPrevInstance:HINST; hCmdLine:PChar; nCmdShow:int32):int32;
    // zpracovavani zprav
    function HandleMessages(hWnd:HWND; uMsg:UINT; wParam:WPARAM; lParam:LPARAM):LRESULT;
    procedure CreateFullScreen();
    procedure SetWindowSettings(Width:int32; Height:int32; BitsPerPixel:int32; DisplayFrequency:int32; VSync:boolean; Multisamples:int32);
  end;

function WinMain(hInstance:HINST; hPrevInstance:HINST; hCmdLine:PChar; nCmdShow:integer):integer; stdcall;

implementation

uses
  Game;   // kvuli circular unit reference musi byt toto tady :(

// mam Delphi 7 kde je stara implementace WinApi a chybi fce GetWindowLongPtr a SetWindowLongPtr
// ktere jsou kompatibilni jak s 32bit OS tak i s 64bit OS, fce kterou musim pouzivat GetWindowLong
// a SetWindowLong NEJSOU kompatibilni s 64bit OS
function WndProc(hWnd:HWND; uMsg:UINT; wParam:WPARAM; lParam:LPARAM):LRESULT; stdcall;
var
  userData:int32;
  pCreation:PCREATESTRUCT;
  appl:TApplication;
begin
  userData := GetWindowLong(hWnd, GWL_USERDATA);                       // ziskame uzivatelska data okna
  if userData = 0 then                                                 // pokud jeste nebyla nastavea
  begin
    if uMsg = WM_CREATE then                                           // kdyz prichozi zprava je WM_CREATE
    begin
      pCreation := PCREATESTRUCT(lParam);                              // v lParam zpravy je obsazen pointer na strukturu obsahujici data okna
      Appl := TApplication(pCreation^.lpCreateParams);                 // do dat okna jsme si v CreateWindowEx() poslali pointer na instanci tridy aplikace tak ho ted ziskame
      // do uzivatelskych dat okna si ulozime pointer na aplikaci
      // (jako int32 xD snad to na 64 bit systemech neudela rotiku xD
      // VERY UNSAFE!!! xDDDD)
      SetWindowLong(hWnd, GWL_USERDATA, int32(Appl));
      Appl.m_IsVisible := true;                                        // zviditelnime aplikaci
      result := 0;                                                     // konec
      exit;
    end;
  end
  else                                                                // pokud uz jsme uzivatelska data nastavili
  begin
    Appl := TApplication(userData);                                   // ziskame z nich instanci aplikace
    result:=Appl.HandleMessages(hWnd,uMsg,wParam,lParam);             // zavolame metodu zpracovani zprav
    exit;                                                             // konec
  end;
  result := DefWindowProc(hWnd, uMsg, wParam, lParam);                // zbyle zpravy(ty ktere byly poslany pred WM_CREATE) posleme systemu na zpracovani
end;

function WinMain(hInstance:HINST; hPrevInstance:HINST; hCmdLine:PChar; nCmdShow:integer):integer; stdcall;
var
  Appl:TApplication;
begin
  result := -1;

  // instance tridy TApplication parametr v konstruktoru se predava
  // jako jmeno wndClass do RegisterClass()
  Appl := TApplication.Init('OpenGL');

  // kdyz byl zvolen fullscreen mod
  if MForm.FullScreen.Checked then
    Appl.CreateFullScreen();              // rekneme hlavnimu oknu at se vytvori ve fullscreenu

  // Zvolime nastaveni okna
  Appl.SetWindowSettings(MForm.GetDisplaySetting().Width, MForm.GetDisplaySetting().Height,
    MForm.GetDisplaySetting().BitsPerPixel, MForm.GetDisplaySetting().DisplayFrequency,
    MForm.VSync.Checked, MForm.Multisample);

  result := Appl.Run(hInstance, hPrevInstance, hCmdLine, nCmdShow);
  Appl.Free();
end;

class function TApplication.Init(ClassName:LPCSTR):TApplication;
var
  game:TGame;
begin
  game := TGame.Create(ClassName);               // vytvorime instanci tridy TGame(potomek TApplication)
  result := TApplication(game);                  // vratime pretypovanou TGame na TApplication
end;

constructor TApplication.Create(ClassName:LPCSTR);
begin
  m_Keys := TKeys.Init();
  m_Window := TWindow.Init();
  
  m_ClassName := ClassName;
  m_IsProgramLooping := true;
  m_CreateFullscreen := false;
  m_ResizeDraw := false;
  m_IsVisible := false;

  // nulovani promenych
  m_LastTickCount := 0;
  m_Milliseconds := 0;
	m_AverageFps := 0;
  m_fps := 0;
end;

destructor TApplication.Destroy();
begin
  inherited Destroy();
  m_Keys.Free();
  m_Window.Free();
end;

procedure TApplication.CreateFullScreen();
begin
  m_CreateFullscreen := true;
end;

procedure TApplication.SetWindowSettings(Width:int32; Height:int32; BitsPerPixel:int32; DisplayFrequency:int32; VSync:boolean; Multisamples:int32);
begin
  //m_Window.SetFullscreenMode(m_CreateFullscreen);
  m_Window.Width := Width;
  m_Window.Height := Height;
  m_Window.ColorDepth := BitsPerPixel;
  m_Window.DisplayFrequency := DisplayFrequency;
  m_Window.SetVSync(VSync);
  if Multisamples = 0 then
    m_Window.SetMultisample(0, false)
  else
    m_Window.SetMultisample(Multisamples, true);
end;

procedure TApplication.ToggleFullscreen();
begin
  PostMessage(m_Window.Handle, WM_TOGGLEFULLSCREEN, 0, 0);
end;

procedure TApplication.TerminateApplication();
begin
  PostMessage(m_Window.Handle, WM_QUIT, 0, 0);
  m_IsProgramLooping := false;
end;

procedure TApplication.ResizeDraw(enable:boolean);
begin
  m_ResizeDraw := enable;
end;

function TApplication.GetFPS():float;
begin
  result := m_fps;
end;

function TApplication.GetMilliseconds():float;
begin
  result := m_Milliseconds;
end;

function TApplication.GetAverageFPSperSec():uint32;
begin
  result := m_AverageFps;
end;

function TApplication.GetCenterX():GLuint;
begin
  result := m_CenterX;
end;

function TApplication.GetCenterY():GLuint;
begin
  result := m_CenterY;
end;

function TApplication.GetTime():float;
var
  time,freq : int64;
  factor: float;
  threadAffinity:int32;
begin
  threadAffinity := SetThreadAffinityMask(GetCurrentThread(), 1);
  QueryPerformanceFrequency(freq);
  if freq = 0 then
    freq := 1;
  factor := 1000 / freq;
  QueryPerformanceCounter(time);
  result := time * factor;
  SetThreadAffinityMask(GetCurrentThread(), threadAffinity);
end;

function TApplication.Run(hInstance:HINST; hPrevInstance:HINST; hCmdLine:PChar; nCmdShow:int32):int32;
var
  wndClass:TWndClass;
  msg:TMsg;
  IsMessagePumpActive:boolean;
  tickCount:float;
  TotalMilli:float;
  numFrames:uint32;
begin
  TotalMilli := 0;
  numFrames := 0;

  wndClass.style := CS_HREDRAW or CS_VREDRAW or CS_OWNDC;                 // Prekresli okno pri kazdem posunu/zmene velikosti
  wndClass.lpfnWndProc := @WndProc;                                       // Definujeme fci pro zpracovani zprav
  wndClass.cbClsExtra := 0;                                               // Zadna extra data
  wndClass.cbWndExtra := 0;                                               // Zadna extra data
  wndClass.hInstance := hInstance;                                        // Nastavime handle Instance
  wndClass.hIcon := MForm.Icon.Handle;                                    // ikona je stejna jako u uvitaciho dialogu ovsem tam neni videt xDDDD
  wndClass.hCursor := LoadCursor(0, IDC_ARROW);                           // Standartni kurzor
  wndClass.hbrBackground := 0;                                            // Pozadi neni nutne
  wndClass.lpszMenuName := nil;                                           // nechceme menu
  wndClass.lpszClassName := m_ClassName;                                  // jmeno tridy

  if RegisterClass(wndClass) = 0 then
  begin
    MessageBox(0, 'Nepodarilo se registrovat tridu okna', 'Error', MB_OK or MB_ICONEXCLAMATION);
    result := -1;
    exit;
  end;

  While m_IsProgramLooping do
  begin
    if m_Window.Create('Maze Game', m_CreateFullScreen, m_ClassName, hInstance, self) then    // vytvarime okno
    begin
      if (not Initialize()) then                                                             // podarilo se inicializovat openGL?
      begin
        TerminateApplication();                                                             // Ukonci applikaci
      end
      else
      begin
        IsMessagePumpActive := true;
        m_LastTickCount := GetTime();                                                        // Ziskame cas
        m_Keys.Clear();                                                                      // Resetujeme klavesy
        While IsMessagePumpActive do                                                         // kdyz bezi cyklus zprav
        begin
          if (PeekMessage(msg, 0, 0, 0, PM_REMOVE)) then                                    // kdyz jsme obdrzeli nejakou zpravu
          begin
            if msg.message <> WM_QUIT then                                                   // kdyz zprava NENI WM_QUIT
            begin
              TranslateMessage(msg);                                                         // Prelozime zpravu
              DispatchMessage(msg);                                                          // Posleme zpravu ke zpracovani
            end
            else
            begin
              IsMessagePumpActive := false;                                                  // Prerusime zpracovavani zprav
            end;
          end
          else                                                                              // kdyz uz nejsou zadne zpravy k zpracovani
          begin
            if not m_IsVisible then                                                         // kdyz neni okno viditelne
            begin
              WaitMessage();                                                                // tak cekame na dalsi zpravy
            end
            else
            begin
              tickCount := GetTime();                                                       // ziskame cas
              m_Milliseconds := tickCount - m_LastTickCount;                                // ziskame rozdil ms od posledniho pruchodu
              m_fps := 1.0 / (m_Milliseconds / 1000.0);                                     // vypocitame aktualni fps
              TotalMilli := TotalMilli + m_Milliseconds;                                    // pricitame si milisekundy
              inc(numFrames);                                                               // ubehl dalsi frame
              if TotalMilli > 1000 then                                                     // kdyz ubehla 1s
              begin
                m_AverageFps := numFrames;                                                  // fps je pocet framu za 1 sec :)
                // nulovani promenych
                TotalMilli := 0;
                numFrames := 0;
              end;
              Update();                                                                     // Stisky klaves a jiny balast :DDD
              m_LastTickCount := tickcount;                                                 // nastavime posledni count na soucasny
              Draw();
              m_Window.SwapBuffers();                                                      // Prohodime buffery
            end;
          end;
        end;
      end;

      Deinitialize();
      m_Window.DestroyWnd();
    end
    else
    begin
      MessageBox(0, 'Nepodarilo se vytvorit okno', 'Error', MB_OK or MB_ICONEXCLAMATION);
      m_IsProgramLooping := false;
    end;
  end;

  UnRegisterClass(m_ClassName, hInstance);
  result := 0;
end;

function TApplication.HandleMessages(hWnd:HWND; uMsg:UINT; wParam:WPARAM; lParam:LPARAM):LRESULT;
begin
  case uMsg of
    WM_SYSCOMMAND:                                                // osetrime systemove zpravy
      case wParam of
        SC_SCREENSAVE,                                            // setric obrazovky se snazi zapnout
        SC_MONITORPOWER:                                          // usporny rezim monitoru
        begin
          result := 0;                                            // Zabrani obojimu
          exit;
        end;
      end;
    WM_CLOSE:
    begin
      TerminateApplication();                                     // ukonci aplikaci
      result := 0;
      exit;
    end;
    WM_EXITMENULOOP,
    WM_EXITSIZEMOVE:
    begin
      m_LastTickCount := GetTime();                                // obnovi cas
      result := 0;
      exit;
    end;
    WM_MOVE:
    begin
      m_Window.PosX := LOWORD(lParam);
      m_Window.PosY := HIWORD(lParam);
      result := 0;
      exit;
    end;
    WM_PAINT:
    begin
      if m_ResizeDraw then
      begin
        m_Window.ReshapeGL();
        Draw();
        m_Window.SwapBuffers();
      end;
    end;
    WM_SIZE:
    begin
      m_CenterX := round(LOWORD(lParam)/2);
      m_CenterY := round(HIWORD(lParam)/2);

      case wParam of
        SIZE_MINIMIZED:
        begin
          m_IsVisible := false;
          result := 0;
          exit;
        end;
        SIZE_MAXIMIZED,
        SIZE_RESTORED:
        begin
          m_IsVisible := true;
          m_Window.Width := LOWORD(lParam);
          m_Window.Height := HIWORD(lParam);
          m_Window.ReshapeGL();
          m_LastTickCount := GetTime();
          result := 0;
          exit;
        end;
      end;
    end;
    WM_KEYDOWN:      // tato zprava se posila pokazde kdyz se stiskne klavesa a kdyz je dlouho drzena tak po case take
    begin
      if (HIWORD(lParam) and KF_REPEAT ) = 0 then    // pokud nebyla zprava poslana automaticky tj. neni to zprava ktera by byla poslana za dlouheho drzeni klavesy
        m_Keys.SetPressed(wParam);
      result := 0;
      exit;
    end;
    WM_KEYUP:
    begin
      m_Keys.SetReleased(wParam);
      result := 0;
      exit;
    end;
    WM_TOGGLEFULLSCREEN:
    begin
      m_CreateFullScreen := not m_CreateFullScreen;
      PostMessage(hWnd, WM_QUIT, wParam, lParam);
      result := 0;
      exit;
    end;
  end;
  result := DefWindowProc(hWnd, uMsg, wParam, lParam);
end;

end.
