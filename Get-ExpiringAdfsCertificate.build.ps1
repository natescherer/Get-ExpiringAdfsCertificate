# Requires -Modules InvokeBuild, platyPs, MarkdownToHtml

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingCmdletAliases", "", Justification="This erroneously triggers on Invoke-Build scripts.")]
[CmdletBinding(DefaultParameterSetName="Snapshot")]
param (
    [parameter(ParameterSetName="Snapshot",Mandatory=$true)]
    [parameter(ParameterSetName="Release",Mandatory=$true)]
    [parameter(ParameterSetName="Publish",Mandatory=$true)]
    [ValidateSet("Snapshot","Release","Publish")]
    [string]$BuildMode,

    [parameter(ParameterSetName="Snapshot",Mandatory=$false)]
    [parameter(ParameterSetName="Release",Mandatory=$false)]
    [string]$InputPs1,

    [parameter(ParameterSetName="Release",Mandatory=$true)]
    [string]$ReleaseVersion,

    [parameter(ParameterSetName="Publish",Mandatory=$true)]
    [string]$GitHubApiUser,

    [parameter(ParameterSetName="Publish",Mandatory=$true)]
    [string]$GitHubApiToken,

    [parameter(ParameterSetName="Publish",Mandatory=$false)]
    [string]$Proxy   
)

$NameWithExt = ""
$NameWithoutExt = ""
$PublishZipName = ""
$PublishVersion = ""
$PublishChangelog = ""
$PublishRepo = ""

Enter-Build {
    switch ($BuildMode) {
        "Snapshot" {}
        "Release" {
            if (!$ReleaseVersion) {
                throw "ReleaseVersion must be specified in Release BuildMode"
            }
        }
        "Publish" {
        }
    } 

    $InputPs1 = "src\$($BuildRoot.Split("\")[-1]).ps1"
    if (Test-Path $InputPs1) {
        Write-Build Green "Assuming `$InputPs1 value of $InputPs1 based on project folder name."
    } else {
        throw "No value for `$InputPs1 provided, and autogenerated value of $InputPs1 does not exist."
    }

    $script:NameWithExt = Split-Path -Path $InputPs1 -Leaf
    $script:NameWithoutExt = $NameWithExt.Split(".")[0]
}

# Synopsis: Perform all build tasks.
task . Clean, GenerateMarkdownHelp, UpdateHelpLinkInReadme, UpdateChangelog, MarkDownHelpToHtml, EmbedDotSource, Zip, 
    FinishRelease, GitVerify, GetDataForGitHubRelease, CreateGitHubRelease

# Synopsis: Removes files from build, doc, and out.
task Clean -If {($BuildMode -eq "Snapshot") -or ($BuildMode -eq "Release")} {
    Remove-Item -Path "docs/*" -Recurse
    Remove-Item -Path "out/*" -Recurse -ErrorAction SilentlyContinue
}

# Synopsis: Embeds scripts that have been dot sourced and are tagged with '# Invoke-Build EmbedDotSource', outputs to out
task EmbedDotSource -If {($BuildMode -eq "Snapshot") -or ($BuildMode -eq "Release")} {
    $InputData = Get-Content $InputPs1
    $OutputData = @()

    foreach ($Line in $InputData) {
        if ($Line -like "*.*# Invoke-Build EmbedDotSource") {
            $Indent = $Line.Split(".")[0]

            $DotSourcedPath = $(Split-Path $InputPs1) + $Line.Split("#")[0].Trim().Substring(2)
            $DotSourcedData = Get-Content -Path $DotSourcedPath
            foreach ($DSLine in $DotSourcedData) {
                $OutputData += $($Indent + $DSLine)
            }
        } else {
            $OutputData += $Line
        }
    }
    Set-Content -Value $OutputData -Path "out\$NameWithoutExt\$NameWithExt"
}

