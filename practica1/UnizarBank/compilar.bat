@echo off
title Compilar UnizarBank - Grupo 03

echo ==========================================
echo      Compilacion de UnizarBank
echo ==========================================
echo.

set /p GNUCOBOL=Introduzca la ruta de GnuCOBOL 3.2: 

if not exist "%GNUCOBOL%\set_env.cmd" (
    echo.
    echo ERROR: No se encuentra set_env.cmd en:
    echo %GNUCOBOL%
    echo.
    pause
    exit /b 1
)

call "%GNUCOBOL%\set_env.cmd"

cd /d "%~dp0"

echo.
echo Verificando ficheros de datos...
if not exist "movimientos.ubd" (
    echo Creando movimientos.ubd...
    cobc -x -free -std=mf CREAR-MOVIMIENTOS.cbl && CREAR-MOVIMIENTOS.exe
)
if not exist "transferencias.ubd" (
    echo Creando transferencias.ubd...
    cobc -x -free -std=mf CREAR-TRANSFERENCIAS.cbl && CREAR-TRANSFERENCIAS.exe
)

echo.
echo Compilando UnizarBank...
echo.

cobc -m -free -std=mf -Wno-goto-section BANK2.cbl || goto ERROR_COMPILACION
cobc -m -free -std=mf -Wno-goto-section BANK3.cbl || goto ERROR_COMPILACION
cobc -m -free -std=mf -Wno-goto-section BANK4.cbl || goto ERROR_COMPILACION
cobc -m -free -std=mf -Wno-goto-section BANK5.cbl || goto ERROR_COMPILACION
cobc -m -free -std=mf -Wno-goto-section BANK6.cbl || goto ERROR_COMPILACION
cobc -m -free -std=mf -Wno-goto-section BANK7.cbl || goto ERROR_COMPILACION
cobc -m -free -std=mf -Wno-goto-section BANK8.cbl || goto ERROR_COMPILACION
cobc -m -free -std=mf -Wno-goto-section BANK9.cbl || goto ERROR_COMPILACION
cobc -x -free -std=mf -Wno-goto-section BANK1.cbl || goto ERROR_COMPILACION

echo.
echo ==========================================
echo   Compilacion completada correctamente.
echo ==========================================
echo.
pause
exit /b 0

:ERROR_COMPILACION
echo.
echo ERROR: Se ha producido un error durante la compilacion.
echo.
pause
exit /b 1