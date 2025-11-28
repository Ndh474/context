# Configuration
$services = @(
    @{ 
        Name = "RECOGNITION"
        Path = "recognition-service"
        Command = "poetry"
        Args = @("run", "uvicorn", "src.recognition_service.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload")
        Color = "Cyan"
        Url = "http://localhost:8000"
    },
    @{ 
        Name = "FRONTEND"
        Path = "frontend-web"
        Command = "cmd"
        Args = @("/c", "npm", "run", "dev")
        Color = "Green"
        Url = "http://localhost:3000"
    },
    @{ 
        Name = "BACKEND"
        Path = "backend"
        Command = "cmd"
        Args = @("/c", "mvnw.cmd", "spring-boot:run")
        Color = "Yellow"
        Url = "http://localhost:8080"
    }
)

# Filter services that don't exist
$existingServices = @()
foreach ($svc in $services) {
    $fullPath = Join-Path $PSScriptRoot $svc.Path
    if (Test-Path $fullPath) {
        $existingServices += $svc
    }
}
$services = $existingServices

# Global state
$global:runningProcesses = @{}
$global:serviceLogs = @{}
foreach ($s in $services) {
    $global:serviceLogs[$s.Name] = New-Object System.Collections.Generic.List[string]
}
$global:consoleLock = [System.Object]::new()
$global:needsRedraw = $true
$global:currentView = "MAIN" # MAIN or DETAIL
$global:selectedServiceIndex = -1

$MAX_LOG_BUFFER = 200
$DETAIL_LOG_LINES = 30

function Stop-Service {
    param($Name)
    if ($global:runningProcesses.ContainsKey($Name)) {
        $proc = $global:runningProcesses[$Name]
        if (-not $proc.HasExited) {
            $null = & taskkill /F /T /PID $proc.Id 2>&1
        }
        $global:runningProcesses.Remove($Name)
    }
}

function Stop-All {
    $keys = @($global:runningProcesses.Keys)
    foreach ($key in $keys) {
        Stop-Service -Name $key
    }
}

function Draw-Main-View {
    Write-Host "=== FUACS System Manager ===" -ForegroundColor Magenta
    Write-Host "----------------------------"
    
    # Status List
    for ($i = 0; $i -lt $services.Count; $i++) {
        $svc = $services[$i]
        $status = "STOPPED"
        $statusColor = "Gray"
        
        if ($global:runningProcesses.ContainsKey($svc.Name)) {
            if ($global:runningProcesses[$svc.Name].HasExited) {
                $status = "EXITED"
                $statusColor = "Red"
            } else {
                $status = "RUNNING"
                $statusColor = "Green"
            }
        }

        Write-Host "$($i + 1). $($svc.Name)" -NoNewline -ForegroundColor $svc.Color
        Write-Host " [$status]" -ForegroundColor $statusColor
        Write-Host "   Url: $($svc.Url)" -ForegroundColor DarkGray
    }
    
    Write-Host "----------------------------"
    Write-Host "0. Start All Services"
    Write-Host "R. Restart All Services"
    Write-Host "Q. Stop All & Quit"
    Write-Host "----------------------------"
    Write-Host "Select an option (0, R, 1-3 for details, Q): " -NoNewline
}

function Draw-Detail-View {
    $svc = $services[$global:selectedServiceIndex]
    $status = "STOPPED"
    if ($global:runningProcesses.ContainsKey($svc.Name) -and -not $global:runningProcesses[$svc.Name].HasExited) {
        $status = "RUNNING"
    }

    Write-Host "=== $($svc.Name) Details ===" -ForegroundColor $svc.Color
    Write-Host "Status: $status" -ForegroundColor $(if($status -eq 'RUNNING'){'Green'}else{'Red'})
    Write-Host "Url: $($svc.Url)"
    Write-Host "----------------------------"
    Write-Host "R. Restart Service"
    Write-Host "B. Back to Main Menu"
    Write-Host "S. Stop Service"
    Write-Host "----------------------------"
    Write-Host "Last $DETAIL_LOG_LINES lines of logs:"
    Write-Host "----------------------------"

    $logs = $global:serviceLogs[$svc.Name]
    $count = $logs.Count
    $start = [Math]::Max(0, $count - $DETAIL_LOG_LINES)
    
    $width = [Console]::WindowWidth - 1
    if ($width -lt 10) { $width = 80 }

    for ($i = $start; $i -lt $count; $i++) {
        $line = $logs[$i]
        if ($line.Length -gt $width) {
            $line = $line.Substring(0, $width)
        }
        Write-Host $line
    }
}

