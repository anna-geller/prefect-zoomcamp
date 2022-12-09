# install prefect
pip install prefect prefect-gcp

# sign up for Prefect Cloud + crete workspace + generate API key, enter those in GHA Secrets and in CLI:
prefect cloud login

# Create GCP account + project => here we use project named "prefect-community" - replace it with your project name


# __________________________________________________________________________________________________________
# download Google SDK: https://cloud.google.com/sdk/docs/install#linux
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-411.0.0-linux-x86_64.tar.gz

# macOS 64-bit (ARM64, Apple M1 silicon)
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-411.0.0-darwin-arm.tar.gz

# macOS 64-bit (x86_64)
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-411.0.0-darwin-x86_64.tar.gz

tar -xf google-cloud-cli- # tab: **yourfile.tar.gz

./google-cloud-sdk/install.sh # follow the wizard

gcloud beta run jobs list

# __________________________________________________________________________________________________________
# + authenticate from CLI: it will redirect to browser:
gcloud auth login

# set default project and region:
export CLOUDSDK_CORE_PROJECT="prefect-community"
export CLOUDSDK_COMPUTE_REGION=us-east1
gcloud config set project "prefect-community"
gcloud config set run/region us-east1

# enable required GCP services:
gcloud services enable iamcredentials.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable cloudscheduler.googleapis.com

# create service account named e.g. prefect:
gcloud iam service-accounts create prefect
export MEMBER="serviceAccount:prefect@prefect-community.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding prefect-community --member=$MEMBER --role="roles/run.admin"
gcloud projects add-iam-policy-binding prefect-community --member=$MEMBER --role="roles/artifactregistry.admin"
gcloud projects add-iam-policy-binding prefect-community --member=$MEMBER --role="roles/secretmanager.admin"
gcloud projects add-iam-policy-binding prefect-community --member=$MEMBER --role="roles/iam.serviceAccountUser"

# create JSON credentials file as follows, then copy-paste its content into your GHA Secret + Prefect GcpCredentials block:
gcloud iam service-accounts keys create prefect.json --iam-account=prefect@prefect-community.iam.gserviceaccount.com

# build and push the image to Google Artifact Registry
gcloud artifacts repositories create prefect --repository-format=docker --location=us-east1
gcloud auth configure-docker us-east1-docker.pkg.dev
export AGENT_IMG="us-east1-docker.pkg.dev/prefect-community/prefect/agent:latest"
docker build -t $AGENT_IMG -f Dockerfile.agent .
docker push $AGENT_IMG

export FLOWS_IMG="us-east1-docker.pkg.dev/prefect-community/prefect/flows:latest"
docker build -t $FLOWS_IMG .
docker push $FLOWS_IMG
echo success

# Create secrets
gcloud secrets create prefectapikey --replication-policy="automatic" --project prefect-community
echo -n PREFECT_API_KEY | gcloud secrets versions add prefectapikey --data-file=- --project prefect-community

gcloud beta run jobs create prefect-cloud-agent --cpu 1 --image "us-east1-docker.pkg.dev/prefect-community/sls/agent:latest" --max-retries=10 --task-timeout="1h" --set-secrets=PREFECT_API_KEY=prefectapikey:latest --set-env-vars=PREFECT_API_URL=https://api.prefect.cloud/api/accounts/c5276cbb-62a2-4501-b64a-74d3d900d781/workspaces/aaeffa0e-13fa-460e-a1f9-79b53c05ab36 # --execute-now

gcloud scheduler jobs create http scheduled_prefect_agent \
  --location us-east1 \
  --schedule="0 * * * *" \
  --uri="https://us-east1-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/prefect-community/jobs/prefect-cloud-agent:run" \
  --http-method POST \
  --oauth-service-account-email 876616337908-compute@developer.gserviceaccount.com

# CLEANUP: you can pause or delete Cloud Scheduler job or the Cloud Run job from the console
# in the same way, you can remove the Artifact Registry repositories and Secrets Manager secret from the console as well

# tip: don't schedule things at the hour, schedule it a little past so that the transition of agent cloud run jobs doesn't cause any issues

# note: by default, Cloud Run jobs for flow runs won't show up in the Cloud Run jobs console because they get deleted after flow run finishes
# you can instead keep them if you set keep_job=True on your Prefect Cloud Run infra block
prefect deployment build -n default -q default -ib cloud-run-job/default -a -t gcp flows/bs.py:bs
prefect deployment build -n default -q default -ib cloud-run-job/default -a -t gcp flows/healthcheck.py:healthcheck

# query for the Log Explorer:
# resource.type = "cloud_run_job" resource.labels.job_name = "prefect-cloud-agent" resource.labels.location = "us-east1"
prefect deployment set-schedule bs/default --cron "*/5 * * * *"
