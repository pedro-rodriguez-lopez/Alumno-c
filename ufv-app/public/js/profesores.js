/**
 * Módulo Profesores - JavaScript
 * Alumno C - Práctica AWS UFV
 * 
 * Funciones para:
 * - Cargar lista de asignaturas
 * - Crear/editar asignaturas
 * - Ver alumnos inscritos
 * - Calificar alumnos
 */

// ============================================================================
// CONSTANTES
// ============================================================================

const API_BASE = '/api/profesores';
const SECTIONS = {
    LISTA: 'asignaturas-section',
    FORM: 'form-section',
    DETALLE: 'detalle-section'
};

let asignaturaEditando = null;

// ============================================================================
// FUNCIONES AUXILIARES
// ============================================================================

/**
 * Realizar petición FETCH a la API
 */
async function fetchAPI(endpoint, options = {}) {
    const url = `${API_BASE}${endpoint}`;
    const config = {
        headers: {
            'Content-Type': 'application/json',
            ...options.headers
        },
        ...options
    };

    try {
        const response = await fetch(url, config);
        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || `Error ${response.status}`);
        }

        return data;
    } catch (error) {
        console.error('Error en API:', error);
        mostrarError(error.message);
        throw error;
    }
}

/**
 * Mostrar/ocultar secciones
 */
function mostrarSeccion(seccion) {
    Object.values(SECTIONS).forEach(s => {
        document.getElementById(s).classList.add('hidden');
    });
    document.getElementById(seccion).classList.remove('hidden');
}

/**
 * Mostrar mensaje de error
 */
function mostrarError(mensaje) {
    alert(`❌ Error: ${mensaje}`);
    console.error(mensaje);
}

/**
 * Mostrar mensaje de éxito
 */
function mostrarExito(mensaje) {
    alert(`✅ ${mensaje}`);
}

/**
 * Actualizar información del nodo
 */
async function actualizarNodoInfo() {
    try {
        const response = await fetch(`${API_BASE}/health`);
        const data = await response.json();
        document.getElementById('nodeInfo').textContent = 
            `Nodo: ${data.node || 'Desconocido'}`;
    } catch (error) {
        console.error('Error obteniendo info del nodo:', error);
    }
}

/**
 * Actualizar timestamp
 */
function actualizarTimestamp() {
    const now = new Date().toLocaleString('es-ES');
    document.getElementById('timestamp').textContent = now;
}

// ============================================================================
// FUNCIONES PRINCIPALES - CRUD
// ============================================================================

/**
 * Cargar lista de asignaturas
 */
async function cargarAsignaturas() {
    try {
        const data = await fetchAPI('/asignaturas');

        if (!data.data || data.data.length === 0) {
            document.getElementById('asignaturas-list').innerHTML = 
                '<p class="empty-state">No hay asignaturas registradas. Crea una nueva.</p>';
            mostrarSeccion(SECTIONS.LISTA);
            return;
        }

        let html = '<table class="table"><thead><tr><th>ID</th><th>Nombre</th><th>Descripción</th><th>Créditos</th><th>Acciones</th></tr></thead><tbody>';

        data.data.forEach(asig => {
            html += `
                <tr>
                    <td>${asig.id}</td>
                    <td>${asig.nombre}</td>
                    <td>${asig.descripcion || '-'}</td>
                    <td>${asig.creditos}</td>
                    <td>
                        <button onclick="verDetalles(${asig.id})" class="btn-small btn-info">👁️ Ver</button>
                        <button onclick="editarAsignatura(${asig.id})" class="btn-small btn-warning">✏️ Editar</button>
                        <button onclick="eliminarAsignatura(${asig.id})" class="btn-small btn-danger">🗑️ Eliminar</button>
                    </td>
                </tr>
            `;
        });

        html += '</tbody></table>';
        document.getElementById('asignaturas-list').innerHTML = html;
        mostrarSeccion(SECTIONS.LISTA);

    } catch (error) {
        console.error('Error cargando asignaturas:', error);
        document.getElementById('asignaturas-list').innerHTML = 
            '<p class="error">Error al cargar asignaturas</p>';
    }
}

/**
 * Mostrar formulario para crear asignatura
 */
function mostrarFormularioCrear() {
    asignaturaEditando = null;
    document.getElementById('form-title').textContent = 'Nueva Asignatura';
    document.getElementById('asignatura-form').reset();
    mostrarSeccion(SECTIONS.FORM);
}

/**
 * Editar asignatura existente
 */
async function editarAsignatura(id) {
    try {
        const data = await fetchAPI(`/asignaturas/${id}`);
        const asig = data.data;

        asignaturaEditando = id;
        document.getElementById('form-title').textContent = `Editar: ${asig.nombre}`;
        document.getElementById('nombre').value = asig.nombre;
        document.getElementById('descripcion').value = asig.descripcion || '';
        document.getElementById('creditos').value = asig.creditos;

        mostrarSeccion(SECTIONS.FORM);
    } catch (error) {
        console.error('Error editando asignatura:', error);
    }
}

