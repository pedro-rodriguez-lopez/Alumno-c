# 📊 ESTADO ACTUAL - Alumno C (Profesores)

**Fecha**: 23 de Abril de 2026  
**Alumno**: C  
**Módulo**: Profesores (/profesores)  
**Estado**: 80% Completado - Falta implementación en AWS y testing

---

## ✅ LO QUE ESTÁ HECHO

### 1. Código Fuente - 100% COMPLETO
- ✅ Backend Node.js (`profesores.js`) - 380 líneas
  - 8 endpoints CRUD operacionales
  - Pool de conexiones PostgreSQL
  - Manejo de errores
  - Health check

- ✅ Frontend JavaScript (`public/js/profesores.js`) - 350 líneas
  - Funciones para listar/crear/editar/eliminar
  - AJAX calls a API
  - Validación de datos
  - Ver alumnos y calificar

- ✅ Estilos CSS (`public/css/style.css`) - 85 líneas
  - Responsive design
  - Tabla para asignaturas
  - Formulario integrado
  - Botones y mensajes

### 2. Configuración de Infraestructura - 100% COMPLETO
- ✅ Nginx reverse proxy (`nginx/AlexUFV_nginx.conf`)
  - 2 upstream (10.1.1.10:3001 + 10.1.1.11:3001)
  - Balanceo round-robin
  - Locations para /profesores y /api/profesores

- ✅ Ansible Playbook (`deploy_profesores_alumno_c.yml`)
  - Instalación de Node.js
  - Copiar archivos
  - Crear servicio systemd
  - Health checks

- ✅ package.json
  - Dependencias: express, pg, aws-sdk, cors

### 3. Documentación - 100% COMPLETO
- ✅ ALUMNO_C_QUICKSTART.md
- ✅ ALUMNO_C_GUIA.md (guía técnica)
- ✅ ALUMNO_C_CHECKLIST.md
- ✅ ALUMNO_C_RESUMEN.md

---

## ❌ LO QUE FALTA - SEGÚN RÚBRICA

### FASE 1: TESTING EN AWS (URGENTE)

#### 1.1 Conexión y Verificación Inicial
- [ ] Conectarse a web server 1 (10.1.1.10)
  ```bash
  ssh -i ~/.ssh/aws_key.pem ec2-user@<IP_PUBLICA>
  ```

- [ ] Conectarse a web server 2 (10.1.1.11)
  ```bash
  ssh -i ~/.ssh/aws_key.pem ec2-user@<IP_PUBLICA>
  ```

- [ ] Verificar que ambos tienen Node.js 16+ instalado
  ```bash
  node --version
  npm --version
  ```

#### 1.2 Desplegar Manualmente (Prueba)
En AMBOS web servers:

```bash
# 1. Clonar repositorio
cd /opt
git clone https://github.com/TU_USUARIO/ufv-infra.git

# 2. Ir a directorio profesores
cd ufv-infra/ufv-app/node

# 3. Instalar dependencias
npm install

# 4. Verificar que conecta a BD
export DB_HOST=10.0.1.10
export DB_USER=backend
export DB_PASSWORD=ContraseñaSegura123
export DB_NAME=academico
export NODE_ENV=production

# 5. Iniciar servidor
node profesores.js

# Debe mostrar:
# Servidor Profesores escuchando en puerto 3001
# Conectado a PostgreSQL en 10.0.1.10
```

#### 1.3 Verificar API (desde otra terminal)
```bash
# Health check
curl http://localhost:3001/api/profesores/health

# Debe retornar:
# {"success":true,"message":"Módulo Profesores operativo",...}

# Listar asignaturas
curl http://localhost:3001/api/profesores/asignaturas

# Crear asignatura (POST)
curl -X POST http://localhost:3001/api/profesores/asignaturas \
  -H "Content-Type: application/json" \
  -d '{"nombre":"DevOps","descripcion":"Infrastructure","creditos":6}'
```

### FASE 2: DESPLIEGUE CON ANSIBLE

#### 2.1 Ejecutar Playbook
```bash
cd /path/to/ufv-infra

# Desplegar en AMBOS web servers
ansible-playbook ansible/playbooks/deploy_profesores_alumno_c.yml -v

# Verificar que no hay errores
```

#### 2.2 Verificar Servicio Systemd
```bash
# En AMBOS web servers
sudo systemctl status profesores

# Debe estar ACTIVE (running)
sudo systemctl restart profesores
```

#### 2.3 Verificar Logs
```bash
# Ver últimos logs
sudo journalctl -u profesores -n 50 -f
```

### FASE 3: TESTING DEL BALANCEO DE CARGA

#### 3.1 Acceder desde Load Balancer
```bash
# Conectarse al Load Balancer
ssh -i key.pem ec2-user@LB_IP

# Probar acceso a /profesores
curl http://localhost/profesores

# Probar API a través del LB
curl http://localhost/api/profesores/health
curl http://localhost/api/profesores/asignaturas
```

#### 3.2 Verificar Redondeo Robin
Hacer varias peticiones y verificar que alterna entre:
- 10.1.1.10:3001 (log del primero)
- 10.1.1.11:3001 (log del segundo)

```bash
for i in {1..10}; do curl http://localhost/api/profesores/health; done

# Ver logs en ambos web servers para confirmar
ssh web1: journalctl -u profesores -n 5
ssh web2: journalctl -u profesores -n 5
```

### FASE 4: INTEGRACIÓN S3 (Si no está implementada)

