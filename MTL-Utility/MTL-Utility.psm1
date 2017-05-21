#region Script-Variables
#endregion Script-Variables

#region Public-Functions
#region *-EnvironmentPath
function Get-EnvironmentPath
{
     [CmdletBinding()]
     [OutputType([System.Collections.Hashtable])]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Scopes to retrieve
          [System.EnvironmentVariableTarget[]]$Scopes = ([System.EnvironmentVariableTarget]::Machine,[System.EnvironmentVariableTarget]::User,[System.EnvironmentVariableTarget]::Process)
     )

     process
     {
          $hTable = @{}
          foreach ($scope in $Scopes)
          {
               $envPath = [String[]] @()
               $envPath = ([System.Environment]::GetEnvironmentVariable('PATH',$scope))
               if ($envPath.Count -gt 0)
               {
                    $fmtdPath = New-Object -TypeName System.Collections.ArrayList
                    foreach ($path in $envPath.Split(';',[StringSplitOptions]::RemoveEmptyEntries))
                    {
                         if (Test-Path -LiteralPath $path -PathType Container)
                         {
                              $fmtdPath.Add((ConvertTo-TitleCase -InputObject $path)) | Out-Null
                         }
                    }

                    $newPath = ($fmtdPath | Select-Object -Unique | Sort-Object)

                    $hTable.Add($scope.ToString(),$newPath)
               }
          }

          return $hTable
     }
}

function Set-EnvironmentPath
{
     [CmdletBinding(DefaultParameterSetName = 'HashTable')]

     param
     (

          [Parameter(
               Mandatory = $true,
               ParameterSetName = 'DirectoryInfo'
          )]
          [ValidateNotNullOrEmpty()]
          # Directory(s) to add
          [System.IO.DirectoryInfo[]]
          $Directory
          ,
          [Parameter(
               Mandatory = $true,
               ParameterSetName = 'String'
          )]
          [ValidateNotNullOrEmpty()]
          # String path to add
          [String]
          $String
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Scopes to modify
          [System.EnvironmentVariableTarget[]]$Scopes = ([System.EnvironmentVariableTarget]::Machine)
     )

     process
     {
          $newPath = [String]::Empty
          switch ($PSCmdlet.ParameterSetName)
          {
               'DirectoryInfo'
               {
                    $newPath = (($Directory | foreach {$PSItem.FullName} | Select-Object -Unique| Sort-Object) -join ';')
               }
               'String'
               {
                    $newPath = (($String.Split(';') | Sort-Object) -join ';')
               }
          }

          Write-Debug ('$newPath = {0}' -f $appendPath)

          foreach ($scope in $Scopes)
          {
               Write-Verbose ('Setting PATH for scope {0} to: {1}' -f $scope,$newPath)
               [System.Environment]::SetEnvironmentVariable('PATH',$newPath,$scope)
          }
     }
}

function Format-EnvironmentPath
{
     [CmdletBinding(DefaultParameterSetName = 'String')]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Scopes to modify
          [System.EnvironmentVariableTarget[]]$Scopes = ([System.EnvironmentVariableTarget]::Machine,[System.EnvironmentVariableTarget]::User,[System.EnvironmentVariableTarget]::Process)
     )

     process
     {
          foreach ($scope in $Scopes)
          {
               $currPath = (([System.Environment]::GetEnvironmentVariable('PATH',$scope)).Split(';') | foreach {([String] $PSItem.ToLower().Trim()) } | Select-Object -Unique | Sort-Object)
               $newPath = New-Object System.Collections.ArrayList

               Write-Debug ('Current PATH for scope {0}' -f $scope)
               $currPath | Out-String | Write-Debug

               foreach ($path in $currPath)
               {
                    Write-Debug ('Testing Current Path: {0}' -f $path)
                    if ($path)
                    {
                         if (Test-Path -LiteralPath $path -PathType Container)
                         {
                              Write-Debug ('{0} exists. Adding' -f $path)
                              $newPath.Add($path) | Out-Null
                         }
                         else
                         {
                              Write-Debug ('{0} does not exist. Removing')
                         }
                    }
                    else
                    {
                         Write-Debug ('Current path empty!')
                    }
               }

               Write-Debug ('Updated PATH for scope {0}' -f $scope)
               $newPath | Out-String | Write-Debug

               Write-Verbose ('Setting PATH for scope {0}' -f $scope)
               $newPathStr = ($newPath -join ';')
               [System.Environment]::SetEnvironmentVariable('PATH',$newPathStr,$scope)
          }
     }
}

