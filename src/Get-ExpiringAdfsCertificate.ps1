<#
.SYNOPSIS
This script checks Active Directory Federation Services (AD FS) certificates and AD FS Relying Party Trust 
certificates to see if they expire within a user-specified number of days.

.DESCRIPTION
This script will query AD FS certificates (via Get-AdfsCertficate) and Relying Party Trust 
certificates (via Get-AdfsRelyingPartyTrust) and check if the certificates expire within a user-defined 
threshold (or the default 30 days if not specified). It will then output details about expiring certificates, and,  
optionally, send an alert email.

.INPUTS
None

.OUTPUTS
Outputs an array of objects containing CertType, Name, and ExpiryDate for each expiring certificate. 
Can be overridden by using -NoOutput.

.EXAMPLE
.\Get-ExpiringAdfsCertificate.ps1 -AdfsServer "adfs01"
CertType            Name                                        ExpiryDate
--------            ----                                        ----------
RP Trust Encryption app.fabrikam.com                            2/14/2018 8:31:43 AM
RP Trust Signing    app.fabrikam.com                            2/14/2018 8:31:43 AM
ADFS                CN=ADFS Encryption - adfs.treyresearch.net  11/12/2018 2:15:12 PM
ADFS                CN=ADFS Signing - adfs.treyresearch.net     11/12/2018 2:15:13 PM

.EXAMPLE
.\Get-ExpiringAdfsCertificate.ps1 -EmailFrom adfs@treyresearch.net -EmailTo noc@treyresearch.net -SmtpServer mail.treyresearch.net -NoOutput
(Does not generate an output, but emails details about expiring AD FS certificates on the local server to noc@treyresearch.net)

.LINK
https://github.com/natescherer/Get-ExpiringAdfsCertificate

.NOTES
The account that runs this script will require Administrator rights on the AD FS server. 
This script was written on PowerShell 5.1 for ADFS 2016, but should theoretically work with older versions. 
#>