# Synopsis: Generates Markdown help file from comment-based help in script.
task GenerateMarkdownHelp -If {($BuildMode -eq "Snapshot") -or ($BuildMode -eq "Release")} {
    New-MarkdownHelp -Command $InputPs1 -OutputFolder docs -NoMetadata | Out-Null
    Rename-Item -Path "docs\$NameWithExt.md" -NewName "$NameWithoutExt.md"
}

# Synopsis: Updates the help link in the readme to point to the file in the new version.
task UpdateHelpLinkInReadme -If {$BuildMode -eq "Release"} {
    $ReadmeData = Get-Content -Path "README.md"
    $ReadmeOutput = @()
    $UpdateNeeded = $true

    foreach ($Line in $ReadmeData) {
        if ($Line -like "*``[HelpMarkdown``]:*") {
            if ($Line -like "*``[HelpMarkdown``]: ../v$ReleaseVersion*") {
                $UpdateNeeded = $false
            } else {
                $ReadmeOutput += "[HelpMarkdown]: ../v" + $ReleaseVersion + "/doc/" + $NameWithoutExt + ".md"
            }
        } else {
            $ReadmeOutput += $Line
        }
    }

    if ($UpdateNeeded) {
        Set-Content -Value $ReadmeOutput -Path "README.md"
    } else {
        Write-Build Yellow "README.md already updated."
    }
}

