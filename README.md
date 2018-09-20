---
external help file:
Module Name:
online version: https://github.com/natescherer/Get-ExpiringAdfsCertificate
schema: 2.0.0
---

# Get-ExpiringAdfsCertificate.ps1

## SYNOPSIS
This script checks Active Directory Federation Services (AD FS) certificates and AD FS Relying Party Trust
certificates to see if they expire within a user-specified number of days.

## SYNTAX

### NoEmail (Default)
```
Get-ExpiringAdfsCertificate.ps1 [-ExpirationThreshold <Int32>] [-IgnoreDisabledTrusts] [<CommonParameters>]
```

### Email
```
Get-ExpiringAdfsCertificate.ps1 [-ExpirationThreshold <Int32>] [-IgnoreDisabledTrusts] -EmailFrom <String>
 -EmailTo <String> -SmtpServer <String> [-SmtpPort <Int32>] [-SmtpAuthenticated] [-Subject <String>]
 [-BodyHeader <String>] [-BodyFooter <String>] [-NoOutput] [<CommonParameters>]
```

### SavePassword
```
Get-ExpiringAdfsCertificate.ps1 [-SaveSmtpCreds] [<CommonParameters>]
```

## DESCRIPTION
This script will query AD FS certificates (via Get-AdfsCertficate) and Relying Party Trust
certificates (via Get-AdfsRelyingPartyTrust) and check if the certificates expire within a user-defined
threshold (or the default 30 days if not specified).
It will then output details about expiring
certificates, and, optionally, send an alert email.

## EXAMPLES

### EXAMPLE 1
```
.\Get-ExpiringAdfsCertificate.ps1
```

CertType            Name                                        ExpiryDate
--------            ----                                        ----------
RP Trust Encryption app.fabrikam.com                            2/14/2018 8:31:43 AM
RP Trust Signing    app.fabrikam.com                            2/14/2018 8:31:43 AM
ADFS                CN=ADFS Encryption - adfs.treyresearch.net  11/12/2018 2:15:12 PM
ADFS                CN=ADFS Signing - adfs.treyresearch.net     11/12/2018 2:15:13 PM

### EXAMPLE 2
```
.\Get-ExpiringAdfsCertificate.ps1 -EmailFrom adfs@treyresearch.net -EmailTo noc@treyresearch.net -SmtpServer mail.treyresearch.net -SmtpAuthenticated -NoOutput
```

(Does not generate an output, but emails details about expiring certificates to noc@treyresearch.net)

## PARAMETERS

### -ExpirationThreshold
The number of days from now to to compare against certificate expiry dates.
If not specified, defaults to 30.

```yaml
Type: Int32
Parameter Sets: NoEmail, Email
Aliases:

Required: False
Position: Named
Default value: 30
Accept pipeline input: False
Accept wildcard characters: False
```

### -IgnoreDisabledTrusts
Ignore any Relying Party Trusts that are disabled.

```yaml
Type: SwitchParameter
Parameter Sets: NoEmail, Email
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmailFrom
From address for alert email.

```yaml
Type: String
Parameter Sets: Email
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmailTo
To address for alert email.

```yaml
Type: String
Parameter Sets: Email
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SmtpServer
SMTP Server for sending alert email.

```yaml
Type: String
Parameter Sets: Email
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SmtpPort
TCP Port to connect to SMTP server on, if it is different than 25.

```yaml
Type: Int32
Parameter Sets: Email
Aliases:

Required: False
Position: Named
Default value: 25
Accept pipeline input: False
Accept wildcard characters: False
```

### -SmtpAuthenticated
Send email using authentication.
Note that you must have previously saved credentials using -SaveSmtpCreds.

```yaml
Type: SwitchParameter
Parameter Sets: Email
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Subject
Custom subject for alert email.

```yaml
Type: String
Parameter Sets: Email
Aliases:

Required: False
Position: Named
Default value: "AD FS Certificates on $env:computername Expire within $ExpirationThreshold Days"
Accept pipeline input: False
Accept wildcard characters: False
```

### -BodyHeader
Custom header for alert email.

```yaml
Type: String
Parameter Sets: Email
Aliases:

Required: False
Position: Named
Default value: ("The following AD FS certificates on $env:computername expire within " +
                            "$ExpirationThreshold days:")
Accept pipeline input: False
Accept wildcard characters: False
```

### -BodyFooter
Custom footer for alert email.

```yaml
Type: String
Parameter Sets: Email
Aliases:

Required: False
Position: Named
Default value: Expiring RP Trust certificates will need to be renewed by the company/application on the other end of the Relying Party Trust.<br />Expiring AD FS certificates will need to be renewed by the AD FS administrator.
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoOutput
Does not output an object; just sends alert email.

```yaml
Type: SwitchParameter
Parameter Sets: Email
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SaveSmtpCreds
Saves SMTP user name, encrypted password, and keyfile to decrypt password to 
Get-ExpiringAdfsCertificate_smtppass.txt, Get-ExpiringAdfsCertificate_smtpkey.txt, 
and Get-ExpiringAdfsCertificate_smtpkey.txt, respectively.
These files must exist in the same directory 
as this script when you use the -SmtpAuthenticated parameter.

```yaml
Type: SwitchParameter
Parameter Sets: SavePassword
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### Outputs contains an array of objects containing CertType, Name, and ExpiryDate for each expiring certificate.
### Can be overridden by using -NoOutput.
## NOTES
As the AD FS cmdlets don't support remoting, this must be run directly on an AD FS server.
The account that
runs this script will require Administrator rights on the AD FS server.

## RELATED LINKS

[https://github.com/natescherer/Get-ExpiringAdfsCertificate](https://github.com/natescherer/Get-ExpiringAdfsCertificate)

