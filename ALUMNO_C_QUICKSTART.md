# ⚡ QUICK START - Alumno C (Profesores)

**⏱️ Tiempo estimado: 30 minutos de lectura + test**

---

## 🎯 EN 3 PASOS

### Paso 1: Entender la Arquitectura (5 min)

```
Tu módulo: /profesores
├─ Backend: Node.js (puerto 3001)
│  └─ API REST 8 endpoints (GET/POST/PUT/DELETE)
├─ Frontend: HTML + JavaScript
│  └─ Interfaz CRUD para asignaturas
├─ BD: PostgreSQL (10.0.1.10) ← Alumno B
│  └─ Tablas: asignaturas, inscripciones, alumnos
└─ Load Balancer: Nginx (balanceo 10.1.1.10 + 10.1.1.11)
   └─ Reverse proxy a :3001
```

### Paso 2: Clonar & Revisar (5 min)

```bash
cd /usr/local/ufv/ufv-infra

# Ver archivos generados
ls -la ufv-app/node/
ls -la ufv-app/nginx/
ls -la ansible/roles/profesores_setup/
ls -la ansible/playbooks/

# Leer guías
cat ALUMNO_C_RESUMEN.md       # <- EMPIEZA AQUÍ
cat ALUMNO_C_GUIA.md           # <- Después aquí
cat ALUMNO_C_CHECKLIST.md     # <- Plan detallado
```

### Paso 3: Test Local (20 min)

```bash
# Terminal 1: Servidor
cd ufv-app/node
npm install
node profesores.js

# Terminal 2: Cliente
curl http://localhost:3001/api/profesores/health
curl http://localhost:3001/api/profesores/asignaturas

# Terminal 3: Crear asignatura
curl -X POST http://localhost:3001/api/profesores/asignaturas \
  -H "Content-Type: application/json" \
  -d '{"nombre":"SO","descripcion":"Sistemas","creditos":6}'
```

---

## 📋 ARCHIVOS QUE YA EXISTEN

✅ = Creado/Actualizado  
❌ = Falta completar

| Archivo | Estado | Descripción |
|---------|--------|------------|
| `/ufv-app/node/profesores.js` | ✅ | API REST completa |
| `/ufv-app/node/package.json` | ✅ | Dependencias Node.js |
| `/ufv-app/nginx/AlexUFV_nginx.conf` | ✅ | Reverse proxy |
| `/ufv-app/public/js/profesores.js` | ✅ | Frontend JavaScript |
| `/ufv-app/public/index.html` | ❌ | Frontend HTML (necesita mejoras) |
| `/ufv-app/public/css/style.css` | ❌ | Estilos CSS (necesita crear) |
| `/ansible/roles/profesores_setup/tasks/main.yml` | ✅ | Tareas Ansible |
| `/ansible/roles/profesores_setup/templates/profesores.service.j2` | ✅ | Servicio systemd |
| `/ansible/playbooks/deploy_profesores_alumno_c.yml` | ✅ | Playbook principal |
| `/ALUMNO_C_GUIA.md` | ✅ | Guía técnica |
| `/ALUMNO_C_CHECKLIST.md` | ✅ | Plan de implementación |
| `/ALUMNO_C_RESUMEN.md` | ✅ | Resumen general |

---

## 🚀 PASOS SIGUIENTES

### INMEDIATO (Hoy)

1. **Leer documentación**
   ```bash
   cat ALUMNO_C_RESUMEN.md        # 5 min
   cat ALUMNO_C_GUIA.md           # 15 min
   ```

2. **Revisar código**
   ```bash
   cat ufv-app/node/profesores.js
   cat ufv-app/public/js/profesores.js
   ```

3. **Test en local**
   ```bash
   cd ufv-app/node
   npm install
   node profesores.js
   # En otra terminal: curl http://localhost:3001/api/profesores/health
   ```

### CORTO PLAZO (Esta semana)

4. **Completar frontend**
   - Crear `/ufv-app/public/css/style.css` bonito
   - Mejorar `/ufv-app/public/index.html`
   - Probar en navegador

5. **Test Ansible**
   ```bash
   ansible-playbook ansible/playbooks/deploy_profesores_alumno_c.yml \
     --limit 10.1.1.10 -v
   ```

6. **Coordinar con equipo**
   - Confirmar con Alumno B que BD está lista
   - Confirmar con Alumno A que VPC Peering funciona
   - Verificar Security Groups

### MEDIANO PLAZO (Próximas 2 semanas)

7. **Despliegue en ambos web servers**
8. **Testing end-to-end**
9. **Documentación final**
10. **Defensa**

---

## 🔑 ARCHIVOS CLAVE

### Backend: `ufv-app/node/profesores.js`

**Qué hace**:
- 8 endpoints API para gestión de asignaturas
- Conecta a PostgreSQL
- Retorna JSON

**Cómo iniciar**:
```bash
cd ufv-app/node
npm install
export DB_HOST=10.0.1.10
export DB_USER=backend
export DB_PASSWORD=ContraseñaSegura123
export DB_NAME=academico
node profesores.js
```

