@echo off
setlocal
title System Toolkit - Win11 Visual Experience Fix
echo.
echo System Toolkit - Win11 visual experience fix
echo This tool will restore taskbar center, Microsoft YaHei UI font,
echo Windows 11 context menu, full-window dragging and selection rectangle.
echo.
net session >nul 2>&1
if not "%errorlevel%"=="0" (
  echo Requesting administrator permission...
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$marker = '#' + ' POWERSHELL_PAYLOAD'; $content = Get-Content -LiteralPath '%~f0' -Raw -Encoding UTF8; $payload = ($content -split [regex]::Escape($marker), 2)[1]; Invoke-Expression $payload"
echo.
echo Done. If some visual settings do not refresh immediately, sign out or restart Windows.
pause
exit /b

# POWERSHELL_PAYLOAD
$ErrorActionPreference = 'SilentlyContinue'
$backupRoot = Join-Path (Get-Location) ('visual-fix-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

function Export-Key($name, $path) {
  $file = Join-Path $backupRoot ($name + '.reg')
  & reg.exe export $path $file /y 2>$null | Out-Null
}

Export-Key 'Desktop' 'HKCU\Control Panel\Desktop'
Export-Key 'WindowMetrics' 'HKCU\Control Panel\Desktop\WindowMetrics'
Export-Key 'ExplorerAdvanced' 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Export-Key 'ClassicContextMenu' 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
Export-Key 'DesktopBackgroundHandlersCU' 'HKCU\Software\Classes\Directory\Background\shellex\ContextMenuHandlers'
Export-Key 'DesktopBackgroundHandlersLM' 'HKLM\Software\Classes\Directory\Background\shellex\ContextMenuHandlers'

# Taskbar center on Windows 11.
New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Force | Out-Null
Set-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name TaskbarAl -Type DWord -Value 1

# Restore Windows 11 default compact context menu.
Remove-Item -LiteralPath 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' -Recurse -Force -ErrorAction SilentlyContinue

# Disable slow desktop-background classic shell extensions.
$desktopHandlers = @(
  'Registry::HKEY_LOCAL_MACHINE\Software\Classes\Directory\Background\shellex\ContextMenuHandlers\NvAppDesktopContext',
  'Registry::HKEY_LOCAL_MACHINE\Software\Classes\Directory\Background\shellex\ContextMenuHandlers\NvCplDesktopContext'
)
foreach ($handler in $desktopHandlers) {
  Remove-Item -LiteralPath $handler -Recurse -Force -ErrorAction SilentlyContinue
}
$cuDesktopHandlers = 'Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shellex\ContextMenuHandlers'
if (Test-Path -LiteralPath $cuDesktopHandlers) {
  Get-ChildItem -LiteralPath $cuDesktopHandlers | Where-Object { $_.PSChildName.Trim() -eq 'FileSyncEx' } | ForEach-Object {
    Remove-Item -LiteralPath $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# Full window dragging and the blue selection rectangle.
New-Item -Path 'HKCU:\Control Panel\Desktop' -Force | Out-Null
Set-ItemProperty -LiteralPath 'HKCU:\Control Panel\Desktop' -Name DragFullWindows -Type String -Value '1'
New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Force | Out-Null
Set-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name ListviewAlphaSelect -Type DWord -Value 1
Set-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name ListviewShadow -Type DWord -Value 1
New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Force | Out-Null
Set-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name VisualFXSetting -Type DWord -Value 1

# Font smoothing.
Set-ItemProperty -LiteralPath 'HKCU:\Control Panel\Desktop' -Name FontSmoothing -Type String -Value '2'
Set-ItemProperty -LiteralPath 'HKCU:\Control Panel\Desktop' -Name FontSmoothingType -Type DWord -Value 2
Set-ItemProperty -LiteralPath 'HKCU:\Control Panel\Desktop' -Name FontSmoothingGamma -Type DWord -Value 1400
Set-ItemProperty -LiteralPath 'HKCU:\Control Panel\Desktop' -Name FontSmoothingOrientation -Type DWord -Value 1

# Microsoft YaHei for desktop, Explorer and shell UI metrics.
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct LOGFONT {
    public int lfHeight;
    public int lfWidth;
    public int lfEscapement;
    public int lfOrientation;
    public int lfWeight;
    public byte lfItalic;
    public byte lfUnderline;
    public byte lfStrikeOut;
    public byte lfCharSet;
    public byte lfOutPrecision;
    public byte lfClipPrecision;
    public byte lfQuality;
    public byte lfPitchAndFamily;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
    public string lfFaceName;
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct NONCLIENTMETRICS {
    public int cbSize;
    public int iBorderWidth;
    public int iScrollWidth;
    public int iScrollHeight;
    public int iCaptionWidth;
    public int iCaptionHeight;
    public LOGFONT lfCaptionFont;
    public int iSmCaptionWidth;
    public int iSmCaptionHeight;
    public LOGFONT lfSmCaptionFont;
    public int iMenuWidth;
    public int iMenuHeight;
    public LOGFONT lfMenuFont;
    public LOGFONT lfStatusFont;
    public LOGFONT lfMessageFont;
    public int iPaddedBorderWidth;
}

public static class NativeVisualFix {
    public const int SPI_GETNONCLIENTMETRICS = 0x0029;
    public const int SPI_SETNONCLIENTMETRICS = 0x002A;
    public const int SPI_SETICONTITLELOGFONT = 0x0022;
    public const int SPI_SETDRAGFULLWINDOWS = 0x0025;
    public const int SPIF_UPDATEINIFILE = 0x01;
    public const int SPIF_SENDCHANGE = 0x02;

    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SystemParametersInfo(int uiAction, int uiParam, ref NONCLIENTMETRICS pvParam, int fWinIni);

    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SystemParametersInfo(int uiAction, int uiParam, ref LOGFONT pvParam, int fWinIni);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uiAction, int uiParam, IntPtr pvParam, int fWinIni);

    public static byte[] StructToBytes<T>(T value) where T : struct {
        int size = Marshal.SizeOf(typeof(T));
        byte[] bytes = new byte[size];
        IntPtr ptr = Marshal.AllocHGlobal(size);
        try {
            Marshal.StructureToPtr(value, ptr, false);
            Marshal.Copy(ptr, bytes, 0, size);
            return bytes;
        } finally {
            Marshal.FreeHGlobal(ptr);
        }
    }
}
'@

$fontName = 'Microsoft YaHei'
$ncm = New-Object NONCLIENTMETRICS
$ncm.cbSize = [Runtime.InteropServices.Marshal]::SizeOf([type][NONCLIENTMETRICS])
[NativeVisualFix]::SystemParametersInfo([NativeVisualFix]::SPI_GETNONCLIENTMETRICS, $ncm.cbSize, [ref]$ncm, 0) | Out-Null
foreach ($field in 'lfCaptionFont','lfSmCaptionFont','lfMenuFont','lfStatusFont','lfMessageFont') {
  $font = $ncm.$field
  $font.lfFaceName = $fontName
  $font.lfCharSet = 134
  $font.lfQuality = 5
  $ncm.$field = $font
}
[NativeVisualFix]::SystemParametersInfo([NativeVisualFix]::SPI_SETNONCLIENTMETRICS, $ncm.cbSize, [ref]$ncm, [NativeVisualFix]::SPIF_UPDATEINIFILE -bor [NativeVisualFix]::SPIF_SENDCHANGE) | Out-Null

$iconFont = $ncm.lfMessageFont
$iconFont.lfFaceName = $fontName
$iconFont.lfCharSet = 134
$iconFont.lfQuality = 5
[NativeVisualFix]::SystemParametersInfo([NativeVisualFix]::SPI_SETICONTITLELOGFONT, [Runtime.InteropServices.Marshal]::SizeOf([type][LOGFONT]), [ref]$iconFont, [NativeVisualFix]::SPIF_UPDATEINIFILE -bor [NativeVisualFix]::SPIF_SENDCHANGE) | Out-Null
[NativeVisualFix]::SystemParametersInfo([NativeVisualFix]::SPI_SETDRAGFULLWINDOWS, 1, [IntPtr]::Zero, [NativeVisualFix]::SPIF_UPDATEINIFILE -bor [NativeVisualFix]::SPIF_SENDCHANGE) | Out-Null

$wmKey = 'HKCU:\Control Panel\Desktop\WindowMetrics'
New-Item -Path $wmKey -Force | Out-Null
Set-ItemProperty -LiteralPath $wmKey -Name CaptionFont -Type Binary -Value ([NativeVisualFix]::StructToBytes($ncm.lfCaptionFont))
Set-ItemProperty -LiteralPath $wmKey -Name SmCaptionFont -Type Binary -Value ([NativeVisualFix]::StructToBytes($ncm.lfSmCaptionFont))
Set-ItemProperty -LiteralPath $wmKey -Name MenuFont -Type Binary -Value ([NativeVisualFix]::StructToBytes($ncm.lfMenuFont))
Set-ItemProperty -LiteralPath $wmKey -Name StatusFont -Type Binary -Value ([NativeVisualFix]::StructToBytes($ncm.lfStatusFont))
Set-ItemProperty -LiteralPath $wmKey -Name MessageFont -Type Binary -Value ([NativeVisualFix]::StructToBytes($ncm.lfMessageFont))
Set-ItemProperty -LiteralPath $wmKey -Name IconFont -Type Binary -Value ([NativeVisualFix]::StructToBytes($iconFont))

Start-Service -Name FontCache -ErrorAction SilentlyContinue
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe
Write-Host "Win11 visual experience settings restored."
Write-Host "Backup folder: $backupRoot"
