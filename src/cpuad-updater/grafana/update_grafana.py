import os
import subprocess
import requests
import base64
import re

elasticsearch_url = os.getenv('ELASTICSEARCH_URL')

if not elasticsearch_url:
    raise ValueError("Please set the ELASTICSEARCH_URL environment variable")

grafana_username = os.getenv('GRAFANA_USERNAME')

if not grafana_username:
    raise ValueError("Please set the GRAFANA_USERNAME environment variable")

grafana_url = os.getenv('GRAFANA_URL', 'http://localhost:3000/')

if not grafana_url: 
    raise ValueError("Please set the GRAFANA_URL environment variable")

grafana_password = os.getenv('GRAFANA_PASSWORD')

if not grafana_password:
    raise ValueError("Please set the GRAFANA_PASSWORD environment variable")

def poll_for_elasticsearch():
    """
    Polls the Elasticsearch server until it is reachable.

    Raises:
        ValueError: If the Elasticsearch server is not reachable.
    """
    while True:
        try:
            response = requests.get(f"{elasticsearch_url.rstrip('/')}/_cluster/health")
            if response.status_code == 200:
                print("Elasticsearch is up and running.")
                break
        except requests.exceptions.RequestException as e:
            print(f"Elasticsearch is not reachable: {e}")
        time.sleep(5)

def poll_for_grafana():
    """
    Polls the Grafana server until it is reachable.

    Raises:
        ValueError: If the Grafana server is not reachable.
    """
    while True:
        try:
            response = requests.get(f"{grafana_url.rstrip('/')}")
            if response.status_code == 200:
                print("Grafana is up and running.")
                break
        except requests.exceptions.RequestException as e:
            print(f"Grafana is not reachable: {e}")
        time.sleep(5)

def create_grafana_service_account():
    """
    Creates a Grafana service account using basic authentication.

    Returns:
        A dictionary containing the headers for the request.
    """
    # Combine username and password for basic auth
    credentials = f"{grafana_username}:{grafana_password}"
    encoded_credentials = base64.b64encode(credentials.encode('utf-8')).decode('utf-8')

    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": f"Basic {encoded_credentials}"
    }

    result = requests.post(
        f"{grafana_url.rstrip('/')}/api/serviceaccounts",
        headers=headers,
        json={
            "name": "sa-for-cpuad",
            "role": "Admin",
            "isDisabled": False
        }
    )

    if result.status_code != 201:
        print(f"Failed to create service account: {result.status_code} - {result.text}")
        return None

    service_account_id = result.json().get('id')

    if not service_account_id:
        print("Failed to retrieve service account ID")
        return None
    
    # Create Grafana token for the service account
    result = requests.post(
        f"{grafana_url.rstrip('/')}/api/serviceaccounts/{service_account_id}/tokens",
        headers=headers,
        json={
            "name": "sa-for-cpuad-key",
            "secondsToLive": 0 # 0 means no expiration
        }
    )

    if result.status_code != 201:
        print(f"Failed to create Grafana API token: {result.status_code} - {result.text}")
        
        raise ValueError("Failed to create Grafana API token")
    
    grafana_api_token = result.json().get('key')

    if not grafana_api_token:
        print("Failed to retrieve Grafana API token")

        raise ValueError("Failed to retrieve Grafana API token")

    # set the API key as an environment variable
    os.environ['GRAFANA_TOKEN'] = grafana_api_token

    return grafana_api_token

def run_bash_script(script_path):
    """
    Runs a bash script and returns the output and error.

    Args:
        script_path: Path to the bash script.

    Returns:
        A tuple containing the standard output and standard error 
        as strings.
    """
    try:
        process = subprocess.run(
            ['bash', script_path],
            capture_output=True,
            text=True,
            check=True
        )
        return process.stdout, process.stderr
    except subprocess.CalledProcessError as e:
        return None, e.stderr

def run_python_script(script_path):
    try:
        process = subprocess.run(
            ['python', script_path],
            args=['--template', 'grafana/dashboard_template.json'],
            capture_output=True,
            text=True,
            check=True
        )
        print("Python script output:\n", process.stdout)
    except subprocess.CalledProcessError as e:
        print("Python script error:\n", e.stderr)

    regex = r"grafana/dashboard-model-\d{4}-\d{2}-\d{2}\.json"

    match = re.search(regex, process.stdout)
    if match:
        dashboard_model_path = match.group()
        print(f"Dashboard model path: {dashboard_model_path}")
    else:
        print("No dashboard model path found in the output.")
        dashboard_model_path = None    

    return dashboard_model_path

def import_grafana_dashboard(dashboard_model_path, grafana_token):
    """
    Imports a Grafana dashboard using the Grafana API.

    Args:
        dashboard_model_path: Path to the dashboard model JSON file.
    """
    with open(dashboard_model_path, 'r') as template_file:
        template_content = template_file.read()

    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": f"Bearer {grafana_token}"
    }

    result = requests.post(
        f"{grafana_url.rstrip('/')}/api/dashboards/db",
        headers=headers,
        data=template_content
    )

    if result.status_code != 200:
        print(f"Failed to import dashboard: {result.status_code} - {result.text}")
    else:
        print("Dashboard imported successfully.")

if __name__ == "__main__":

    poll_for_elasticsearch()

    poll_for_grafana()

    # Create Grafana service account and token
    grafana_token = create_grafana_service_account()

    # Run the bash script
    script_path = 'add_grafana_data_sources.sh'
    stdout, stderr = run_bash_script(script_path)

    if stdout:
        print("Bash script output:\n", stdout)
    if stderr:
        print("Bash script error:\n", stderr)

    # Run the Python script
    python_script_path = 'gen_grafana_model.py'
    
    dashboard_model_path = run_python_script(python_script_path)

    import_grafana_dashboard(dashboard_model_path=dashboard_model_path, 
                             grafana_token=grafana_token)