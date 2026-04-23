# 🚀 INFORMACIÓN DE DESPLIEGUE - Alumno C

**Fecha**: 23 de Abril de 2026  
**Usuario**: pedri  
**Estado**: Listo para desplegar

---

## 📊 TUS DATOS DE AWS

### Account ID
```
922384914513
```
✅ **Compartir esto con**: Alumno A, Alumno B, Profesor

---

## 🌐 VPC INFORMATION

Tienes **3 VPCs de 10.0.0.0/16** configuradas. Aquí están:

| VPC ID | CIDR | Estado | Instancias |
|--------|------|--------|-----------|
| `vpc-0f7a1d9bcfdc1af1f` | 10.0.0.0/16 | ? | ? |
| `vpc-070721fbe8f394231` | 10.0.0.0/16 | ? | ? |
| `vpc-0aeee302bbe9c49b8` | 10.3.0.0/16 | ✅ ACTIVA | 2 instancias |

### VPC Activa Actual
```
vpc-0aeee302bbe9c49b8 (CIDR: 10.3.0.0/16)
```

### Instancias Running
```
i-0b1f3e132619030bd (10.3.13.165)
i-0f120f3611bc09c06 (10.3.10.234)
```

---

## ⚠️ PREGUNTAS PARA TI

**Necesitas responder lo siguiente para continuar:**

1. **¿Cuál es tu VPC de PRODUCCIÓN (la que usarás para la práctica)?**
   - [ ] `vpc-0f7a1d9bcfdc1af1f` (10.0.0.0/16)
   - [ ] `vpc-070721fbe8f394231` (10.0.0.0/16)
   - [ ] `vpc-0aeee302bbe9c49b8` (10.3.0.0/16)

2. **¿Ya has desplegado CloudFormation o es la primera vez?**
   - [ ] Ya está desplegado
   - [ ] Primera vez

3. **¿Tienes credenciales AWS CLI configuradas?**
   - [ ] Sí, con `aws configure`
   - [ ] No, necesito configurar

---

## 🔐 COMPARTIR CON TU EQUIPO

Copia esto y comparte con Alumno A y Alumno B:

```
=== INFORMACIÓN DEL EQUIPO ===
Alumno C (Profesores)
Account ID: 922384914513
VPC ID: [ESPECIFICAR CUÁL]
Region: eu-south-2

Para acceso entre cuentas:
- Alumno A: Crear rol de confianza en su cuenta
- Alumno B: Usar este Account ID para permiso VPC Peering
```

---

## 📋 PASOS PARA DESPLEGAR

### OPCIÓN A: Si ya tienes CloudFormation (Stack)

#### Paso 1: Verificar stack
```powershell
# Listar stacks disponibles
aws cloudformation list-stacks --query "StackSummaries[?StackStatus!='DELETE_COMPLETE'].{StackName:StackName,Status:StackStatus,CreationTime:CreationTime}" --output table

# Ver detalles de tu stack
aws cloudformation describe-stacks --stack-name tu-stack-name --output json
```

#### Paso 2: Obtener outputs del stack
```powershell
aws cloudformation describe-stacks --stack-name tu-stack-name --query "Stacks[0].Outputs[]" --output table
```

---

### OPCIÓN B: Desplegar desde cero

#### Paso 1: Validar template
```powershell
# Validar que el template es correcto
aws cloudformation validate-template --template-body file://cloudformation/stack-personal.yaml
```

#### Paso 2: Crear stack
```powershell
# Reemplazar VALORES según tu configuración
$VPC_ID = "vpc-0aeee302bbe9c49b8"  # Tu VPC
$ACCOUNT_ID = "922384914513"        # Tu Account ID
$REGION = "eu-south-2"

aws cloudformation create-stack `
  --stack-name ufv-profesores-alumno-c `
  --template-body file://cloudformation/stack-personal.yaml `
  --parameters `
    ParameterKey=VpcId,ParameterValue=$VPC_ID `
    ParameterKey=AccountId,ParameterValue=$ACCOUNT_ID `
  --region $REGION `
  --output json
```

#### Paso 3: Monitorear creación
```powershell
# Ver estado del stack
aws cloudformation describe-stacks `
  --stack-name ufv-profesores-alumno-c `
  --query "Stacks[0].[StackStatus,CreationTime]" `
  --output table

# Ver eventos (para debuggear errores)
aws cloudformation describe-stack-events `
  --stack-name ufv-profesores-alumno-c `
  --query "StackEvents[].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]" `
  --output table
```

#### Paso 4: Obtener outputs
```powershell
aws cloudformation describe-stacks `
  --stack-name ufv-profesores-alumno-c `
  --query "Stacks[0].Outputs[]" `
  --output table
```

---

## 🐳 DESPLEGAR APLICACIÓN (Profesores)

Una vez que CloudFormation esté UP:

### Paso 1: Obtener IPs de Web Servers
```powershell
# Listar instancias EC2
aws ec2 describe-instances `
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running" `
  --query "Reservations[].Instances[].[InstanceId,PrivateIpAddress,PublicIpAddress,Tags[?Key=='Name']|[0].Value]" `
  --output table
```

