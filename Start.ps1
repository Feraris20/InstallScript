if ($env:IS_RELAUNCH -ne "1") {
    $env:IS_RELAUNCH = "1"

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
    $env:IS_RELAUNCH = "0"
    exit
}

Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Select Actions to Run"
$form.Size = New-Object System.Drawing.Size(500, 300)
$form.StartPosition = "CenterScreen"

# Create checkboxes
$checkboxes = @()

$cbEnableFeature = New-Object System.Windows.Forms.CheckBox
$cbEnableFeature.Text = "Enable .NET Framework 3.5"
$cbEnableFeature.Location = New-Object System.Drawing.Point(20, 20)
$cbEnableFeature.AutoSize = $true
$cbEnableFeature.Checked = $true
$checkboxes += $cbEnableFeature

$cbInstallAppInstaller = New-Object System.Windows.Forms.CheckBox
$cbInstallAppInstaller.Text = "Install Microsoft App Installer"
$cbInstallAppInstaller.Location = New-Object System.Drawing.Point(20, 50)
$cbInstallAppInstaller.AutoSize = $true
$cbInstallAppInstaller.Checked = $true
$checkboxes += $cbInstallAppInstaller

$cbInstallApps = New-Object System.Windows.Forms.CheckBox
$cbInstallApps.Text = "Install Applications (VSCode, vcredist, NanaZip, Shell)"
$cbInstallApps.Location = New-Object System.Drawing.Point(20, 80)
$cbInstallApps.AutoSize = $true
$cbInstallApps.Checked = $true
$checkboxes += $cbInstallApps

$cbInstallFloorpExtras = New-Object System.Windows.Forms.CheckBox
$cbInstallFloorpExtras.Text = "Install Floorp + Extras"
$cbInstallFloorpExtras.Location = New-Object System.Drawing.Point(20, 110)
$cbInstallFloorpExtras.AutoSize = $true
$cbInstallFloorpExtras.Checked = $true
$checkboxes += $cbInstallFloorpExtras


$cbWindowsDefender = New-Object System.Windows.Forms.CheckBox
$cbWindowsDefender.Text = "Disable Windows Defender (kutt.it/off)" #(zoicware DefenderProTools)"
$cbWindowsDefender.Location = New-Object System.Drawing.Point(20, 140)
$cbWindowsDefender.AutoSize = $true
$cbWindowsDefender.Checked = $false #$true
$checkboxes += $cbWindowsDefender

# Create the Run button
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Run Selected"
$runButton.Size = New-Object System.Drawing.Size(150, 30)
$runButton.Location = New-Object System.Drawing.Point(20, 170)

# Add controls to form
$form.Controls.AddRange($checkboxes + @($runButton))

# Timer for countdown
$countdownTimer = New-Object System.Windows.Forms.Timer
$countdownTimer.Interval = 1000  # 1 second

# Variables
$secondsRemaining = 15
$mouseMovedDuringCountdown = $false

# Function to update button text
function Update-ButtonText {
    param($remaining)
    $runButton.Text = "Proceed in $remaining s"
}

# Mouse move event handler
$mouseMoved = {
    if ($countdownTimer.Enabled) {
        $mouseMovedDuringCountdown = $true
        $countdownTimer.Stop()
        $runButton.Text = "Run Selected"
        Write-Host "Mouse moved. Countdown canceled. Please click 'Run Selected' to proceed."
    }
}
$form.Add_MouseMove($mouseMoved)
$form.Add_MouseDown($mouseMoved)
$form.Add_MouseHover($mouseMoved)

# When form loads (shown), start countdown
$form.Add_Shown({
        $secondsRemaining = 15
        Update-ButtonText $secondsRemaining
        $countdownTimer.Start()
    })


# Timer tick event
$countdownTimer.Add_Tick({
        $secondsRemaining--
        if ($secondsRemaining -gt 0) {
            Update-ButtonText $secondsRemaining
        }
        else {
            $countdownTimer.Stop()
            $runButton.Text = "Running..."
            proceedWithActions
        }
    })

