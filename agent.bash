# install prefect
pip install .

# sign up for Prefect Cloud + crete workspace + generate API key, enter those in GHA Secrets and in CLI:
prefect cloud login

# Create GCP account + project => here we use project named "prefect-community" - replace it with your project name
# set default project and region:
export CLOUDSDK_CORE_PROJECT="prefect-community"
export CLOUDSDK_COMPUTE_REGION=us-east1

# enable required GCP services:
gcloud services enable iamcredentials.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable run.googleapis.com

# create service account named e.g. prefect:
gcloud iam service-accounts create prefect
export MEMBER=serviceAccount:prefect@"$CLOUDSDK_CORE_PROJECT".iam.gserviceaccount.com
gcloud projects add-iam-policy-binding prefect-community --member=$MEMBER --role="roles/run.admin"
gcloud projects add-iam-policy-binding prefect-community --member=$MEMBER --role="roles/compute.instanceAdmin.v1"
gcloud projects add-iam-policy-binding prefect-community --member=$MEMBER --role="roles/artifactregistry.writer"
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

python setup/blocks.py
prefect deployment build -n default -q default -ib cloud-run-job/default -a -t gcp flows/bs.py:bs
prefect deployment build -n default -q default -ib cloud-run-job/default -a -t gcp flows/healthcheck.py:healthcheck

# query for the Log Explorer:
# resource.type = "cloud_run_job" resource.labels.job_name = "prefect-cloud-agent" resource.labels.location = "us-east1"
prefect deployment set-schedule bs/default --cron "*/5 * * * *"
