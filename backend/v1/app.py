from flask import Flask, jsonify, Response
import os
from prometheus_client import Counter, Histogram, generate_latest, REGISTRY
from prometheus_client.exposition import CONTENT_TYPE_LATEST
from multiprocessing import Process

# Fetch environment variables
api_url = os.getenv('API_URL')
log_level = os.getenv('LOG_LEVEL')

app = Flask(__name__)
metrics_app = Flask(__name__)

# Create custom metrics
REQUESTS = Counter('hello_requests_total', 'Total number of requests to /api/hello')
RESPONSE_TIME = Histogram('hello_response_time_seconds', 'Response time of /api/hello')
ERROR_COUNTER = Counter('http_errors_total', 'Total number of HTTP errors', ['status'])

@app.route('/api/hello')
@RESPONSE_TIME.time()
def hello():
    REQUESTS.inc() # Increment number of hello requests
    # Include environment variables in the response
    return jsonify(
        message="Hello from the backend!",
        database_url=database_url,
        api_url=api_url,
        log_level=log_level
    )

@metrics_app.route('/metrics')
def metrics():
    return Response(generate_latest(REGISTRY), mimetype=CONTENT_TYPE_LATEST)

@app.errorhandler(404)
def page_not_found(e):
    ERROR_COUNTER.labels(status='404').inc()
    return jsonify(error=str(e)), 404

@app.errorhandler(500)
def internal_server_error(e):
    ERROR_COUNTER.labels(status='500').inc()
    return jsonify(error=str(e)), 500

@app.route('/error')
def error():
    1 / 0

def run_app():
    app.run(host='0.0.0.0', port=5000)

def run_metrics():
    metrics_app.run(host='0.0.0.0', port=5005)

if __name__ == '__main__':
    app_process = Process(target=run_app)
    metrics_process = Process(target=run_metrics)
    
    app_process.start()
    metrics_process.start()
    
    app_process.join()
    metrics_process.join()
