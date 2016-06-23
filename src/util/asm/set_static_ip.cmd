@echo off
REM Set up static networking in WinPE environment
REM
REM First, translate a MAC address into a 'Connection Name' as
REM shown in ipconfig /all output. This allows us to specify
REM the correct (and required) 'Connection Name' in the 
REM netsh command below.
REM
REM The _XXXXX_ strings below will be overwritten with the 
REM actial network info from the deployment from ASM at the time
REM the customized ipxe.iso is generated during deployment
REM
REM NOTE: This works for English only since it searches for
REM       English words in ipconfig output.
REM

setlocal enableDelayedExpansion

set MAC_ADDRESS=_TARGET_MAC_
set IP_ADDRESS=_IP_ADDRESS_
set NETMASK=_NETMASK_
set GATEWAY=_GATEWAY_

REM
REM Run ipconfig /all and capture output. Loop through lines 
REM recording the connection name. Then search for a MAC 
REM address that matches MAC_ADDRESS passed in
REM 
for /f "delims=" %%a in ('ipconfig /all') do (
    set line=%%a
    if not "!line:~0,1!"==" " if not "!line:adapter=!"=="!line!" (
        set name=!line:*adapter =!
        set name=!name::=!
    )
    for /f "tokens=1,2,*" %%b in ("%%a") do (
        if "%%b %%c"=="Physical Address." (
            set mac=%%d
            set mac=!mac:*: =!
            if "!mac!"=="!MAC_ADDRESS!" (
                set CONNECTION_NAME=!name!
                echo Connection '!CONNECTION_NAME!' found for MAC address '!MAC_ADDRESS!'
            )
        )
    )
)

echo "Running netcfg -v -winpe..."
netcfg -v -winpe

echo "Running wpeutil InitializeNetwork ..."
wpeutil InitializeNetwork

echo "Running netsh to set up static network info ..."
if defined GATEWAY (
  netsh interface ipv4 set address "%CONNECTION_NAME%" static %IP_ADDRESS% %NETMASK% %GATEWAY%
) else (
  netsh interface ipv4 set address "%CONNECTION_NAME%" static %IP_ADDRESS% %NETMASK%
)
