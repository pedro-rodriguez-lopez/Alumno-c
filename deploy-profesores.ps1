#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script automatizado de despliegue para Alumno C (Profesores)
    AWS + Ansible Deployment

.DESCRIPTION
    Automatiza el proceso de despliegue del módulo de Profesores en AWS
    - Obtiene información de la cuenta AWS
    - Valida CloudFormation templates
    - Despliega stack
    - Ejecuta playbook Ansible
    - Realiza verificaciones

.EXAMPLE
    .\deploy-profesores.ps1 -VpcId vpc-0aeee302bbe9c49b8 -Action Deploy

.PARAMETER Action
    Acción a realizar: Info, Validate, Deploy, Verify, Cleanup

.PARAMETER VpcId
    VPC ID donde desplegar
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Info", "Validate", "Deploy", "Verify", "Cleanup")]
    [string]$Action = "Info",

    [Parameter(Mandatory = $false)]
    [string]$VpcId = "vpc-0aeee302bbe9c49b8",

    [Parameter(Mandatory = $false)]
    [string]$StackName = "ufv-profesores-alumno-c",

    [Parameter(Mandatory = $false)]
    [string]$Region = "eu-south-2",

    [Parameter(Mandatory = $false)]
    [string]$InventoryPath = "ansible/inventory/hosts.ini"
)

# ============================================================================
# VARIABLES GLOBALES
# ============================================================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path $ScriptDir "deployment.log"

# Colores
$ColorSuccess = "Green"
$ColorError = "Red"
$ColorWarning = "Yellow"
$ColorInfo = "Cyan"

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $LogFile -Value $logMessage
    
    switch ($Level) {
        "SUCCESS" { Write-Host $Message -ForegroundColor $ColorSuccess }
        "ERROR" { Write-Host $Message -ForegroundColor $ColorError }
        "WARNING" { Write-Host $Message -ForegroundColor $ColorWarning }
        "INFO" { Write-Host $Message -ForegroundColor $ColorInfo }
        default { Write-Host $Message }
    }
}

function Test-AWSCredentials {
    Write-Log "Verificando credenciales AWS..." "INFO"
    
    try {
        $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
        Write-Log "✓ AWS Account: $($identity.Account)" "SUCCESS"
        Write-Log "✓ ARN: $($identity.Arn)" "SUCCESS"
        return $identity
    }
    catch {
        Write-Log "✗ Error de credenciales: $_" "ERROR"
        throw
    }
}

function Get-AWSInfo {
    Write-Log "Obteniendo información de AWS..." "INFO"
    
    # VPCs
    Write-Log "--- VPCs ---" "INFO"
    $vpcs = aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock]" --output table
    Write-Host $vpcs
    
    # Instancias
    Write-Log "--- Instancias EC2 ---" "INFO"
    $instances = aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" `
        --query "Reservations[].Instances[].[InstanceId,PrivateIpAddress,PublicIpAddress,VpcId]" `
        --output table
    Write-Host $instances
    
    # Security Groups
    Write-Log "--- Security Groups ---" "INFO"
    $sgs = aws ec2 describe-security-groups `
        --query "SecurityGroups[].[GroupId,GroupName,VpcId]" `
        --output table
    Write-Host $sgs
    
    Write-Log "Información completada" "SUCCESS"
}

function Test-CloudFormationTemplate {
    param([string]$TemplatePath)
    
    Write-Log "Validando CloudFormation template: $TemplatePath" "INFO"
    
    if (-not (Test-Path $TemplatePath)) {
        Write-Log "✗ Template no encontrado: $TemplatePath" "ERROR"
        throw "Template file not found"
    }
    
    try {
        $validation = aws cloudformation validate-template `
            --template-body "file://$TemplatePath" `
            --output json | ConvertFrom-Json
        
        Write-Log "✓ Template válido" "SUCCESS"
        Write-Log "Descripción: $($validation.Description)" "INFO"
        Write-Log "Parámetros: $($validation.Parameters.Length)" "INFO"
        return $validation
    }
    catch {
        Write-Log "✗ Error en template: $_" "ERROR"
        throw
    }
}

function New-CloudFormationStack {
    param(
        [string]$StackName,
        [string]$TemplatePath,
        [string]$VpcId,
        [string]$Region
    )
    
    Write-Log "Creando CloudFormation Stack: $StackName" "INFO"
    
    $accountId = (aws sts get-caller-identity --output json | ConvertFrom-Json).Account
    
    try {
        $stackId = aws cloudformation create-stack `
            --stack-name $StackName `
            --template-body "file://$TemplatePath" `
            --parameters `
                "ParameterKey=VpcId,ParameterValue=$VpcId" `
                "ParameterKey=AccountId,ParameterValue=$accountId" `
            --region $Region `
            --output json | ConvertFrom-Json | Select-Object -ExpandProperty StackId
        
        Write-Log "✓ Stack creado: $stackId" "SUCCESS"
        return $stackId
    }
    catch {
        Write-Log "✗ Error creando stack: $_" "ERROR"
        throw
    }
}

