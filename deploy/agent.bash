# first clone the repo to make sure you have your own

# Clone the repo from Cloud Shell
# Create GCP account + project => here we use project named "prefect-community" - replace it with your project name
# set default project and region:
export CLOUDSDK_CORE_PROJECT="prefect-community"
export CLOUDSDK_COMPUTE_REGION=us-east1
export GCP_AR_REPO=prefect
export GCP_SA_NAME=prefect

# enable required GCP services:
gcloud services enable iamcredentials.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable compute.googleapis.com

# create service account named e.g. prefect:
gcloud iam service-accounts create $GCP_SA_NAME
export MEMBER=serviceAccount:"$GCP_SA_NAME"@"$CLOUDSDK_CORE_PROJECT".iam.gserviceaccount.com
gcloud projects add-iam-policy-binding $CLOUDSDK_CORE_PROJECT --member=$MEMBER --role="roles/run.admin"
gcloud projects add-iam-policy-binding $CLOUDSDK_CORE_PROJECT --member=$MEMBER --role="roles/compute.instanceAdmin.v1"
gcloud projects add-iam-policy-binding $CLOUDSDK_CORE_PROJECT --member=$MEMBER --role="roles/artifactregistry.writer"
gcloud projects add-iam-policy-binding $CLOUDSDK_CORE_PROJECT --member=$MEMBER --role="roles/iam.serviceAccountUser"

# create JSON credentials file as follows, then copy-paste its content into your GHA Secret + Prefect GcpCredentials block:
gcloud iam service-accounts keys create prefect.json --iam-account="$GCP_SA_NAME"@"$CLOUDSDK_CORE_PROJECT".iam.gserviceaccount.com

# build and push the image to Google Artifact Registry
gcloud artifacts repositories create $GCP_AR_REPO --repository-format=docker --location=$CLOUDSDK_COMPUTE_REGION
