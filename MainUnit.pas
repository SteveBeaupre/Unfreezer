unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, TrayIcon, ExtCtrls;

type
  TMainForm = class(TForm)
    TrayIcon: TTrayIcon;
    TrayPopupMenu: TPopupMenu;
    CloseUnFreezerMenu: TMenuItem;
    UnFreezerTimer: TTimer;
    procedure UnFreezerTimerTimer(Sender: TObject);
    procedure CloseUnFreezerMenuClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    hDesktopWindow: HWND;
    hProgManWindow: HWND;
    function  IsKeysPressed: Boolean;
    procedure KillProcess;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

function OneInstance(MutexName: string): Boolean;
var
  hMutex: THANDLE;
  Running: Boolean;
begin
//attempt to create Mutex
hMutex := CreateMutex(nil, FALSE, PCHAR(MutexName));
//See if it was successful
Running := ((GetLastError() = ERROR_ALREADY_EXISTS) or (GetLastError() = ERROR_ACCESS_DENIED));
 //release rhe mutex
if(hMutex <> NULL) then
  ReleaseMutex(hMutex);

result := Running;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
if(OneInstance('UnFreezerApp')) then begin
  Application.Terminate;
  Exit;
end;

// Get the desktop windows handle
hDesktopWindow := GetDesktopWindow();
hProgManWindow := FindWindow(PCHAR('Progman'), PCHAR('Program Manager'));
end;

procedure TMainForm.KillProcess;
var
pid: DWORD;
hWindow, hProc: HWND;
begin
// Get the foreground window handle
hWindow := GetForegroundWindow();
// Bail if the handle is the desktop window
if((hWindow = Self.Handle) or (hWindow = hProgManWindow) or (hWindow = hDesktopWindow)) then
  Exit;

pid := 0;
// Terminate the process belonging to the foreground window
GetWindowThreadProcessId(hWindow, @pid);
if(pid <> 0) then begin
  hProc := OpenProcess(PROCESS_TERMINATE, False, pid);
  TerminateProcess(hProc, 0);
  CloseHandle(hProc);
end;
end;

function TMainForm.IsKeysPressed: Boolean;
begin
Result := False;
// Check if the keys are pressed
if(((GetAsyncKeyState(VK_CONTROL) and $8000) > 0)) then begin
  if(((GetAsyncKeyState(VK_SHIFT) and $8000) > 0)) then begin
    if(((GetAsyncKeyState(VK_INSERT) and $8000) > 0)) then begin
      Result := True;
    end;
  end;
end;
end;

procedure TMainForm.UnFreezerTimerTimer(Sender: TObject);
begin
// If the good combinason of keys are pressed, kill the process of the foreground window
if(IsKeysPressed) then begin
  // Disable the timer
  UnFreezerTimer.Enabled := False;
  Application.ProcessMessages;

  // Kill the process
  KillProcess;

  // Wait to restart the timer until the keys are released
  while(IsKeysPressed) do
    Sleep(1000);

  // Enable the timer
  UnFreezerTimer.Enabled := True;
end;
end;

procedure TMainForm.CloseUnFreezerMenuClick(Sender: TObject);
begin
// Stop the timer then close the app.
UnFreezerTimer.Enabled := False;
Application.ProcessMessages;
Close;
end;

end.
