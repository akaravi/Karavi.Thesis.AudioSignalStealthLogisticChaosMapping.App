# Writes LastRunInfo.html after local run / port allocation (see .cursor/rules/last-run-info-html.mdc).
# Dot-source:  . .\_last-run-info.ps1

function ConvertTo-KaraviHtmlEncoded {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return '' }
    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function New-KaraviRunResultRow {
    param(
        [Parameter(Mandatory = $true)][string]$Step,
        [Parameter(Mandatory = $true)][ValidateSet('Success', 'Failed', 'Skipped', 'Warning', 'Started', 'Running')]
        [string]$Status,
        [string]$Detail = ''
    )

    return [ordered]@{
        Step   = $Step
        Status = $Status
        Detail = $Detail
    }
}

function Get-KaraviPortAllocationRows {
    $notes = @{
        FlutterWeb       = 'Flutter Web (web-server), HTTP'
        FlutterWebChrome = 'Flutter Web (chrome / edge), HTTP'
        WpfDesktop       = 'WPF reserved (no HTTP)'
        FlutterWindowsVm = 'Flutter Windows VM service'
        FlutterDevTools  = 'Dart DevTools'
        Reserved6        = 'Reserved'
        Reserved7        = 'Reserved'
        Reserved8        = 'Reserved'
        Reserved9        = 'Reserved'
        Reserved10       = 'Reserved'
    }

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($entry in $script:KaraviDevPorts.GetEnumerator()) {
        $note = $notes[$entry.Key]
        if (-not $note) { $note = 'رزرو' }
        $rows.Add([ordered]@{
                Name = $entry.Key
                Port = $entry.Value
                Note = $note
            }) | Out-Null
    }
    return $rows
}

function Write-KaraviLastRunInfoHtml {
    param(
        [Parameter(Mandatory = $true)][string]$OutputPath,
        [Parameter(Mandatory = $true)][string]$InvokedBy,
        [Parameter(Mandatory = $true)][array]$RunResults,
        [array]$ServiceAddresses = @(),
        [bool]$OverallSuccess = $true,
        [string]$Summary = ''
    )

    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

    if (-not (Get-Variable -Name KaraviDevPorts -Scope Script -ErrorAction SilentlyContinue)) {
        $portsScript = Join-Path $scriptRoot '_dev-ports.ps1'
        if (Test-Path -LiteralPath $portsScript) {
            . $portsScript
        }
    }

    $portRows = Get-KaraviPortAllocationRows
    $generatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $overallClass = if ($OverallSuccess) { 'ok' } else { 'fail' }
    $overallLabelHtml = if ($OverallSuccess) { '&#1605;&#1608;&#1601;&#1602;' } else { '&#1606;&#1575;&#1605;&#1608;&#1601;&#1602;' }

    if ([string]::IsNullOrWhiteSpace($Summary)) {
        $Summary = "Run $InvokedBy at $generatedAt"
    }

    function Render-TableRows {
        param(
            [array]$Rows,
            [string[]]$ColumnKeys
        )
        $sb = New-Object System.Text.StringBuilder
        foreach ($row in $Rows) {
            [void]$sb.AppendLine('          <tr>')
            foreach ($key in $ColumnKeys) {
                $val = if ($row -is [hashtable] -or $row -is [System.Collections.Specialized.OrderedDictionary]) {
                    $row[$key]
                }
                else {
                    $row.$key
                }
                $class = ''
                if ($key -eq 'Status') {
                    $class = switch ([string]$val) {
                        'Success' { ' class="ok"' }
                        'Failed' { ' class="fail"' }
                        'Warning' { ' class="warn"' }
                        'Skipped' { ' class="muted"' }
                        'Started' { ' class="ok"' }
                        'Running' { ' class="warn"' }
                        default { '' }
                    }
                }
                [void]$sb.AppendLine(("            <td{0}>{1}</td>" -f $class, (ConvertTo-KaraviHtmlEncoded ([string]$val)))
                )
            }
            [void]$sb.AppendLine('          </tr>')
        }
        return $sb.ToString()
    }

    $resultRowsHtml = Render-TableRows -Rows $RunResults -ColumnKeys @('Step', 'Status', 'Detail')
    $serviceRowsHtml = Render-TableRows -Rows $ServiceAddresses -ColumnKeys @('Service', 'Address', 'Notes')
    $portRowsHtml = Render-TableRows -Rows $portRows -ColumnKeys @('Name', 'Port', 'Note')

    $templatePath = Join-Path $scriptRoot '_last-run-info.template.html'
    if (-not (Test-Path -LiteralPath $templatePath)) {
        throw "HTML template not found: $templatePath"
    }

    $utf8NoBomRead = New-Object System.Text.UTF8Encoding $false
    $template = [System.IO.File]::ReadAllText($templatePath, $utf8NoBomRead)
    $overallBadge = "<span class=""badge $overallClass"">$overallLabelHtml</span>"

    $html = ($template.Replace('__SUMMARY__', (ConvertTo-KaraviHtmlEncoded $Summary)).
        Replace('__INVOKED_BY__', (ConvertTo-KaraviHtmlEncoded $InvokedBy)).
        Replace('__GENERATED_AT__', (ConvertTo-KaraviHtmlEncoded $generatedAt)).
        Replace('__OVERALL_BADGE__', $overallBadge).
        Replace('__RESULT_ROWS__', $resultRowsHtml).
        Replace('__SERVICE_ROWS__', $serviceRowsHtml).
        Replace('__PORT_ROWS__', $portRowsHtml))

    $dir = Split-Path -Parent $OutputPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($OutputPath, $html, $utf8NoBom)
    Write-Host "LastRunInfo.html -> $OutputPath" -ForegroundColor Green
}
