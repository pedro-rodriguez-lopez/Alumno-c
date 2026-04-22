# 📋 Checklist de Implementación - Alumno C (Profesores)

## Estado: EN PREPARACIÓN ✅

Este documento es un checklist completo para que el Alumno C implemente el módulo de Profesores según la rúbrica.

---

## FASE 1: PREPARACIÓN (Semana 1)

### 1.1 Coordinación con el Equipo
- [ ] Confirmar que Alumno A ha desplegado CloudFormation
- [ ] Confirmar que Alumno B ha configurado PostgreSQL
- [ ] Confirmar IPs de web servers (10.1.1.10, 10.1.1.11)
- [ ] Confirmar acceso SSH a web servers
- [ ] Confirmar conectividad de red (VPC Peering funcionando)

### 1.2 Preparación del Código
- [ ] Clonar repositorio ufv-infra
- [ ] Revisar estructura de directorios
- [ ] Instalar dependencias locales (Node.js 16+, npm)
- [ ] Revisar documentación de la rúbrica
- [ ] Leer guía del Alumno C (ALUMNO_C_GUIA.md)

---

## FASE 2: BACKEND (Semana 2)

### 2.1 Implementar API REST (profesores.js)
- [ ] **GET /api/profesores/asignaturas** - Listar todas
  - [ ] Query a tabla `academico.asignaturas`
  - [ ] Retornar JSON con array de asignaturas
  - [ ] Incluir manejo de errores

- [ ] **GET /api/profesores/asignaturas/:id** - Obtener una
  - [ ] Validar que ID existe
  - [ ] Retornar detalles de asignatura
  - [ ] Código 404 si no existe

- [ ] **GET /api/profesores/asignaturas/:id/inscritos** - Alumnos
  - [ ] JOIN con tabla `inscripciones` y `alumnos`
  - [ ] Retornar lista con alumno_id, nombre, email, nota
  - [ ] Retornar count de inscritos

- [ ] **POST /api/profesores/asignaturas** - Crear
  - [ ] Validar campos requeridos (nombre, creditos)
  - [ ] Insertar en BD
  - [ ] Retornar 201 Created con datos

- [ ] **PUT /api/profesores/asignaturas/:id** - Actualizar
  - [ ] Validar que existe
  - [ ] Actualizar campos (COALESCE para opcionales)
  - [ ] Retornar datos actualizados

- [ ] **DELETE /api/profesores/asignaturas/:id** - Eliminar
  - [ ] Validar que existe
  - [ ] Eliminar de BD
  - [ ] Retornar 200 OK

- [ ] **PUT /api/profesores/asignaturas/:id/alumnos/:id/calificar**
  - [ ] Validar nota (0-10)
  - [ ] Actualizar nota en inscripciones
  - [ ] Retornar datos actualizados

### 2.2 Conexión a PostgreSQL
- [ ] Pool de conexiones configurado
- [ ] Variables de entorno (DB_HOST, DB_USER, DB_PASSWORD, DB_NAME)
- [ ] Manejo de errores de conexión
- [ ] Logs de conexión exitosa

### 2.3 Integración AWS S3
- [ ] IAM Role asignado a instancia EC2
- [ ] Configuración de cliente S3
- [ ] Endpoints preparados para subir/descargar archivos
- [ ] Manejo de errores de S3

### 2.4 Testing Local
- [ ] Instalar dependencias (npm install)
- [ ] Ejecutar en local: `node profesores.js`
- [ ] Test cada endpoint con curl/Postman
- [ ] Verificar health check: `GET /api/profesores/health`
- [ ] Verificar manejo de errores

---

## FASE 3: FRONTEND (Semana 2-3)

### 3.1 Interfaz Web (index.html)
- [ ] Crear página principal con:
  - [ ] Header con título "Panel de Profesores"
  - [ ] Navegación con 3 opciones (Asignaturas, Nueva, Refrescar)
  - [ ] Sección para listar asignaturas
  - [ ] Sección para formulario (oculta inicialmente)
  - [ ] Sección para detalles (oculta inicialmente)
  - [ ] Footer con info del nodo

### 3.2 Lógica JavaScript (profesores.js)
- [ ] Función `cargarAsignaturas()` - Listar en tabla
- [ ] Función `mostrarFormularioCrear()` - Mostrar formulario vacío
- [ ] Función `editarAsignatura(id)` - Prellenar formulario
- [ ] Función `guardarAsignatura(event)` - POST/PUT
- [ ] Función `eliminarAsignatura(id)` - DELETE con confirmación
- [ ] Función `verDetalles(id)` - Mostrar alumnos inscritos
- [ ] Función `calificarAlumno(id, id)` - Prompt para nota
- [ ] Función `fetchAPI()` - Abstracción de llamadas HTTP
- [ ] Función `mostrarError()` / `mostrarExito()` - Mensajes
- [ ] Función `actualizarNodoInfo()` - Mostrar nodo actual

