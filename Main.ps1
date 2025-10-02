Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Main Installer"
$form.Size = New-Object System.Drawing.Size(520,400)
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

# Checkbox for Disable Services
$checkboxDisableServices = New-Object System.Windows.Forms.CheckBox
$checkboxDisableServices.Text = "Disable Selected Services"
$checkboxDisableServices.AutoSize = $true
$checkboxDisableServices.Location = New-Object System.Drawing.Point(20,140)
$form.Controls.Add($checkboxDisableServices)

# Apply Button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Apply"
$button.Size = New-Object System.Drawing.Size(80,30)
$button.Location = New-Object System.Drawing.Point(420,350)
$form.Controls.Add($button)

# Function to configure services with loops
function Configure-Services {
    # List of services to disable
    $servicesToDisable = @(
        "AJRouter","AppVClient","Appinfo","AssignedAccessManagerSvc","BDESVC",
        "BTAGService","BcastDVRUserService","BluetoothUserService","DiagTrack",
        "DialogBlockingService","DevQueryBroker","DeviceAssociationService",
        "DeviceInstall","DevicePickerUserSvc","DevicesFlowUserSvc","RemoteAccess",
        "RemoteRegistry","SensorDataService","SensrSvc","SharedAccess",
        "SmsRouter","StiSvc","StateRepository","StorSvc","TapiSrv",
        "TextInputManagementService","TieringEngineService","TokenBroker",
        "TroubleshootingSvc","UdkUserSvc","UnistoreSvc","WpnService","WwanSvc",
        "autotimesvc","bthserv","cbdhsvc","cloudidsvc","dcsvc","defragsvc",
        "diagnosticshub.standardcollector.service","diagsvc","dmwappushservice",
        "dot3svc","embeddedmode","fdPHost","fhsvc","hidserv","icssvc",
        "lfsvc","lltdsvc","lmhosts","netprofm","p2pimsvc","p2psvc",
        "perceptionsimulation","seclogon","smphost","svsvc","swprv",
        "tzautoupdate","upnphost","vds","vmicguestinterface","vmicheartbeat",
        "vmickvpexchange","vmicrdv","vmicshutdown","vmictimesync","vmicvmsession",
        "vmicvss","vmvss","wbengine","wcncsvc","webthreatdefsvc","wercplsupport",
        "wisvc","wlidsvc","wlpasvc","wmiApSrv","workfolderssvc","wuauserv",
        "wudfsvc"
    )

    # List of services to set to demand
    $servicesToDemand = @(
        "ALG","AppIDSvc","AppMgmt","AppReadiness","AppXSvc","CertPropSvc","ClipSVC",
        "ConsentUxUserSvc","CscService","DeviceInstall","DevicePickerUserSvc",
        "DevicesFlowUserSvc","DisplayEnhancementService","DmEnrollmentSvc","DsSvc",
        "DsmSvc","EFS","EapHost","EntAppSvc","FDResPub","FrameServer",
        "FrameServerMonitor","GraphicsPerfSvc","HvHost","IEEtwCollectorService",
        "InstallService","InventorySvc","IpxlatCfgSvc","KtmRm","LicenseManager",
        "LxpSvc","MSDTC","MSiSCSI","McpManagementService","MessagingService",
        "MicrosoftEdgeElevationService","MsKeyboardFilter","NPSMSvc",
        "NaturalAuthentication","NcaSvc","NcbService","NcdAutoSetup",
        "NetSetupSvc","NetTcpPortSharing","Netman","NgcCtnrSvc","NgcSvc",
        "NlaSvc","P9RdrService","PNRPAutoReg","PNRPsvc","PcaSvc","PeerDistSvc",
        "PenService","PerfHost","PhoneSvc","PimIndexMaintenanceSvc","PlugPlay",
        "PolicyAgent","PrintNotify","PushToInstall","QWAVE","RasAuto","RasMan",
        "SCPolicySvc","SCardSvr","SDRSVC","SEMgrSvc","SNMPTRAP","SNMPTrap",
        "SSDPSRV","ScDeviceEnum","SensorService","SessionEnv","SmsRouter",
        "SstpSvc","StiSvc","WerSvc","WiaRpc","WinHttpAutoProxySvc","WinRM",
        "WpcMonSvc","WdiServiceHost","WdiSystemHost","WebClient",
        "Wecsvc","Wersvc","WiaRpc","WinHttpAutoProxySvc","WinRM","WpcMonSvc",
        "WdiServiceHost","WdiSystemHost","webthreatdefsvc","wermgr","WbioSrvc"
    )

    # Disable services loop with output
    foreach ($service in $servicesToDisable) {
        try {
            $svc = Get-WmiObject -Class Win32_Service -Filter "Name='$service'"
            if ($svc) {
                $result = $svc.ChangeStartMode("Disabled")
                if ($result.ReturnValue -eq 0) {
                    Write-Host "Disabled service: $service" -ForegroundColor Gray
                } else {
                    Write-Host "Failed to disable $service (ReturnCode: $($result.ReturnValue))" -ForegroundColor Red
                }
            } else {
                Write-Host "Service not found: $service" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Error disabling $service : $_" -ForegroundColor Red
        }
    }

    # Set services to demand with output
    foreach ($service in $servicesToDemand) {
        try {
            $svc = Get-WmiObject -Class Win32_Service -Filter "Name='$service'"
            if ($svc) {
                $result = $svc.ChangeStartMode("Manual")
                if ($result.ReturnValue -eq 0) {
                    Write-Host "Set service to demand: $service" -ForegroundColor Gray
                } else {
                    Write-Host "Failed to set $service to demand (ReturnCode: $($result.ReturnValue))" -ForegroundColor Red
                }
            } else {
                Write-Host "Service not found: $service" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Error setting $service to demand: $_" -ForegroundColor Red
        }
    }

    Write-Host "Service configuration complete." -ForegroundColor Cyan
}

# Your Apply button click event
$button.Add_Click({
    # Clear the console
    Clear-Host
    Write-Host "Starting operations..." -ForegroundColor Cyan

    # 1. Enable .NET Framework 3.5
    if ($checkboxNetFx.Checked) {
        Write-Host "Enabling .NET Framework 3.5..." -ForegroundColor Yellow
        try {
            Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart -ErrorAction Stop
            Write-Host ".NET Framework 3.5 enabled successfully." -ForegroundColor Green
        } catch {
            Write-Host "Error enabling .NET Framework 3.5: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # 2. Install Microsoft App Installer
    if ($checkboxAppInstaller.Checked) {
        Write-Host "Installing Microsoft App Installer..." -ForegroundColor Yellow
        try {
            winget install --id=Microsoft.AppInstaller --accept-source-agreements --accept-package-agreements
            Write-Host "Microsoft App Installer installed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Error installing Microsoft App Installer: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # 3. Install additional apps
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

    # 4. Install Floorp + Extras if checked
    if ($checkboxFloorpExtras.Checked) {
        Write-Host "Installing Floorp + Extras..." -ForegroundColor Yellow
        Install-FloorpExtras
    }

    # 5. Configure services if checkbox checked
    if ($checkboxDisableServices.Checked) {
        Write-Host "Configuring services (disable then demand)..." -ForegroundColor Yellow
        Configure-Services
    }

    Write-Host "Operations completed." -ForegroundColor Cyan
})

# Show the form
$form.Show()
[System.Windows.Forms.Application]::Run()