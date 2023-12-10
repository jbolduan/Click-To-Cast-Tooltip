$WarcraftDir = "D:\Games\World of Warcraft\_retail_\Interface\AddOns"
$Mod = "Click-To-Cast-Tooltip"
$Files = Get-ChildItem ..\Click-To-Cast-Tooltip

if (Test-Path -Path "$WarcraftDir\$Mod") {
    Remove-Item -Path "$WarcraftDir\$Mod\*" -Recurse -Force
}



foreach ($File in $Files) {
    Copy-Item -Path $File.FullName -Destination "$WarcraftDir\$Mod" -Force
}
