@echo off
chcp 65001 > nul
title Doce & Ponto - Painel Web de Gestão e Estoque
echo ===================================================================
echo     DOCE & PONTO - PAINEL WEB DE GESTÃO E CONTROLE DE ESTOQUE
echo ===================================================================
echo.
echo [1/2] Iniciando servidor web local na porta 8080...
echo [2/2] Abrindo navegador em http://localhost:8080
echo.
echo Pressione Ctrl+C para encerrar o servidor quando terminar o uso.
echo ===================================================================
echo.

start http://localhost:8080
python -m http.server 8080 --directory "%~dp0web_portal"
pause
