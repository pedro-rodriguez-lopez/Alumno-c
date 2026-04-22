# Módulo Profesores - Guía Alumno C

## 📋 Descripción General

**Alumno C** es responsable del **módulo de Profesores**, que permite:
- ✅ Gestión completa de asignaturas (CRUD)
- ✅ Consulta de estudiantes inscritos en cada asignatura
- ✅ Calificación de alumnos
- ✅ Almacenamiento en PostgreSQL
- ✅ Balanceo de carga entre 2 instancias EC2

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────┐
│ Load Balancer (10.0.1.11 - Personal)                │
│ Nginx reverse proxy a /profesores                   │
└──────────────┬──────────────────────────────────────┘
               │
        ┌──────┴──────┐
        ↓             ↓
    10.1.1.10    10.1.1.11
    (UFV Web 1)  (UFV Web 2)
    Nginx + Node.js profesores.js (puerto 3001)
        │             │
        └──────┬──────┘
               ↓
    ┌──────────────────────┐
    │ Base de Datos        │
    │ (10.0.1.10)          │
    │ PostgreSQL DB        │
    │ academico / backend  │
    │ (Alumno B)           │
    └──────────────────────┘
```

---

## 📁 Estructura de Archivos

```
ufv-infra/
├── ufv-app/
│   ├── node/
│   │   ├── profesores.js         ✅ Backend (API REST)
│   │   └── package.json          ✅ Dependencias Node.js
│   ├── nginx/
│   │   └── AlexUFV_nginx.conf    ✅ Config reverse proxy
│   └── public/
│       ├── index.html            ✅ Portal principal
│       ├── css/
│       │   └── style.css         Estilos
│       └── js/
│           └── profesores.js     ✅ Frontend (interactivo)
│
├── ansible/
│   ├── roles/
│   │   └── profesores_setup/
│   │       ├── tasks/
│   │       │   └── main.yml      ✅ Tareas de despliegue
│   │       └── templates/
│   │           └── profesores.service.j2  ✅ Servicio systemd
│   └── playbooks/
│       └── deploy_profesores_alumno_c.yml ✅ Playbook principal
│
├── cloudformation/                         ✅ Lo hace Alumno A
└── scripts/
    └── setup-all-jobs.sh                   ✅ Lo hace Alumno A
```

---

## 🔧 Instalación Manual (Prueba)

### 1. Conectar a Web Server 1 (UFV)

```bash
ssh -i ~/.ssh/aws_ufv.pem ec2-user@<IP_PUBLICA_WEB1>

# Actualizaciones
sudo yum update -y
sudo yum install -y nodejs npm git

# Crear directorio
sudo mkdir -p /opt/profesores
cd /opt/profesores

# Descargar código
git clone https://github.com/tu-usuario/ufv-infra.git
cp ufv-infra/ufv-app/node/profesores.js .
cp ufv-infra/ufv-app/node/package.json .

# Instalar dependencias
npm install

# Iniciar servidor
export DB_HOST=10.0.1.10
export DB_USER=backend
export DB_PASSWORD=ContraseñaSegura123
export DB_NAME=academico

node profesores.js
```

### 2. Verificar que funciona

```bash
# En otra terminal
curl http://localhost:3001/api/profesores/health
# Respuesta: {"success":true,"message":"Módulo Profesores operativo"}

# Listar asignaturas
curl http://localhost:3001/api/profesores/asignaturas
```

---

## 🚀 Despliegue con Ansible

### Ejecutar el playbook

```bash
cd /usr/local/ufv/ufv-infra

# Desplegar en TODOS los web servers
ansible-playbook ansible/playbooks/deploy_profesores_alumno_c.yml -v

# O desplegar solo en web1
ansible-playbook ansible/playbooks/deploy_profesores_alumno_c.yml \
  --limit 10.1.1.10 -v

# Con variables personalizadas
ansible-playbook ansible/playbooks/deploy_profesores_alumno_c.yml \
  -e "db_host=10.0.1.10" \
  -e "db_password=MiContraseña" -v
```

### Verificar despliegue

```bash
# Ver estado del servicio
ansible linux_ufv -m shell -a "systemctl status profesores"

# Ver logs
ansible linux_ufv -m shell -a "journalctl -u profesores -n 20"

# Test de API
ansible linux_ufv -m uri -a "url=http://localhost:3001/api/profesores/health"
```

---

## 📊 API Endpoints

### Base URL
```
http://<IP_WEB_SERVER>:3001/api/profesores
```

### Endpoints Disponibles

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/health` | Health check del servicio |
| GET | `/asignaturas` | Listar todas las asignaturas |
| GET | `/asignaturas/:id` | Obtener detalles de asignatura |
| GET | `/asignaturas/:id/inscritos` | Listar alumnos inscritos |
| POST | `/asignaturas` | Crear nueva asignatura |
| PUT | `/asignaturas/:id` | Actualizar asignatura |
| DELETE | `/asignaturas/:id` | Eliminar asignatura |
| PUT | `/asignaturas/:id/alumnos/:id/calificar` | Calificar alumno |

### Ejemplos de uso

#### Listar asignaturas
```bash
curl -X GET http://localhost:3001/api/profesores/asignaturas \
  -H "Content-Type: application/json"

# Respuesta
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nombre": "Sistemas Operativos",
      "descripcion": "Conceptos fundamentales de SO",
      "creditos": 6,
      "fecha_creacion": "2026-04-22T10:00:00.000Z"
    }
  ],
  "count": 1
}
```

#### Crear asignatura
```bash
curl -X POST http://localhost:3001/api/profesores/asignaturas \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "DevOps",
    "descripcion": "Automatización e infraestructura",
    "creditos": 6
  }'
```