function Update-EnvironmentPath
{
     [CmdletBinding(DefaultParameterSetName = 'String')]

     param
     (
          [Parameter(
               Mandatory = $true,
               ParameterSetName = 'DirectoryInfo'
          )]
          [ValidateNotNullOrEmpty()]
          # Directory(s) to add
          [System.IO.DirectoryInfo[]]$Directory
          ,
          [Parameter(
               Mandatory = $true,
               ParameterSetName = 'String'
          )]
          [ValidateNotNullOrEmpty()]
          # String path to add
          [String]$String
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Scopes to modify
          [System.EnvironmentVariableTarget[]]$Scopes = ([System.EnvironmentVariableTarget]::Machine,[System.EnvironmentVariableTarget]::User,[System.EnvironmentVariableTarget]::Process)
     )

     process
     {
          $appendPath = [String]::Empty
          switch ($PSCmdlet.ParameterSetName)
          {
               'DirectoryInfo'
               {
                    $appendPath = ($Directory | foreach {(';{0}' -f $PSItem.FullName)})
               }
               'String'
               {
                    $appendPath = $String
               }
          }

          Write-Debug ('$appendPath = {0}' -f $appendPath)

          foreach ($scope in $Scopes)
          {
               $envPath = ([System.Environment]::GetEnvironmentVariable('PATH',$scope))
               $modPath = ('{0};{1}' -f $envPath,$appendPath)

               Write-Verbose ('Appending {0} to PATH for scope {1}' -f $appendPath,$scope)
               [System.Environment]::SetEnvironmentVariable('PATH',$modPath,$scope)
          }
     }

}
#endregion *-EnvironmentPath

#region *-Module
function Install-Module
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [System.IO.DirectoryInfo]
          # Path to source location of module
          $Source = $PSScriptRoot
     )

     process
     {
          Write-Host ($MyInvocation.MyCommand.Path)
          Write-Host ($PSScriptRoot)
          Write-Host ($PSCommandPath)

          $destination = ([System.IO.DirectoryInfo] ('{0}\{1}\Documents\WindowsPowerShell\Modules\{2}' -f $env:HOMEDRIVE,$env:HOMEPATH,$Source.Name))

          Write-Debug ("Source: {0}" -f $Source.FullName)
          Write-Debug ("Destination: {0}" -f $destination.FullName)

          ROBOCOPY $Source $destination /MIR | Out-Null
     }
}

function Uninstall-Module
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [String]
          # Name of module to remove
          $Name
     )

     process
     {
          $destination = ([System.IO.DirectoryInfo] ('{0}\{1}\Documents\WindowsPowerShell\Modules\{2}' -f $env:HOMEDRIVE,$env:HOMEPATH,$Name))

          Write-Debug ("Destination: {0}" -f $destination.FullName)

          Remove-Item -LiteralPath $destination -Recurse -Force
     }
}
#endregion *-Module

#region *-*Preference
function Set-DebugPreference
{
     [CmdletBinding()]
     param(
          [ValidateNotNullOrEmpty()]
          [System.Management.Automation.ActionPreference]
          $Preference
     )

     If ($PSBoundParameters['Debug'])
     {
          $DebugPreference = $Preference
     }

     $Global:DebugPreference = $Preference
     $currPref = $Global:DebugPreference
     $Global:DebugPreference = 'Continue'
     Write-Debug ('DebugPreference: {0}' -f $currPref)
     $Global:DebugPreference = $currPref
}