[CmdletBinding(DefaultParameterSetName="Default")]
param (
    [parameter(ParameterSetName="Default",Mandatory=$false)]
    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # The AD FS server to query, if is remote.
    [string]$AdfsServer = $env:computername,

    [parameter(ParameterSetName="Default",Mandatory=$false)]
    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # The number of days from now to to compare against certificate expiry dates. If not specified, defaults to 30.
    [int]$ExpirationThreshold = 30,

    [parameter(ParameterSetName="Default",Mandatory=$false)]
    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # Ignore any Relying Party Trusts that are disabled.
    [switch]$IgnoreDisabledTrusts,

    [parameter(ParameterSetName="Email",Mandatory=$true)]
    # From address for alert email.
    [string]$EmailFrom,

    [parameter(ParameterSetName="Email",Mandatory=$true)]
    # To address for alert email.
    [string]$EmailTo,

    [parameter(ParameterSetName="Email",Mandatory=$true)]
    # SMTP Server for sending alert email.
    [string]$SmtpServer,

    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # TCP Port to connect to SMTP server on, if it is different than 25.
    [int]$SmtpPort = 25,

    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # Send email using authentication. Note that you must have previously saved credentials using -SaveSmtpCreds.
    [switch]$SmtpAuthenticated,

    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # Send email using SSL.
    [switch]$SmtpSSLDisable,

    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # Custom subject for alert email.
    [string]$Subject = "AD FS Certificates on $AdfsServer Expire within $ExpirationThreshold Days",

    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # Custom header for alert email.
    [string]$BodyHeader = ("The following AD FS certificates on $AdfsServer expire within " +
                            "$ExpirationThreshold days:"),

    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # Custom footer for alert email.
    [string]$BodyFooter = ("Expiring RP Trust certificates will need to be renewed " +
                        "by the company/application on the other end of the Relying Party Trust.<br />Expiring " +
                        "AD FS certificates will need to be renewed by the AD FS administrator."),

    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # Does not output an object; just sends alert email.
    [switch]$NoOutput,

    [parameter(ParameterSetName="SaveSmtpCreds",Mandatory=$true)]
    # Saves SMTP user name, encrypted password, and key to decrypt password to 
    # Get-ExpiringAdfsCertificate_SmtpCreds.xml. This file must exist in the same directory 
    # as this script when you use the -SmtpAuthenticated parameter.
    [switch]$SaveSmtpCreds
)
begin {
    . .\New-HtmlEmailBody.ps1 # Invoke-Build EmbedDotSource

    if ($SaveSmtpCreds) {
        $SSCred = Get-Credential -Message "Enter the username and password for SMTP"
        $SSKey = Get-Random -Count 32 -InputObject (0..255)
        $SSPassUsingKey = ConvertFrom-SecureString -SecureString $SSCred.Password -Key $SSKey
        $CredObject = @{
            "Key" = $SSKey
            "Username" = $SSCred.UserName
            "Password" = $SSPassUsingKey
        }

        Export-Clixml -InputObject $CredObject -Path "Get-ExpiringAdfsCertificate_SmtpCreds.xml"

        exit
    }
}
process {
    $ComparisonDate = $( Get-Date ).AddDays($ExpirationThreshold)
    $ExpiringCertArray = @()

    $Trusts = Invoke-Command -ComputerName $AdfsServer -ScriptBlock {Get-AdfsRelyingPartyTrust}
    if ($IgnoreDisabledTrusts) {
        $Trusts = $Trusts | Where-Object {$_.enabled -eq $true}
    }

    foreach ($Trust in $Trusts) {
        if ($Trust.EncryptionCertificate -and ($Trust.EncryptionCertificate.NotAfter -lt $ComparisonDate)) {
            $ExpiringCertArray += [PSCustomObject]@{'CertType' = 'RP Trust Encryption'
                                    'Name' = $Trust.Name
                                    'ExpiryDate' = $Trust.EncryptionCertificate.NotAfter}

        }
        if ($Trust.RequestSigningCertificate -and ($Trust.RequestSigningCertificate.NotAfter -lt $ComparisonDate)) {
            $ExpiringCertArray += [PSCustomObject]@{'CertType' = 'RP Trust Signing'
                                    'Name' = $Trust.Name
                                    'ExpiryDate' = $Trust.RequestSigningCertificate.NotAfter}
        }
    }

    $Certs = Invoke-Command -ComputerName $AdfsServer -ScriptBlock {Get-AdfsCertificate}       
    foreach ($Cert in $Certs) {
        if ($Cert.Certificate.NotAfter -lt $ComparisonDate) {
            $ExpiringCertArray += [PSCustomObject]@{'CertType' = 'AD FS'
                                    'Name' = $Cert.Certificate.Subject
                                    'ExpiryDate' = $Cert.Certificate.NotAfter}
        }
    }

    $ExpiringCertArray = $ExpiringCertArray | Sort-Object ExpiryDate

    if ($ExpiringCertArray -and ($PSCmdlet.ParameterSetName -eq "Email")) {
        $BodyData = @()
        foreach ($ExpiringCert in $ExpiringCertArray) {
            $BodyData += ("<strong>" + $ExpiringCert.Name + "</strong>: Cert for '" +
                            $ExpiringCert.CertType + "' expires " + $ExpiringCert.ExpiryDate)
        }

        $Body = New-HtmlEmailBody -Header $BodyHeader -Data $BodyData -Footer $BodyFooter

        if (!($SmtpSSLDisable)) {
            $SmtpSSLDisable = $true
        } else {
            $SmtpSSLDisable = $false
        }

        $SmtpParams = @{
            From = $EmailFrom
            To = $EmailTo
            Subject = $Subject
            Body = $Body
            BodyAsHtml = $true
            SmtpServer = $SmtpServer
            Port = $SmtpPort
            UseSsl = $SmtpSSLDisable
        }
        
        if ($SmtpAuthenticated) {
            if (!(Test-Path "Get-ExpiringAdfsCertificate_SmtpCreds.xml")) {
                throw ("Saved SMTP credentials are missing. Please run script with -SaveSmtpCreds " +
                        "to save SMTP credentials, then run again.")
            }

            $CredObject = Import-Clixml -Path "Get-ExpiringAdfsCertificate_SmtpCreds.xml"
            $SmtpSS = ConvertTo-SecureString -String $CredObject.Password -Key $CredObject.Key
            $SMTPCreds = New-Object System.Management.Automation.PSCredential($CredObject.UserName, $SmtpSS)
            $SmtpParams += @{Credential = $SMTPCreds}
        }
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
        Send-MailMessage @SMTPParams
    }
    if ($NoOutput -eq $false) {
        $ExpiringCertArray
    }
}