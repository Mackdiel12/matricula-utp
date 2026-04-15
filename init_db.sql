-- =====================================================
-- BASE DE DATOS: SISTEMA DE MATRÍCULA UTP
-- Universidad Tecnológica de Panamá
-- Versión PostgreSQL para Render.com
-- =====================================================

-- =====================================================
-- TABLA: FACULTADES
-- =====================================================
CREATE TABLE IF NOT EXISTS facultades (
    id_facultad SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: CARRERAS
-- =====================================================
CREATE TABLE IF NOT EXISTS carreras (
    id_carrera SERIAL PRIMARY KEY,
    id_facultad INT NOT NULL REFERENCES facultades(id_facultad),
    nombre VARCHAR(150) NOT NULL,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    duracion_semestres INT DEFAULT 10,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: ESTUDIANTES
-- =====================================================
CREATE TABLE IF NOT EXISTS estudiantes (
    id_estudiante SERIAL PRIMARY KEY,
    cedula VARCHAR(15) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    usuario VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    id_carrera INT NOT NULL REFERENCES carreras(id_carrera),
    semestre_actual INT DEFAULT 1,
    estado VARCHAR(20) DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'graduado', 'suspendido')),
    fecha_ingreso DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: PROFESORES
-- =====================================================
CREATE TABLE IF NOT EXISTS profesores (
    id_profesor SERIAL PRIMARY KEY,
    cedula VARCHAR(15) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    especialidad VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: MATERIAS
-- =====================================================
CREATE TABLE IF NOT EXISTS materias (
    id_materia SERIAL PRIMARY KEY,
    id_carrera INT NOT NULL REFERENCES carreras(id_carrera),
    codigo VARCHAR(20) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    creditos INT NOT NULL DEFAULT 3,
    semestre INT NOT NULL,
    horas_teoria INT DEFAULT 2,
    horas_practica INT DEFAULT 2,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (codigo, id_carrera)
);

-- =====================================================
-- TABLA: PERIODOS ACADÉMICOS
-- =====================================================
CREATE TABLE IF NOT EXISTS periodos (
    id_periodo SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    anio INT NOT NULL,
    semestre_num INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    fecha_inicio_matricula DATE,
    fecha_fin_matricula DATE,
    activo BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: SECCIONES (Grupos de clase)
-- =====================================================
CREATE TABLE IF NOT EXISTS secciones (
    id_seccion SERIAL PRIMARY KEY,
    id_materia INT NOT NULL REFERENCES materias(id_materia),
    id_profesor INT REFERENCES profesores(id_profesor),
    id_periodo INT NOT NULL REFERENCES periodos(id_periodo),
    seccion VARCHAR(10) NOT NULL,
    cupo_maximo INT DEFAULT 35,
    cupo_actual INT DEFAULT 0,
    horario VARCHAR(100),
    aula VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: MATRÍCULAS
-- =====================================================
CREATE TABLE IF NOT EXISTS matriculas (
    id_matricula SERIAL PRIMARY KEY,
    id_estudiante INT NOT NULL REFERENCES estudiantes(id_estudiante),
    id_seccion INT NOT NULL REFERENCES secciones(id_seccion),
    id_periodo INT NOT NULL REFERENCES periodos(id_periodo),
    fecha_matricula TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'activa' CHECK (estado IN ('activa', 'retirada', 'completada')),
    UNIQUE (id_estudiante, id_seccion)
);

-- =====================================================
-- INSERTAR DATOS DE PRUEBA
-- =====================================================

-- Facultades
INSERT INTO facultades (nombre, codigo) VALUES
('Facultad de Ingeniería de Sistemas Computacionales', 'FISC'),
('Facultad de Ingeniería Eléctrica', 'FIE'),
('Facultad de Ingeniería Civil', 'FIC'),
('Facultad de Ingeniería Mecánica', 'FIM')
ON CONFLICT DO NOTHING;

-- Carreras
INSERT INTO carreras (id_facultad, nombre, codigo, duracion_semestres) VALUES
(1, 'Licenciatura en Ingeniería de Sistemas y Computación', 'LISC', 10),
(1, 'Licenciatura en Ingeniería de Software', 'LISW', 10),
(1, 'Licenciatura en Redes y Comunicaciones', 'LIRC', 10),
(2, 'Licenciatura en Ingeniería Electrónica', 'LIEL', 10)
ON CONFLICT DO NOTHING;

-- Profesores
INSERT INTO profesores (cedula, nombre, apellido, email, especialidad) VALUES
('8-700-1001', 'Carlos', 'Gonzalez', 'carlos.gonzalez@utp.ac.pa', 'Programación'),
('8-700-1002', 'Maria', 'Rodriguez', 'maria.rodriguez@utp.ac.pa', 'Bases de Datos'),
('8-700-1003', 'Jose', 'Perez', 'jose.perez@utp.ac.pa', 'Redes'),
('8-700-1004', 'Ana', 'Martinez', 'ana.martinez@utp.ac.pa', 'Sistemas Operativos'),
('8-700-1005', 'Luis', 'Sanchez', 'luis.sanchez@utp.ac.pa', 'Matemáticas'),
('8-700-1006', 'Carmen', 'Lopez', 'carmen.lopez@utp.ac.pa', 'Física'),
('8-700-1007', 'Roberto', 'Hernandez', 'roberto.hernandez@utp.ac.pa', 'Inteligencia Artificial'),
('8-700-1008', 'Patricia', 'Garcia', 'patricia.garcia@utp.ac.pa', 'Seguridad Informática')
ON CONFLICT DO NOTHING;

-- Estudiantes
INSERT INTO estudiantes (cedula, nombre, apellido, email, usuario, password, id_carrera, semestre_actual, fecha_ingreso) VALUES
('8-900-1001', 'Andy', 'Martinez', 'andy.martinez@utp.ac.pa', 'andy.martinez', 'Clave@1234', 1, 3, '2024-03-01'),
('8-900-1002', 'Mackdiel', 'Dominguez', 'mackdiel.dominguez@utp.ac.pa', 'mackdiel.dominguez', 'Clave@1234', 1, 3, '2024-03-01'),
('8-900-1003', 'Maria', 'Lopez', 'maria.lopez@utp.ac.pa', 'maria.lopez', 'Clave@5678', 1, 2, '2024-08-01'),
('8-900-1004', 'Juan', 'Garcia', 'juan.garcia@utp.ac.pa', 'juan.garcia', 'Clave@5678', 1, 4, '2023-08-01'),
('8-900-1005', 'Sofia', 'Torres', 'sofia.torres@utp.ac.pa', 'sofia.torres', 'Clave@5678', 1, 4, '2023-08-01'),
('8-900-1006', 'Carlos', 'Ruiz', 'carlos.ruiz@utp.ac.pa', 'carlos.ruiz', 'Clave@1234', 2, 2, '2024-08-01'),
('8-900-1007', 'Ana', 'Mendoza', 'ana.mendoza@utp.ac.pa', 'ana.mendoza', 'Clave@1234', 2, 3, '2024-03-01'),
('8-900-1008', 'Pedro', 'Castro', 'pedro.castro@utp.ac.pa', 'pedro.castro', 'Clave@5678', 1, 5, '2023-03-01'),
('8-900-1009', 'Laura', 'Vargas', 'laura.vargas@utp.ac.pa', 'laura.vargas', 'Clave@5678', 1, 1, '2025-03-01'),
('8-900-1010', 'Diego', 'Morales', 'diego.morales@utp.ac.pa', 'diego.morales', 'Clave@1234', 1, 1, '2025-03-01')
ON CONFLICT DO NOTHING;

-- Materias de LISC (Ingeniería de Sistemas) - Semestres 1 al 5
INSERT INTO materias (id_carrera, codigo, nombre, creditos, semestre, horas_teoria, horas_practica, descripcion) VALUES
-- Semestre 1
(1, 'MAT-101', 'Calculo I', 4, 1, 4, 2, 'Fundamentos de cálculo diferencial'),
(1, 'FIS-101', 'Fisica I', 4, 1, 3, 2, 'Mecánica clásica y termodinámica'),
(1, 'PRG-101', 'Introduccion a la Programacion', 3, 1, 2, 3, 'Fundamentos de programación con Python'),
(1, 'MAT-102', 'Algebra Lineal', 3, 1, 3, 1, 'Vectores, matrices y sistemas de ecuaciones'),
(1, 'COM-101', 'Comunicacion Oral y Escrita', 2, 1, 2, 0, 'Técnicas de comunicación efectiva'),
-- Semestre 2
(1, 'MAT-201', 'Calculo II', 4, 2, 4, 2, 'Cálculo integral y series'),
(1, 'FIS-201', 'Fisica II', 4, 2, 3, 2, 'Electromagnetismo y ondas'),
(1, 'PRG-201', 'Programacion Orientada a Objetos', 4, 2, 2, 4, 'POO con Java'),
(1, 'EST-201', 'Estadistica I', 3, 2, 3, 1, 'Probabilidad y estadística descriptiva'),
(1, 'LOG-201', 'Logica Computacional', 3, 2, 3, 1, 'Lógica proposicional y de predicados'),
-- Semestre 3
(1, 'MAT-301', 'Calculo III', 4, 3, 4, 2, 'Cálculo multivariable'),
(1, 'PRG-301', 'Estructuras de Datos', 4, 3, 2, 4, 'Listas, árboles, grafos y algoritmos'),
(1, 'BDD-301', 'Bases de Datos I', 4, 3, 2, 4, 'Diseño y modelado de bases de datos relacionales'),
(1, 'ARQ-301', 'Arquitectura de Computadoras', 3, 3, 3, 2, 'Organización y arquitectura de sistemas'),
(1, 'RED-301', 'Fundamentos de Redes', 3, 3, 2, 2, 'Introducción a redes de computadoras'),
-- Semestre 4
(1, 'PRG-401', 'Algoritmos y Complejidad', 4, 4, 3, 3, 'Diseño y análisis de algoritmos'),
(1, 'BDD-401', 'Bases de Datos II', 4, 4, 2, 4, 'SQL avanzado y administración de BD'),
(1, 'SOP-401', 'Sistemas Operativos', 4, 4, 3, 3, 'Gestión de procesos, memoria y archivos'),
(1, 'RED-401', 'Redes de Computadoras', 4, 4, 2, 4, 'Protocolos TCP/IP y configuración de redes'),
(1, 'ING-401', 'Ingenieria de Software I', 3, 4, 3, 2, 'Metodologías de desarrollo de software'),
-- Semestre 5
(1, 'WEB-501', 'Desarrollo Web', 4, 5, 2, 4, 'HTML, CSS, JavaScript y frameworks'),
(1, 'ING-501', 'Ingenieria de Software II', 4, 5, 2, 4, 'Patrones de diseño y arquitectura de software'),
(1, 'SEG-501', 'Seguridad Informatica', 3, 5, 2, 2, 'Fundamentos de ciberseguridad'),
(1, 'IAR-501', 'Inteligencia Artificial', 4, 5, 3, 3, 'Machine Learning y redes neuronales'),
(1, 'MOV-501', 'Desarrollo de Aplicaciones Moviles', 3, 5, 2, 3, 'Desarrollo para Android e iOS')
ON CONFLICT DO NOTHING;

-- Periodo Académico Activo
INSERT INTO periodos (nombre, anio, semestre_num, fecha_inicio, fecha_fin, fecha_inicio_matricula, fecha_fin_matricula, activo) VALUES
('I Semestre 2026', 2026, 1, '2026-03-02', '2026-07-15', '2026-02-15', '2026-03-10', TRUE),
('II Semestre 2025', 2025, 2, '2025-08-01', '2025-12-15', '2025-07-15', '2025-08-05', FALSE)
ON CONFLICT DO NOTHING;

-- Secciones para el periodo activo (I Semestre 2026)
INSERT INTO secciones (id_materia, id_profesor, id_periodo, seccion, cupo_maximo, horario, aula) VALUES
-- Semestre 1
(1, 5, 1, '1IL-111', 35, 'Lun-Mie 7:00-8:30', 'Aula 101'),
(1, 5, 1, '1IL-112', 35, 'Mar-Jue 7:00-8:30', 'Aula 102'),
(2, 6, 1, '1IL-111', 35, 'Lun-Mie 8:40-10:10', 'Lab Fisica'),
(3, 1, 1, '1IL-111', 35, 'Mar-Jue 8:40-10:10', 'Lab Comp 1'),
(3, 1, 1, '1IL-112', 35, 'Lun-Mie 10:20-11:50', 'Lab Comp 2'),
(4, 5, 1, '1IL-111', 35, 'Mar-Jue 10:20-11:50', 'Aula 103'),
(5, 2, 1, '1IL-111', 35, 'Vie 7:00-9:00', 'Aula 104'),
-- Semestre 2
(6, 5, 1, '1IL-211', 35, 'Lun-Mie 7:00-8:30', 'Aula 201'),
(7, 6, 1, '1IL-211', 35, 'Mar-Jue 7:00-8:30', 'Lab Fisica'),
(8, 1, 1, '1IL-211', 35, 'Lun-Mie 8:40-10:10', 'Lab Comp 3'),
(9, 5, 1, '1IL-211', 35, 'Mar-Jue 8:40-10:10', 'Aula 202'),
(10, 4, 1, '1IL-211', 35, 'Vie 7:00-9:00', 'Aula 203'),
-- Semestre 3
(11, 5, 1, '1IL-311', 35, 'Lun-Mie 7:00-8:30', 'Aula 301'),
(12, 1, 1, '1IL-311', 35, 'Mar-Jue 7:00-8:30', 'Lab Comp 4'),
(12, 1, 1, '1IL-312', 35, 'Lun-Mie 10:20-11:50', 'Lab Comp 5'),
(13, 2, 1, '1IL-311', 35, 'Lun-Mie 8:40-10:10', 'Lab BD 1'),
(14, 4, 1, '1IL-311', 35, 'Mar-Jue 8:40-10:10', 'Aula 302'),
(15, 3, 1, '1IL-311', 35, 'Vie 7:00-9:00', 'Lab Redes'),
-- Semestre 4
(16, 1, 1, '1IL-411', 35, 'Lun-Mie 7:00-8:30', 'Aula 401'),
(17, 2, 1, '1IL-411', 35, 'Mar-Jue 7:00-8:30', 'Lab BD 2'),
(18, 4, 1, '1IL-411', 35, 'Lun-Mie 8:40-10:10', 'Lab SO'),
(19, 3, 1, '1IL-411', 35, 'Mar-Jue 8:40-10:10', 'Lab Redes'),
(20, 7, 1, '1IL-411', 35, 'Vie 7:00-9:00', 'Aula 402'),
-- Semestre 5
(21, 1, 1, '1IL-511', 35, 'Lun-Mie 7:00-8:30', 'Lab Web'),
(22, 7, 1, '1IL-511', 35, 'Mar-Jue 7:00-8:30', 'Aula 501'),
(23, 8, 1, '1IL-511', 35, 'Lun-Mie 8:40-10:10', 'Lab Seg'),
(24, 7, 1, '1IL-511', 35, 'Mar-Jue 8:40-10:10', 'Lab IA'),
(25, 1, 1, '1IL-511', 35, 'Vie 7:00-9:00', 'Lab Movil')
ON CONFLICT DO NOTHING;

-- Algunas matrículas de ejemplo
INSERT INTO matriculas (id_estudiante, id_seccion, id_periodo, estado) VALUES
(1, 13, 1, 'activa'),
(1, 14, 1, 'activa'),
(1, 16, 1, 'activa'),
(2, 13, 1, 'activa'),
(2, 15, 1, 'activa'),
(3, 8, 1, 'activa'),
(3, 10, 1, 'activa')
ON CONFLICT DO NOTHING;

-- Actualizar cupos
UPDATE secciones SET cupo_actual = 2 WHERE id_seccion = 13;
UPDATE secciones SET cupo_actual = 1 WHERE id_seccion = 14;
UPDATE secciones SET cupo_actual = 1 WHERE id_seccion = 15;
UPDATE secciones SET cupo_actual = 1 WHERE id_seccion = 16;
UPDATE secciones SET cupo_actual = 1 WHERE id_seccion = 8;
UPDATE secciones SET cupo_actual = 1 WHERE id_seccion = 10;
