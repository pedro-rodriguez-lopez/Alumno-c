#!/usr/bin/env pwsh
# Script simple para desplegar profesores.js

# Mostrar menú
function Show-Menu {
    Write-Host "`n╔════════════════════════════════════════╗"
    Write-Host "║  DESPLIEGUE PROFESORES - ALUMNO C    ║"
    Write-Host "╚════════════════════════════════════════╝`n"
    
    Write-Host "1. Ver información de AWS"
    Write-Host "2. Desplegar CloudFormation"
    Write-Host "3. Ejecutar Ansible playbook"
    Write-Host "4. Ver logs de despliegue"
    Write-Host "5. Conectarse a web server (SSH)"
    Write-Host "6. Hacer request a API"
    Write-Host "7. Salir`n"
}

# Opción 1: Información de AWS
function Get-AWSInfo {
    Write-Host "`n📊 Obteniendo información de AWS...`n" -ForegroundColor Cyan
    
    # Account ID
    Write-Host "Account ID:" -ForegroundColor Yellow
    aws sts get-caller-identity --query 'Account' --output text
    
    # VPCs
    Write-Host "`nVPCs disponibles:" -ForegroundColor Yellow
    aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault]" --output table
    
    # Instancias
    Write-Host "`nInstancias EC2:" -ForegroundColor Yellow
    aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" `
      --query "Reservations[].Instances[].[InstanceId,PrivateIpAddress,PublicIpAddress,VpcId]" `
      --output table
    
    Write-Host "✓ Información completada`n" -ForegroundColor Green
}

# Opción 2: Desplegar CloudFormation
function Deploy-CloudFormation {
    Write-Host "`n🚀 Despliegue de CloudFormation`n" -ForegroundColor Cyan
    
    $VpcId = Read-Host "Ingresa tu VPC ID (default: vpc-0aeee302bbe9c49b8)"
    if (-not $VpcId) { $VpcId = "vpc-0aeee302bbe9c49b8" }
    
    $StackName = Read-Host "Ingresa nombre del stack (default: ufv-profesores-alumno-c)"
    if (-not $StackName) { $StackName = "ufv-profesores-alumno-c" }
    
    $Region = "eu-south-2"
    $AccountId = (aws sts get-caller-identity --query 'Account' --output text)
    
    Write-Host "`nProceediendo con:" -ForegroundColor Yellow
    Write-Host "  VPC ID: $VpcId"
    Write-Host "  Stack: $StackName"
    Write-Host "  Account: $AccountId`n"
    
    $confirm = Read-Host "¿Continuar? (s/n)"
    if ($confirm -ne "s") {
        Write-Host "Cancelado" -ForegroundColor Red
        return
    }
    
    Write-Host "`nValidando template..." -ForegroundColor Cyan
    try {
        aws cloudformation validate-template --template-body "file://cloudformation/stack-personal.yaml" | Out-Null
        Write-Host "✓ Template válido" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Error en template: $_" -ForegroundColor Red
        return
    }
    
    Write-Host "`nCreando stack..." -ForegroundColor Cyan
    try {
        aws cloudformation create-stack `
            --stack-name $StackName `
            --template-body "file://cloudformation/stack-personal.yaml" `
            --parameters `
                ParameterKey=VpcId,ParameterValue=$VpcId `
                ParameterKey=AccountId,ParameterValue=$AccountId `
            --region $Region
        
        Write-Host "✓ Stack creado. Esperando..." -ForegroundColor Green
        
        # Esperar
        $completed = $false
        $attempts = 0
        while (-not $completed -and $attempts -lt 60) {
            Start-Sleep -Seconds 5
            $status = aws cloudformation describe-stacks --stack-name $StackName --query "Stacks[0].StackStatus" --output text
            Write-Host "  Estado: $status" -ForegroundColor Yellow
            
            if ($status -like "*COMPLETE*") {
                $completed = $true
                Write-Host "`n✓ Stack completado exitosamente" -ForegroundColor Green
                
                # Mostrar outputs
                Write-Host "`nOutputs:" -ForegroundColor Yellow
                aws cloudformation describe-stacks --stack-name $StackName --query "Stacks[0].Outputs[]" --output table
            }
            elseif ($status -like "*FAILED*" -or $status -like "*ROLLBACK*") {
                Write-Host "`n✗ Stack falló: $status" -ForegroundColor Red
                return
            }
            $attempts++
        }
    }
    catch {
        Write-Host "✗ Error: $_" -ForegroundColor Red
    }
}

