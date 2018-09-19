<#
.SYNOPSIS
    This script checks Active Directory Federation Services (AD FS) certificates and AD FS Relying Party Trust
    certificates to see if they expire within a user-specified number of days.

.DESCRIPTION
    This script will query AD FS certificates (via Get-AdfsCertficate) and Relying Party Trust
    certificates (via Get-AdfsRelyingPartyTrust) and check if the certificates expire within a user-defined
    threshold (or the default 30 days if not specified). It will then output details about expiring
    certificates, and, optionally, send an alert email.

.INPUTS
    None

.OUTPUTS
    Outputs contains an array of objects containing CertType, Name, and ExpiryDate for each expiring certificate.
    Can be overridden by using -NoOutput.

.EXAMPLE
    .\Get-ExpiringAdfsCertificate.ps1
    CertType            Name                                        ExpiryDate
    --------            ----                                        ----------
    RP Trust Encryption app.fabrikam.com                            2/14/2018 8:31:43 AM
    RP Trust Signing    app.fabrikam.com                            2/14/2018 8:31:43 AM
    ADFS                CN=ADFS Encryption - adfs.treyresearch.net  11/12/2018 2:15:12 PM
    ADFS                CN=ADFS Signing - adfs.treyresearch.net     11/12/2018 2:15:13 PM

