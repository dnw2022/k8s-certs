# Login to docker hub
echo "$DOCKER_PASSWORD" | docker login -u $DOCKER_ID --password-stdin

# Build and push image
docker build -t dnw2022/default-backend:latest -f ./default-backend/Dockerfile ./default-backend
docker push dnw2022/default-backend:latest

# Apply kubernetes files
kubectl apply -f k8s