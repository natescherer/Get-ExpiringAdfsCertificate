# SYNOPSIS
    This script checks Active Directory Federation Services (AD FS) certificates and AD FS Relying Party Trust
    certificates to see if they expire within a user-specified number of days.


# SYNTAX
    H:\scripts\adfs_cert_alert\Get-ExpiringAdfsCertificate.ps1 [-ExpirationThreshold <Int32>] [-IgnoreDisabledTrusts]
    [<CommonParameters>]

    H:\scripts\adfs_cert_alert\Get-ExpiringAdfsCertificate.ps1 [-ExpirationThreshold <Int32>] [-IgnoreDisabledTrusts]
    -EmailFrom <String> -EmailTo <String> -SmtpServer <String> [-SmtpPort <Int32>] [-SmtpAuthenticated] [-Subject
    <String>] [-BodyHeader <String>] [-BodyFooter <String>] [-NoOutput] [<CommonParameters>]

    H:\scripts\adfs_cert_alert\Get-ExpiringAdfsCertificate.ps1 -SaveSmtpAuth [<CommonParameters>]


# DESCRIPTION
    This script will query AD FS certificates (via Get-AdfsCertficate) and Relying Party Trust
    certificates (via Get-AdfsRelyingPartyTrust) and check if the certificates expire within a user-defined
    threshold (or the default 30 days if not specified). It will then output details about expiring
    certificates, and, optionally, send an alert email.


# PARAMETERS
    -ExpirationThreshold <Int32>
        The number of days from now to to compare against certificate expiry dates. If not specified, defaults to 30.

        Required?                    false
        Position?                    named
        Default value                30
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -IgnoreDisabledTrusts [<SwitchParameter>]
        Ignore any Relying Party Trusts that are disabled.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -EmailFrom <String>
        From address for alert email.

        Required?                    true
        Position?                    named
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -EmailTo <String>
        To address for alert email.

        Required?                    true
        Position?                    named
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -SmtpServer <String>
        SMTP Server for sending alert email.

        Required?                    true
        Position?                    named
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -SmtpPort <Int32>
        TCP Port to connect to SMTP server on, if it is different than 25.

        Required?                    false
        Position?                    named
        Default value                25
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -SmtpAuthenticated [<SwitchParameter>]
        Send email using authentication. Note that you must have previously saved credentials using -SaveSmtpAuth.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Subject <String>
        Custom subject for alert email.

        Required?                    false
        Position?                    named
        Default value                "AD FS Certificates on $env:computername Expire within $ExpirationThreshold Days"
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -BodyHeader <String>
        Custom header for alert email.

        Required?                    false
        Position?                    named
        Default value                ("The following AD FS certificates on $env:computername expire within " +
                                    "$ExpirationThreshold days:")
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -BodyFooter <String>
        Custom footer for alert email.

        Required?                    false
        Position?                    named
        Default value                In general, expiring Relying Party Trust certificates will need to be renewed by
        the company/application on the other end of the trust. Expiring AD FS Certificates will need to be renewed by
        the AD FS administrator.
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -NoOutput [<SwitchParameter>]
        Does not output an object; just sends alert email.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -SaveSmtpAuth [<SwitchParameter>]
        Generates a Secure String and keyfile for storing the password used to send email.

        Required?                    true
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216).

# INPUTS
    None


# OUTPUTS
    Outputs contains an array of objects containing CertType, Name, and ExpiryDate for each expiring certificate.
    Can be overridden by using -NoOutput.


# NOTES


        As the AD FS cmdlets don't support remoting, this must be run directly on an AD FS server. The account that
        runs this script will require Administrator rights on the AD FS server.

#    -------------------------- EXAMPLE 1 --------------------------

    PS C:\>.\Get-ExpiringAdfsCertificate.ps1

    CertType            Name                                        ExpiryDate
    --------            ----                                        ----------
    RP Trust Encryption app.fabrikam.com                            2/14/2018 8:31:43 AM
    RP Trust Signing    app.fabrikam.com                            2/14/2018 8:31:43 AM
    ADFS                CN=ADFS Encryption - adfs.treyresearch.net  11/12/2018 2:15:12 PM
    ADFS                CN=ADFS Signing - adfs.treyresearch.net     11/12/2018 2:15:13 PM




#    -------------------------- EXAMPLE 2 --------------------------

    PS C:\>.\Get-ExpiringAdfsCertificate.ps1 -EmailFrom adfs@treyresearch.net -EmailTo noc@treyresearch.net
    -SmtpServer mail.treyresearch.net -SmtpAuthenticated -NoOutput

    (Does not generate an output, but emails details about expiring certificates to noc@treyresearch.net)





# RELATED LINKS
    https://github.com/natescherer/Get-ExpiringAdfsCertifate