function Set-InformationPreference
{
     [CmdletBinding()]
     param(
          [ValidateNotNullOrEmpty()]
          [System.Management.Automation.ActionPreference]
          $Preference
     )

     $Global:InformationPreference = $Preference
     Write-Information ('InformationPreference: {0}' -f $InformationPreference) -Verbose
}

function Set-VerbosePreference
{
     [CmdletBinding()]
     param(
          [ValidateNotNullOrEmpty()]
          [System.Management.Automation.ActionPreference]
          $Preference
     )

     $Global:VerbosePreference = $Preference
     Write-Verbose ('VerbosePrefernce: {0}' -f $VerbosePreference) -Verbose
}
#endregion *-*Preference

#region *-StopWatch
function New-StopWatch
{
     [CmdletBinding()]
     [OutputType([System.Diagnostics.StopWatch])]

     param ()

     process
     {
          return (New-Object -TypeName System.Diagnostics.StopWatch)
     }
}
#endregion *-StopWatch

#region Disk-Functions
function Get-FileSizeOnDisk
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [System.IO.DirectoryInfo]
          # Path to interrogate
          $LiteralPath
     )

     begin
     {

          $source = @"
 using System;
 using System.Runtime.InteropServices;
 using System.ComponentModel;
 using System.IO;

 namespace Win32
  {

    public class Disk {

    [DllImport("kernel32.dll")]
    static extern uint GetCompressedFileSizeW([In, MarshalAs(UnmanagedType.LPWStr)] string lpFileName,
    [Out, MarshalAs(UnmanagedType.U4)] out uint lpFileSizeHigh);

    public static ulong GetSizeOnDisk(string filename)
    {
      uint HighOrderSize;
      uint LowOrderSize;
      ulong size;

      FileInfo file = new FileInfo(filename);
      LowOrderSize = GetCompressedFileSizeW(file.FullName, out HighOrderSize);

      if (HighOrderSize == 0 && LowOrderSize == 0xffffffff)
       {
	 throw new Win32Exception(Marshal.GetLastWin32Error());
      }
      else {
	 size = ((ulong)HighOrderSize << 32) + LowOrderSize;
	 return size;
       }
    }
  }
}

"@

          Add-Type -TypeDefinition $source
     }

     process
     {
          if (-not $LiteralPath.Exists)
          {
               Get-PSCallStack | Format-Table Command,Location,Arguments -AutoSize -Wrap | Out-String | Out-Host
               throw (New-Object -TypeName System.IO.DirectoryNotFoundException -ArgumentList ('Cannot access directory ''{0}''' -f $LiteralPath.FullName))
          }

          try
          {
               $queryStartTime = Get-Date
               Write-Host ('Retrieving all files from all subfolders under ''{0}''' -f $LiteralPath.FullName)
               $allFiles = Get-ChildItem -LiteralPath $LiteralPath -Recurse -File
               Write-Host ('Retrieved {0} files from ''{1}'' in {2}' -f $allFiles.Count,$LiteralPath.FullName,((Get-Date).Subtract($queryStartTime)))

               foreach ($file in $allFiles)
               {
                    $fSizeOnDisk = [Win32.Disk]::GetSizeOnDisk($file.FullName)

                    Write-Output ([PSCustomObject] @{
                              Path          = $file.FullName
                              ActualSize    = $file.Length
                              AllocatedSize = $fSizeOnDisk
                         })
               }
          }
          catch [Exception]
          {
               Get-PSCallStack | Format-Table Command,Location,Arguments -AutoSize -Wrap | Out-String | Out-Host
               throw $PSItem.Exception
          }
     }
}

function Get-ServiceWithPath
{
     [CmdletBinding()]
     [OutputType([Object[]])]

     param ()

     process
     {
          $fmtdServices = @(Get-WmiObject -Class Win32_Service | Select-Object -Property Name, DisplayName, State, StartMode,  @{Name = "AbsolutePath"; Expression = {$_.PathName.Trim('"')}}, StartName, InstallDate, SystemName)
          Write-Output -InputObject $fmtdServices -NoEnumerate
     }
}

