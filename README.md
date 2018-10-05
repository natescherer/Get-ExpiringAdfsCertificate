# Get-ExpiringAdfsCertificate

This script will query AD FS certificates (via Get-AdfsCertficate) and Relying Party Trust certificates (via Get-AdfsRelyingPartyTrust) and check if the certificates expire within a user-defined threshold (or the default 30 days if not specified). It will then output details about expiring certificates, and,  optionally, send an alert email.

## Getting Started

This script was written with PowerShell 5.1 on AD FS 2016, but should be compatible back to AD FS 2 and PowerShell 2. (Please see Contributing/Bug Reporting below if you run into issues on older versions.)

### Prerequisites

The only real prerequisite is having AD FS installed. If you plan on running the script remotely, you should ensure the computer running the script is able to PSRemote to the AD FS server.

### Installing

1. Download the latest release from [releases](../../releases).
1. Store the script either on the AD FS server, or something that is able to connect to the AD FS server via PowerShell Remoting.
1. Schedule the script to run either with Task Scheduler or your preferred scheduling solution. (Running at least once a week is recommended.)

Alternately, the script can be used by a monitoring solution capable of understanding PowerShell output objects. When run normally (wihout using the -NoOutput parameter), there will be no output unless there are expiring certificates, so the existence of output indicates a failure condition.

## Usage

### Examples

```PowerShell
.\Get-ExpiringAdfsCertificate.ps1 -AdfsServer "adfs01"
CertType            Name                                        ExpiryDate
--------            ----                                        ----------
RP Trust Encryption app.fabrikam.com                            2/14/2018 8:31:43 AM
RP Trust Signing    app.fabrikam.com                            2/14/2018 8:31:43 AM
ADFS                CN=ADFS Encryption - adfs.treyresearch.net  11/12/2018 2:15:12 PM
ADFS                CN=ADFS Signing - adfs.treyresearch.net     11/12/2018 2:15:13 PM
```

```PowerShell
.\Get-ExpiringAdfsCertificate.ps1 -AdfsServer "adfs01" -EmailFrom adfs@treyresearch.net -EmailTo noc@treyresearch.net -SmtpServer mail.treyresearch.net -SmtpAuthenticated -NoOutput
(Does not generate an output, but emails details about expiring certificates to noc@treyresearch.net)
```

### Documentation

For detailed documentation, [click here on GitHub][HelpMarkdown], see the docs folder in a release, or run Get-Help Get-ExpiringAdfsCertificate.ps1 in PowerShell.

[HelpMarkdown]: ../v1.1.0/docs

## Questions/Comments

If you have questions, comments, etc, please enter a GitHub Issue with the "question" tag.

## Contributing/Bug Reporting

Contributions and bug reports are gladly accepted! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Building

## Authors

**Nate Scherer** - *Initial work* - [natescherer](https://github.com/natescherer)

## License

This project is licensed under The MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgements

[PurpleBooth](https://gist.github.com/PurpleBooth/109311bb0361f32d87a2) - README.md template

[nayafia/contributing-template](https://github.com/nayafia/contributing-template) - CONTRIBUTING.md template

[olivierlacan/keep-a-changelog](https://github.com/olivierlacan/keep-a-changelog) - CHANGELOG.md template

[WetHat/MarkdownToHtml](https://github.com/WetHat/MarkdownToHtml) - Conversion of Markdown help to HTML

[sindresorhus/github-markdown-css](https://github.com/sindresorhus/github-markdown-css) - CSS for HTML Help
