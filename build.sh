#!/usr/bin/env bash
# Script de build para Render.com

# Instalar dependencias
pip install -r requirements.txt

# Inicializar base de datos (solo si no existe ya)
python init_db.py
