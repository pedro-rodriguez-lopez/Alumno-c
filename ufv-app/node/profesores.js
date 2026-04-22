#!/usr/bin/env node

/**
 * Módulo Profesores - Gestión de Asignaturas e Inscripciones
 * Alumno C - Práctica AWS UFV
 * 
 * Funcionalidad:
 * - Gestión de asignaturas (CRUD)
 * - Consulta de estudiantes inscritos
 * - Calificación de alumnos
 */

const express = require('express');
const { Pool } = require('pg');
const AWS = require('aws-sdk');

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ============================================================================
// CONFIGURACIÓN POSTGRESQL
// ============================================================================
const pool = new Pool({
    host: process.env.DB_HOST || '10.0.1.10' || 'localhost',
    user: process.env.DB_USER || 'backend',
    password: process.env.DB_PASSWORD || 'ContraseñaSegura123',
    database: process.env.DB_NAME || 'academico',
    port: process.env.DB_PORT || 5432
});

// ============================================================================
// CONFIGURACIÓN AWS S3 (IAM Role)
// ============================================================================
const s3 = new AWS.S3({
    region: process.env.AWS_REGION || 'eu-south-2'
});

// ============================================================================
// API REST - ENDPOINTS PROFESORES
// ============================================================================

/**
 * GET /api/profesores/health
 * Health check
 */
app.get('/api/profesores/health', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Módulo Profesores operativo',
        node: process.env.HOSTNAME || 'desconocido',
        timestamp: new Date().toISOString()
    });
});

/**
 * GET /api/profesores/asignaturas
 * Listar todas las asignaturas
 */
app.get('/api/profesores/asignaturas', async (req, res) => {
    try {
        const query = `
            SELECT id, nombre, descripcion, creditos, fecha_creacion
            FROM academico.asignaturas
            ORDER BY nombre ASC
        `;
        const result = await pool.query(query);
        res.status(200).json({
            success: true,
            data: result.rows,
            count: result.rows.length
        });
    } catch (err) {
        console.error('Error en GET /asignaturas:', err);
        res.status(500).json({
            success: false,
            error: 'Error al obtener asignaturas',
            details: err.message
        });
    }
});

/**
 * GET /api/profesores/asignaturas/:id
 * Obtener detalles de una asignatura
 */