function New-Folder
{
     [CmdletBinding()]
     [OutputType([System.IO.DirectoryInfo])]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [System.IO.DirectoryInfo]
          # Path to folder
          $LiteralPath
     )

     process
     {
          try
          {

          }
          catch [Exception]
          {

          }

     }
}
#endregion Disk-Functions

#region String-Manipulation
function ConvertTo-TitleCase
{
     [CmdletBinding()]

     param
     (
          [Parameter(Mandatory = $true,
               ValueFromPipeline = $true)]
          [ValidateNotNullOrEmpty()]
          [String[]]
          $InputObject,

          [Switch]
          $ToClipboard
     )

     foreach ($string in $InputObject)
     {
          $retVal = ((Get-Culture).TextInfo.ToTitleCase($InputObject.ToLower()))

          if ($ToClipboard.IsPresent)
          {
               Set-Clipboard -Value $retVal -Verbose
          }

          Write-Output $retVal
     }

}
#endreigion String-Manipulation

#region Miscellaneous
function Get-EnumValues
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [String]
          # Name of enum to list the values of
          $EnumNamespace
     )

     [Enum]::GetValues($EnumNamespace)
}

function Export-ConsoleBuffer
{
     [CmdletBinding()]
     [OutputType([System.IO.FileInfo])]

     param ()

     process
     {
          if ($Host.Name -ne 'ConsoleHost')
          {
               throw (New-Object -TypeName System.InvalidOperationException -ArgumentList ('Buffers only exist on the PowerShell ConsoleHost. As such, this command can only be used from within ConsoleHost'))
          }

          $aList = New-Object -TypeName System.Collections.ArrayList

          $buffWidth = $Host.UI.RawUI.BufferSize.Width
          $buffHeight = $Host.UI.RawUI.BufferSize.Height
          $rectangle = New-Object -TypeName System.Management.Automation.Host.Rectangle -ArgumentList 0,0,($buffWidth - 1),$buffHeight

          $conBuffer = $Host.UI.RawUI.GetBufferContents($rectangle)
          $startLogging = $false

          for ($i = $buffHeight;$i -gt -1;$i--)
          {
               $sb = New-Object -TypeName System.Text.StringBuilder
               for ($j = 0;$j -lt $buffWidth;$j++)
               {
                    $cell = $conBuffer[$i,$j]
                    $sb.Append($cell.Character) | Out-Null
               }

               #Write-Debug ('Line {0:0000}: {1}' -f $i,$sb.ToString())

               if (-not ($sb.ToString().Trim() -eq [String]::Empty))
               {
                    #Write-Debug ('Starting to save buffer output')
                    $startLogging = $true
               }

               if ($startLogging)
               {
                    $sb.Append("`n") | Out-Null
                    $aList.Add($sb.ToString()) | Out-Null
               }
          }

          Write-Output ($aList) -NoEnumerate
     }
}

function Out-Exception
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter(Mandatory = $true,
               ValueFromPipeline = $true)]
          [ValidateNotNullOrEmpty()]
          [System.Management.Automation.ErrorRecord]
          # Error record to parse
          $ErrorRecord
          ,
          [Parameter()]
          [Switch]
          # Throw the error record instead of the exception.
          $ThrowErrorRecord
     )

     process
     {
          $cStack = Get-PSCallStack

          if ($ThrowErrorRecord.IsPresent)
          {
               $ex = Add-Member -InputObject $ErrorRecord -PassThru -MemberType NoteProperty -Name PsCallStack -Value (($cStack[1..$cStack.Count]))
               throw $ErrorRecord
          }
          else
          {
               $ex = $ErrorRecord.Exception
               $ex = Add-Member -InputObject $ex -PassThru -MemberType NoteProperty -Name PsCallStack -Value (($cStack[1..$cStack.Count]))
          }

          throw $ex
     }
}
#endregion
#endregion Public-Functions

#region Private-Functions
#endregion Private-Functions

#region Environment-Initialization
#endregion Environment-Initialization