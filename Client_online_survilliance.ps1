<#
.SYNOPSIS
Dieses Skript überwacht den Status eines Zielhosts durch einen ICMP-Ping und optional durch Port-Knocking.

.DESCRIPTION
Dieses PowerShell-Skript überwacht den Status eines Zielhosts, indem es einen ICMP-Ping ausführt und optional Port-Knocking durchführt, um zu überprüfen, ob bestimmte Ports erreichbar sind. Es zeigt den aktuellen Status live in einer Tabelle an und speichert die Ergebnisse in einer CSV-Datei.

.PARAMETER Target
Die IP-Adresse oder der Hostname des Zielhosts.

.PARAMETER Port
Der gewünschte Zielport für das Port-Knocking.

.PARAMETER FRQ
Der Zeitabstand in Sekunden, in dem das Ziel überprüft wird. Standardwert ist 5 Sekunden.

.PARAMETER TIME
Die Gesamtzeit in Sekunden, wie lange das Ziel überprüft wird. Standardwert ist 600 Sekunden (10 Minuten).

.PARAMETER Knock
Gibt an, ob Port-Knocking ausgeführt werden soll, unabhängig vom Erfolg des ICMP-Pings.

.EXAMPLE
.\Client_online_surveillance.ps1 -Target 192.168.1.100 -Port 8080 -FRQ 10 -TIME 300

Überwacht den Status des Zielhosts 192.168.1.100 auf Port 8080 alle 10 Sekunden für insgesamt 300 Sekunden (5 Minuten).

.EXAMPLE
.\Client_online_surveillance.ps1 -Target google.com -Knock

Überwacht den Status des Zielhosts google.com, führt Port-Knocking durch und verwendet die Standardwerte für FRQ (5 Sekunden) und TIME (600 Sekunden).

#>

param (
    [string]$Target,
    [int]$Port,
    [int]$FRQ = 5,
    [int]$TIME = 600,
    [switch]$Knock,
	$PortsToKnock = @(80, 443, 22, 3389, 445, 139, 53, 161, 389, 636, 3268, 3269, 1433, 1521, 5432, 1521, 8080, 8443)
)

function Show-WorkingCursor {
    while ($true) {
        $cursorSymbols = "|", "\", "-", "/"
        foreach ($cursor in $cursorSymbols) {
            Write-Progress -Activity "Working" -Status $cursor -PercentComplete -1
            Start-Sleep -Milliseconds 100
        }
    }
}


function PerformICMPPing {
    param (
        [string]$Target
    )
    $ping = New-Object System.Net.NetworkInformation.Ping
    $pingResult = $ping.Send($Target)
    if ($pingResult.Status -eq "Success") {
        Write-Host ("ICMP Ping erfolgreich mit einer Zeit von {0} ms`n" -f $pingResult.RoundtripTime) -ForegroundColor Green
        return "Online"
    } else {
        Write-Host "ICMP Ping fehlgeschlagen: $($pingResult.Status)" -ForegroundColor Red
        return "Offline"
    }
}

function PerformPortKnocking {
    param (
        [string]$Target,
        [int[]]$PortsToKnock
    )
    
    $knockingTasks = @()
    $successPorts = @()
    $failedPorts = @()

    foreach ($Port in $PortsToKnock) {
        $knockingTask = {
            param (
                [string]$Target,
                [int]$Port
            )
            try {
                $knockClient = New-Object System.Net.Sockets.TcpClient
                $knockClient.Connect($Target, $Port)
                $knockClient.Close()
                return $Port
            } catch {
                return $Port
            }
        }

        $knockingTasks += Start-Job -ScriptBlock $knockingTask -ArgumentList $Target, $Port
    }

    $results = $knockingTasks | Wait-Job | Receive-Job
    $successPorts = $results | Where-Object { $_ -is [int] }
    $failedPorts = $results | Where-Object { $_ -is [int] -eq $false }

    Write-Host  # Move to the next line after the working cursor
    Write-Host "Erfolgreich angeklopft:" -ForegroundColor Green
    $successPorts
    Write-Host "Fehler beim Anklopfen:" -ForegroundColor Red
    $failedPorts
}

function ReportStatustoScreen {
    param (
        [string]$status,
        [int]$Port
    )
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $client.Connect($Target, $Port)
        $clientAddress = $client.Client.RemoteEndPoint.Address
        $clientPort = $client.Client.RemoteEndPoint.Port
        Write-Host ('Neue Verbindung von {0}:{1} zum Zielport {2}' -f $clientAddress, $clientPort, $Port)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter $stream
        $writer.WriteLine($status)
        $writer.Flush()
        $client.Close()
    } catch {
        Write-Host "Fehler beim Melden des Status: $_"
    }
}

function ReportStatustoFile {
    param (
        [string]$status,
        [int]$Port
    )
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $tableEntry = [PSCustomObject]@{
        "Timestamp" = $timeStamp
        "Status" = $status
        "Port" = $Port
    }
    $tableEntry | Format-Table -AutoSize
    $tableEntry | Export-Csv -Append -NoTypeInformation -Path "StatusReport.csv"
}

function Main {
    $status = PerformICMPPing $Target
    $reportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	ReportStatustoFile $status $Port
	
	$icmpPingSuccessful = PerformICMPPing $Target

    
        if (-not $icmpPingSuccessful -or $Knock) {
			Write-Host "Port Knocking wird durchgeführt auf die Ports: $PortsToKnock"
            PerformPortKnocking -Target $Target -portsToKnock $PortsToKnock
            $Port = Read-Host "Geben Sie den gewünschten Zielport ein+"
        }
    

    # Tabellenausgabe on demand und Schreiben in CSV-Datei
    $endTime = (Get-Date).AddSeconds($TIME)
    while ((Get-Date) -le $endTime) {
        $pingResult = PerformICMPPing $Target
        if ($pingResult) {
            ReportStatustoFile "Online" $Port
        } else {
            ReportStatustoFile "Offline" $Port
        }
        Start-Sleep -Seconds $FRQ
	}
}


# Start der Show-WorkingCursor Funktion im Hintergrund
$cursorTask = Start-Job -ScriptBlock { Show-WorkingCursor }

Main

# Beenden der Show-WorkingCursor Funktion
$cursorTask | Stop-Job
$cursorTask | Remove-Job