#### Ver alumnos de una asignatura
```bash
curl -X GET http://localhost:3001/api/profesores/asignaturas/1/inscritos \
  -H "Content-Type: application/json"
```

#### Calificar alumno
```bash
curl -X PUT http://localhost:3001/api/profesores/asignaturas/1/alumnos/5/calificar \
  -H "Content-Type: application/json" \
  -d '{"nota": 9.5}'
```

---

## 🗄️ Base de Datos

### Tablas Utilizadas

#### academico.asignaturas
```sql
CREATE TABLE academico.asignaturas (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  creditos INT NOT NULL,
  fecha_creacion TIMESTAMP DEFAULT NOW()
);
```

#### academico.inscripciones
```sql
CREATE TABLE academico.inscripciones (
  id SERIAL PRIMARY KEY,
  alumno_id INT NOT NULL,
  asignatura_id INT NOT NULL,
  nota DECIMAL(5,2),
  FOREIGN KEY (alumno_id) REFERENCES academico.alumnos(id),
  FOREIGN KEY (asignatura_id) REFERENCES academico.asignaturas(id)
);
```

#### academico.alumnos (existente, hecha por Alumno B)
```sql
CREATE TABLE academico.alumnos (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE,
  fecha_registro TIMESTAMP DEFAULT NOW()
);
```

**IMPORTANTE**: Las tablas las crea el **Alumno B** en el Database Server.
Tu rol solo instala el backend Node.js que LEE estos datos.

---

## 🔐 Variables de Entorno

El servicio usa estas variables (configuradas en `profesores.service`):

```bash
NODE_ENV=production
PORT=3001
DB_HOST=10.0.1.10           # IP del servidor BD (Alumno B)
DB_PORT=5432
DB_USER=backend             # Usuario BD
DB_PASSWORD=ContraseñaSegura123
DB_NAME=academico           # Nombre de la BD
AWS_REGION=eu-south-2
```

---

## 🐛 Troubleshooting

### Error: "connect ECONNREFUSED 10.0.1.10:5432"

**Problema**: No hay conectividad a la BD

**Soluciones**:
```bash
# 1. Verificar que BD está corriendo (Alumno B)
ansible linux_personal -m shell -a "sudo systemctl status postgresql"

# 2. Verificar conexión de red
ping 10.0.1.10
telnet 10.0.1.10 5432

# 3. Verificar Security Group permite puerto 5432
aws ec2 describe-security-groups --profile AlexPersonal

# 4. Verificar credenciales de BD
psql -h 10.0.1.10 -U backend -d academico -c "SELECT VERSION();"
```

### Error: "listen EADDRINUSE :::3001"

**Problema**: Puerto 3001 ya está en uso

**Solución**:
```bash
# Matar proceso anterior
sudo lsof -i :3001
sudo kill -9 <PID>

# Reiniciar servicio
sudo systemctl restart profesores
```

### Nginx muestra 502 Bad Gateway

**Problema**: Node.js no está respondiendo

**Soluciones**:
```bash
# 1. Verificar estado del servicio
sudo systemctl status profesores

# 2. Ver logs
sudo journalctl -u profesores -n 50 -f

# 3. Test de conectividad
curl http://localhost:3001/api/profesores/health

# 4. Reiniciar
sudo systemctl restart profesores
sudo systemctl restart nginx
```

---

## 📝 Tareas de Alumno C

### ✅ Responsabilidades

1. **Instalación y Configuración**
   - [ ] Instalar Node.js y npm en 2 web servers (10.1.1.10, 10.1.1.11)
   - [ ] Copiar código profesores.js
   - [ ] Copiar package.json
   - [ ] Instalar dependencias (npm install)

2. **Backend Node.js**
   - [ ] Crear los 6 endpoints API (GET, POST, PUT, DELETE)
   - [ ] Conexión a PostgreSQL
   - [ ] Manejo de errores
   - [ ] Logs y debugging

3. **Frontend**
   - [ ] Crear interfaz web para gestión de asignaturas
   - [ ] Integración con API REST
   - [ ] Formularios CRUD
   - [ ] Estilos CSS

4. **Nginx**
   - [ ] Configurar reverse proxy en /profesores
   - [ ] Balanceo de carga entre 2 web servers
   - [ ] Upstreams y locations
   - [ ] Health checks

5. **Automatización Ansible**
   - [ ] Crear rol `profesores_setup`
   - [ ] Crear playbook de despliegue
   - [ ] Pruebas end-to-end

6. **Documentación**
   - [ ] README con instrucciones de despliegue
   - [ ] Diagrama de arquitectura
   - [ ] Ejemplos de API
   - [ ] Troubleshooting guide

---

## 🔗 Dependencias Externas

El Alumno C DEPENDE de:

| Componente | Responsable | Estado |
|------------|------------|--------|
| CloudFormation Stack (VPC, EC2) | Alumno A | ✅ Previo |
| Base de Datos PostgreSQL | Alumno B | ✅ Previo |
| Load Balancer Nginx | Alumno A/C | Coordinado |
| Security Groups | Alumno A | ✅ Previo |

---

## 📞 Contacto y Coordinación

- **BD (Alumno B)**: Debe tener acceso a `academico` con usuario `backend`
- **Load Balancer (Alumno A)**: Debe permitir tráfico a puerto 3001
- **Infrastructure (Alumno A)**: VPC Peering debe estar funcional

---

## 📚 Referencias

- [Express.js Documentation](https://expressjs.com/)
- [PostgreSQL Node.js Driver](https://node-postgres.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Ansible Documentation](https://docs.ansible.com/)

---

**Versión**: 1.0  
**Autor**: Alumno C  
**Fecha**: Abril 2026  
**Práctica**: Integración de Sistemas en AWS - UFV
