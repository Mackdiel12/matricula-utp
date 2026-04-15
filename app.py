from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
import psycopg2
import psycopg2.extras
from functools import wraps
import os

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'clave-secreta-utp-2026')

# =====================================================
# CONEXIÓN A POSTGRESQL
# =====================================================
def get_db_connection():
    database_url = os.environ.get('DATABASE_URL')
    if database_url:
        conn = psycopg2.connect(database_url, cursor_factory=psycopg2.extras.RealDictCursor)
    else:
        # Conexión local para desarrollo
        conn = psycopg2.connect(
            host='localhost',
            database='matricula_utp',
            user='postgres',
            password='admin',
            cursor_factory=psycopg2.extras.RealDictCursor
        )
    return conn

# =====================================================
# DECORADOR: Requiere Login
# =====================================================
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'logged_in' not in session:
            flash('Debes iniciar sesión para acceder', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

# =====================================================
# RUTA: Página Principal (Redirige a Login)
# =====================================================
@app.route('/')
def index():
    if 'logged_in' in session:
        return redirect(url_for('matricula'))
    return redirect(url_for('login'))

# =====================================================
# RUTA: Login
# =====================================================
@app.route('/login', methods=['GET', 'POST'])
def login():
    if 'logged_in' in session:
        return redirect(url_for('matricula'))
    
    if request.method == 'POST':
        usuario = request.form.get('usuario', '').strip()
        password = request.form.get('password', '').strip()
        
        if not usuario or not password:
            flash('Por favor complete todos los campos', 'error')
            return render_template('login.html')
        
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('''
            SELECT e.*, c.nombre as carrera_nombre, c.codigo as carrera_codigo
            FROM estudiantes e
            JOIN carreras c ON e.id_carrera = c.id_carrera
            WHERE e.usuario = %s AND e.password = %s AND e.estado = 'activo'
        ''', (usuario, password))
        estudiante = cur.fetchone()
        cur.close()
        conn.close()
        
        if estudiante:
            session['logged_in'] = True
            session['id_estudiante'] = estudiante['id_estudiante']
            session['usuario'] = estudiante['usuario']
            session['nombre'] = f"{estudiante['nombre']} {estudiante['apellido']}"
            session['cedula'] = estudiante['cedula']
            session['email'] = estudiante['email']
            session['id_carrera'] = estudiante['id_carrera']
            session['carrera'] = estudiante['carrera_nombre']
            session['carrera_codigo'] = estudiante['carrera_codigo']
            session['semestre_actual'] = estudiante['semestre_actual']
            
            flash(f'¡Bienvenido/a {estudiante["nombre"]}!', 'success')
            return redirect(url_for('matricula'))
        else:
            flash('Usuario o contraseña incorrectos', 'error')
    
    return render_template('login.html')

# =====================================================
# RUTA: Logout
# =====================================================
@app.route('/logout')
def logout():
    session.clear()
    flash('Sesión cerrada exitosamente', 'info')
    return redirect(url_for('login'))

# =====================================================
# RUTA: Página de Matrícula
# =====================================================
@app.route('/matricula')
@login_required
def matricula():
    conn = get_db_connection()
    cur = conn.cursor()
    
    # Obtener periodo activo
    cur.execute('SELECT * FROM periodos WHERE activo = TRUE LIMIT 1')
    periodo = cur.fetchone()
    
    if not periodo:
        flash('No hay periodo de matrícula activo', 'warning')
        cur.close()
        conn.close()
        return render_template('matricula.html', materias=[], mi_matricula=[], periodo=None, total_creditos=0, secciones_matriculadas=[])
    
    # Obtener materias disponibles para la carrera del estudiante
    cur.execute('''
        SELECT 
            s.id_seccion,
            m.id_materia,
            m.codigo,
            m.nombre as materia,
            m.creditos,
            m.semestre,
            CONCAT(p.nombre, ' ', p.apellido) as profesor,
            s.seccion,
            s.horario,
            s.aula,
            s.cupo_maximo,
            s.cupo_actual,
            (s.cupo_maximo - s.cupo_actual) as cupos_disponibles
        FROM secciones s
        JOIN materias m ON s.id_materia = m.id_materia
        JOIN profesores p ON s.id_profesor = p.id_profesor
        WHERE s.id_periodo = %s AND m.id_carrera = %s
        ORDER BY m.semestre, m.nombre, s.seccion
    ''', (periodo['id_periodo'], session['id_carrera']))
    materias = cur.fetchall()
    
    # Obtener matrícula actual del estudiante
    cur.execute('''
        SELECT 
            mat.id_matricula,
            s.id_seccion,
            m.codigo,
            m.nombre as materia,
            m.creditos,
            m.semestre,
            CONCAT(p.nombre, ' ', p.apellido) as profesor,
            s.seccion,
            s.horario,
            s.aula,
            mat.fecha_matricula
        FROM matriculas mat
        JOIN secciones s ON mat.id_seccion = s.id_seccion
        JOIN materias m ON s.id_materia = m.id_materia
        JOIN profesores p ON s.id_profesor = p.id_profesor
        WHERE mat.id_estudiante = %s AND mat.id_periodo = %s AND mat.estado = 'activa'
        ORDER BY m.semestre, m.nombre
    ''', (session['id_estudiante'], periodo['id_periodo']))
    mi_matricula = cur.fetchall()
    
    # Calcular total de créditos
    total_creditos = sum(m['creditos'] for m in mi_matricula)
    
    # IDs de secciones ya matriculadas
    secciones_matriculadas = [m['id_seccion'] for m in mi_matricula]
    
    cur.close()
    conn.close()
    
    return render_template('matricula.html', 
                         materias=materias, 
                         mi_matricula=mi_matricula, 
                         periodo=periodo,
                         total_creditos=total_creditos,
                         secciones_matriculadas=secciones_matriculadas)

# =====================================================
# RUTA API: Matricular materia
# =====================================================
@app.route('/api/matricular', methods=['POST'])
@login_required
def matricular():
    data = request.get_json()
    id_seccion = data.get('id_seccion')
    
    if not id_seccion:
        return jsonify({'success': False, 'message': 'Sección no especificada'}), 400
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        # Obtener periodo activo
        cur.execute('SELECT id_periodo FROM periodos WHERE activo = TRUE LIMIT 1')
        periodo = cur.fetchone()
        
        if not periodo:
            return jsonify({'success': False, 'message': 'No hay periodo activo'}), 400
        
        # Verificar que la sección existe y tiene cupo
        cur.execute('''
            SELECT s.*, m.nombre as materia, m.creditos, m.id_materia
            FROM secciones s
            JOIN materias m ON s.id_materia = m.id_materia
            WHERE s.id_seccion = %s
        ''', (id_seccion,))
        seccion = cur.fetchone()
        
        if not seccion:
            return jsonify({'success': False, 'message': 'Sección no encontrada'}), 404
        
        if seccion['cupo_actual'] >= seccion['cupo_maximo']:
            return jsonify({'success': False, 'message': 'No hay cupos disponibles'}), 400
        
        # Verificar que no esté ya matriculado en esta sección
        cur.execute('''
            SELECT id_matricula FROM matriculas 
            WHERE id_estudiante = %s AND id_seccion = %s AND estado = 'activa'
        ''', (session['id_estudiante'], id_seccion))
        
        if cur.fetchone():
            return jsonify({'success': False, 'message': 'Ya estás matriculado en esta sección'}), 400
        
        # Verificar que no esté matriculado en otra sección de la misma materia
        cur.execute('''
            SELECT mat.id_matricula 
            FROM matriculas mat
            JOIN secciones s ON mat.id_seccion = s.id_seccion
            WHERE mat.id_estudiante = %s 
            AND s.id_materia = %s 
            AND mat.estado = 'activa'
            AND mat.id_periodo = %s
        ''', (session['id_estudiante'], seccion['id_materia'], periodo['id_periodo']))
        
        if cur.fetchone():
            return jsonify({'success': False, 'message': 'Ya estás matriculado en otra sección de esta materia'}), 400
        
        # Realizar la matrícula
        cur.execute('''
            INSERT INTO matriculas (id_estudiante, id_seccion, id_periodo, estado)
            VALUES (%s, %s, %s, 'activa')
        ''', (session['id_estudiante'], id_seccion, periodo['id_periodo']))
        
        # Actualizar cupo
        cur.execute('UPDATE secciones SET cupo_actual = cupo_actual + 1 WHERE id_seccion = %s', (id_seccion,))
        
        conn.commit()
        
        return jsonify({
            'success': True, 
            'message': f'Matriculado exitosamente en {seccion["materia"]}'
        })
        
    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        cur.close()
        conn.close()

# =====================================================
# RUTA API: Retirar materia
# =====================================================
@app.route('/api/retirar', methods=['POST'])
@login_required
def retirar():
    data = request.get_json()
    id_matricula = data.get('id_matricula')
    
    if not id_matricula:
        return jsonify({'success': False, 'message': 'Matrícula no especificada'}), 400
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        # Verificar que la matrícula pertenece al estudiante
        cur.execute('''
            SELECT mat.*, m.nombre as materia, s.id_seccion
            FROM matriculas mat
            JOIN secciones s ON mat.id_seccion = s.id_seccion
            JOIN materias m ON s.id_materia = m.id_materia
            WHERE mat.id_matricula = %s AND mat.id_estudiante = %s AND mat.estado = 'activa'
        ''', (id_matricula, session['id_estudiante']))
        matricula_record = cur.fetchone()
        
        if not matricula_record:
            return jsonify({'success': False, 'message': 'Matrícula no encontrada'}), 404
        
        # Actualizar estado de matrícula
        cur.execute("UPDATE matriculas SET estado = 'retirada' WHERE id_matricula = %s", (id_matricula,))
        
        # Actualizar cupo
        cur.execute('UPDATE secciones SET cupo_actual = cupo_actual - 1 WHERE id_seccion = %s', (matricula_record['id_seccion'],))
        
        conn.commit()
        
        return jsonify({
            'success': True, 
            'message': f'Materia {matricula_record["materia"]} retirada exitosamente'
        })
        
    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        cur.close()
        conn.close()

# =====================================================
# RUTA API: Obtener materias (para filtros AJAX)
# =====================================================
@app.route('/api/materias')
@login_required
def get_materias():
    semestre = request.args.get('semestre', type=int)
    busqueda = request.args.get('busqueda', '').strip()
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    # Obtener periodo activo
    cur.execute('SELECT id_periodo FROM periodos WHERE activo = TRUE LIMIT 1')
    periodo = cur.fetchone()
    
    if not periodo:
        cur.close()
        conn.close()
        return jsonify([])
    
    query = '''
        SELECT 
            s.id_seccion,
            m.id_materia,
            m.codigo,
            m.nombre as materia,
            m.creditos,
            m.semestre,
            CONCAT(p.nombre, ' ', p.apellido) as profesor,
            s.seccion,
            s.horario,
            s.aula,
            s.cupo_maximo,
            s.cupo_actual,
            (s.cupo_maximo - s.cupo_actual) as cupos_disponibles
        FROM secciones s
        JOIN materias m ON s.id_materia = m.id_materia
        JOIN profesores p ON s.id_profesor = p.id_profesor
        WHERE s.id_periodo = %s AND m.id_carrera = %s
    '''
    params = [periodo['id_periodo'], session['id_carrera']]
    
    if semestre:
        query += ' AND m.semestre = %s'
        params.append(semestre)
    
    if busqueda:
        query += ' AND (m.nombre ILIKE %s OR m.codigo ILIKE %s)'
        params.extend([f'%{busqueda}%', f'%{busqueda}%'])
    
    query += ' ORDER BY m.semestre, m.nombre, s.seccion'
    
    cur.execute(query, params)
    materias = cur.fetchall()
    cur.close()
    conn.close()
    
    return jsonify([dict(m) for m in materias])

# =====================================================
# EJECUTAR APLICACIÓN
# =====================================================
if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(debug=True, host='0.0.0.0', port=port)