### Paso 2: Conectarse al web server (SSH)
```powershell
# Necesitas tu key pair y la IP pública
$WEB_SERVER_IP = "15.217.59.62"  # Tu IP pública
$KEY_PATH = "$env:USERPROFILE\.ssh\aws_key.pem"

# Conectarse
ssh -i $KEY_PATH ec2-user@$WEB_SERVER_IP
```

### Paso 3: Desplegar profesores.js
```bash
# Una vez conectado al servidor:

# 1. Actualizar e instalar dependencias
sudo yum update -y
sudo yum install -y nodejs npm git

# 2. Clonar repositorio
cd /opt
git clone https://github.com/tu-usuario/ufv-infra.git
cd ufv-infra

# 3. Instalar Node.js deps
cd ufv-app/node
npm install

# 4. Crear archivo .env
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
```

### Paso 4: Verificar con curl
```bash
# Test de conexión
curl http://localhost:3001/api/profesores/health

# Debe retornar:
# {"success":true,"message":"Módulo Profesores operativo",...}
```

---

## 🔄 DESPLEGAR CON ANSIBLE (AUTOMATIZADO)

Si tienes Ansible instalado:

### Paso 1: Configurar inventario
```ini
# archivo: inventory/hosts.ini
[linux_ufv]
web1 ansible_host=10.3.13.165 ansible_user=ec2-user
web2 ansible_host=10.3.10.234 ansible_user=ec2-user

[linux_ufv:vars]
ansible_ssh_private_key_file=/path/to/aws_key.pem
db_host=10.0.1.10
db_user=backend
db_password=ContraseñaSegura123
db_name=academico
```

### Paso 2: Ejecutar playbook
```powershell
$InventoryPath = "ansible/inventory/hosts.ini"

ansible-playbook `
  -i $InventoryPath `
  ansible/playbooks/deploy_profesores_alumno_c.yml `
  -v
```

### Paso 3: Verificar despliegue
```powershell
# Ver estado del servicio
ansible linux_ufv -i $InventoryPath -m shell -a "systemctl status profesores"

# Ver logs
ansible linux_ufv -i $InventoryPath -m shell -a "journalctl -u profesores -n 20"

# Test de API
ansible linux_ufv -i $InventoryPath -m uri -a "url=http://localhost:3001/api/profesores/health"
```

---

## 📦 COMANDOS ÚTILES

### Ver Security Groups
```powershell
aws ec2 describe-security-groups `
  --filters "Name=vpc-id,Values=$VPC_ID" `
  --query "SecurityGroups[].[GroupId,GroupName,IpPermissions[0].FromPort]" `
  --output table
```

### Ver subredes
```powershell
aws ec2 describe-subnets `
  --filters "Name=vpc-id,Values=$VPC_ID" `
  --query "Subnets[].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key=='Name']|[0].Value]" `
  --output table
```

### Ver Load Balancer
```powershell
aws elbv2 describe-load-balancers `
  --query "LoadBalancers[].{ARN:LoadBalancerArn,DNS:DNSName,VPC:VpcId}" `
  --output table
```

### Parar/Iniciar instancias
```powershell
# Parar
aws ec2 stop-instances --instance-ids i-0b1f3e132619030bd --output json

# Iniciar
aws ec2 start-instances --instance-ids i-0b1f3e132619030bd --output json
```

---

## 🔧 TROUBLESHOOTING

### Error: "No such file or directory"
```powershell
# Verifica que estás en el directorio correcto
Get-Location
cd c:\Users\pedri\Documents\Alumno c\Alumno-c\

# Listar archivos
Get-ChildItem -Recurse -Include "*.yaml", "*.yml"
```

### Error: "Access Denied" (Credenciales)
```powershell
# Verificar credenciales
aws sts get-caller-identity

# Reconfigurarse
aws configure
```

### Error: CloudFormation stack creation failed
```powershell
# Ver eventos de error
aws cloudformation describe-stack-events `
  --stack-name ufv-profesores-alumno-c `
  --query "StackEvents[?ResourceStatus=='CREATE_FAILED']" `
  --output json
```

---

## ✅ CHECKLIST PRE-DESPLIEGUE

- [ ] Tengo AWS CLI instalado (`aws --version`)
- [ ] Tengo credenciales configuradas (`aws sts get-caller-identity`)
- [ ] He identificado mi VPC ID correctamente
- [ ] He compartido Account ID con mi equipo
- [ ] Tengo copia de mi Key Pair (.pem)
- [ ] CloudFormation template está validado
- [ ] Tengo Node.js 16+ para testing local
- [ ] Tengo Ansible instalado (opcional)

---

## 🎯 SIGUIENTE PASO

**Responde las 3 preguntas al inicio de este documento y cuéntame:**
1. ¿Cuál es tu VPC de producción?
2. ¿Ya tiene CloudFormation desplegado o es primera vez?
3. ¿Necesitas ayuda con la configuración de Ansible?

Una vez que confirmes, ejecutaremos los comandos específicos para tu caso.

