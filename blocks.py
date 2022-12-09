from prefect.filesystems import GitHub
from prefect.infrastructure import KubernetesJob

k8s = KubernetesJob(
    image="prefecthq/prefect:2-python3.10",
    namespace="prefect",
    image_pull_policy="IfNotPresent",
    env={"PREFECT_LOGGING_LEVEL": "INFO"},
)
k8s.save("default", overwrite=True)

gh = GitHub(repository="https://github.com/anna-geller/prefect-zoomcamp", reference="main")
gh.save("default", overwrite=True)