### 3.3 Estilos CSS (style.css)
- [ ] Diseño responsive
- [ ] Tabla para listar asignaturas
- [ ] Formulario con campos alineados
- [ ] Botones con colores (primary, success, warning, danger)
- [ ] Espacios en blanco y padding adecuados
- [ ] Footer pegado al final
- [ ] Ocultar/mostrar secciones con .hidden

---

## FASE 4: NGINX & REVERSE PROXY (Semana 3)

### 4.1 Configuración Nginx (AlexUFV_nginx.conf)
- [ ] Definir upstream con 2 web servers (10.1.1.10:3001, 10.1.1.11:3001)
- [ ] Location `/profesores/` → proxy a upstream
- [ ] Location `/api/profesores/` → proxy a upstream
- [ ] Location `/static/` → servir archivos estáticos
- [ ] Location `/health` → health check
- [ ] Redirección `/` → `/profesores/`
- [ ] Denegar acceso a archivos sensibles (`.`, `~`)
- [ ] Gzip compression habilitado
- [ ] Keepalive connections
- [ ] Timeouts configurados (60s)
- [ ] Buffer sizes configurados

### 4.2 Testing Nginx
- [ ] `nginx -t` sin errores de sintaxis
- [ ] `systemctl restart nginx` exitoso
- [ ] `curl http://localhost/health` retorna 200
- [ ] `curl http://localhost/api/profesores/asignaturas` retorna JSON

---

## FASE 5: AUTOMATIZACIÓN ANSIBLE (Semana 3-4)

### 5.1 Rol Ansible (roles/profesores_setup/)

#### tasks/main.yml
- [ ] Actualizar cache de paquetes
- [ ] Instalar nodejs, npm, git
- [ ] Crear directorios (/opt/profesores, /var/log/profesores)
- [ ] Copiar profesores.js y package.json
- [ ] Ejecutar `npm install`
- [ ] Crear servicio systemd desde template
- [ ] Habilitar y iniciar servicio
- [ ] Health check (GET /health)
- [ ] Mostrar logs en caso de error

#### templates/profesores.service.j2
- [ ] Tipo: simple
- [ ] Usuario: root
- [ ] WorkingDirectory: /opt/profesores
- [ ] ExecStart: /usr/bin/node /opt/profesores/profesores.js
- [ ] Restart: always, RestartSec: 10
- [ ] Variables de entorno (DB_HOST, DB_USER, etc)
- [ ] StandardOutput/StandardError: journal

### 5.2 Playbook Principal (deploy_profesores_alumno_c.yml)
- [ ] Hosts: linux_ufv (web servers)
- [ ] Llamar al rol profesores_setup
- [ ] Pre-tasks: mostrar info del host
- [ ] Post-tasks: verificar servicio, health check
- [ ] Handlers: reload systemd, restart profesores
- [ ] Variables por defecto (db_host, db_user, etc)

### 5.3 Testing del Playbook
- [ ] Syntax check: `ansible-playbook --syntax-check`
- [ ] Ejecución en seco: `--check` (opcional)
- [ ] Ejecución real con `-v` para verbose
- [ ] Verificar que servicio está running
- [ ] Verificar que puerto 3001 responde
- [ ] Verificar logs sin errores

---

## FASE 6: INTEGRACIÓN END-TO-END (Semana 4)

### 6.1 Test de Funcionamiento Completo
- [ ] SSH a web server 1 (10.1.1.10)
- [ ] Verificar servicio profesores: `systemctl status profesores`
- [ ] Verificar puerto: `netstat -tlnp | grep 3001`
- [ ] Health check: `curl http://localhost:3001/api/profesores/health`
- [ ] Listar asignaturas: `curl http://localhost:3001/api/profesores/asignaturas`
- [ ] Crear asignatura: `curl -X POST ...`
- [ ] Editar asignatura: `curl -X PUT ...`
- [ ] Eliminar asignatura: `curl -X DELETE ...`
- [ ] Ver inscritos: `curl http://localhost:3001/api/profesores/asignaturas/1/inscritos`

### 6.2 Test desde Load Balancer (10.0.1.11)
- [ ] Desde web1 o web2 personal:
- [ ] `curl http://10.1.1.10/profesores/` - ¿Retorna HTML?
- [ ] `curl http://10.1.1.11/profesores/` - ¿Retorna HTML?
- [ ] Balanceo: refrescar múltiples veces, ¿varía el nodo?
- [ ] Acceder desde navegador: `http://<IP_PERSONAL>/profesores/`

### 6.3 Test de Redundancia
- [ ] Parar servicio en web1: `sudo systemctl stop profesores`
- [ ] ¿Nginx redirige a web2 automáticamente?
- [ ] Reiniciar web1: `sudo systemctl start profesores`
- [ ] ¿Vuelve a distribuir carga?