# Synopsis: Updates the CHANGELOG.md file for the new release.
task UpdateChangelog -If {$BuildMode -eq "Release"} {
    $ChangelogData = Get-Content -Path "CHANGELOG.md" | Out-String
    $ChangelogOutput = ""
       
    # Split changelog into $ChangelogSections and split header and footer into their own variables
    [System.Collections.ArrayList]$ChangelogSections = $ChangelogData -split "## \["
    $ChangelogHeader = $ChangelogSections[0]
    $ChangelogSections.Remove($ChangelogHeader)
    if ($ChangelogSections[-1] -like "*[Unreleased]:*") {
        $ChangelogFooter = "[Unreleased]:" + $($ChangelogSections[-1] -split "\[Unreleased\]:")[1]
        $ChangelogSections[-1] = $($ChangelogSections[-1] -split "\[Unreleased\]:")[0]
    }

    # Restore the leading "## [" onto each section that was previously removed by split function
    $i = 1
    while ($i -le $ChangelogSections.Count) {
        $ChangelogSections[$i - 1] = "## [" + $ChangelogSections[$i - 1]
        $i++
    }

    # Split release history (all that currently remains in $ChangelogSections) into the $ChangelogNewReleaseSection 
    # (what is currently the Unreleased section) and $ChangelogHistorySections (everything else)
    $ChangelogNewReleaseSection = $ChangelogSections[0]
    $ChangelogSections.Remove($ChangelogNewReleaseSection)
    $ChangelogHistorySections = ($ChangelogSections -join "").TrimEnd(" `r`n")

    # Set $LastVersion to the version number of the latest release listed in the changelog, or null if this will be the first release
    # If there is a previous version detected, also check if $ReleaseVersion is newer, and error out if it isn't
    if ($ChangelogHistorySections) {
        $LastVersion = $ChangelogHistorySections.Split("[")[1].Split("]")[0]
        if ([System.Version]$ReleaseVersion -le [System.Version]$LastVersion) {
            throw "$ReleaseVersion is not greater than the previous listed version in the changelog ($LastVersion)."
        }
    } else {
        $LastVersion = $null
    }

    # Update $ChangelogNewReleaseSection to remove empty sections (types of changes that did not occur in this version)
    $ChangelogNewReleaseSection = $ChangelogNewReleaseSection -replace "### Added`r`n### Changed","### Changed"
    $ChangelogNewReleaseSection = $ChangelogNewReleaseSection -replace "### Changed`r`n### Deprecated","### Deprecated"
    $ChangelogNewReleaseSection = $ChangelogNewReleaseSection -replace "### Deprecated`r`n### Removed","### Removed"
    $ChangelogNewReleaseSection = $ChangelogNewReleaseSection -replace "### Removed`r`n### Fixed","### Fixed"
    $ChangelogNewReleaseSection = $ChangelogNewReleaseSection -replace "### Fixed`r`n### Security","### Security"
    $ChangelogNewReleaseSection = $ChangelogNewReleaseSection -replace "### Security`r`n",""

    # Edit $ChangelogNewReleaseSection to add version number and today's date
    $ChangelogNewReleaseSection = $ChangelogNewReleaseSection -replace ("## \[Unreleased\]","## [$ReleaseVersion] - $((Get-Date -Format 'o').Split('T')[0])")

    # Inject compare/tree URL(s) into footer
    if ($ChangelogHistorySections -ne "") {
        $UrlBase = ($ChangelogFooter.TrimStart("[Unreleased]: ") -split "/compare")[0]
        $ChangelogFooter = ($ChangelogFooter -replace "\[Unreleased\].*",("[Unreleased]: " +
            "$UrlBase/compare/v$ReleaseVersion...HEAD`r`n" +
            "[$ReleaseVersion]: $UrlBase/compare/v$LastVersion..v$ReleaseVersion"))
        $ChangelogFooter = "`r`n`r`n" + $ChangelogFooter

    } else {
        $ChangelogFooter = "`r`n[Unreleased]: https://github.com/REPLACEUSERNAME/REPLACEREPONAME/compare/v$ReleaseVersion...HEAD"
        $ChangelogFooter += "`r`n[$ReleaseVersion]: https://github.com/REPLACEUSERNAME/REPLACEREPONAME/tree/v$ReleaseVersion"

        Write-Output "Because this is the first release, you will need to manually edit the repository URL at the bottom of the file. Future releases will reuse this information, and won't require this manual step."
    }

    # Build & write updated CHANGELOG.md
    $ChangelogOutput += $ChangelogHeader
    $ChangelogOutput += "## [Unreleased]`r`n" +
        "### Added`r`n" +
        "### Changed`r`n" +
        "### Deprecated`r`n" +
        "### Removed`r`n" +
        "### Fixed`r`n" +
        "### Security`r`n`r`n"
    $ChangelogOutput += $ChangelogNewReleaseSection
    $ChangelogOutput += $ChangelogHistorySections
    $ChangelogOutput += $ChangelogFooter.TrimEnd("`r`n")

    Set-Content -Value $ChangelogOutput -Path "CHANGELOG.md" -NoNewline

    # Build & write CHANGELOG.md without Unreleased section for inclusion in distribution package
    $ChangelogOutput = ""
    $ChangelogOutput += $ChangelogHeader
    $ChangelogOutput += $ChangelogNewReleaseSection
    $ChangelogOutput += $ChangelogHistorySections
    $ChangelogOutput += $ChangelogFooter.TrimEnd("`r`n")

    Set-Content -Value $ChangelogOutput -Path "docs\CHANGELOG.md" -NoNewline
}

# Synopsis: Converts README.md and anything matching docs*.md to HTML, and puts in out folder.
task MarkdownHelpToHtml -If {($BuildMode -eq "Snapshot") -or ($BuildMode -eq "Release")} {
    if (!(Test-Path -Path "docs\CHANGELOG.md")) {
        Copy-Item -Path "CHANGELOG.md" -Destination "docs\"
    }
    Copy-Item -Path "README.md" -Destination "docs"
    Convert-MarkdownToHTML -Path "docs" -Destination "out\$NameWithoutExt\docs" -Template "src\MarkdownToHtmlTemplate" | Out-Null
    Remove-Item -Path "docs\README.md"
    Remove-Item -Path "docs\CHANGELOG.md"
}

# Synopsis: Zip up files.
task Zip -If {($BuildMode -eq "Snapshot") -or ($BuildMode -eq "Release")} {
    if ($ReleaseVersion) {
        Compress-Archive -Path "out\$NameWithoutExt\*" -DestinationPath "out\$NameWithoutExt-v$ReleaseVersion.zip"
    } else {
        Compress-Archive -Path "out\$NameWithoutExt\*" -DestinationPath "out\$NameWithoutExt-snapshot$(Get-Date -Format yyMMdd).zip"
    }
}

