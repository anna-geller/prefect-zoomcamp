# install prefect
pip install prefect
pip install .

# if prefect command is not found, add to path:
export PATH="$HOME/.local/bin:$PATH"

# sign up for Prefect Cloud + crete workspace + generate API key, enter those in GHA Secrets and in CLI:
prefect cloud login

# Then, run:
prefect config view --show-secrets

# this will display the value of PREFECT_API_KEY and PREFECT_API_URL --> paste those into GHA secrets
python blocks.py  # todo adjust your block values in that file
prefect deployment build -n default -ib cloud-run-job/default -a -sb github/zoomcamp flows/bs.py:bs
prefect deployment build -n default -ib cloud-run-job/default -a -sb github/zoomcamp flows/healthcheck.py:healthcheck
