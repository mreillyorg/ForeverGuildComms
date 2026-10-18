FOREVER GUILD COMMS 0.4.0-beta - Integrated Windows Installer
============================================================

START HERE: after Extract All, open ForeverGuildComms\install and double-click Install-ForeverGuildComms.cmd.

DO NOT run Install-ForeverGuildComms.ps1 directly. Windows may reject an
unsigned PowerShell script with a "not digitally signed" error. The CMD
launcher starts the SAME installer with a PROCESS-ONLY execution policy
setting. It does not change your permanent PowerShell execution policy.

INSTALL / UPDATE
1. Right-click the ZIP and choose Extract All.
2. Open the extracted ForeverGuildComms folder, then open its install
   subfolder. This contains the CMD, PS1 and this INSTALL-README.txt.
3. Double-click Install-ForeverGuildComms.cmd (NOT the .ps1).
4. If asked, select the WoW Forever client folder, typically:
      C:\Program Files (x86)\World of Warcraft\_classic_beta_
   You may also select the Interface or Interface\AddOns folder.
5. After success, restart WoW Forever or type /reload in the game.

The installer copies ONLY ForeverGuildComms.toc, the Lua/XML files listed
in that manifest, and the in-game icon Media\Icon.tga. Identical files are skipped. The README, tests, and
install subfolder are NOT copied into the live AddOns folder.

Updated files are backed up under:
    <WoW client>\Interface\AddOnBackups\ForeverGuildComms-<timestamp>

Unrelated addons and user SavedVariables are not touched. If a copy fails,
the installer attempts to restore files it modified. Existing custom messages
and settings are retained.

IF YOU PREFER TO LAUNCH FROM POWERSHELL
From the extracted ZIP folder use:
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\ForeverGuildComms\install\Install-ForeverGuildComms.ps1"

To choose a game folder without browsing:
    .\ForeverGuildComms\install\Install-ForeverGuildComms.cmd -GamePath "D:\World of Warcraft\_classic_beta_"

If you already tried .\Install-ForeverGuildComms.ps1 and saw a digital
signature error, that is expected on machines with restrictive execution
policies. Use the CMD launcher above instead. Do not change the global
Windows execution policy just to install this addon.

IF THE SCRIPT IS STILL BLOCKED
If execution policy is enforced by your workplace or school via Group
Policy, even the process-only override may be blocked. Do not attempt to
circumvent an enforced policy. Install manually instead:
    a. Open the extracted ForeverGuildComms folder (one level above install).
    b. Copy the .toc and .lua files, plus the Media\Icon.tga texture, into:
       <WoW client>\Interface\AddOns\ForeverGuildComms
       Create the Media subfolder as well if needed. You can overwrite older addon files.
    c. Leave your SavedVariables folder alone. Restart WoW or type /reload.

Installations under Program Files may require Windows administrator
permissions for file copying. The CMD launcher does not automatically
request elevated permissions.

PACKAGER NOTE
The BigWigsMods/packager output omits this install/ directory on purpose.
This integrated installer is available in the manually supplied source ZIP.
