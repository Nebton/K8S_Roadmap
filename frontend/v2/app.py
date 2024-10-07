from flask import Flask, render_template
import requests

app = Flask(__name__)

@app.route('/')
def index():
    # Fetch data from the backend API
    try:
        response = requests.get('http://backend-service-v2:5000/api/hello')
        data = response.json()
        message = data.get('message', 'No message from backend')
        database_url = data.get('database_url', 'Not available')
        api_url = data.get('api_url', 'Not available')
        log_level = data.get('log_level', 'Not available')
    except Exception as e:
        message = f"Error contacting backend service: {e}"
        database_url = api_url = log_level = 'Not available'

    # Pass data to the template
    return render_template('index.html', 
                           message=message, 
                           database_url=database_url, 
                           api_url=api_url, 
                           log_level=log_level)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5050)

