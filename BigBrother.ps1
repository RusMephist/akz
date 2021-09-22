Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  using System.Diagnostics;

  public class MainWindow {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
}

namespace PInvoke.Win32 {
    public static class UserInput {
        [DllImport("user32.dll")]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO {
            public uint cbSize;
            public int dwTime;
        }
        public static DateTime LastInput {
            get {
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }
        public static TimeSpan IdleTime {
            get {
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }
        public static int LastInputTicks {
            get {
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
}
"@

$uri ='http://192.168.122.175/test.php'

while ($true) {
  $mainProc = get-process | ? { $_.mainwindowhandle -eq [MainWindow]::GetForegroundWindow() }
  if ( (([PInvoke.Win32.UserInput]::IdleTime).Seconds -ge 5) `
  -or (([PInvoke.Win32.UserInput]::IdleTime).Minutes -gt 0) `
  -or (([PInvoke.Win32.UserInput]::IdleTime).Minutes -gt 0)) { $idle_flag = 1 } else { $idle_flag = 0 }

  $json = @{
      MainWindowHandle = $MainProc | Select -expand MainWindowHandle
      user_login = $env:USERNAME
      pc_name = $env:COMPUTERNAME
      app_name = $MainProc | Select -expand processName
      app_title = $MainProc | Select -expand MainWindowTItle
      idle_flag = $idle_flag
  }

  Invoke-WebRequest -Uri $uri -Method Post -Body $json

  sleep -Seconds 1
}
