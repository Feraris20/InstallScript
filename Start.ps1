Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Select Actions to Run"
$form.Size = New-Object System.Drawing.Size(500,300)
$form.StartPosition = "CenterScreen"

# Create checkboxes
$checkboxes = @()

$cbEnableFeature = New-Object System.Windows.Forms.CheckBox
$cbEnableFeature.Text = "Enable .NET Framework 3.5"
$cbEnableFeature.Location = New-Object System.Drawing.Point(20,20)
$cbEnableFeature.AutoSize = $true
$cbEnableFeature.Checked = $true
$checkboxes += $cbEnableFeature

$cbInstallAppInstaller = New-Object System.Windows.Forms.CheckBox
$cbInstallAppInstaller.Text = "Install Microsoft App Installer"
$cbInstallAppInstaller.Location = New-Object System.Drawing.Point(20,50)
$cbInstallAppInstaller.AutoSize = $true
$cbInstallAppInstaller.Checked = $true
$checkboxes += $cbInstallAppInstaller

$cbInstallApps = New-Object System.Windows.Forms.CheckBox
$cbInstallApps.Text = "Install Applications (VSCode, vcredist, NanaZip, Shell)"
$cbInstallApps.Location = New-Object System.Drawing.Point(20,80)
$cbInstallApps.AutoSize = $true
$cbInstallApps.Checked = $true
$checkboxes += $cbInstallApps

$cbWindowsDefender = New-Object System.Windows.Forms.CheckBox
$cbWindowsDefender.Text = "Disable Windows Defender (zoicware DefenderProTools)"
$cbWindowsDefender.Location = New-Object System.Drawing.Point(20,110)
$cbWindowsDefender.AutoSize = $true
$cbWindowsDefender.Checked = $true
$checkboxes += $cbWindowsDefender

# Create the Run button
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Run Selected"
$runButton.Size = New-Object System.Drawing.Size(150,30)
$runButton.Location = New-Object System.Drawing.Point(20,150)

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
    } else {
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

    # Prepare scriptblocks for each action
    $scriptBlocks = @()

    if ($cbEnableFeature.Checked) {
        $scriptBlocks += {
            try {
                Write-Host "Enabling .NET Framework 3.5..."
                Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart -ErrorAction Stop
            } catch {
                Write-Host "Error enabling .NET Framework: $_"
            }
        }
    }

    if ($cbInstallAppInstaller.Checked) {
        $scriptBlocks += {
            try {
                Write-Host "Installing Microsoft App Installer..."
                winget install --id=Microsoft.AppInstaller --accept-source-agreements --accept-package-agreements --silent
            } catch {
                Write-Host "Error installing App Installer: $_"
            }
        }
    }

    if ($cbInstallApps.Checked) {
        $scriptBlocks += {
            try {
                $apps = @("Microsoft.VisualStudioCode", "abbodi1406.vcredist", "M2Team.NanaZip", "Nilesoft.Shell")
                foreach ($app in $apps) {
                    Write-Host "Installing $app ..."
                    winget install --id=$app --accept-source-agreements --accept-package-agreements --silent
                }
            } catch {
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
        } catch {
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
    } else {
        # Already proceeded (if countdown finished)
        proceedWithActions
    }
})

# Show the form
[void]$form.ShowDialog()