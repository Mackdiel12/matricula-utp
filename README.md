# Sistema de Matrícula UTP - Render.com

## Pasos para subir a Render.com

### 1. Subir a GitHub

1. Crear un repositorio nuevo en GitHub
2. Subir todos estos archivos al repositorio

### 2. Crear base de datos en Render

1. Ve a https://dashboard.render.com
2. New → PostgreSQL
3. Name: `matricula-utp-db`
4. Region: Oregon (US West)
5. Plan: Free
6. Create Database

Copia la **Internal Database URL** (la necesitarás después)

### 3. Crear Web Service en Render

1. New → Web Service
2. Connect your GitHub repository
3. Configura:
   - Name: `matricula-utp`
   - Region: Oregon
   - Runtime: Python 3
   - Build Command: `./build.sh`
   - Start Command: `gunicorn app:app`
4. Environment Variables:
   - `DATABASE_URL` = (pega la Internal Database URL)
   - `SECRET_KEY` = `clave-secreta-utp-2026`
5. Create Web Service

### 4. ¡Listo!

Tu URL será: `https://matricula-utp.onrender.com`

## Credenciales de prueba

| Usuario | Contraseña |
|---------|------------|
| andy.martinez | Clave@1234 |
| mackdiel.dominguez | Clave@1234 |
| maria.lopez | Clave@5678 |