.EXAMPLE
<<<<<<< HEAD
    .\Get-ExpiringAdfsCertificate.ps1 -EmailFrom adfs@treyresearch.net -EmailTo noc@treyresearch.net `
    -SmtpServer mail.treyresearch.net -SmtpAuthenticated -NoOutput
    
    (Does not generate an output, but emails details about expiring certificates to noc@treyresearch.net)

.LINK
    https://github.com/natescherer/Get-ExpiringAdfsCertificate
=======
    .\Get-ExpiringAdfsCertificate.ps1 -EmailFrom adfs@treyresearch.net -EmailTo noc@treyresearch.net -SmtpServer mail.treyresearch.net -SmtpAuthenticated -NoOutput
    (Does not generate an output, but emails details about expiring certificates to noc@treyresearch.net)

.LINK
    https://github.com/natescherer/Get-ExpiringAdfsCertifate
>>>>>>> 7a3733dc7996da80f2921aa0c8c9a4c117e9aeb0

.NOTES
    As the AD FS cmdlets don't support remoting, this must be run directly on an AD FS server. The account that
    runs this script will require Administrator rights on the AD FS server.
#>

[CmdletBinding(DefaultParameterSetName="NoEmail")]
param (
    [parameter(ParameterSetName="NoEmail",Mandatory=$false)]
    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # The number of days from now to to compare against certificate expiry dates. If not specified, defaults to 30.
    [int]$ExpirationThreshold = 30,

    [parameter(ParameterSetName="NoEmail",Mandatory=$false)]
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
<<<<<<< HEAD
    # Send email using authentication. Note that you must have previously saved credentials using -SaveSmtpCreds.
=======
    # Send email using authentication. Note that you must have previously saved credentials using -SaveSmtpAuth.
>>>>>>> 7a3733dc7996da80f2921aa0c8c9a4c117e9aeb0
    [switch]$SmtpAuthenticated,

    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # Custom subject for alert email.
    [string]$Subject = "AD FS Certificates on $env:computername Expire within $ExpirationThreshold Days",

    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # Custom header for alert email.
    [string]$BodyHeader = ("The following AD FS certificates on $env:computername expire within " +
                            "$ExpirationThreshold days:"),

    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # Custom footer for alert email.
<<<<<<< HEAD
    [string]$BodyFooter = ("Expiring RP Trust certificates will need to be renewed " +
                        "by the company/application on the other end of the Relying Party Trust.<br />Expiring " +
                        "AD FS certificates will need to be renewed by the AD FS administrator."),
=======
    [string]$BodyFooter = ("In general, expiring Relying Party Trust certificates will need to be renewed " +
                        "by the company/application on the other end of the trust. Expiring AD FS " +
                        "Certificates will need to be renewed by the AD FS administrator."),
>>>>>>> 7a3733dc7996da80f2921aa0c8c9a4c117e9aeb0

    [parameter(ParameterSetName="Email",Mandatory=$false)]
    # Does not output an object; just sends alert email.
    [switch]$NoOutput,

    [parameter(ParameterSetName="SavePassword",Mandatory=$true)]
<<<<<<< HEAD
    # Saves SMTP user name, encrypted password, and keyfile to decrypt password to 
    # Get-ExpiringAdfsCertificate_smtppass.txt, Get-ExpiringAdfsCertificate_smtpkey.txt, 
    # and Get-ExpiringAdfsCertificate_smtpkey.txt, respectively. These files must exist in the same directory 
    # as this script when you use the -SmtpAuthenticated parameter.
    [switch]$SaveSmtpCreds
)
begin {
    function Format-HtmlEmailBody {
        [CmdletBinding(DefaultParameterSetName="NoEmail")]
        param (
            [parameter(Mandatory=$true)]
            [string]$Header,

            [parameter(Mandatory=$true)]
            [array]$Data,

            [parameter(Mandatory=$true)]
            [string]$Footer,

            [parameter(Mandatory=$false)]
            [int]$Width
        )
        process {
            if ($Width) {
                $StringWidth = "$Width"
            } else {
                $StringWidth = "100%"
            }
            $HtmlTop = ("<!DOCTYPE html PUBLIC `"-//W3C//DTD XHTML 1.0 Transitional//EN`" `"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd`">`r`n" +
                "<html xmlns=`"http://www.w3.org/1999/xhtml`">`r`n" +
                "<head>`r`n" +
                "<meta http-equiv=`"Content-Type`" content=`"text/html; charset=UTF-8`" />`r`n" +
                "<title>_</title>`r`n" +
                "</head>`r`n" +
                "<body>`r`n" +
                "<table border=`"0`" cellpadding=`"0`" cellspacing=`"0`" width=`"100%`" id=`"bodyTable`">`r`n" +
                "`t<tr>`r`n" +
                "`t`t<td valign=`"top`">`r`n" +
                "`t`t`t<table border=`"0`" cellpadding=`"0`" cellspacing=`"0`" width=`"$StringWidth`" id=`"emailContainer`">`r`n" +
                "`t`t`t`t<tr>`r`n" +
                "`t`t`t`t`t<td align=`"center`" valign=`"top`">`r`n" +
                "`t`t`t`t`t`t<table border=`"0`" cellpadding=`"10`" cellspacing=`"0`" width=`"100%`" id=`"emailHeader`">`r`n" +
                "`t`t`t`t`t`t`t<tr>`r`n" +
                "`t`t`t`t`t`t`t`t<td valign=`"top`" style=`"font-family: sans-serif; font-size: 12px`">")
            $HtmlHeaderToData = ("`</td>`r`n" +
                "`t`t`t`t`t`t`t</tr>`r`n" +
                "`t`t`t`t`t`t</table>`r`n" +
                "`t`t`t`t`t</td>`r`n" +
                "`t`t`t`t</tr>`r`n" +
                "`t`t`t`t<tr>`r`n" +
                "`t`t`t`t`t<td align=`"center`" valign=`"top`">`r`n" +
                "`t`t`t`t`t`t<table border=`"0`" cellpadding=`"10`" cellspacing=`"0`" width=`"100%`" id=`"emailBody`">`r`n")
            $HtmlDataToFooter = ("`t`t`t`t`t`t</table>`r`n" +
                "`t`t`t`t`t</td>`r`n" +
                "`t`t`t`t</tr>`r`n" +
                "`t`t`t`t<tr>`r`n" +
                "`t`t`t`t`t<td align=`"center`" valign=`"top`">`r`n" +
                "`t`t`t`t`t`t<table border=`"0`" cellpadding=`"10`" cellspacing=`"0`" width=`"100%`" id=`"emailFooter`">`r`n" +
                "`t`t`t`t`t`t`t<tr>`r`n" +
                "`t`t`t`t`t`t`t`t<td valign=`"top`" style=`"font-family: sans-serif; font-size: 12px`">")
            $HtmlBottom = ("</td>`r`n" +
                "`t`t`t`t`t`t`t</tr>`r`n" +
                "`t`t`t`t`t`t</table>`r`n" +
                "`t`t`t`t`t</td>`r`n" +
                "`t`t`t`t</tr>`r`n" +
                "`t`t`t</table>`r`n" +
                "`t`t</td>`r`n" +
                "`t</tr>`r`n" +
                "</table>`r`n" +
                "</body>`r`n" +
                "</html>")
            $FormattedData = ""
            foreach ($Datum in $Data) {
                $FormattedData += ("`t`t`t`t`t`t`t<tr>`r`n" +
                    "`t`t`t`t`t`t`t`t<td valign=`"top`"></td>`r`n" +
                    "`t`t`t`t`t`t`t`t<td valign=`"top`" style=`"font-family: monospace; font-size: 12px`">" +
                    $Datum +
                    "</td>`r`n" +
                    "`t`t`t`t`t`t`t</tr>`r`n")
            }

            $CompleteBody = $HtmlTop + $Header + $HtmlHeaderToData + $FormattedData + $HtmlDataToFooter + 
                            $Footer + $HtmlBottom

            $CompleteBody
        }
    }
}