# Opción 3: Ejecutar Ansible
function Deploy-Ansible {
    Write-Host "`n🤖 Despliegue con Ansible`n" -ForegroundColor Cyan
    
    if (-not (Test-Path "ansible/inventory/hosts.ini")) {
        Write-Host "⚠️  Archivo de inventario no encontrado: ansible/inventory/hosts.ini" -ForegroundColor Yellow
        Write-Host "Necesitas crear este archivo con tus web servers`n" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Ejecutando playbook..." -ForegroundColor Cyan
    try {
        ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/deploy_profesores_alumno_c.yml -v
        Write-Host "✓ Playbook completado" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Error ejecutando playbook: $_" -ForegroundColor Red
    }
}

# Opción 4: Ver logs
function Show-Logs {
    Write-Host "`n📋 Logs disponibles:`n" -ForegroundColor Cyan
    
    if (Test-Path "deployment.log") {
        Write-Host "deployment.log:" -ForegroundColor Yellow
        Get-Content "deployment.log" -Tail 20
    }
    else {
        Write-Host "No hay logs aún" -ForegroundColor Yellow
    }
}

# Opción 5: SSH a servidor
function Connect-WebServer {
    Write-Host "`n🔌 Conectar a Web Server\n" -ForegroundColor Cyan
    
    $KeyPath = Read-Host "Ruta a tu llave privada (.pem)"
    $ServerIP = Read-Host "IP pública del servidor"
    
    if (-not (Test-Path $KeyPath)) {
        Write-Host "✗ Llave no encontrada: $KeyPath" -ForegroundColor Red
        return
    }
    
    Write-Host "`nConectando a $ServerIP..." -ForegroundColor Yellow
    ssh -i $KeyPath ec2-user@$ServerIP
}

# Opción 6: Test API
function Test-API {
    Write-Host "`n🧪 Testing API\n" -ForegroundColor Cyan
    
    $BaseUrl = Read-Host "URL base (default: http://localhost:3001)"
    if (-not $BaseUrl) { $BaseUrl = "http://localhost:3001" }
    
    Write-Host "`nTest 1: Health check" -ForegroundColor Yellow
    try {
        $result = Invoke-WebRequest -Uri "$BaseUrl/api/profesores/health" -ErrorAction Stop
        Write-Host "✓ Status: $($result.StatusCode)" -ForegroundColor Green
        Write-Host $result.Content
    }
    catch {
        Write-Host "✗ Error: $_" -ForegroundColor Red
    }
    
    Write-Host "`nTest 2: Listar asignaturas" -ForegroundColor Yellow
    try {
        $result = Invoke-WebRequest -Uri "$BaseUrl/api/profesores/asignaturas" -ErrorAction Stop
        Write-Host "✓ Status: $($result.StatusCode)" -ForegroundColor Green
        Write-Host $result.Content
    }
    catch {
        Write-Host "✗ Error: $_" -ForegroundColor Red
    }
}

# Main loop
$running = $true
while ($running) {
    Show-Menu
    $choice = Read-Host "Elige una opción"
    
    switch ($choice) {
        "1" { Get-AWSInfo }
        "2" { Deploy-CloudFormation }
        "3" { Deploy-Ansible }
        "4" { Show-Logs }
        "5" { Connect-WebServer }
        "6" { Test-API }
        "7" { 
            Write-Host "`n¡Hasta luego! 👋`n" -ForegroundColor Green
            $running = $false 
        }
        default { Write-Host "`n✗ Opción no válida`n" -ForegroundColor Red }
    }
}
