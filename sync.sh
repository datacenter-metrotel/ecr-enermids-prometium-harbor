#!/bin/bash

# Verificar si el comando aws está instalado
if ! command -v aws &> /dev/null; then
  echo "El comando 'aws' no está instalado. Instalándolo ahora..."
  sudo yum install -y awscli
  if [ $? -ne 0 ]; then
    echo "Error: No se pudo instalar el comando 'aws'."
    exit 1
  fi
fi

# Credenciales de AWS
AWS_ACCESS_KEY_ID="AKIMiArean"
AWS_SECRET_ACCESS_KEY="arena2222222222"
AWS_REGION="us-east-2"
ECR_REGISTRY="204251639772.dkr.ecr.us-east-2.amazonaws.com"

# Credenciales de Docker para metro-registry
METRO_REGISTRY="metro-registry.metrotel.com.ar"
METRO_USERNAME="usuarioharbor-metro"
METRO_PASSWORD="arenaypolvo"

# Lista de imágenes
IMAGES=(
  "administrador-backend:RELEASE_v11"
  "administrador-frontend:RELEASE_v9"
  "backend-api-gateway:RELEASE_v5.5"
  "backend-event-consumer-business-spatial:RELEASE_v4"
  "backend-server-config:RELEASE_v5.1"
  "backend-server-eureka:RELEASE_v4.1"
  "backend-server-oauth2:RELEASE_v10.2"
  "backend-service-cromo-red:RELEASE_v2406.5"
  "backend-service-fo-tracking:RELEASE_v2406.3"
  "backend-service-profile:RELEASE_v6.3"
  "backend-service-version:RELEASE_v4.1"
  "cromo-blocks:RELEASE_v2407_r6"
  "cromo-business:RELEASE_v2407_r6"
  "cromo-consolidator:RELEASE_v2407_r6"
  "cromo-env-epe:RELEASE_v2407_r2"
  "cromo-env-metrotel:RELEASE_v2407_r6"
  "cromo-fastar:RELEASE_2408"
  "cromo-fo:RELEASE_v2406.5"
  "cromo-layers:RELEASE_v1.4"
  "cromo-migration:RELEASE_v2407_r6"
  "cromo-monitor:RELEASE_v1.1"
  "cromo-reader:RELEASE_v2407_r6"
  "cromo-tools:RELEASE_v2407_r6"
  "cromo-trx-out:RELEASE_v2407_r6"
  "cromo-updater:RELEASE_v2407_r6"
  "cromo-web:RELEASE_v2407_r6"
  "cross-reserve-service:RELEASE_v2401"
  "database-service:RELEASE_v1"
  "frontend-fo-tracking:RELEASE_v2406.2"
  "graphic-optical-path:RELEASE_v2406.2"
  "interfaz-last-gasp:RELEASE_v2.2"
  "kafka:6.2.0"
  "metrotel-interface-batch-update-service-status:RELEASE_v2309"
  "metrotel-interface-endpoint-apply-work-order:RELEASE_v2309"
  "metrotel-interface-endpoint-check-cost-center:RELEASE_v2309"
  "metrotel-interface-endpoint-check-service-status:RELEASE_v2309"
  "metrotel-interface-endpoint-get-worker-team:RELEASE_v2309"
  "notas-backend:RELEASE_v2.5"
  "notas-frontend:RELEASE_v3.1"
  "project-module-backend:RELEASE_v2406.3"
  "project-module-frontend:RELEASE_v2406.1"
  "visualization-panel-front:RELEASE_v2310"
  "zookeeper:6.2.0"
)

# Configurar credenciales de AWS temporalmente en el entorno
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$AWS_REGION

# Realizar Docker login en el ECR
LOGIN_PASSWORD=$(aws ecr get-login-password --region $AWS_REGION)
if [ $? -ne 0 ]; then
  echo "Error: No se pudo obtener el token de autenticación de ECR."
  exit 1
fi

docker login --username AWS --password $LOGIN_PASSWORD $ECR_REGISTRY
if [ $? -ne 0 ]; then
  echo "Error: Falló el inicio de sesión en Docker para el registro $ECR_REGISTRY."
  exit 1
fi

# Realizar Docker login en el metro-registry
echo "$METRO_PASSWORD" | docker login $METRO_REGISTRY --username $METRO_USERNAME --password-stdin
if [ $? -ne 0 ]; then
  echo "Error: Falló el inicio de sesión en Docker para el registro $METRO_REGISTRY."
  exit 1
fi

# Descargar y reenviar cada imagen del listado
for IMAGE in "${IMAGES[@]}"; do
  FULL_IMAGE_PATH="$ECR_REGISTRY/$IMAGE"
  echo "Descargando la imagen: $FULL_IMAGE_PATH"
  docker pull $FULL_IMAGE_PATH
  if [ $? -ne 0 ]; then
    echo "Error: Falló la descarga de la imagen $FULL_IMAGE_PATH."
    continue
  fi

  TARGET_IMAGE_PATH="$METRO_REGISTRY/cromo-prometium/$IMAGE"
  echo "Reetiquetando y enviando la imagen: $TARGET_IMAGE_PATH"
  docker tag $FULL_IMAGE_PATH $TARGET_IMAGE_PATH
  docker push $TARGET_IMAGE_PATH
  if [ $? -ne 0 ]; then
    echo "Error: Falló el envío de la imagen $TARGET_IMAGE_PATH."
  fi
done

echo "Todas las imágenes han sido procesadas."