process {
    if ($SaveSmtpCreds) {
        $SSCred = Get-Credential -Message "Enter the username and password for SMTP"
        $SSKey = Get-Random -Count 32 -InputObject (0..255)
        $SSPassUsingKey = ConvertFrom-SecureString -SecureString $SSCred.Password -Key $SSKey

        Out-File -InputObject $SSKey -FilePath "Get-ExpiringAdfsCertificate_smtpkey.txt"
        Out-File -InputObject $SSCred.UserName -FilePath "Get-ExpiringAdfsCertificate_smtpuser.txt"
        Out-File -InputObject $SSPassUsingKey -FilePath "Get-ExpiringAdfsCertificate_smtppass.txt"
=======
    # Generates a Secure String and keyfile for storing the password used to send email.
    [switch]$SaveSmtpAuth
)
process {
    if ($SaveSmtpAuth) {
        $SSKey = Get-Random -Count 32 -InputObject (0..255)
        Out-File -InputObject $SSKey -FilePath "getexpadfscert-key.txt"

        $SSCred = Get-Credential -Message "Enter the username and password for SMTP"
        Out-File -InputObject $SSCred.UserName -FilePath "getexpadfscert-user.txt"
        $SSPassUsingKey = ConvertFrom-SecureString -SecureString $SSCred.Password -Key (Get-Content -Path "getexpadfscert-key.txt")
        Out-File -InputObject $SSPassUsingKey -FilePath "getexpadfscert-pass.txt"
>>>>>>> 7a3733dc7996da80f2921aa0c8c9a4c117e9aeb0
    } else {
        $ComparisonDate = $(Get-Date).AddDays($ExpirationThreshold)
        $ExpiringCertArray = @()

        if ($IgnoreDisabledTrusts) {
            $Trusts = Get-AdfsRelyingPartyTrust | where-object {$_.enabled -eq $true}
        } else {
            $Trusts = Get-AdfsRelyingPartyTrust
        }

        foreach ($Trust in $Trusts) {
            if ($Trust.EncryptionCertificate -and ($Trust.EncryptionCertificate.NotAfter -lt $ComparisonDate)) {
                $ExpiringCertArray += [PSCustomObject]@{'CertType' = 'RP Trust Encryption';
                                        'Name' = $Trust.Name;
                                        'ExpiryDate' = $Trust.EncryptionCertificate.NotAfter}

            }
            if ($Trust.RequestSigningCertificate -and ($Trust.RequestSigningCertificate.NotAfter -lt $ComparisonDate)) {
                $ExpiringCertArray += [PSCustomObject]@{'CertType' = 'RP Trust Signing';
                                        'Name' = $Trust.Name;
                                        'ExpiryDate' = $Trust.RequestSigningCertificate.NotAfter}
            }
        }

        $Certs = Get-AdfsCertificate
        foreach ($Cert in $Certs) {
            if ($Cert.Certificate.NotAfter -lt $ComparisonDate) {
<<<<<<< HEAD
                $ExpiringCertArray += [PSCustomObject]@{'CertType' = 'AD FS';
=======
                $ExpiringCertArray += [PSCustomObject]@{'CertType' = 'ADFS';
>>>>>>> 7a3733dc7996da80f2921aa0c8c9a4c117e9aeb0
                                        'Name' = $Cert.Certificate.Subject;
                                        'ExpiryDate' = $Cert.Certificate.NotAfter}
            }
        }

<<<<<<< HEAD
        if ($ExpiringCertArray -and ($PSCmdlet.ParameterSetName -eq "Email")) {
            $BodyData = @()
            foreach ($ExpiringCert in $ExpiringCertArray) {
                $BodyData += ("<strong>" + $ExpiringCert.Name + "</strong>: Cert for '" +
                                $ExpiringCert.CertType + "' expires " + $ExpiringCert.ExpiryDate)
            }

            $Body = Format-HtmlEmailBody -Header $BodyHeader -Data $BodyData -Footer $BodyFooter

=======
        if ($ExpiringCertArray -and ($PSCmdlet.ParameterSetName -like "Email*")) {
            $BodyData = ""
            foreach ($ExpiringCert in $ExpiringCertArray) {
                $BodyData += ('<strong>' + $ExpiringCert.Name + '</strong>: Certificate for ' +
                                $ExpiringCert.CertType + ' expires ' + $ExpiringCert.ExpiryDate + '<br>')
            }
            $Body = ('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' +
                    '<html xmlns="http://www.w3.org/1999/xhtml">' +
                    '<head> <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /> <title></title> <style></style> </head>' +
                    '<body> <table border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="bodyTable"> <tr> <td valign="top">' +
                    '<table border="0" cellpadding="0" cellspacing="0" width="800" id="emailContainer">' +
                    '<tr> <td align="center" valign="top"> <table border="0" cellpadding="10" cellspacing="0" width="100%" id="emailHeader"> <tr>' +
                    '<td valign="top" style="font-family: sans-serif; font-size: 12px"> ' +
                    $BodyHeader +
                    '</td> </tr> </table> </td> </tr>' +
                    '<tr> <td align="center" valign="top"> <table border="0" cellpadding="10" cellspacing="0" width="100%" id="emailBody"> <tr> ' +
                    '<td valign="top" style="font-family: monospace; font-size: 12px"> ' +
                    $BodyData +
                    '</td> </tr> </table> </td> </tr>' +
                    '<tr> <td align="center" valign="top">' +
                    '<table border="0" cellpadding="10" cellspacing="0" width="100%" id="emailFooter"> <tr> ' +
                    '<td valign="top" style="font-family: sans-serif; font-size: 12px">' +
                    $BodyFooter +
                    '</td> </tr> </table> </td> </tr>' +
                    '</table> </td> </tr> </table> </body> </html>')
>>>>>>> 7a3733dc7996da80f2921aa0c8c9a4c117e9aeb0
            $SmtpParams = @{
                From = $EmailFrom
                To = $EmailTo
                Subject = $Subject
                Body = $Body
                BodyAsHtml = $true
                SmtpServer = $SmtpServer
                Port = $SmtpPort
                UseSsl = $true
            }
            if ($SmtpAuthenticated) {
<<<<<<< HEAD
                if (!(Test-Path "Get-ExpiringAdfsCertificate_smtpuser.txt") -and
                !(Test-Path "Get-ExpiringAdfsCertificate_smtppass.txt") -and
                !(Test-Path "Get-ExpiringAdfsCertificate_smtpkey.txt")) {
                    throw ("Saved SMTP credentials are missing. Please run script with -SaveSmtpCreds " +
                            "to save SMTP credentials, then run again.")

                }
                $SmtpUser = Get-Content "Get-ExpiringAdfsCertificate_smtpuser.txt"
                $SmtpKey = Get-Content "Get-ExpiringAdfsCertificate_smtpkey.txt"
                $SmtpSS = Get-Content "Get-ExpiringAdfsCertificate_smtppass.txt"
=======
                $SmtpUser = Get-Content "getexpadfscert-user.txt"
                $SmtpKey = Get-Content "getexpadfscert-key.txt"
                $SmtpSS = Get-Content "getexpadfscert-pass.txt"
>>>>>>> 7a3733dc7996da80f2921aa0c8c9a4c117e9aeb0
                $SmtpSS = ConvertTo-SecureString -String $SmtpSS -Key $SmtpKey
                $SMTPCreds = New-Object System.Management.Automation.PSCredential($SmtpUser, $SmtpSS)
                $SmtpParams += @{Credential = $SMTPCreds}
            }
<<<<<<< HEAD
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
=======

>>>>>>> 7a3733dc7996da80f2921aa0c8c9a4c117e9aeb0
            Send-MailMessage @SMTPParams
        }
        if ($NoOutput -eq $false) {
            $ExpiringCertArray
        }
    }
}