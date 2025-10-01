Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Main Installer"
$form.Size = New-Object System.Drawing.Size(500,350)
$form.StartPosition = "CenterScreen"

# Checkbox for .NET Framework 3.5
$checkboxNetFx = New-Object System.Windows.Forms.CheckBox
$checkboxNetFx.Text = "Enable .NET Framework 3.5"
$checkboxNetFx.AutoSize = $true
$checkboxNetFx.Location = New-Object System.Drawing.Point(20,20)
$form.Controls.Add($checkboxNetFx)

# Checkbox for Microsoft App Installer
$checkboxAppInstaller = New-Object System.Windows.Forms.CheckBox
$checkboxAppInstaller.Text = "Install Microsoft App Installer"
$checkboxAppInstaller.AutoSize = $true
$checkboxAppInstaller.Checked = $true
$checkboxAppInstaller.Location = New-Object System.Drawing.Point(20,50)
$form.Controls.Add($checkboxAppInstaller)

# Checkbox for installing additional apps
$checkboxApps = New-Object System.Windows.Forms.CheckBox
$checkboxApps.Text = "Install Additional Apps"
$checkboxApps.AutoSize = $true
$checkboxApps.Checked = $true
$checkboxApps.Location = New-Object System.Drawing.Point(20,80)
$form.Controls.Add($checkboxApps)

# Checkbox for "Install Floorp + Extras" (checked by default)
$checkboxFloorpExtras = New-Object System.Windows.Forms.CheckBox
$checkboxFloorpExtras.Text = "Install Floorp + Extras"
$checkboxFloorpExtras.AutoSize = $true
$checkboxFloorpExtras.Checked = $true
$checkboxFloorpExtras.Location = New-Object System.Drawing.Point(20,110)
$form.Controls.Add($checkboxFloorpExtras)

# Apply Button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Apply"
$button.Size = New-Object System.Drawing.Size(80,30)
$button.Location = New-Object System.Drawing.Point(350,290)
$form.Controls.Add($button)

# Button click event
$button.Add_Click({
    # Clear the console
    Clear-Host
    Write-Host "Starting operations..." -ForegroundColor Cyan

    # Enable .NET Framework 3.5
    if ($checkboxNetFx.Checked) {
        Write-Host "Enabling .NET Framework 3.5..." -ForegroundColor Yellow
        try {
            Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart -ErrorAction Stop
            Write-Host ".NET Framework 3.5 enabled successfully." -ForegroundColor Green
        } catch {
            Write-Host "Error enabling .NET Framework 3.5: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Install Microsoft App Installer
    if ($checkboxAppInstaller.Checked) {
        Write-Host "Installing Microsoft App Installer..." -ForegroundColor Yellow
        try {
            winget install --id=Microsoft.AppInstaller --accept-source-agreements --accept-package-agreements
            Write-Host "Microsoft App Installer installed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Error installing Microsoft App Installer: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Install additional apps
    if ($checkboxApps.Checked) {
        $apps = @(
            "Microsoft.VisualStudioCode",
            "abbodi1406.vcredist",
            "M2Team.NanaZip",
            "IrfanSkiljan.IrfanView",
            "IrfanSkiljan.IrfanView.PlugIns",
            "CodecGuide.K-LiteCodecPack.Standard",
            "Ablaze.Floorp",
            "Nilesoft.Shell"
        )
        foreach ($app in $apps) {
            Write-Host "Installing $app ..." -ForegroundColor Cyan
            try {
                winget install --id=$app --accept-source-agreements --accept-package-agreements --silent
                Write-Host "$app installed successfully." -ForegroundColor Green
            } catch {
                Write-Host "Error installing $($app): ${($_.Exception.Message)}" -ForegroundColor Red
            }
            Start-Sleep -Seconds 1
        }
        Write-Host "All selected apps installed." -ForegroundColor Cyan
    }

    # Install Floorp + Extras if checked
    if ($checkboxFloorpExtras.Checked) {
        Write-Host "Installing Floorp + Extras..." -ForegroundColor Yellow
        try {
            # Replace 'YourRegistryPath' with the actual registry path you want to use
            $registryPath = "HKCU:\Software\YourApp"  # Example path; replace as needed

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
            } else {
                Write-Host "Registry path or default value not found." -ForegroundColor Red
            }
        } catch {
            Write-Host "Error during Floorp + Extras setup: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "Operations completed." -ForegroundColor Cyan
})

# Show the form
$form.Show()
[System.Windows.Forms.Application]::Run()