/**
 * Guardar asignatura (crear o actualizar)
 */
async function guardarAsignatura(event) {
    event.preventDefault();

    const nombre = document.getElementById('nombre').value;
    const descripcion = document.getElementById('descripcion').value;
    const creditos = parseInt(document.getElementById('creditos').value);

    try {
        if (asignaturaEditando) {
            // Actualizar
            const response = await fetchAPI(`/asignaturas/${asignaturaEditando}`, {
                method: 'PUT',
                body: JSON.stringify({ nombre, descripcion, creditos })
            });
            mostrarExito('Asignatura actualizada correctamente');
        } else {
            // Crear
            const response = await fetchAPI('/asignaturas', {
                method: 'POST',
                body: JSON.stringify({ nombre, descripcion, creditos })
            });
            mostrarExito('Asignatura creada correctamente');
        }

        asignaturaEditando = null;
        cargarAsignaturas();
    } catch (error) {
        console.error('Error guardando asignatura:', error);
    }
}

/**
 * Eliminar asignatura
 */
async function eliminarAsignatura(id) {
    if (!confirm('¿Estás seguro de que quieres eliminar esta asignatura?')) {
        return;
    }

    try {
        await fetchAPI(`/asignaturas/${id}`, {
            method: 'DELETE'
        });
        mostrarExito('Asignatura eliminada correctamente');
        cargarAsignaturas();
    } catch (error) {
        console.error('Error eliminando asignatura:', error);
    }
}

/**
 * Ver detalles de asignatura (alumnos inscritos)
 */
async function verDetalles(id) {
    try {
        const asigData = await fetchAPI(`/asignaturas/${id}`);
        const estudiantesData = await fetchAPI(`/asignaturas/${id}/inscritos`);

        const asig = asigData.data;
        const estudiantes = estudiantesData.data;

        let html = `
            <div class="detalle-box">
                <h3>${asig.nombre}</h3>
                <p><strong>Descripción:</strong> ${asig.descripcion || 'N/A'}</p>
                <p><strong>Créditos:</strong> ${asig.creditos}</p>
                <p><strong>Fecha Creación:</strong> ${new Date(asig.fecha_creacion).toLocaleDateString()}</p>
            </div>

            <h3>Alumnos Inscritos (${estudiantes.length})</h3>
        `;

        if (estudiantes.length === 0) {
            html += '<p class="empty-state">No hay alumnos inscritos en esta asignatura.</p>';
        } else {
            html += '<table class="table"><thead><tr><th>ID Alumno</th><th>Nombre</th><th>Email</th><th>Nota</th><th>Acciones</th></tr></thead><tbody>';

            estudiantes.forEach(est => {
                html += `
                    <tr>
                        <td>${est.alumno_id}</td>
                        <td>${est.alumno_nombre}</td>
                        <td>${est.alumno_email}</td>
                        <td>${est.nota !== null ? est.nota : 'Sin calificar'}</td>
                        <td>
                            <button onclick="calificarAlumno(${id}, ${est.alumno_id})" class="btn-small btn-warning">
                                📝 Calificar
                            </button>
                        </td>
                    </tr>
                `;
            });

            html += '</tbody></table>';
        }

        document.getElementById('detalle-title').textContent = `Detalles: ${asig.nombre}`;
        document.getElementById('detalle-content').innerHTML = html;
        mostrarSeccion(SECTIONS.DETALLE);

    } catch (error) {
        console.error('Error viendo detalles:', error);
    }
}

/**
 * Calificar alumno
 */
async function calificarAlumno(asigId, alumId) {
    const nota = prompt('Ingresa la nota (0-10):');
    
    if (nota === null) return;

    const notaNum = parseFloat(nota);
    if (isNaN(notaNum) || notaNum < 0 || notaNum > 10) {
        mostrarError('La nota debe estar entre 0 y 10');
        return;
    }

    try {
        await fetchAPI(`/asignaturas/${asigId}/alumnos/${alumId}/calificar`, {
            method: 'PUT',
            body: JSON.stringify({ nota: notaNum })
        });
        mostrarExito('Alumno calificado correctamente');
        verDetalles(asigId); // Refrescar detalles
    } catch (error) {
        console.error('Error calificando alumno:', error);
    }
}

/**
 * Cancelar edición
 */
function cancelarEdicion() {
    asignaturaEditando = null;
    cargarAsignaturas();
}

/**
 * Volver al listado
 */
function volverListado() {
    cargarAsignaturas();
}

/**
 * Refrescar página
 */
function refrescar() {
    location.reload();
}
