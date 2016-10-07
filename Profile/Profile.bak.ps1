#Set-StrictMode -Version 2.0

#region Module-Import
<# Commented out for later use.
	$RsatModules = (
	"NetSecurity",
    "NetConnection",
    "NetAdapter",
    "NetTCPIP",
    "SmbShare",
    "PSDiagnostics",
    "DnsClient"
)
#>

#Import-Module ($RsatModules) -Force -Global
#Import-Module Pscx -Force -Global
#Import-Module AgilePsDeveloperLibrary -Global -Force
#Import-Module AgileClipboardLibrary -Global -Force
#Import-Module AgileSecurityLibrary -Global -Force
#Import-Module PowerTab -Force -Global
#endregion Module-Import

#region Script-Variables
#region Script-Root
$script:ScriptRoot = ([System.IO.DirectoryInfo] (Split-Path -Path $MyInvocation.MyCommand.Path -Parent))
#endregion Script-Root

#region For:New-VersionNumber
[int]$script:NvnMajor = 0
[int]$script:NvnMinor = 1
[int]$script:NvnBuild = 0
[int]$script:NvnRevision = 0
#endregion For:New-VersionNumber
#endregion Script-Variables

#region Public-Functions
function ConvertTo-UniqueFilename
{
    #REGION Parameters
    Param
    (
    [CmdletBinding(
        SupportsShouldProcess=$false,
        ConfirmImpact = "Low",
        DefaultParameterSetName="FileInfo"
    )]

    ### ParameterSet - StringPath Parameters ###

    #REGION 00-$LiteralPath
    # Parameter Definition - Start
    [Parameter(
        Position=00,
        Mandatory=$true,
        ValueFromPipeline=$true,
        ParameterSetName="StringPath",
        HelpMessage="Path to file"
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $LiteralPath
    # Parameter Definition - End
    #ENDREGION

    ### ParameterSet - DirectoryInfo Parameters ###
    ,
    #REGION 00-$DirectoryInfo
    # Parameter Definition - Start
    [Parameter(
        Position=00,
        Mandatory=$true,
        ValueFromPipeline=$true,
        ParameterSetName="DirectoryInfo",
        HelpMessage="[DirectoryInfo] object representing directory"
    )]
    [ValidateNotNullOrEmpty()]
    [System.IO.DirectoryInfo]
    $DirectoryInfo
    # Parameter Definition - End
    #ENDREGION

    ### ParameterSet - FileInfo Parameters ###
    ,
    #REGION 00-$FileInfo
    # Parameter Definition - Start
    [Parameter(
        Position=00,
        Mandatory=$true,
        ValueFromPipeline=$true,
        ParameterSetName="FileInfo",
        HelpMessage="[FileInfo] object representing directory"
    )]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]
    $FileInfo
    # Parameter Definition - End
    #ENDREGION

    ### ParameterSet - Setless Parameters ###
    ,
    #region NP-$LeadingDigits
    [Parameter(
        #Position=NP,
        #Mandatory=$true,
        HelpMessage="Number of digits preceding the file number"
    )]
    [ValidateNotNullOrEmpty()]
    [int]
    $LeadingDigits = 2
    #endregion

    )
    #ENDREGION Parameters

    #REGION Body
    #region Begin {}
    BEGIN
    {
        function Get-LeadingDigits
        {
            Write-Output ("0" * $LeadingDigits)
        }

        function Get-PeakValue
        {
            Write-Output ([int] ("9" * $LeadingDigits))
        }

        $Digits = Get-LeadingDigits
	}
    #endregion

    PROCESS
    {
        #region ParameterSet-Specific-Actions
        switch ($PsCmdlet.ParameterSetName)
        {
            #region ParameterSet-FileInfo
            "FileInfo"
            {
                $FsObject = [System.IO.FileInfo]($FileInfo)

                break
            }
            #endregion ParameterSet-FileInfo
            #region ParameterSet-DirectoryInfo
            "DirectoryInfo"
            {
                $FsObject = [System.IO.DirectoryInfo]($DirectoryInfo)

                break
            }
            #endregion ParameterSet-DirectoryInfo
            #region ParameterSet-StringPath
            "StringPath"
            {
                if ((Test-Path -Path $LiteralPath) -eq $true)
                {
                    if ((Get-Item -Path $LiteralPath) -is [System.IO.DirectoryInfo])
                    {
                        $FsObject = (New-Object -TypeName System.IO.DirectoryInfo -ArgumentList $LiteralPath)
                    }
                    elseif ((Get-Item -Path $LiteralPath) -is [System.IO.FileInfo])
                    {
                        $FsObject = (New-Object -TypeName System.IO.FileInfo -ArgumentList $LiteralPath)
                    }
                    else
                    {
                        throw (New-Object -TypeName System.InvalidOperationException -ArgumentList ("{0} is not a valid file or directory" -f $LiteralPath))
                    }
                }
                else
                {
                    throw (New-Object -TypeName System.InvalidOperationException -ArgumentList ("{0} is not a valid file or directory" -f $LiteralPath))
                }

                break
            }
            #endregion ParameterSet-StringPath
            default
            {
                Write-Error -Message ((New-AlConsoleTimeStamp) + '$PsCmdlet.ParameterSetName Switch statement broken! This should never execute!')
            }
        }
        #endregion ParameterSet-Specific-Actions

        if ($FsObject -ne $null)
        {
            #region Generate-New-Directory-Name
            if($FsObject -is [System.IO.DirectoryInfo])
            {
                Write-AlDebug -Invocation $MyInvocation ("[System.IO.DirectoryInfo] detected")

                $Count = 1
                $NewName = ("{0}\{1}-#{2:$Digits}" -f `
                    ($FsObject.Parent.Fullname.TrimEnd('\')),`
                    ($FsObject.BaseName,$Count)
                )

                Write-AlDebug -Invocation $MyInvocation ("Name #{0,3:000} | {1}" -f `
                    ($Count),`
                    ($NewName)
                )

                while ((Test-Path -LiteralPath $NewName -PathType Container) -eq $true)
                {
                    $Count++
                    $NewName = ("{0}\{1}-#{2:$Digits}" -f `
                        ($FsObject.Parent.Fullname.TrimEnd('\')),`
                        ($FsObject.BaseName,$Count)
                    )

                    Write-AlDebug -Invocation $MyInvocation ("Name #{0,3:000} | {1}" -f `
                        ($Count),`
                        ($NewName)
                    )

                    if($Count -gt (Get-PeakValue)) { $LeadingDigits++; $Digits = (Get-LeadingDigits)}
                }
            }
            #endregion Generate-New-Directory-Name
            #region Generate-New-File-Name
            elseif($FsObject -is [System.IO.FileInfo])
            {
                Write-AlDebug -Invocation $MyInvocation ("[System.IO.FileInfo] detected")

                $Count = 1
                $NewName = ("{0}\{1}-#{2:$Digits}{3}" -f `
                    ($FsObject.DirectoryName.TrimEnd('\')),`
                    ($FsObject.BaseName),`
                    ($Count),`
                    ($FsObject.Extension)
                )

                Write-AlDebug -Invocation $MyInvocation ("Name #{0,3:000} | {1}" -f `
                    ($Count),`
                    ($NewName)
                )

                while ((Test-Path -LiteralPath $NewName -PathType Leaf) -eq $true)
                {
                    $Count++
                    $NewName = ("{0}\{1}-#{2:$Digits}{3}" -f `
                        ($FsObject.DirectoryName.TrimEnd('\')),`
                        ($FsObject.BaseName),`
                        ($Count),`
                        ($FsObject.Extension)
                    )

                    Write-AlDebug -Invocation $MyInvocation ("Name #{0,3:000} | {1}" -f `
                        ($Count),`
                        ($NewName)
                    )

                    if($Count -gt (Get-PeakValue)) { $LeadingDigits++; $Digits = (Get-LeadingDigits)}
                }
            }
            #endregion Generate-New-File-Name
        }
        else
        {
            throw (New-Object -TypeName System.InvalidOperationException -ArgumentList ("I've somehow lost track of the filesystem object ... This should never execute...."))
        }

        Write-Output ($NewName)
    }
    #ENDREGION
}

<#
    Summary:    Time elapses since I started
#>
function Get-ElapsedTimeSinceStartDate
{
	#REGION Process{}
    PROCESS
    {
        Write-Verbose ("Location: [Profile:Get-ElapsedTimeSinceStartDate]: Entering PROCESS ... ")

        $StartDate      = (Get-Date "10/22/2013 09:00 am")
        $TotalElapsed   = ((Get-Date).Subtract($StartDate))

        $Object = [PSCustomObject]@{
            'StartDate'         = [DateTime] (Get-Date "10/22/2013 09:00 am")
            'TotalElapsed'      = [TimeSpan] ($TotalElapsed)
            'WeeksElapsed'      = [double] ("{0:####0.00}" -f ($TotalElapsed.TotalDays / 7))
            'DaysElapsed'       = [double] ("{0:####0.00}" -f ($TotalElapsed.TotalDays))
            'HoursElapsed'      = [double] ("{0:#########0.00}" -f ($TotalElapsed.TotalHours))
            'MinutesElapsed'    = [double] ("{0:################0.00}" -f ($TotalElapsed.TotalMinutes))
            'SecondsElapsed'    = [double] ("{0:################################0.00}" -f ($TotalElapsed.TotalSeconds))
		}

        Write-Output $Object
        Write-Verbose ("Location: [Profile:Get-ElapsedTimeSinceStartDate]: Exiting PROCESS ... ")
    }
    #ENDREGION
}

function New-BuildNumber
{
    #region Function-Parameters
    Param
    (
    [CmdletBinding(
        SupportsShouldProcess=$false,
        ConfirmImpact = "Low"
    )]

    ### ParameterSet - Setless Function-Parameters ###

    #region 00 - $StartDate
    [Parameter(
        Position=00
    )]
    [ValidateNotNullOrEmpty()]
    [DateTime] $StartDate = (Get-Date 1/1/2000)
    #endregion -- - $StartDate

    )
    #endregion Function-Parameters

    #region Process {}
    PROCESS
    {
        Write-Output ("{0:0}" -f ((Get-Date).Subtract($StartDate).TotalDays))
    }
    #endregion Process {}
}

function New-VersionNumber
{
    #region Function-Parameters
    Param
    (
    [CmdletBinding(
        SupportsShouldProcess=$false,
        ConfirmImpact = "Low"
        #DefaultParameterSetName=""
    )]

    ### ParameterSet - Setless Function-Parameters ###

    #region 00 - $Major
    [Parameter(
        Position=00,
        HelpMessage="Major version number"
    )]
    [ValidateNotNullOrEmpty()]
    [int] $Major
    #endregion -- - $Major
    ,
    #region 01 - $Minor
    [Parameter(
        Position=01,
        HelpMessage="Minor version number"
    )]
    [ValidateNotNullOrEmpty()]
    [int] $Minor
    #endregion -- - $Minor
    ,
    #region 02 - $Build
    [Parameter(
        Position=02,
        HelpMessage="Build Number"
    )]
    [ValidateNotNullOrEmpty()]
    [int] $Build
    #endregion -- - $Build
    ,
    #region 03 - $Revision
    [Parameter(
        Position=03,
        HelpMessage="Revision Number"
    )]
    [ValidateNotNullOrEmpty()]
    [int] $Revision
    #endregion -- - $Revision

    )
    #endregion Function-Parameters

    #region Process {}
    PROCESS
    {
        #region Indent-Strings
        $OneTab = ("`t" * 1)
        #endregion Indent-Strings

        #region Out-Debug
        if($PSBoundParameters.Count -gt 0)
        {

            Write-Debug ("`$PSBoundParameters Key/Value Pairs:")
            foreach($Param in ($PSBoundParameters.GetEnumerator()))
            {
                Write-Debug ("{0}{1,-10}:{2}" -f `
                    ($OneTab),`
                    ($Param.Key),`
                    ($Param.Value)
                )
            }
        }

        Write-Debug ("")
        Write-Debug ('Parameter Values:')
        Write-Debug ("{0}{1,-10}{2}" -f `
            ($OneTab),`
            ("-Major"),`
            ($Major)
        )

        Write-Debug ("{0}{1,-10}{2}" -f `
            ($OneTab),`
            ("-Minor"),`
            ($Minor)
        )

        Write-Debug ("{0}{1,-10}{2}" -f `
            ($OneTab),`
            ("-Build"),`
            ($Build)
        )

        Write-Debug ("{0}{1,-10}{2}" -f `
            ($OneTab),`
            ("-Revision"),`
            ($Revision)
        )
        #endregion Out-Debug

        <#
            [int]$script:NvnMajor = 0
            [int]$script:NvnMinor = 0
            [int]$script:NvnBuild = 1
            [int]$script:NvnRevision = 1
        #>

        #region Update-Script-Variables
        $AllArgNames = @("Major","Minor","Build","Revision")
        foreach($ArgName in $AllArgNames)
        {
            if($PSBoundParameters.ContainsKey($ArgName))
            {
                switch($ArgName)
                {
                    "Major"     { $script:NvnMajor = $Major }
                    "Minor"     { $script:NvnMinor = $Minor }
                    "Build"     { $script:NvnBuild = $Build }
                    "Revision"  { $script:NvnRevision = $Revision }
                }
            }
            else
            {
                switch($ArgName)
                {
#                    "Major"     { $script:NvnMajor++ }
#                    "Minor"     { $script:NvnMinor++ }
                    "Build"     { $script:NvnBuild = (New-BuildNumber) }
                    "Revision"  { $script:NvnRevision++ }
                }
            }
        }

        $Major = ($script:NvnMajor)
        $Minor = ($script:NvnMinor)
        $Build = ($script:NvnBuild)
        $Revision = ($script:NvnRevision)
        #endregion Update-Script-Variables

        #region Out-Debug
        Write-Debug ("")
        Write-Debug ('Version Numbers:')
        Write-Debug ("{0}{1,-10}{2}" -f `
            ($OneTab),`
            ("Major"),`
            ($Major)
        )

        Write-Debug ("{0}{1,-10}{2}" -f `
            ($OneTab),`
            ("Minor"),`
            ($Minor)
        )

        Write-Debug ("{0}{1,-10}{2}" -f `
            ($OneTab),`
            ("Build"),`
            ($Build)
        )

        Write-Debug ("{0}{1,-10}{2}" -f `
            ($OneTab),`
            ("Revision"),`
            ($Revision)
        )
        #endregion Out-Debug

        #region Create-Version-Object
        [System.Version]$ReturnVal = ("{0}.{1}.{2}.{3}" -f `
            ($Major),`
            ($Minor),`
            ($Build),`
            ($Revision)
        )
        #endregion Create-Version-Object

        Write-Output ($ReturnVal)
    }
    #endregion Process {}
}

function Ping-UntilOnline
{
    #region Function-Parameters
    Param
    (
    [CmdletBinding(
        SupportsShouldProcess=$false,
        ConfirmImpact = "Low"
        #DefaultParameterSetName=""
    )]
    
    ### ParameterSet - Setless Function-Parameters ###
    
    #region 00 - $ComputerName
    [Parameter(
        Position=00,
        HelpMessage="Name of computer to ping"
    )]
    [Alias("C")]
    [ValidateNotNullOrEmpty()]
    [String] $ComputerName
    #endregion -- - $ComputerName
    ,
    #region 01 - $Sleep
    [Parameter(
        Position=01,
        HelpMessage="Seconds to ping between attempts"
    )]
    [Alias("S")]
    [ValidateNotNullOrEmpty()]
    [ValidateRange(1,255)]
    [Int] $Sleep = 15
    #endregion -- - $Sleep
    ,
    #region SW - $WaitUntilOffline
    [Parameter(
        #Position=SW,
        HelpMessage="HelpMessage"
    )]
    [Alias("W")]
    [ValidateNotNullOrEmpty()]
    [Switch] $WaitUntilOffline
    #endregion -- - $WaitUntilOffline
    
    )
    #endregion Function-Parameters
    
    #region Process {}
    PROCESS
    {
        Write-AlDebug ("Parameter Values:")
        Write-AlDebug -Tabs 1 ("`$ComputerName:         {0}" -f ($ComputerName))
        Write-AlDebug -Tabs 1 ("`$Sleep:                {0}" -f ($Sleep))
        Write-AlDebug -Tabs 1 ("`$WaitUntilOffline:     {0}" -f ($WaitUntilOffline.IsPresent))
    
        #region -WaitUntilOffline
        if ($WaitUntilOffline.IsPresent)
        {
        	[bool]$IsOffline = $false
            $StartTime = (Get-Date)
            Write-AlHost ("Waiting for {0} to stop pinging ... " -f ($ComputerName))
            $OfflineCount = 1
            :UntilOffline while($IsOffline -eq $false)
            {
                Write-AlHost -NoNewline -Tabs 2 -Object `
                    ("Marco [#{0:000}] ... " -f ($OfflineCount))
                    
                $PingResult = (Test-Connection -ComputerName $ComputerName -Quiet -Count 1)
                $OfflineCount++
                
#                Write-AlHost -NoTimeStamp -NoNewline -Object (" {0,5} " -f "...")
                if($PingResult -eq $true)
                {
                    Write-AlHost -NoTimeStamp -NoNewline -ForegroundColor Gray -Object `
                        ("{0,8}" -f ("Polo"))
                        
                    $Runtime = ((Get-Date).Subtract($StartTime))
                }
                else
                {
                    $IsOffline = $true
                    Write-AlHost -NoTimeStamp -NoNewline -ForegroundColor Green -Object `
                        ("{0,8}" -f ("Silence!"))
                        
                    $Runtime = ((Get-Date).Subtract($StartTime))
                }
                
                Write-AlHost -NoTimeStamp -ForegroundColor DarkGray -Object `
                    (" [Elapsed: {0:0}:{1:00}]" -f ($Runtime.TotalMinutes),($Runtime.Seconds))
                    
                if($IsOffline -eq $true) { break UntilOffline }
                
                Start-Sleep -Seconds $Sleep
            }
            
            Write-Host
            
            #region Write-Host
            $Runtime = ((Get-Date).Subtract($StartTime))
            Write-AlHost -ForegroundColor White -NoNewline -Object `
                ("{0}" -f ($ComputerName)) 
            
             Write-AlHost -NoTimeStamp -NoNewline -Object `
                (" is offline after ") 
            
            Write-AlHost -NoTimeStamp -NoNewline -ForegroundColor Green -Object `
                ("{0}" -f ($OfflineCount -1))
            
            Write-AlHost -NoTimeStamp -NoNewline -Object `
                (" pings and ")
            
            Write-AlHost -NoTimeStamp -NoNewline -ForegroundColor Green -Object `
                ("{0:0}:{1:00}" -f ($Runtime.TotalMinutes),($Runtime.Seconds))
            
            Write-AlHost -NoTimeStamp -Object `
                (" (m:s) to stop responding to ping")
            #endregion Write-Host
            
            Write-Host
        }
        #endregion -WaitUntilOffline
        
        #region Ping-Computer-Until-Response
        [bool]$IsOnline = $false
        $StartTime = (Get-Date)
        Write-AlHost ("Waiting for {0} to respond to ping ... " -f ($ComputerName))
        $PingCount = 1
        :UntilOnline while($IsOnline -eq $false)
        {
            Write-AlHost -NoNewline -Tabs 2 -Object `
                ("Marco [#{0:000}] ... " -f ($PingCount))
                
            $IsOnline = (Test-Connection -ComputerName $ComputerName -Quiet -Count 1)
            $PingCount++
            
#            Write-AlHost -NoTimeStamp -NoNewline -Object (" {0,5} " -f "...")
            if($IsOnline -eq $true)
            {
                Write-AlHost -NoTimeStamp -NoNewline -ForegroundColor Green -Object `
                    ("{0,8}" -f ("Polo"))
                    
                $Runtime = ((Get-Date).Subtract($StartTime))
            }
            else
            {
                $IsOnline = $true
                Write-AlHost -NoTimeStamp -NoNewline -ForegroundColor Gray -Object `
                    ("{0,8}" -f ("Silence!"))
                    
                $Runtime = ((Get-Date).Subtract($StartTime))
            }
            
            Write-AlHost -NoTimeStamp -ForegroundColor DarkGray -Object `
                (" [Elapsed: {0:0}:{1:00}]" -f ($Runtime.TotalMinutes),($Runtime.Seconds))
                
            if($IsOnline -eq $true) { break UntilOnline }

            Start-Sleep -Seconds $Sleep
        }

        Write-Host

        #region Write-Host
        $Runtime = ((Get-Date).Subtract($StartTime))
        Write-AlHost -ForegroundColor White -NoNewline -Object `
            ("{0}" -f ($ComputerName)) 
        
         Write-AlHost -NoTimeStamp -NoNewline -Object `
            (" is online after ") 
        
        Write-AlHost -NoTimeStamp -NoNewline -ForegroundColor Green -Object `
            ("{0}" -f ($PingCount - 1))
        
        Write-AlHost -NoTimeStamp -NoNewline -Object `
            (" pings and ")
        
        Write-AlHost -NoTimeStamp -NoNewline -ForegroundColor Green -Object `
            ("{0:0}:{1:00}" -f ($Runtime.TotalMinutes),($Runtime.Seconds))
        
        Write-AlHost -NoTimeStamp -Object `
            (" (m:s) to start responding to ping")
        #endregion Write-Host
        
        Write-Host
        
        #endregion Ping-Computer-Until-Response
    }
    #endregion Process {}
}

#region Custom-Prompt
<#
    Customized prompt that gives a little more info than the standard prompt
#>
function prompt
{
    <#
        Out-Of-Box Prompt

        PS C:\WINDOWS\system32> get-content function:\prompt
        "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
        # .Link
        # http://go.microsoft.com/fwlink/?LinkID=225750
        # .ExternalHelp System.Management.Automation.dll-help.xml
    #>

    Write-Host

    #region Set-Window-Title
    $host.UI.RawUI.WindowTitle = (Get-Location)
    #endregion Set-Window-Title

    #region Set-TimeStamp-Format
    $DtFormat = 'MM/dd HH:mm:ss.ffff'
    #endregion Set-TimeStamp-Format

    #region Test-Is-Prompt-Elevated
    $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
    $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin=$prp.IsInRole($adm)
    #endregion Test-Is-Prompt-Elevated

    #region Set-Prompt
    $Delimiter = " | "

    #region Add-TimeStamp
    (Write-Host -NoNewline -ForegroundColor Gray -Object `
        ("{0}" -f `
            (Get-Date -Format $DtFormat)
        )
    )

    Write-Host -NoNewline -ForegroundColor DarkGray -Object ($Delimiter)
    #endregion Add-TimeStamp

    #region Add-UserName-And-Elevation-Status
    $UserName = (" {0}\{1} " -f `
        ($env:USERDOMAIN.ToUpper()),`
        ($env:USERNAME.ToLower())
    )

    if ($IsAdmin)
    {
        Write-Host -NoNewline -ForegroundColor White -BackgroundColor DarkRed -Object `
            (" $UserName " )
    }
    else
    {
        Write-Host -NoNewline -ForegroundColor White -BackgroundColor DarkGray -Object `
            (" $UserName ")
    }

    Write-Host -NoNewline -ForegroundColor DarkGray -Object ($Delimiter)
    #endregion Add-UserName-And-Elevation-Status

    #region Add-Host-Name
    $DnsHostname = (([System.Net.Dns]::Resolve($env:COMPUTERNAME)).HostName.Split('.')[0,1] -join '.')

    Write-Host -NoNewline -ForegroundColor Gray -Object `
        ($DnsHostname)

    Write-Host -NoNewline -ForegroundColor DarkGray -Object ($Delimiter)
    #endregion Add-Host-Name

    #region Add-Elevated-Moniker
    $Moniker = 'Elevated'
    if ($IsAdmin)
    {
        Write-Host -ForegroundColor White -BackgroundColor DarkRed  -Object `
            (" {0}:True " -f `
                ($Moniker)
            )
    }
    else
    {
        Write-Host -ForegroundColor White -BackgroundColor DarkGray  -Object `
            (" {0}:False " -f `
                ($Moniker)
            )
    }
    #endregion Add-Elevated-Moniker

    #region Add-Current-Folder
    $CurrentPath = ([System.IO.DirectoryInfo] ($PWD.ProviderPath))
    $TreeDepth = [int]($CurrentPath.FullName.TrimEnd('\').Split('\').Count)

    if($TreeDepth -gt 1)
    {
        Write-Host -NoNewline -ForegroundColor DarkGray -Object `
            ("{0}\" -f `
                ($CurrentPath.Parent.FullName.Trim('\'))
            )
    }

    Write-Host -ForegroundColor White -Object `
        ("{0}>" -f `
            ($CurrentPath.Name)
        )
    #endregion Add-Current-Folder
    #endregion Set-Prompt

    return ""
}
#endregion Custom-Prompt
#endregion Public-Functions

#region Execution
#region Set-Location
Set-Location -LiteralPath ("{0}\" -f ($env:SystemDrive))
#endregion Set-Location
#endregion Execution