#### 4.1 Verificar IAM Role
```bash
# En el web server:
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Debe retornar el nombre del role
```

#### 4.2 Implementar Upload a S3
En `profesores.js`, agregar endpoint:
```javascript
app.post('/api/profesores/documentos', async (req, res) => {
    const file = req.files.documento;
    const params = {
        Bucket: 'ufv-app-bucket',
        Key: `profesores/${file.name}`,
        Body: file.data
    };
    await s3.upload(params).promise();
    res.json({success: true});
});
```

### FASE 5: FRONTEND HTML ESPECÍFICO

#### 5.1 Crear página dedicada /profesores
**Archivo**: `ufv-app/public/profesores.html`

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <title>Panel de Profesores</title>
    <link rel="stylesheet" href="/static/css/style.css">
</head>
<body>
    <div class="container">
        <h1>👨‍🏫 Gestión de Asignaturas</h1>
        
        <div class="nav">
            <button onclick="cargarAsignaturas()">Listar</button>
            <button onclick="mostrarFormularioCrear()">Nueva</button>
            <button onclick="actualizarNodoInfo()">Nodo</button>
        </div>
        
        <!-- Sección de lista -->
        <div id="asignaturas-section">
            <table id="tabla-asignaturas">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nombre</th>
                        <th>Créditos</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody></tbody>
            </table>
        </div>
        
        <!-- Sección de formulario -->
        <div id="form-section" class="hidden">
            <h2>Formulario de Asignatura</h2>
            <form onsubmit="guardarAsignatura(event)">
                <input type="hidden" id="form-id">
                <input type="text" id="form-nombre" placeholder="Nombre" required>
                <textarea id="form-descripcion" placeholder="Descripción"></textarea>
                <input type="number" id="form-creditos" placeholder="Créditos" required>
                <button type="submit">Guardar</button>
                <button type="button" onclick="mostrarSeccion('asignaturas-section')">Cancelar</button>
            </form>
        </div>
        
        <div id="nodeInfo"></div>
    </div>
    
    <script src="/static/js/profesores.js"></script>
</body>
</html>
```

#### 5.2 Configurar Nginx para servir
En `nginx.conf`:
```nginx
location /profesores {
    alias /var/www/ufv-app/public/profesores.html;
}

location /static {
    alias /var/www/ufv-app/public;
}
```

### FASE 6: DOCUMENTACIÓN Y MEMORIA TÉCNICA

#### 6.1 Agregar a Memoria Técnica
- [ ] Diagrama de arquitectura
- [ ] Explicación de endpoints
- [ ] Screenshots del funcionamiento
- [ ] Logs de despliegue
- [ ] Evidencia de tests

#### 6.2 Checklist de Rúbrica
Según 6.2 "Web Servers (100%)":

- [ ] **Nginx operativo** (25%)
  - [ ] Reverse proxy funcionando
  - [ ] Health checks activos
  - [ ] Logs en /var/log/nginx

- [ ] **Acceso a BD** (25%)
  - [ ] Conexión a PostgreSQL exitosa
  - [ ] Queries SELECT/INSERT/UPDATE/DELETE funcionan
  - [ ] Pool de conexiones configurado

- [ ] **Uso de S3** (10%)
  - [ ] IAM Role asignado
  - [ ] Endpoints para subir/descargar
  - [ ] Archivos almacenados en S3

- [ ] **Frontend + Backend** (40%)
  - [ ] API REST con 8 endpoints
  - [ ] Frontend HTML+CSS+JS
  - [ ] CRUD completo
  - [ ] Manejo de errores

---

## 🚀 PLAN DE ACCIÓN INMEDIATO

### HOY (ANTES DE QUE TERMINE LA SEMANA)
1. [ ] Conectarse a web servers y verificar Node.js
2. [ ] Hacer clone del repositorio
3. [ ] Ejecutar `npm install`
4. [ ] Iniciar servicio manualmente y probar CRUD

### ESTA SEMANA
5. [ ] Ejecutar Ansible playbook
6. [ ] Verificar servicio systemd
7. [ ] Hacer testing del balanceo de carga

### LA PRÓXIMA SEMANA
8. [ ] Implementar S3 si falta
9. [ ] Crear página HTML dedicada
10. [ ] Documentar en Memoria Técnica

---

## 📞 DEPENDENCIAS CON OTROS ALUMNOS

- ✅ **Alumno A**: VPC, Security Groups, Load Balancer, CloudFormation
- ✅ **Alumno B**: PostgreSQL, base de datos, tablas
- ✅ **Tu turno**: Desplegar y verificar en AWS

---

## 💾 ARCHIVOS A REVISAR

1. `/ufv-app/node/profesores.js` - Verificar endpoints
2. `/ufv-app/public/js/profesores.js` - Verificar funciones
3. `/ansible/playbooks/deploy_profesores_alumno_c.yml` - Revisar automatización
4. `/ufv-app/nginx/AlexUFV_nginx.conf` - Verificar configuración

---

## 🎯 CRITERIOS DE ÉXITO

✅ API REST responde en ambos web servers
✅ CRUD funciona (crear, listar, editar, eliminar)
✅ Balanceo de carga alterna entre web1 y web2
✅ Conexión a PostgreSQL exitosa
✅ Archivos se guardan en S3
✅ Frontend es navegable y funcional
✅ Servicios inician automáticamente con systemd

---

**Nota**: Este documento se actualizará conforme avances. Mantén comunicación constante con Alumno A (infraestructura) y Alumno B (base de datos).
