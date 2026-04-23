# 📋 MI INFORMACIÓN DE AWS - ALUMNO C

**Generado**: 23 de Abril de 2026
**Alumno**: Pedri (Alumno C - Profesores)
**Región**: eu-south-2

---

## ✅ DATOS CONFIRMADOS

### Account ID
```
922384914513
```

### VPC ID (PRINCIPAL)
```
vpc-0aeee302bbe9c49b8
```

**CIDR**: 10.3.0.0/16  
**Estado**: ACTIVE  

### Instancias EC2 Activas
```
Web Server 1: i-0b1f3e132619030bd (IP: 10.3.13.165)
Web Server 2: i-0f120f3611bc09c06 (IP: 10.3.10.234)
```

---

## 🔗 PARA COMPARTIR CON EL EQUIPO

### Alumno A (Infraestructura)
```
Account ID: 922384914513
VPC ID: vpc-0aeee302bbe9c49b8
CIDR: 10.3.0.0/16

Necesito que verifiques:
- Security Groups permiten tráfico entre componentes
- VPC Peering con otros alumnos (si es necesario)
- Load Balancer configurado correctamente
```

### Alumno B (Base de Datos)
```
Account ID del Alumno C: 922384914513
VPC ID de Alumno C: vpc-0aeee302bbe9c49b8

Mi aplicación (Node.js profesores.js) se conectará a:
- DB_HOST: [IP privada de tu DB server]
- DB_USER: backend
- DB_PASSWORD: [La que acordemos]
- DB_NAME: academico

Espero tablas:
- academico.asignaturas
- academico.inscripciones
- academico.alumnos
```

### Profesor / Evaluador
```
Alumno: C (Profesores)
Account ID: 922384914513
Stack Name: ufv-profesores-alumno-c
Módulo: /profesores (CRUD de asignaturas)

Para acceder:
- URL: http://<LOAD_BALANCER_IP>/profesores
- API: http://<LOAD_BALANCER_IP>/api/profesores/asignaturas
```

---

## 🚀 PRÓXIMAS ACCIONES

### INMEDIATO (Hoy)
- [ ] Compartir esta información con el equipo
- [ ] Ejecutar `.\deploy-profesores.ps1 -Action Info` para confirmar
- [ ] Esperar confirmación de Alumno A (infraestructura lista)

### ESTA SEMANA
- [ ] Ejecutar `.\deploy-profesores.ps1 -Action Deploy`
- [ ] Verificar CloudFormation Stack
- [ ] Desplegar aplicación en web servers

### LA PRÓXIMA SEMANA
- [ ] Testing de integración
- [ ] Documentar para memoria técnica
- [ ] Preparar para defensa

---

## 📝 COMANDOS DE REFERENCIA RÁPIDA

```powershell
# Ver información de AWS
aws sts get-caller-identity

# Ver VPCs
aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock]" --output table

# Ver instancias
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" `
  --query "Reservations[].Instances[].[InstanceId,PrivateIpAddress,PublicIpAddress]" `
  --output table

# Ver Security Groups
aws ec2 describe-security-groups --query "SecurityGroups[].[GroupId,GroupName]" --output table

# Ver Load Balancers
aws elbv2 describe-load-balancers --output table

# Ver subredes
aws ec2 describe-subnets --query "Subnets[].[SubnetId,CidrBlock,VpcId]" --output table
```

---

## ✨ ESTADO DE DESPLIEGUE

| Componente | Estado |
|-----------|--------|
| Credenciales AWS | ✅ Configuradas |
| Account ID | ✅ 922384914513 |
| VPC ID | ✅ vpc-0aeee302bbe9c49b8 |
| Código Backend | ✅ Listo |
| Código Frontend | ✅ Listo |
| CloudFormation | ⏳ Pendiente |
| Despliegue Ansible | ⏳ Pendiente |
| Testing en AWS | ⏳ Pendiente |

---

**Último Update**: 23 Abril 2026, 14:30

