from prefect.filesystems import GitHub
from prefect_gcp.cloud_run import CloudRunJob
from prefect_gcp.credentials import GcpCredentials
from prefect_utils import PostgresPandas, BigQueryPandas


block = CloudRunJob(
    image="us-east1-docker.pkg.dev/prefect-community/prefect/flows:latest",
    region="us-east1",
    credentials=GcpCredentials.load("default"),
    cpu=1,
    timeout=3600,
)
block.save("default", overwrite=True)


gh = GitHub(
    repository="https://github.com/anna-geller/prefect-zoomcamp", reference="main"
)
gh.save("prefect-zoomcamp", overwrite=True)


postgres_block = PostgresPandas(user_name="postgres", password="postgres")
postgres_block.save("default", overwrite=True)

block = BigQueryPandas(
    credentials=GcpCredentials.load("default"),
    project="prefect-community",
)
block.save("default", overwrite=True)
