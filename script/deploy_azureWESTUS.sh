#!/bin/sh

ENV=$1
echo "Deploying webservice to $ENV"

NAME=airflowtestwestus-$ENV
ACR_NAME=airflowtestwestus$ENV
echo "Deploying webservice to Azure for $NAME"
REGION=us-west
ECR_URL="$ACR_NAME.azurecr.io"

COMMIT_HASH=`date +%Y%m%d%H%M%S`
echo "COMMIT_HASH: $COMMIT_HASH"

# Build the Docker image
docker build --rm -t $NAME:$COMMIT_HASH .

az acr login --name $ACR_NAME

# tag and push image using COMMIT_HASH
docker tag $NAME:$COMMIT_HASH $ECR_URL/$NAME:$COMMIT_HASH
docker push $ECR_URL/$NAME:$COMMIT_HASH

# Deploy to AKS cluster
az aks get-credentials --resource-group Test --name airflow-test-WESTUS

# Add debugging information
echo "Current context:"
kubectl config current-context

echo "View cluster information:"
kubectl cluster-info

# Update the AKS deployment to use the newly tagged image
kubectl set image deployment/airflow-webserver airflow-webserver=$ECR_URL/$NAME:$COMMIT_HASH
kubectl set image deployment/airflow-scheduler airflow-scheduler=$ECR_URL/$NAME:$COMMIT_HASH
kubectl set image deployment/airflow-worker airflow-worker=$ECR_URL/$NAME:$COMMIT_HASH
#kubectl set image deployment/airflow-flower airflow-flower=$ECR_URL/$NAME:$COMMIT_HASH

# Monitor the deployment status
kubectl rollout status deployment airflow-webserver
kubectl rollout status deployment airflow-scheduler
kubectl rollout status deployment airflow-worker
#kubectl rollout status deployment airflow-flower
