<#
.SYNOPSIS
Gets the SSL certificate expiration date for a specified site.

.DESCRIPTION
Function to retrieve the SSL certificate expiration date for a given hostname and port.

.PARAMETER Hostname
The DNS name or IP address of the website to check. Defaults to srv010010038050.generationsgaihter.com.

.PARAMETER Port
The port to connect to (default is 443).

.PARAMETER Verbose
Displays detailed output of connection steps.

.EXAMPLE
Get-CertExpiration
Retrieves the certificate expiration date for the default hostname.

.EXAMPLE
Get-CertExpiration -Hostname "example.com" -Port 443
Retrieves the certificate expiration date for a custom hostname and port.

.EXAMPLE
Get-CertExpiration -Verbose
Shows detailed output while retrieving the certificate expiration date for the default hostname.
#>

function Get-CertExpiration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Hostname = "srv010010038050.generationsgaither.com",
        [int]$Port = 443
    )

    class CertInfo {
        [string]$Hostname
        [int]$Port
        [datetime]$Expiration
        [datetime]$ValidFrom
        CertInfo([string]$Hostname, [int]$Port, [datetime]$Expiration, [datetime]$ValidFrom) {
            $this.Hostname = $Hostname
            $this.Port = $Port
            $this.Expiration = $Expiration
            $this.ValidFrom = $ValidFrom
        }
    }

    Write-Verbose "Connecting to $Hostname on port $Port..."
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient($Hostname, $Port)
        Write-Verbose "TCP connection established. Creating SSL stream..."
        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, ({ $true }))
        $sslStream.AuthenticateAsClient($Hostname)
        Write-Verbose "SSL authentication completed. Retrieving certificate..."
        $cert = $sslStream.RemoteCertificate
        $cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $cert
        $expiration = $cert2.NotAfter
        $validFrom = $cert2.NotBefore
        Write-Verbose "Certificate valid from: $validFrom"
        Write-Verbose "Certificate expiration date: $expiration"
        $sslStream.Close()
        $tcpClient.Close()
        return [CertInfo]::new($Hostname, $Port, $expiration, $validFrom)
    } catch {
        Write-Error "Failed to retrieve certificate: $_"
    }
}


# Example usage:
# Get certificate info for default hostname
# $certInfo = Get-CertExpiration
# Write-Output "Certificate for $($certInfo.Hostname) on port $($certInfo.Port) is valid from $($certInfo.ValidFrom) to $($certInfo.Expiration)"
#
# Get certificate info for a custom hostname and port
# $certInfo = Get-CertExpiration -Hostname "example.com" -Port 443
# Write-Output "Certificate for $($certInfo.Hostname) on port $($certInfo.Port) is valid from $($certInfo.ValidFrom) to $($certInfo.Expiration)"
#
# Show verbose output
# $certInfo = Get-CertExpiration -Verbose
# Write-Output "Certificate for $($certInfo.Hostname) on port $($certInfo.Port) is valid from $($certInfo.ValidFrom) to $($certInfo.Expiration)"

