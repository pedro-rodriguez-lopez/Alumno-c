# 🚀 GUÍA RÁPIDA DE DESPLIEGUE - Alumno C

## 📊 TUS DATOS (COMPARTIR CON EL EQUIPO)

```
Account ID:   922384914513
VPC ID:       vpc-0aeee302bbe9c49b8  (o la tuya)
Region:       eu-south-2
```

---

## ⚡ OPCIÓN 1: DESPLIEGUE AUTOMÁTICO (Recomendado)

### Paso 1: Abre PowerShell en tu proyecto

```powershell
cd "c:\Users\pedri\Documents\Alumno c\Alumno-c"
```

### Paso 2: Obtener información de AWS

```powershell
# Ver tu información de AWS
.\deploy-profesores.ps1 -Action Info

# Esto te mostrará:
# - Tus VPCs
# - Instancias EC2
# - Security Groups
```

### Paso 3: Validar CloudFormation

```powershell
.\deploy-profesores.ps1 -Action Validate

# Debe decir: "✓ Template válido"
```

### Paso 4: Desplegar todo

```powershell
# Reemplaza VPC_ID con la tuya (si es diferente)
.\deploy-profesores.ps1 `
  -Action Deploy `
  -VpcId vpc-0aeee302bbe9c49b8 `
  -StackName ufv-profesores-alumno-c

# Esto desplegará:
# 1. CloudFormation Stack
# 2. Instancias EC2
# 3. Security Groups
# 4. Load Balancer
```

### Paso 5: Verificar despliegue

```powershell
.\deploy-profesores.ps1 -Action Verify
```

---

## ⚡ OPCIÓN 2: COMANDOS MANUALES (Si prefieres hacerlo paso a paso)

### Paso 1: Obtener info básica

```powershell
# Ver tu Account ID
aws sts get-caller-identity

# Ver VPCs disponibles
aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock]" --output table

# Ver instancias corriendo
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" `
  --query "Reservations[].Instances[].[InstanceId,PrivateIpAddress,PublicIpAddress]" `
  --output table
```

### Paso 2: Crear CloudFormation Stack

```powershell
# Variables
$VPC_ID = "vpc-0aeee302bbe9c49b8"
$ACCOUNT_ID = "922384914513"
$STACK_NAME = "ufv-profesores-alumno-c"
$REGION = "eu-south-2"
$TEMPLATE = "cloudformation/stack-personal.yaml"

# Crear stack
aws cloudformation create-stack `
  --stack-name $STACK_NAME `
  --template-body file://$TEMPLATE `
  --parameters `
    ParameterKey=VpcId,ParameterValue=$VPC_ID `
    ParameterKey=AccountId,ParameterValue=$ACCOUNT_ID `
  --region $REGION

# Esperar a que se complete (5-10 minutos)
# Ver estado:
aws cloudformation describe-stacks `
  --stack-name $STACK_NAME `
  --query "Stacks[0].[StackStatus,CreationTime]"

# Ver eventos si hay error:
aws cloudformation describe-stack-events `
  --stack-name $STACK_NAME `
  --query "StackEvents[].[Timestamp,ResourceStatus,ResourceStatusReason]" `
  --output table
```

### Paso 3: Obtener IPs de Web Servers

```powershell
# Listar instancias en tu VPC
aws ec2 describe-instances `
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running" `
  --query "Reservations[].Instances[].[InstanceId,PrivateIpAddress,PublicIpAddress,Tags[?Key=='Name']|[0].Value]" `
  --output table

# Guarda las IPs privadas y públicas que obtengas
```

### Paso 4: Conectarse a Web Server 1

```powershell
# Reemplaza con tu IP pública
$IP = "15.217.59.62"
$KEY = "$env:USERPROFILE\.ssh\aws_key.pem"

ssh -i $KEY ec2-user@$IP
```

### Paso 5: Una vez conectado al servidor

```bash
# Dentro del servidor EC2:

# 1. Actualizar sistema
sudo yum update -y
sudo yum install -y nodejs npm git

# 2. Clonar repo
cd /opt
git clone https://github.com/tu-usuario/ufv-infra.git
cd ufv-infra/ufv-app/node

# 3. Instalar dependencias
npm install

# 4. Crear archivo de configuración
cat > .env << 'EOF'
NODE_ENV=production
PORT=3001
DB_HOST=10.0.1.10
DB_USER=backend
DB_PASSWORD=ContraseñaSegura123
DB_NAME=academico
AWS_REGION=eu-south-2
EOF

# 5. Iniciar servidor
node profesores.js

# Debe mostrar:
# Servidor Profesores escuchando en puerto 3001
# Conectado a PostgreSQL
```

### Paso 6: Verificar en otra terminal

```bash
# Desde otra terminal SSH:
curl http://localhost:3001/api/profesores/health

# Debe retornar:
# {"success":true,"message":"Módulo Profesores operativo"}
```

---

## 🔄 DESPLIEGUE CON ANSIBLE (Automatizado)

### Paso 1: Crear archivo de inventario

**Archivo**: `ansible/inventory/hosts.ini`