function Wait-CloudFormationStack {
    param(
        [string]$StackName,
        [int]$MaxWaitSeconds = 1800
    )
    
    Write-Log "Esperando a que se complete el stack: $StackName" "INFO"
    
    $startTime = Get-Date
    $completed = $false
    
    while (-not $completed) {
        try {
            $stack = aws cloudformation describe-stacks `
                --stack-name $StackName `
                --query "Stacks[0]" `
                --output json | ConvertFrom-Json
            
            $status = $stack.StackStatus
            Write-Log "Estado: $status" "INFO"
            
            if ($status -like "*CREATE_COMPLETE*" -or $status -like "*UPDATE_COMPLETE*") {
                Write-Log "✓ Stack completado exitosamente" "SUCCESS"
                $completed = $true
            }
            elseif ($status -like "*FAILED*" -or $status -like "*ROLLBACK*") {
                Write-Log "✗ Stack falló: $status" "ERROR"
                throw "Stack creation failed"
            }
            else {
                Start-Sleep -Seconds 30
            }
            
            $elapsed = (Get-Date) - $startTime
            if ($elapsed.TotalSeconds -gt $MaxWaitSeconds) {
                throw "Stack creation timeout"
            }
        }
        catch {
            Write-Log "✗ Error esperando stack: $_" "ERROR"
            throw
        }
    }
    
    return $stack
}

function Get-CloudFormationOutputs {
    param([string]$StackName)
    
    Write-Log "Obteniendo outputs del stack: $StackName" "INFO"
    
    try {
        $outputs = aws cloudformation describe-stacks `
            --stack-name $StackName `
            --query "Stacks[0].Outputs[]" `
            --output table
        
        Write-Host $outputs
        Write-Log "✓ Outputs obtenidos" "SUCCESS"
    }
    catch {
        Write-Log "✗ Error obteniendo outputs: $_" "ERROR"
    }
}

function Invoke-AnsiblePlaybook {
    param(
        [string]$PlaybookPath,
        [string]$InventoryPath,
        [bool]$Verbose = $true
    )
    
    Write-Log "Ejecutando Ansible playbook: $PlaybookPath" "INFO"
    
    if (-not (Test-Path $PlaybookPath)) {
        Write-Log "✗ Playbook no encontrado: $PlaybookPath" "ERROR"
        throw "Playbook not found"
    }
    
    if (-not (Test-Path $InventoryPath)) {
        Write-Log "✗ Inventory no encontrado: $InventoryPath" "ERROR"
        throw "Inventory not found"
    }
    
    try {
        $ansibleCmd = "ansible-playbook"
        if ($Verbose) {
            $ansibleCmd += " -v"
        }
        $ansibleCmd += " -i $InventoryPath $PlaybookPath"
        
        Write-Log "Ejecutando: $ansibleCmd" "INFO"
        Invoke-Expression $ansibleCmd
        
        Write-Log "✓ Ansible playbook completado" "SUCCESS"
    }
    catch {
        Write-Log "✗ Error ejecutando playbook: $_" "ERROR"
        throw
    }
}

function Verify-Deployment {
    param([string]$VpcId)
    
    Write-Log "Verificando despliegue..." "INFO"
    
    # Verificar instancias
    Write-Log "--- Instancias en VPC ---" "INFO"
    $instances = aws ec2 describe-instances `
        --filters "Name=vpc-id,Values=$VpcId" "Name=instance-state-name,Values=running" `
        --query "Reservations[].Instances[].[InstanceId,PrivateIpAddress,PublicIpAddress]" `
        --output table
    Write-Host $instances
    
    # Verificar security groups
    Write-Log "--- Security Groups ---" "INFO"
    $sgs = aws ec2 describe-security-groups `
        --filters "Name=vpc-id,Values=$VpcId" `
        --query "SecurityGroups[].[GroupId,GroupName,IpPermissions[0].FromPort]" `
        --output table
    Write-Host $sgs
    
    Write-Log "✓ Verificación completada" "SUCCESS"
}

function Cleanup-Resources {
    param([string]$StackName)
    
    Write-Log "Eliminando recursos (Stack: $StackName)..." "WARNING"
    
    $confirm = Read-Host "¿Estás seguro? Escribe 'sí' para confirmar"
    
    if ($confirm -ne "sí") {
        Write-Log "Operación cancelada" "INFO"
        return
    }
    
    try {
        aws cloudformation delete-stack --stack-name $StackName
        Write-Log "✓ Stack marcado para eliminación" "SUCCESS"
        Write-Log "Nota: Espera a que CloudFormation termine de eliminar todos los recursos" "WARNING"
    }
    catch {
        Write-Log "✗ Error eliminando stack: $_" "ERROR"
        throw
    }
}

# ============================================================================
# MAIN
# ============================================================================

Write-Log "====== DESPLIEGUE PROFESORES - ALUMNO C ======" "INFO"
Write-Log "Acción: $Action" "INFO"
Write-Log "VPC ID: $VpcId" "INFO"
Write-Log "Stack Name: $StackName" "INFO"
Write-Log "Region: $Region" "INFO"

try {
    # Verificar credenciales
    $identity = Test-AWSCredentials
    
    switch ($Action) {
        "Info" {
            Get-AWSInfo
        }
        
        "Validate" {
            $templatePath = "cloudformation/stack-personal.yaml"
            Test-CloudFormationTemplate -TemplatePath $templatePath
        }
        
        "Deploy" {
            $templatePath = "cloudformation/stack-personal.yaml"
            
            # Validar
            Test-CloudFormationTemplate -TemplatePath $templatePath
            
            # Crear stack
            $stackId = New-CloudFormationStack `
                -StackName $StackName `
                -TemplatePath $templatePath `
                -VpcId $VpcId `
                -Region $Region
            
            # Esperar
            $stack = Wait-CloudFormationStack -StackName $StackName
            
            # Outputs
            Get-CloudFormationOutputs -StackName $StackName
            
            Write-Log "====== DESPLIEGUE COMPLETADO ======" "SUCCESS"
        }
        
        "Verify" {
            Verify-Deployment -VpcId $VpcId
        }
        
        "Cleanup" {
            Cleanup-Resources -StackName $StackName
        }
    }
    
    Write-Log "Logs guardados en: $LogFile" "INFO"
}
catch {
    Write-Log "✗ Error fatal: $_" "ERROR"
    exit 1
}
