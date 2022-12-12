FROM prefecthq/prefect:2-python3.10

COPY requirements.txt .
COPY setup.py .
COPY prefect_utils .

RUN pip install --upgrade pip --no-cache-dir
RUN pip install setuptools>=58.2.0 --no-cache-dir
RUN pip install --trusted-host pypi.python.org --no-cache-dir .

COPY flows/ /opt/prefect/flows/