# Function to run selected actions in parallel runspaces
function proceedWithActions {
    # Minimize the form
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    # Disable button to prevent re-entry
    $runButton.Enabled = $false

    if ($cbInstallAppInstaller.Checked) {
        $scriptBlocks += {
            try {
                Write-Host "Installing Microsoft App Installer..."
                winget install --id=Microsoft.AppInstaller --accept-source-agreements --accept-package-agreements --silent                
            }
            catch {
                Write-Host "Error installing App Installer: $_"
            }
        }
    }

    # Prepare scriptblocks for each action
    $scriptBlocks = @()

    if ($cbEnableFeature.Checked) {
        $scriptBlocks += {
            try {
                Write-Host "Enabling .NET Framework 3.5..."
                Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart -ErrorAction Stop
            }
            catch {
                Write-Host "Error enabling .NET Framework: $_"
            }
        }
    }


    if ($cbInstallApps.Checked) {
        $scriptBlocks += {
            try {
                $apps = @("Microsoft.VisualStudioCode", "abbodi1406.vcredist", "M2Team.NanaZip", "IrfanSkiljan.IrfanView", "IrfanSkiljan.IrfanView.PlugIns", "CodecGuide.K-LiteCodecPack.Standard", "Ablaze.Floorp", "Nilesoft.Shell")
                foreach ($app in $apps) {
                    Write-Host "Installing $app ..."
                    winget install --id=$app --accept-source-agreements --accept-package-agreements --silent
                    Start-Sleep 1
                    Write-Output "sssssssssInstalling $app ..."
                }
            }
            catch {
                Write-Host "Error installing applications: $_"
            }
        }
    }


    # Run each scriptblock in a runspace
    $runspaces = @()
    foreach ($sb in $scriptBlocks) {
        $ps = [PowerShell]::Create()
        $ps.AddScript($sb)
        $asyncResult = $ps.BeginInvoke()
        $runspaces += [PSCustomObject]@{ PowerShellInstance = $ps; AsyncResult = $asyncResult }
    }

    # Wait for all runspaces to finish
    foreach ($rs in $runspaces) {
        $rs.PowerShellInstance.EndInvoke($rs.AsyncResult)
        $rs.PowerShellInstance.Dispose()
    }

    if ($cbInstallFloorpExtras.Checked) {
        $scriptBlocks += {
            try {
                # Replace 'program.exe' with the actual executable name
                $executableName = "floorp.exe"

                # Registry path to check
                $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$executableName"

                try {
                    # Get the default value which usually contains the full path
                    $programPath = (Get-ItemProperty -Path $registryPath -ErrorAction Stop).'(Default)'
    
                    if ($programPath) {
                        # Extract the directory from the full path
                        $installDirectory = Split-Path $programPath -Parent

                        # Define the 'distribution' folder path
                        $distributionFolder = Join-Path -Path $installDirectory -ChildPath "distribution"

                        # Create the 'distribution' folder if it doesn't exist
                        if (-Not (Test-Path -Path $distributionFolder)) {
                            New-Item -Path $distributionFolder -ItemType Directory | Out-Null
                            Write-Output "Created folder: $distributionFolder"
                        }
                        else {
                            Write-Output "Folder already exists: $distributionFolder"
                        }

                        # Path for policies.json
                        $policiesFilePath = Join-Path -Path $distributionFolder -ChildPath "policies.json"

                        # Define the JSON content
                        $jsonContent = @"
{
  "policies": {
    "Extensions": {
      "Install": [
        "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi",
        "https://addons.mozilla.org/firefox/downloads/latest/adguard-adblocker/latest.xpi"
      ],
      "InstallSources": [
        "https://addons.mozilla.org"
      ]
    }
  }
}
"@

                        # Write JSON to file without BOM
                        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                        [System.IO.File]::WriteAllText($policiesFilePath, $jsonContent, $utf8NoBom)
                        Write-Output "Created policies.json at: $policiesFilePath"
                    }
                    else {
                        Write-Output "Path not found in registry for $executableName"
                    }
                }
                catch {
                    Write-Output "Could not find registry key for $executableName."
                }            
            }
            catch {
                Write-Host "Error installing Floorp Extras: $_"
            }
        }
    }

    # After all other actions are complete, run Windows Defender disable if checked
    if ($cbWindowsDefender.Checked) {
        try {
            Write-Host "Disabling Windows Defender..."
            # Invoke-WebRequest https://raw.githubusercontent.com/zoicware/DefenderProTools/main/DisableDefender.ps1 | Invoke-Expression
            # Invoke-WebRequest kutt.it/off | Invoke-Expression -- "apply" "1"
            # iex "& { $(irm kutt.it/off) } apply 1"
            # cmd /c curl -Lo %tmp%\.cmd kutt.it/off&&%tmp%\.cmd
            cmd /c "curl -Lo %tmp%\.cmd kutt.it/off && %tmp%\.cmd apply 1"
            Write-Host "Windows Defender disabled."
        }
        catch {
            Write-Host "Error disabling Windows Defender: $_"
        }
    }

    # Indicate completion
    Write-Host "All selected actions completed."
    # Reset button text and enable
    $runButton.Text = "Run Selected"
    $runButton.Enabled = $true
}

# Button click handler
$runButton.Add_Click({
        if ($countdownTimer.Enabled) {
            $countdownTimer.Stop()
        }
        if ($mouseMovedDuringCountdown) {
            $mouseMovedDuringCountdown = $false
            proceedWithActions
        }
        else {
            # Already proceeded (if countdown finished)
            proceedWithActions
        }
    })



#     if ($env:IS_RELAUNCH -ne "1") {
#     $scriptPath = $MyInvocation.MyCommand.Path
#     $env:IS_RELAUNCH = "1"
#     Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
#     $env:IS_RELAUNCH = "0"
#     exit
# }

# Show the form
[void]$form.ShowDialog()