### 6.4 Test de BD
- [ ] ¿Inserta asignaturas en `academico.asignaturas`?
- [ ] ¿Lee inscripciones correctamente?
- [ ] ¿Calificaciones se guardan en BD?
- [ ] Verificar desde Alumno B: `SELECT * FROM academico.asignaturas;`

---

## FASE 7: DOCUMENTACIÓN (Semana 4)

### 7.1 Crear Documentación
- [ ] README.md con instrucciones
- [ ] Diagrama de arquitectura (en texto o imagen)
- [ ] API documentation completa
- [ ] Ejemplos de curl para cada endpoint
- [ ] Instrucciones de despliegue con Ansible
- [ ] Troubleshooting guide

### 7.2 Guía ALUMNO_C_GUIA.md ✅ (ya creada)
- [x] Descripción general del módulo
- [x] Arquitectura y diagrama
- [x] Estructura de archivos
- [x] Instalación manual
- [x] Despliegue con Ansible
- [x] API endpoints documentados
- [x] Ejemplos de curl
- [x] Schema de BD
- [x] Variables de entorno
- [x] Troubleshooting

### 7.3 Código Limpio
- [ ] Comentarios en código (profesores.js)
- [ ] Variables bien nombradas
- [ ] Manejo consistente de errores
- [ ] Logging adecuado

---

## FASE 8: DEFENSA (Semana 5)

### 8.1 Preparar Presentación
- [ ] Slides con arquitectura
- [ ] Demostración en vivo (crear/editar/eliminar asignaturas)
- [ ] Mostrar logs de Ansible
- [ ] Mostrar BD con datos
- [ ] Explicar decisiones técnicas

### 8.2 Prepararse para Preguntas
- [ ] ¿Por qué Node.js? (explain arquitectura)
- [ ] ¿Cómo funciona el balanceo? (upstream round-robin)
- [ ] ¿Qué pasa si falla una BD? (connection errors, retry)
- [ ] ¿Cómo se scalea? (agregar más upstreams)
- [ ] ¿Qué bases de datos usa? (asignaturas, inscripciones, alumnos)
- [ ] ¿Cómo integraste con S3? (IAM Role, boto3)
- [ ] Explicar cada endpoint
- [ ] Mostrar logs en directo

### 8.3 Conocimiento Integral (Alumno C debe entender TODO)
- [ ] Arquitectura completa del sistema
- [ ] Cómo funciona CloudFormation (Alumno A)
- [ ] Schema BD y relaciones (Alumno B)
- [ ] Módulos de otros alumnos (C, D, E)
- [ ] VPC Peering entre cuentas
- [ ] Security Groups y IAM
- [ ] DRP del equipo

---

## 📊 Criterios de Evaluación

### Por Rúbrica (20% Componentes Linux)

| Criterio | Peso | ¿Completado? |
|----------|------|------------|
| Nginx operativo | 25% | [ ] |
| Acceso a BD | 25% | [ ] |
| Uso de S3 | 10% | [ ] |
| Frontend + Backend | 40% | [ ] |

**Nota**: Todos los componentes deben estar al ≥50% para pasar.

---

## 🎯 Resumen Rápido

```bash
# INSTALACIÓN
npm install
node profesores.js

# TESTING
curl http://localhost:3001/api/profesores/health

# ANSIBLE
ansible-playbook deploy_profesores_alumno_c.yml -v

# VERIFICACIÓN FINAL
systemctl status profesores
curl http://localhost/profesores/asignaturas
```

---

## 📅 Timeline Sugerido

- **Semana 1**: Coordinación + Setup inicial
- **Semana 2**: Backend (API completa) + Test local
- **Semana 3**: Frontend + Nginx + Ansible
- **Semana 4**: Integration testing + Documentación
- **Semana 5**: Defensa

---

## ✅ ARCHIVOS GENERADOS

Todos estos archivos ya han sido creados/actualizados:

- [x] `/ufv-app/node/profesores.js` - Backend Node.js
- [x] `/ufv-app/node/package.json` - Dependencias
- [x] `/ufv-app/nginx/AlexUFV_nginx.conf` - Nginx config
- [x] `/ufv-app/public/js/profesores.js` - Frontend JS
- [x] `/ansible/roles/profesores_setup/tasks/main.yml` - Tareas Ansible
- [x] `/ansible/roles/profesores_setup/templates/profesores.service.j2` - Servicio systemd
- [x] `/ansible/playbooks/deploy_profesores_alumno_c.yml` - Playbook
- [x] `/ALUMNO_C_GUIA.md` - Guía completa
- [x] `/ALUMNO_C_CHECKLIST.md` - Este checklist

---

**¡Listo para implementar! 🚀**

Sigue este checklist paso a paso y tendrás el módulo de Profesores funcionando perfectamente.

**Última actualización**: Abril 22, 2026  
**Versión**: 1.0