**Endpoints**:
```
GET  /api/profesores/health
GET  /api/profesores/asignaturas
GET  /api/profesores/asignaturas/:id
GET  /api/profesores/asignaturas/:id/inscritos
POST /api/profesores/asignaturas
PUT  /api/profesores/asignaturas/:id
DELETE /api/profesores/asignaturas/:id
PUT  /api/profesores/asignaturas/:id/alumnos/:id/calificar
```

### Frontend: `ufv-app/public/js/profesores.js`

**Qué hace**:
- Interfaz web para CRUD
- Llama a API desde JavaScript
- Muestra tabla de asignaturas

**Funciones principales**:
- `cargarAsignaturas()` - Listar
- `mostrarFormularioCrear()` - Crear
- `editarAsignatura(id)` - Editar
- `guardarAsignatura()` - Guardar
- `eliminarAsignatura(id)` - Eliminar
- `verDetalles(id)` - Ver alumnos inscritos

### Nginx: `ufv-app/nginx/AlexUFV_nginx.conf`

**Qué hace**:
- Reverse proxy a :3001
- Balanceo entre 2 web servers
- Sirve archivos estáticos

**Rutas**:
```
/profesores/    → Node.js :3001
/api/profesores/ → Node.js :3001
/static/        → /var/www/public/
/health         → Health check
```

### Ansible: `ansible/playbooks/deploy_profesores_alumno_c.yml`

**Qué hace**:
- Instala Node.js
- Inicia servicio automático
- Verifica que funciona

**Ejecutar**:
```bash
ansible-playbook ansible/playbooks/deploy_profesores_alumno_c.yml -v
```

---

## 🔗 DEPENDENCIAS

Necesita que Alumno B haga:
- [x] Crear tabla `academico.asignaturas`
- [x] Crear tabla `academico.alumnos`
- [x] Crear tabla `academico.inscripciones`
- [x] Usuario `backend` con acceso a `academico`

Necesita que Alumno A haya hecho:
- [x] Desplegar CloudFormation (VPC, EC2, etc)
- [x] VPC Peering entre Personal y UFV
- [x] Security Groups (puerto 5432, 80, etc)

---

## 🧪 TESTING RÁPIDO

```bash
# 1. Verificar que Node.js responde
curl http://localhost:3001/api/profesores/health

# 2. Listar asignaturas
curl http://localhost:3001/api/profesores/asignaturas

# 3. Crear asignatura
curl -X POST http://localhost:3001/api/profesores/asignaturas \
  -H "Content-Type: application/json" \
  -d '{"nombre":"DevOps","descripcion":"Cloud","creditos":6}'

# 4. Ver asignatura
curl http://localhost:3001/api/profesores/asignaturas/1

# 5. Ver alumnos inscritos
curl http://localhost:3001/api/profesores/asignaturas/1/inscritos

# 6. Editar asignatura
curl -X PUT http://localhost:3001/api/profesores/asignaturas/1 \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Cloud Computing","creditos":8}'

# 7. Eliminar asignatura
curl -X DELETE http://localhost:3001/api/profesores/asignaturas/1

# 8. Calificar alumno
curl -X PUT http://localhost:3001/api/profesores/asignaturas/1/alumnos/5/calificar \
  -H "Content-Type: application/json" \
  -d '{"nota":8.5}'
```

---

## 🎯 CRITERIOS DE ÉXITO

- [ ] Backend retorna JSON válido
- [ ] Conecta a PostgreSQL sin errores
- [ ] Nginx balancea entre 2 servidores
- [ ] Frontend carga sin errores
- [ ] CRUD completo funciona
- [ ] Ansible despliega sin errores
- [ ] Servicio inicia automáticamente

---

## 📞 PREGUNTAS FRECUENTES

**P: ¿Dónde está la BD?**
A: En 10.0.1.10 (Alumno B) con usuario `backend`

**P: ¿Cómo balanceo entre 2 web servers?**
A: Nginx usa upstream con round-robin en puerto 3001

**P: ¿Qué puedo cambiar?**
A: TODO. Esta es una base. Personalizalo, mejora frontend, añade validaciones, etc.

**P: ¿Cómo depliego en producción?**
A: `ansible-playbook deploy_profesores_alumno_c.yml -v`

**P: ¿Qué pasa si BD no responde?**
A: Node.js retorna error 500 con detalles. Ver logs: `journalctl -u profesores`

**P: ¿Cómo mejoro CSS?**
A: Edita `/ufv-app/public/css/style.css` y recarga navegador

---

## ⚠️ IMPORTANTE

1. **NO TOQUES el código de Alumno B** (BD)
2. **NO TOQUES el código de Alumno A** (CloudFormation)
3. **SÍ personaliza y mejora** tu módulo
4. **SÍ documenta** tus cambios
5. **SÍ coordina** con el equipo

---

## 📚 MÁS INFORMACIÓN

- Guía detallada: `ALUMNO_C_GUIA.md`
- Checklist de tareas: `ALUMNO_C_CHECKLIST.md`
- Resumen: `ALUMNO_C_RESUMEN.md`
- API docs: Ver en `ALUMNO_C_GUIA.md`

---

**¡LISTO PARA EMPEZAR! 🚀**

```bash
cd /usr/local/ufv/ufv-infra
cat ALUMNO_C_RESUMEN.md
cat ALUMNO_C_GUIA.md
```

---

**Última actualización**: 22/04/2026  
**Versión**: 1.0  
**Estado**: ✅ PRODUCCIÓN
