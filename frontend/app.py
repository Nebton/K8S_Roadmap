from flask import Flask, render_template
import requests
import hvac
from hvac.api.auth_methods import Kubernetes

app = Flask(__name__)


@app.route('/')
def index():
    client = hvac.Client(url="http://vault.vault.svc.cluster.local:8200")

    with open("/var/run/secrets/kubernetes.io/serviceaccount/token",'r') as f :
        jwt = f.read()
    try : 
        Kubernetes(client.adapter).login(role="frontend",jwt=jwt)
    except Exception as e: 
        print(f"Exception {e} occured for token {jwt}")
    # Fetch data from the backend API
    try:
        response = requests.get('http://backend-service:5000/api/hello')
        data = response.json()
        message = data.get('message', 'No message from backend')
        secret = client.secrets.kv.v2.read_secret_version(path='frontend', mount_point="kv")['data']['data']['k3y']
        database_url = data.get('database_url', 'Not available')
        api_url = data.get('api_url', 'Not available')
        log_level = data.get('log_level', 'Not available')
    except Exception as e:
        message = f"Error contacting backend service: {e}"
        secret = database_url = api_url = log_level = 'Not available'

    # Pass data to the template
    return render_template('index.html', 
                           message=message, 
                           secret=secret,
                           database_url=database_url, 
                           api_url=api_url, 
                           log_level=log_level
                           )

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5050)

