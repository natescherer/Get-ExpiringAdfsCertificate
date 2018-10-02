# Requires -Modules InvokeBuild, platyPs, MarkdownToHtml

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingCmdletAliases", "", Justification="This erroneously triggers on Invoke-Build scripts.")]
param (
    [parameter(Mandatory=$true)]
    [string]$InputPs1,

    [parameter(Mandatory=$true)]
    [string]$ReleaseVersion
)

use 4.0 MSBuild

$NameWithExt = Split-Path -Path $InputPs1 -Leaf
$NameWithoutExt = $NameWithExt.Split(".")[0]

# Synopsis: Removes files from build, doc, and out.
task Clean {
    Remove-Item -Path docs/* -Recurse
    Remove-Item -Path out/* -Recurse -ErrorAction SilentlyContinue
}

# Synopsis: Embeds scripts that have been dot sourced and are tagged with # Invoke-Build EmbedDotSource, outputs to out
task EmbedDotSource -If {$InputPs1} {
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
    Out-File -InputObject $OutputData -FilePath out\$NameWithoutExt\$NameWithExt
}

# Synopsis: Generates Markdown help file from comment-based help in script.
task GenerateMarkdownHelp {
    New-MarkdownHelp -Command $InputPs1 -OutputFolder docs -NoMetadata | Out-Null
    Rename-Item -Path "docs\$NameWithExt.md" -NewName "$NameWithoutExt.md"
}

# Synopsis: Updates the help link in the readme to point to the file in the new version.
task UpdateHelpLinkInReadme {
    $ReadmeData = Get-Content -Path .\README.md
    $ReadmeOutput = @()

    foreach ($Line in $ReadmeData) {
        if ($Line -like "*``[HelpMarkdown``]:*") {
            $ReadmeOutput += "[HelpMarkdown]: ../" + $ReleaseVersion + "/doc/" + 
                $NameWithoutExt + ".md"
        } else {
            $ReadmeOutput += $Line
        }
    }

    Set-Content -Value $ReadmeOutput -Path README.md
}

# Synopsis: Converts README.md and anything matching docs*.md to HTML, and puts in out folder.
task MarkdownHelpToHtml {
    Copy-Item -Path README.md -Destination docs
    Convert-MarkdownToHTML -Path docs -Destination out\$NameWithoutExt\docs -Template src\MarkdownToHtmlTemplate
    Remove-Item -Path docs\README.md
}

# Synopsis: Zip up files for release.
task ZipForRelease {
    Compress-Archive -Path "out\$NameWithoutExt\*" -DestinationPath "out\$NameWithoutExt-$ReleaseVersion.zip"
}

# Synopsis: Perform all build (but not publish) tasks.
task . Clean, GenerateMarkdownHelp, UpdateHelpLinkInReadme, MarkDownHelpToHtml, EmbedDotSource, ZipForRelease

task 