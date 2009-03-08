{
 * TWindow class used to create openGL window
 *
 *  based on
 *     Object Orientated NeHeGL Using Base Class
 *     Author: Andreas Oberdorfer           2004
 *
 *     ported from c++ to Delphi by: Jan Dušek
 *     multisampling implented by: Jan Dušek
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
  
unit Window;

interface

uses
  Windows,
  Messages,
  defines,
  dglOpenGL;

type
  TWindow = class
  private
    m_hWnd:HWND;                                                     // handle okna
    m_hRC:HGLRC;                                                     // rendering kontext
    m_hDC:HDC;                                                       // device kontext
    m_arbMultisamplePixelFormat:int32;                             // pixel format pro fsaa
    m_IsMultisampleChosen:boolean;                                   // bude indikovat zda jsme jiz nasli validni pixelformat pro fsaa
    m_Samples:int32;                                               // pocet samples do multisamplingu
    m_IsMultisampleSelected:boolean;                                 // bude indikovat zda uzivatel zvolil multisampling

    m_WindowPosX:int32;                                            // X pozice okna
    m_WindowPosY:int32;                                            // Y pozice okna
    m_WindowWidth:int32;                                           // sirka okna
    m_WindowHeight:int32;                                          // vyska okna
    m_ScreenWidth:int32;                                           // sirka fullscreenu
    m_ScreenHeight:int32;                                          // vyska fullscreenu
    m_BitsPerPixel:int32;                                          // pocet bitu na pixel
    m_DisplayFrequency:int32;                                      // obnovovaci frekvence monitoru
    m_IsFullScreen:boolean;                                          // Indikuje zda je okno ve fullscreenu
    m_IsVSyncEnabled:boolean;                                        // Indikuje zda budeme zapinat ci vypinat VSync
    // Nastavi pozici okna
    procedure SetPosX(x:int32);
    procedure SetPosY(y:int32);
    // Ziska velikost okna podle modu
    function GetWidth():int32;
    function GetHeight():int32;
    // nastavi velikost okna podle modu
    procedure SetWidth(width:int32);
    procedure SetHeight(height:int32);
    // Ziska pozici okna podle modu
    function GetPosX():int32;
    function GetPosY():int32;
    // nastavi obnovovaci frekvency monitoru
    procedure SetDisplayFrequency(DisplayFrequency:int32);
    // nastavi barevnou hloubku
    procedure SetColorDepth(ColorDepth:int32);
    // Ziska handle okna
    function GetHWND():HWND;
    // Ziska device kontext
    function GetHDC():HDC;
    // Ziska rendering kontext
    function GetHRC():HGLRC;
  public
    // konstruktor
    constructor Init();
    // vytvori OpenGL okno
    function Create(windowTitle:LPCSTR; fullScreen:boolean; className:LPCSTR; hInstance:HINST; lpParam:Pointer):boolean;
    // znici okno
    procedure DestroyWnd();
    // Zmeni rozliseni
    function ChangeResolution():boolean;
    // Nastavi vertikalni synchronizaci
    procedure SetVSync(enabled:boolean);
    // nastaveni multisamplingu
    procedure SetMultisample(Samples:int32; enabled:boolean);
    // Nastaveni openGL atp.
    procedure ReshapeGL();
    // Prehodi buffery(pouzivame totiz double buffering)
    procedure SwapBuffers();

    property Width:int32 read GetWidth write SetWidth;
    property Height:int32 read GetHeight write SetHeight;
    property PosX:int32 read GetPosX write SetPosX;
    property PosY:int32 read GetPosY write SetPosY;
    property DisplayFrequency:int32 read m_DisplayFrequency write SetDisplayFrequency;
    property ColorDepth:int32 read m_BitsPerPixel write SetColorDepth;
    property Handle:HWND read GetHWND;
    property HandleDevice:HDC read GetHDC;
    property HandleRenderingContext:HGLRC read GetHRC;
  end;

implementation

constructor TWindow.Init();
begin
  m_WindowPosX	:= 0;												                          // X pozice okna
	m_WindowPosY	:= 0;												                          // Y pozice okna
	m_WindowWidth	:= 1024;												                      // sirka okna
	m_WindowHeight	:= 768;											                      	// vyska okna
	m_ScreenWidth	:= 1024;												                      // sirka fullscreenu
	m_ScreenHeight	:= 768;												                      // vyska fullscreenu
	m_BitsPerPixel	:= 32;												                      // Bity na pixel
  m_DisplayFrequency := 75;                                           // Obnovovaci frekvence monitoru
	m_IsFullScreen	:= false;											                      // Fullscreen
  m_IsMultisampleChosen := false;                                     // multisampling este neinicializovan
  m_IsMultisampleSelected := false;
  m_Samples := 0;

	// nulovani promenych
	m_hWnd := 0;
	m_hDc := 0;
	m_hRc := 0;
end;

procedure TWindow.SetVSync(enabled:boolean);
begin
  m_IsVSyncEnabled := enabled;
end;

procedure TWindow.SetMultisample(Samples:int32; enabled:boolean);
begin
  m_Samples := Samples;
  m_IsMultisampleSelected := enabled;
end;

procedure TWindow.SetDisplayFrequency(DisplayFrequency:int32);
begin
  m_DisplayFrequency := DisplayFrequency;
end;

procedure TWindow.SetColorDepth(ColorDepth:int32);
begin
  m_BitsPerPixel := ColorDepth;
end;

function TWindow.GetWidth():int32;
begin
  if m_IsFullScreen then
  begin
    result := m_ScreenWidth;
    exit;
  end
  else
    result := m_WindowWidth;
end;

function TWindow.GetHeight():int32;
begin
  if m_IsFullScreen then
  begin
    result := m_ScreenHeight;
    exit;
  end
  else
    result := m_WindowHeight;
end;

procedure TWindow.SetWidth(width:int32);
begin
  if m_IsFullScreen then
    m_ScreenWidth := width
  else
    m_WindowWidth := width;
end;

procedure TWindow.SetHeight(height:int32);
begin
  if m_IsFullScreen then
    m_ScreenHeight := height
  else
    m_WindowHeight := height;
end;

function TWindow.GetPosX():int32;
begin
  if not m_IsFullScreen then
  begin
    result := m_WindowPosX;
    exit;
  end
  else
    result := 0;
end;

function TWindow.GetPosY():int32;
begin
  if not m_IsFullScreen then
  begin
    result := m_WindowPosY;
    exit;
  end
  else
    result := 0;
end;

procedure TWindow.SetPosX(x:int32);
begin
  if not m_IsFullScreen then
    m_WindowPosX := x;
end;

procedure TWindow.SetPosY(y:int32);
begin
  if not m_IsFullScreen then
    m_WindowPosY := y;
end;

procedure TWindow.SwapBuffers();
begin
  Windows.SwapBuffers(m_hDC);
end;

procedure TWindow.ReshapeGL();
var
  width, height:GLsizei;
begin
  width:= GetWidth();
  height := GetHeight();
  glViewport(0, 0, width, height);                                        // resetne viewport
  glMatrixMode(GL_PROJECTION);                                            // vybere projekcni matic
  glLoadIdentity();                                                       // resetuje matici
  gluPerspective(45.0, width / height, 0.1, 1000.0);                      // perspektivni projekce
  //glOrtho(0.0, width, 0.0, height,-10.0, 10.0);
  glMatrixMode(GL_MODELVIEW);                                             // vybere modelview matici
  glLoadIdentity();                                                       // resetujeme matici
end;

function TWindow.ChangeResolution():boolean;
var
  dmScreenSettings:DEVMODE;
begin
  ZeroMemory(@dmScreenSettings, sizeof(dmScreenSettings));                // Procistime pamet: @ == & v c++ tedy z promene udela ukazatel na promenou
  with dmScreenSettings do
  begin
    dmSize := sizeof(dmScreenSettings);                                   // velikost recordu(c++: struktury)
    dmPelsWidth := GetWidth();                                            // sirka
    dmPelsHeight := GetHeight();                                          // vyska
    dmBitsPerPel := m_BitsPerPixel;                                       // bitu na pixel
    dmDisplayFrequency := m_DisplayFrequency;                             // obnovovaci frekvence monitoru
    dmFields := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT or DM_DISPLAYFREQUENCY;
  end;
  if (ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN)) <> DISP_CHANGE_SUCCESSFUL then
  begin
    result := false;                                                      // zmena selhala vracime false
    exit;
  end;
  result := true;                                                         // zmena uspesna vraci true
