@echo off
setlocal EnableDelayedExpansion

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Need admin privileges!!! Please run as administrator.
    exit /b
)

:: Variable(s)
set "reg_path=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"

:: Enumerate available NICs and randomize MAC addresses for each
for /f "skip=2 tokens=2 delims=," %%A in ('wmic nic get NetConnectionId /format:csv') do (
    for /f "delims=" %%B in ("%%~A") do (
        set "NetworkAdapter=%%B"
        call :GEN_MAC
        call :NIC_INDEX
        >nul 2>&1 (
            netsh interface set interface "!NetworkAdapter!" admin=disable
            reg add "!reg_path!\!Index!" /v "NetworkAddress" /t REG_SZ /d "!mac_address!" /f
            netsh interface set interface "!NetworkAdapter!" admin=enable
        )
    )
)
exit /b

:: Generating Random MAC Address
:GEN_MAC
set "hex_chars=0123456789ABCDEF`AE26"
set mac_address=
for /l %%A in (1,1,11) do (
    set /a "random_index=!random! %% 16"
    for %%B in (!random_index!) do (
        set mac_address=!mac_address!!hex_chars:~%%B,1!
    )
)
set /a "random_index=!random! %% 4 + 17"
set mac_address=!mac_address:~0,1!!hex_chars:~%random_index%,1!!mac_address:~1!
exit /b

:: Retrieving current caption & converting into a Index
:NIC_INDEX
for /f "tokens=2 delims=[]" %%A in ('wmic nic where "NetConnectionId='!NetworkAdapter!'" get Caption /format:value ^| find "Caption"') do (
    set "Index=%%A"
    set "Index=!Index:~-4!"
)
exit /b
