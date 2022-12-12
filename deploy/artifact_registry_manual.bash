export GCP_REGION=us-east1
export GCP_PROJECT=prefect-community
export GCP_AR_REPO=prefect

gcloud auth configure-docker "$GCP_REGION"-docker.pkg.dev
export AGENT_IMG="$GCP_REGION"-docker.pkg.dev/"$GCP_PROJECT"/"$GCP_AR_REPO"/agent:latest
docker build -t $AGENT_IMG -f Dockerfile.agent .
docker push $AGENT_IMG

export FLOWS_IMG=us-east1-docker.pkg.dev/"$GCP_PROJECT"/"$GCP_AR_REPO"/flows:latest
docker build -t $FLOWS_IMG .
docker push $FLOWS_IMG
echo success