

$script = if ($PSCommandPath) {
    "& { & `'$($PSCommandPath)`' $($argList -join ' ') }"
}
else {
    "&([ScriptBlock]::Create((irm https://raw.githubusercontent.com/Feraris20/InstallScript/refs/heads/main/Main.ps1))) $($argList -join ' ')"
}

$powershellCmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
$processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { "$powershellCmd" }

if ($processCmd -eq "wt.exe") {
    Start-Process $processCmd -ArgumentList "$powershellCmd -ExecutionPolicy Bypass -NoProfile -Command `"$script`"" -Verb RunAs
}
else {
    Start-Process $processCmd -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"$script`"" -Verb RunAs
}


exit