end;

function TWindow.GetHDC():HDC;
begin
  result := m_hDC;
end;

function TWindow.GetHRC():HGLRC;
begin
  result := m_hRC;
end;

function TWindow.GetHWND():HWND;
begin
  result := m_hWnd;
end;

function TWindow.Create(windowTitle:LPCSTR; fullScreen:boolean; className:LPCSTR; hInstance:HINST; lpParam:Pointer ):boolean;
const
  fAttributes:array[0..1] of float = ( 0, 0 );
var
  windowStyle:DWORD;
  windowExtendedStyle:DWORD;
  windowRect:TRect;
  valid:boolean;
  numFormats:GLuint;
  pixelFormat:int32;
  pfd:PIXELFORMATDESCRIPTOR;
  iAttributes:array[0..21] of int32;
begin
  m_IsFullScreen := fullScreen;

  // definujeme styl okna
  windowStyle := WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU
      or WS_MINIMIZEBOX;
  windowExtendedStyle := WS_EX_APPWINDOW;                             // definujeme rozsireny styl okna

  iAttributes[0] := WGL_DRAW_TO_WINDOW_ARB;
  iAttributes[1] := GL_TRUE;
  iAttributes[2] := WGL_SUPPORT_OPENGL_ARB;
  iAttributes[3] := GL_TRUE;
  iAttributes[4] := WGL_ACCELERATION_ARB;
  iAttributes[5] := WGL_FULL_ACCELERATION_ARB;
  iAttributes[6] := WGL_COLOR_BITS_ARB;
  iAttributes[7] := 24;
  iAttributes[8] := WGL_ALPHA_BITS_ARB;
  iAttributes[9] := 8;
  iAttributes[10] := WGL_DEPTH_BITS_ARB;
  iAttributes[11] := 16;
  iAttributes[12] := WGL_STENCIL_BITS_ARB;
  iAttributes[13] := 0;
  iAttributes[14] := WGL_DOUBLE_BUFFER_ARB;
  iAttributes[15] := GL_TRUE;
  iAttributes[16] := WGL_SAMPLE_BUFFERS_ARB;
  iAttributes[17] := GL_TRUE;
  iAttributes[18] := WGL_SAMPLES_ARB;
  iAttributes[19] := m_Samples;
  iAttributes[20] := 0;
  iAttributes[21] := 0;


  with pfd do                                         // OznßmÝme Windows jak chceme vÜe nastavit
    begin
    nSize := SizeOf(PIXELFORMATDESCRIPTOR);        // Velikost struktury
    nVersion := 1;                                   // Cislo verze
    dwFlags := PFD_DRAW_TO_WINDOW                    // Podpora okna
            or PFD_SUPPORT_OPENGL                         // Podpora OpenGL
            or PFD_DOUBLEBUFFER;                          // Podpora Double Bufferingu
    iPixelType := PFD_TYPE_RGBA;                     // RGBA Format
    cColorBits := m_BitsPerPixel;                    // Zvolí barevnou hloubku
    cRedBits := 0;                                   // Bity barev ignorovány
    cRedShift := 0;
    cGreenBits := 0;
    cGreenShift := 0;
    cBlueBits := 0;
    cBlueShift := 0;
    cAlphaBits := 0;                                 // zadny alpha buffer
    cAlphaShift := 0;                                // Ignorovan Shift bit
    cAccumBits := 0;                                 // zadny akumulaèní buffer
    cAccumRedBits := 0;                              // Akumulaèní bity ignorovany
    cAccumGreenBits := 0;
    cAccumBlueBits := 0;
    cAccumAlphaBits := 0;
    cDepthBits := 24;                                // 24-bitovy hloubkovy buffer (Z-Buffer)
    cStencilBits := 0;                               // zadny Stencil Buffer
    cAuxBuffers := 0;                                // zadny Auxiliary Buffer
    iLayerType := PFD_MAIN_PLANE;                    // Hlavni vykreslovaci vrstva
    bReserved := 0;                                  // Rezervovano
    dwLayerMask := 0;                                // Maska vrstvy ignorovana
    dwVisibleMask := 0;
    dwDamageMask := 0;
    end;

   // definujeme koordinaty okna
  windowRect.Left := GetPosX();
  windowRect.Top := GetPosY();
  windowRect.Right := GetPosX() + GetWidth();
  windowRect.Bottom := GetPosY() + GetHeight();

  if m_IsFullScreen then
  begin
    if ChangeResolution() then
    begin                                                               // zmena modu se zdarila
      ShowCursor(false);                                                // zneviditelnime kursor
      windowStyle := WS_POPUP;
      windowExtendedStyle := WS_EX_APPWINDOW or WS_EX_TOPMOST;
    end
    else
    begin
      MessageBox(0, 'Zmena modu se nezdarila, pobezim v okne', 'Error', MB_OK or MB_ICONEXCLAMATION);
      m_IsFullScreen := false;
    end;
  end;

  if not m_IsFullScreen then                                          // kdyz nebyl zvolen fullscreen
  begin
    // prizpusobeni velikosti okna
    AdjustWindowRectEx(windowRect, windowStyle, false, windowExtendedStyle);
    // ujistime se zda je levy roh v obrazovce
    if windowRect.Left < 0 then                                     // kdyz je X pozice negativni
    begin
      windowRect.Right := windowRect.Right - windowRect.Left;       // opravime pozici vpravo
      windowRect.Left := 0;                                         // X sour dame na 0
    end;
    if windowRect.Top < 0 then                                      // kdyz je Y pozice negativni
    begin
      windowRect.Bottom := windowRect.Bottom - windowRect.Top;      // opravime pozici dole
      windowRect.Top := 0;                                          // Y sour dame na 0
    end
  end;

  m_hWnd := CreateWindowEx(windowExtendedStyle,                     // rozsireny styl okna
    className,                                                      // jmeno tridy okna
    windowTitle,                                                    // jmeno okna
    windowStyle,                                                    // styl okna
    windowRect.Left, windowRect.Top,                                // X,Y souradnice okna
    windowRect.Right - windowRect.Left,                             // sirka
    windowRect.Bottom - windowRect.Top,                             // vyska
    0,                                                              // rodic okna je desktop -> 0
    0,                                                              // nemame menu
    hInstance,                                                      // instance applikace
    lpParam);                                                       // do WM_CREATE jsme si poslali pointer na instanci tridy TApplication a tak budeme moct vyvolat ve WndProc metodu HandleMessages()

  while m_hWnd <> 0 do
  begin
    m_hDC := GetDC(m_hWnd);                                         // ziskani device kontextu
    if m_IsMultisampleChosen then
    begin
      pixelFormat := m_arbMultisamplePixelFormat;
    end
    else
    begin
      pixelFormat := ChoosePixelFormat(m_hDC, @pfd);
    end;

    SetPixelFormat(m_hDC, pixelFormat, @pfd);
    m_hRC := wglCreateContext(m_hDC);
    wglMakeCurrent(m_hDC, m_hRC);
    ReadExtensions();
    ReadImplementationProperties();

    if (not m_IsMultisampleChosen) and (m_IsMultisampleSelected) then
    begin
      valid := wglChoosePixelFormatARB(m_hDC, @iAttributes, @fAttributes, 1,
        @m_arbMultisamplePixelFormat, @numFormats);
      if valid and (numFormats >= 1) then
      begin
        m_IsMultisampleChosen := true;
        DestroyWnd();
        result := Create(windowTitle, fullScreen, className, hInstance, lpParam);
        exit;
      end;
    end;

    if m_IsVSyncEnabled then
    begin
      wglSwapIntervalEXT(1);
    end
    else
    begin
      wglSwapIntervalEXT(0);
    end;

    ShowWindow(m_hWnd, SW_NORMAL);                                  // zobrazi okno
    ReshapeGL();                                                    // nastaveni openGL
    result := true;
    exit;
  end;

  DestroyWnd();
  result := false;
end;

procedure TWindow.DestroyWnd();
begin
  if m_hWnd <> 0 then                                               // mame handle okno?
  begin
    if m_hDC <> 0 then                                              // mame device kontext?
    begin
      DeactivateRenderingContext();                                 // deaktivujeme rendering kontext
      if m_hRC <> 0 then                                            // ma okno rendering kontext?
      begin
        wglDeleteContext(m_hRC);                                    // zrusime rendering kontext
        m_hRC := 0;
      end;
      ReleaseDC(m_hWnd, m_hDC);                                     // uvolnime kontext zarizeni
      m_hDC := 0;
    end;
    DestroyWindow(m_hWnd);                                          // zrusime okno
    m_hWnd := 0;
  end;

  if m_IsFullScreen then                                            // jsme ve fullscreenu?
  begin
    ChangeDisplaySettings(devmode(nil^), 0);                        // prepnuti z5 do systemu
    ShowCursor(true);                                               // zviditelnime kurzor
  end;
end;

end.