```ini
[linux_ufv]
web1 ansible_host=10.3.13.165 ansible_user=ec2-user
web2 ansible_host=10.3.10.234 ansible_user=ec2-user

[linux_ufv:vars]
ansible_ssh_private_key_file=/path/to/aws_key.pem
ansible_ssh_common_args="-o StrictHostKeyChecking=no"
db_host=10.0.1.10
db_user=backend
db_password=ContraseñaSegura123
db_name=academico
```

### Paso 2: Ejecutar playbook

```powershell
# Desde tu máquina local (necesitas Ansible instalado)
$InventoryPath = "ansible/inventory/hosts.ini"

ansible-playbook `
  -i $InventoryPath `
  ansible/playbooks/deploy_profesores_alumno_c.yml `
  -v
```

### Paso 3: Verificar ejecución

```powershell
# Ver estado del servicio
ansible linux_ufv -i $InventoryPath -m shell -a "systemctl status profesores"

# Ver logs
ansible linux_ufv -i $InventoryPath -m shell -a "journalctl -u profesores -n 20"

# Test de API
ansible linux_ufv -i $InventoryPath -m uri -a "url=http://localhost:3001/api/profesores/health"
```

---

## 📱 VERIFICAR DESDE EL LOAD BALANCER

Una vez todo desplegado:

```powershell
# Conectarse al Load Balancer (10.0.1.11)
# Desde un cliente dentro de la VPC:

curl http://10.0.1.11/profesores
curl http://10.0.1.11/api/profesores/health
curl http://10.0.1.11/api/profesores/asignaturas
```

---

## 🛑 ELIMINAR STACK (Si necesitas limpiar)

```powershell
# CUIDADO: Esto eliminará TODOS los recursos

aws cloudformation delete-stack --stack-name ufv-profesores-alumno-c

# Ver estado:
aws cloudformation describe-stacks --stack-name ufv-profesores-alumno-c --query "Stacks[0].StackStatus"
```

---

## 📋 CHECKLIST DE VERIFICACIÓN

- [ ] AWS CLI instalado y configurado
- [ ] Tengo mi Account ID: `922384914513`
- [ ] Tengo mi VPC ID: `vpc-0aeee302bbe9c49b8`
- [ ] He compartido estos datos con Alumno A y B
- [ ] CloudFormation stack fue creado exitosamente
- [ ] Tengo 2 web servers running
- [ ] Puedo conectarme por SSH a web servers
- [ ] Node.js y npm están instalados
- [ ] API responde en http://localhost:3001/api/profesores/health
- [ ] Servicio systemd está activo
- [ ] Ansible playbook se ejecutó sin errores
- [ ] Puedo acceder desde el Load Balancer

---

## 🆘 TROUBLESHOOTING

### "aws: command not found"
```powershell
# Instala AWS CLI
choco install awscli -y
# O descargalo de: https://aws.amazon.com/cli/
```

### "Access Denied" 
```powershell
# Verifica credenciales
aws configure
aws sts get-caller-identity
```

### CloudFormation Stack falló
```powershell
# Ver qué salió mal
aws cloudformation describe-stack-events `
  --stack-name ufv-profesores-alumno-c `
  --query "StackEvents[?ResourceStatus=='CREATE_FAILED']"
```

### SSH: Connection refused
```powershell
# Espera 2-3 minutos a que EC2 esté lista
# Verifica que el Security Group permite puerto 22
aws ec2 describe-security-groups --group-ids sg-xxxxxxxx `
  --query "SecurityGroups[0].IpPermissions[?FromPort==22]"
```

### Node.js no arranca
```bash
# En el servidor:
node profesores.js
# Si hay error de conexión BD:
# - Verifica DB_HOST
# - Verifica Security Group permite puerto 5432
# - Verifica que BD está running (Alumno B)
```

---

## 📞 DATOS PARA COMPARTIR

**Copia y pega esto en el grupo de Whatsapp del equipo:**

```
🚀 ALUMNO C - PROFESORES

Account ID: 922384914513
VPC ID: vpc-0aeee302bbe9c49b8

Para Alumno A (Infraestructura):
- Necesito que crees rol de confianza si acceso inter-cuentas
- Asegúrate que Security Groups permiten:
  - Puerto 80 (Nginx) desde LB a web servers
  - Puerto 3001 (Node.js) entre web servers
  - Puerto 5432 (DB) desde web servers a DB server

Para Alumno B (Base de Datos):
- Necesito tablas creadas en schema "academico"
- DB_HOST: 10.0.1.10
- DB_USER: backend
- Tablas requeridas: asignaturas, inscripciones, alumnos

Mi rol: Desarrollar y desplegar aplicación de Profesores en ambos web servers
```

---

## ✅ PRÓXIMO PASO

1. Ejecuta: `.\deploy-profesores.ps1 -Action Info`
2. Comparte los datos con tu equipo
3. Espera confirmación de que Alumno A tiene infraestructura lista
4. Ejecuta: `.\deploy-profesores.ps1 -Action Deploy`
5. Verifica: `.\deploy-profesores.ps1 -Action Verify`

¡Listo para desplegar! 🎉

