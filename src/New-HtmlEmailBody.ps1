function New-HtmlEmailBody {
    [CmdletBinding(DefaultParameterSetName="Default")]
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
