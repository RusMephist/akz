Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class MainWindow {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
}
"@
$Proc = [MainWindow]::GetForegroundWindow()
$mainProc = get-process | ? { $_.mainwindowhandle -eq $Proc }

$json = @{
    MainWindowHandle = $MainProc | Select -expand MainWindowHandle
    timestamp = Get-Date -Format "yyMMddHHmmss"
    user_login = $env:USERNAME
    pc_name = $env:COMPUTERNAME
    ip = (Get-NetIPConfiguration -InterfaceAlias Ethernet | Get-NetIPAddress -AddressFamily IPv4).IPv4Address
    app_name = $MainProc | Select -expand processName
    app_title = $MainProc | Select -expand MainWindowTItle
    idle_flag = 0
}

Invoke-WebRequest -Uri http://192.168.122.175/test.php -Method Post -Body $json