app.get('/api/profesores/asignaturas/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const query = `
            SELECT id, nombre, descripcion, creditos, fecha_creacion
            FROM academico.asignaturas
            WHERE id = $1
        `;
        const result = await pool.query(query, [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Asignatura no encontrada'
            });
        }
        
        res.status(200).json({
            success: true,
            data: result.rows[0]
        });
    } catch (err) {
        console.error('Error en GET /asignaturas/:id:', err);
        res.status(500).json({
            success: false,
            error: 'Error al obtener asignatura',
            details: err.message
        });
    }
});

/**
 * GET /api/profesores/asignaturas/:id/inscritos
 * Listar alumnos inscritos en una asignatura
 */
app.get('/api/profesores/asignaturas/:id/inscritos', async (req, res) => {
    try {
        const { id } = req.params;
        const query = `
            SELECT 
                a.id as alumno_id,
                a.nombre as alumno_nombre,
                a.email as alumno_email,
                a.fecha_registro,
                i.nota,
                i.id as inscripcion_id
            FROM academico.alumnos a
            INNER JOIN academico.inscripciones i ON a.id = i.alumno_id
            WHERE i.asignatura_id = $1
            ORDER BY a.nombre ASC
        `;
        const result = await pool.query(query, [id]);
        
        res.status(200).json({
            success: true,
            data: result.rows,
            count: result.rows.length
        });
    } catch (err) {
        console.error('Error en GET /asignaturas/:id/inscritos:', err);
        res.status(500).json({
            success: false,
            error: 'Error al obtener alumnos inscritos',
            details: err.message
        });
    }
});

/**
 * POST /api/profesores/asignaturas
 * Crear nueva asignatura
 */
app.post('/api/profesores/asignaturas', async (req, res) => {
    try {
        const { nombre, descripcion, creditos } = req.body;
        
        if (!nombre || !creditos) {
            return res.status(400).json({
                success: false,
                error: 'Faltan campos requeridos: nombre, creditos'
            });
        }
        
        const query = `
            INSERT INTO academico.asignaturas (nombre, descripcion, creditos, fecha_creacion)
            VALUES ($1, $2, $3, NOW())
            RETURNING id, nombre, descripcion, creditos, fecha_creacion
        `;
        const result = await pool.query(query, [nombre, descripcion || null, creditos]);
        
        res.status(201).json({
            success: true,
            message: 'Asignatura creada exitosamente',
            data: result.rows[0]
        });
    } catch (err) {
        console.error('Error en POST /asignaturas:', err);
        res.status(500).json({
            success: false,
            error: 'Error al crear asignatura',
            details: err.message
        });
    }
});

/**
 * PUT /api/profesores/asignaturas/:id
 * Actualizar asignatura
 */
app.put('/api/profesores/asignaturas/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { nombre, descripcion, creditos } = req.body;
        
        const query = `
            UPDATE academico.asignaturas
            SET 
                nombre = COALESCE($1, nombre),
                descripcion = COALESCE($2, descripcion),
                creditos = COALESCE($3, creditos)
            WHERE id = $4
            RETURNING id, nombre, descripcion, creditos, fecha_creacion
        `;
        const result = await pool.query(query, [nombre, descripcion, creditos, id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Asignatura no encontrada'
            });
        }
        
        res.status(200).json({
            success: true,
            message: 'Asignatura actualizada exitosamente',
            data: result.rows[0]
        });
    } catch (err) {
        console.error('Error en PUT /asignaturas/:id:', err);
        res.status(500).json({
            success: false,
            error: 'Error al actualizar asignatura',
            details: err.message
        });
    }
});

/**
 * DELETE /api/profesores/asignaturas/:id
 * Eliminar asignatura
 */
app.delete('/api/profesores/asignaturas/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const query = `
            DELETE FROM academico.asignaturas
            WHERE id = $1
            RETURNING id
        `;
        const result = await pool.query(query, [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Asignatura no encontrada'
            });
        }
        
        res.status(200).json({
            success: true,
            message: 'Asignatura eliminada exitosamente'
        });
    } catch (err) {
        console.error('Error en DELETE /asignaturas/:id:', err);
        res.status(500).json({
            success: false,
            error: 'Error al eliminar asignatura',
            details: err.message
        });
    }
});

/**
 * PUT /api/profesores/asignaturas/:asigId/alumnos/:alumId/calificar
 * Calificar a un alumno en una asignatura
 */
app.put('/api/profesores/asignaturas/:asigId/alumnos/:alumId/calificar', async (req, res) => {
    try {
        const { asigId, alumId } = req.params;
        const { nota } = req.body;
        
        if (nota === undefined || nota === null) {
            return res.status(400).json({
                success: false,
                error: 'Campo requerido: nota'
            });
        }
        
        const query = `
            UPDATE academico.inscripciones
            SET nota = $1
            WHERE asignatura_id = $2 AND alumno_id = $3
            RETURNING *
        `;
        const result = await pool.query(query, [nota, asigId, alumId]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Inscripción no encontrada'
            });
        }
        
        res.status(200).json({
            success: true,
            message: 'Alumno calificado exitosamente',
            data: result.rows[0]
        });
    } catch (err) {
        console.error('Error al calificar alumno:', err);
        res.status(500).json({
            success: false,
            error: 'Error al calificar alumno',
            details: err.message
        });
    }
});

// ============================================================================
// INICIO DEL SERVIDOR
// ============================================================================

const PORT = process.env.PORT || 3001;
const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`🎓 Módulo Profesores escuchando en puerto ${PORT}`);
    console.log(`📚 BD: ${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 5432}/${process.env.DB_NAME || 'academico'}`);
    console.log(`🕐 Iniciado: ${new Date().toISOString()}`);
});

// Manejo de errores de conexión a BD
pool.on('error', (err) => {
    console.error('Error no capturado en pool de conexiones:', err);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM recibido. Cerrando servidor...');
    server.close(() => {
        pool.end();
        process.exit(0);
    });
});

module.exports = app;