# Synopsis: Write a note if release build finished properly.
task FinishRelease -If {$BuildMode -eq "Release"} {
    Write-Build Yellow "Release finished. Please verify files in out/, CHANGELOG.md, and README.md all look correct."
    Write-Build Yellow "Once done, commit and push all changes, then run the following:"
    Write-Build Blue "Invoke-Build -BuildMode Publish -GitHubApiUser `"usernamehere`" -GitHubApiToken `"0123456789abcdef0123456789abcdef01234567`""
}

# Synopsis: Verify Git changes are committed and pushed.
task GitVerify -If {$BuildMode -eq "Publish"} {
    $GitUncommitedChanges = git diff
    if ($GitUncommitedChanges) {
        throw "There are changes uncommitted to Git."
    }

    $GitUnpushedCommits = git log origin/master..HEAD --oneline
    if ($GitUnpushedCommits) {
        throw "There are commits that have not been pushed to remote yet."
    }
}

task GetDataForGitHubRelease  -If {$BuildMode -eq "Publish"} {
    $Zip = Get-ChildItem out/*.zip
    if ($Zip.Count -gt 1) {
        throw "Multiple .zip files detected in out/. Please ensure only the .zip you want to release is in out/."
    } elseif ($Zip.Count -eq 0) {
        throw "No .zip files detected in out/. Please make sure you've run Invoke-Build in Release mode."
    }
    $script:PublishZipName = $Zip.Name
    $script:PublishVersion = $Zip.Name.TrimEnd(".zip").Split("-")[-1].TrimStart("v")

    $ChangelogData = Get-Content -Path "CHANGELOG.md" | Out-String
    $script:PublishChangelog = (($ChangelogData -split "## \[$PublishVersion")[1] -split "`r`n`r`n")[0] -replace "\].*`r`n",""

    $script:PublishRepo = (($ChangelogData -split "https://github.com/")[1] -split "/compare")[0]
}

task CreateGitHubRelease -If {$BuildMode -eq "Publish"} {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $AuthHeader = "Basic {0}" -f [System.Convert]::ToBase64String([char[]]"$GitHubApiUser`:$GitHubApiToken")
    $ReleaseHeaders = @{
        "Authorization" = $AuthHeader
    }
    $ReleaseBody = @{
        "tag_name" = "v$PublishVersion"
        "name" = "v$PublishVersion"
        "body" = $PublishChangelog
    }
    
    $ReleaseParams = @{
        "Headers" = $ReleaseHeaders
        "Body" = $(ConvertTo-Json -InputObject $ReleaseBody)
        "Uri" = "https://api.github.com/repos/$PublishRepo/releases"
        "Method" = "Post"
    }
    
    if ($Proxy) {
        $ReleaseParams += @{"Proxy" = "http://$Proxy"}
        $ReleaseParams += @{"ProxyUseDefaultCredentials" = $true}       
    }
    
    $ReleaseResult = Invoke-RestMethod @ReleaseParams
    
    if ($ReleaseResult.upload_url) {
        $UploadHeaders = @{
            "Authorization" = $AuthHeader
            "Content-Type" = "application/zip"
        }
        $UploadParams = @{
            "Headers" = $UploadHeaders
            "Uri" = $ReleaseResult.upload_url.split("{")[0] + "?name=$PublishZipName"
            "Method" = "Post"
            "InFile" = "out\$PublishZipName"
        }

        if ($Proxy) {
            $UploadParams += @{"Proxy" = "http://$Proxy"}
            $UploadParams += @{"ProxyUseDefaultCredentials" = $true}       
        }

        $UploadResult = Invoke-RestMethod @UploadParams
        if ($UploadResult.state -ne "uploaded") {
            Write-Output $UploadResult
            throw "There was a problem uploading."
        }
    } else {
        Write-Output $ReleaseResult
        throw "There was a problem releasing"
    }
}