function Draw-Screen {
    [System.Threading.Monitor]::Enter($global:consoleLock)
    try {
        [Console]::CursorVisible = $false
        Clear-Host # Simple clear for this logic as we redraw full screen content differently
        
        if ($global:currentView -eq "MAIN") {
            Draw-Main-View
        } else {
            Draw-Detail-View
        }
    } finally {
        [Console]::CursorVisible = $true
        [System.Threading.Monitor]::Exit($global:consoleLock)
    }
}

function global:Write-Log {
    param($Name, $Message, $Color)
    
    [System.Threading.Monitor]::Enter($global:consoleLock)
    try {
        if (-not $global:serviceLogs.ContainsKey($Name)) {
             $global:serviceLogs[$Name] = New-Object System.Collections.Generic.List[string]
        }
        $logList = $global:serviceLogs[$Name]
        
        $logList.Add($Message)
        while ($logList.Count -gt $MAX_LOG_BUFFER) {
            $logList.RemoveAt(0)
        }
        
        # Only trigger redraw if we are in detail view of this service
        if ($global:currentView -eq "DETAIL" -and $services[$global:selectedServiceIndex].Name -eq $Name) {
            $global:needsRedraw = $true
        }
    } finally {
        [System.Threading.Monitor]::Exit($global:consoleLock)
    }
}

function Start-Service {
    param($SvcConfig)
    $Name = $SvcConfig.Name
    
    if ($global:runningProcesses.ContainsKey($Name)) {
        Stop-Service -Name $Name
    }

    $workingDir = Join-Path $PSScriptRoot $SvcConfig.Path
    $command = $SvcConfig.Command
    
    if ($command -match "^\.\\") {
        $command = Join-Path $workingDir ($command -replace "^\.\\", "")
    }

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $command
    $pinfo.Arguments = $SvcConfig.Args -join " "
    $pinfo.WorkingDirectory = $workingDir
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true
    $pinfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $pinfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.EnableRaisingEvents = $true

    $action = {
        $line = $Event.SourceEventArgs.Data
        if ($line) {
            Write-Log -Name $Event.MessageData.Name -Message $line -Color $Event.MessageData.Color
        }
    }

    Register-ObjectEvent -InputObject $p -EventName "OutputDataReceived" -Action $action -MessageData $SvcConfig | Out-Null
    Register-ObjectEvent -InputObject $p -EventName "ErrorDataReceived" -Action $action -MessageData $SvcConfig | Out-Null

    Write-Log -Name $Name -Message "Starting..." -Color "White"
    try {
        $p.Start() | Out-Null
        $p.BeginOutputReadLine()
        $p.BeginErrorReadLine()
        $global:runningProcesses[$Name] = $p
        $global:needsRedraw = $true # Update status in main menu
    } catch {
        Write-Log -Name $Name -Message "Failed to start: $_" -Color "Red"
    }
}

# Main execution
try {
    Draw-Screen
    
    while ($true) {
        if ($global:needsRedraw) {
            Draw-Screen
            $global:needsRedraw = $false
        }

        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            $char = $key.KeyChar.ToString().ToLower()
            
            if ($global:currentView -eq "MAIN") {
                switch ($char) {
                    '0' {
                        foreach ($svc in $services) { Start-Service -SvcConfig $svc }
                    }
                    'r' {
                        Stop-All
                        foreach ($key in $global:serviceLogs.Keys) { $global:serviceLogs[$key].Clear() }
                        foreach ($svc in $services) { Start-Service -SvcConfig $svc }
                    }
                    'q' {
                        Stop-All
                        Clear-Host
                        exit
                    }
                    default {
                        # Check for 1, 2, 3...
                        if ($char -match '^[1-9]$') {
                            $idx = [int]$char - 1
                            if ($idx -ge 0 -and $idx -lt $services.Count) {
                                $global:selectedServiceIndex = $idx
                                $global:currentView = "DETAIL"
                                $global:needsRedraw = $true
                            }
                        }
                    }
                }
            } elseif ($global:currentView -eq "DETAIL") {
                switch ($char) {
                    'r' { # Restart
                        $svc = $services[$global:selectedServiceIndex]
                        Start-Service -SvcConfig $svc
                    }
                    'b' { # Back
                        $global:currentView = "MAIN"
                        $global:needsRedraw = $true
                    }
                    's' { # Stop
                        $svc = $services[$global:selectedServiceIndex]
                        Stop-Service -Name $svc.Name
                        $global:needsRedraw = $true
                    }
                }
            }
        }
        
        Start-Sleep -Milliseconds 100
    }
} finally {
    Stop-All
}
