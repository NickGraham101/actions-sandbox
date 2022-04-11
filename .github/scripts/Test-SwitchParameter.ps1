#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ThisDoesNothing,
    [Parameter(Mandatory=$false)]
    [switch]$ThisIsASwitch,
    [Parameter(Mandatory=$true)]
    [string]$MoreNothing
)

$InformationPreference = "Continue"

if ($ThisIsASwitch.IsPresent) {
    Write-Information "There is a switch present."
}
else {
    Write-Information "There isn't a switch!"
}
