from flask import Flask, jsonify, Response, request
from flask_caching import Cache
import os
import time
import random
from prometheus_client import Counter, Histogram, generate_latest, REGISTRY, Summary
from prometheus_client.exposition import CONTENT_TYPE_LATEST
from multiprocessing import Process

app = Flask(__name__)
metrics_app = Flask(__name__)

# Configure caching
cache = Cache(app, config={'CACHE_TYPE': 'simple'})

# Environment variables
database_url = os.getenv('DATABASE_URL')
api_url = os.getenv('API_URL')
log_level = os.getenv('LOG_LEVEL')

# Metrics
REQUESTS = Counter('hello_requests_total', 'Total number of requests to /api/hello')
RESPONSE_TIME = Histogram('hello_response_time_seconds', 'Response time of /api/hello')
ERROR_COUNTER = Counter('http_errors_total', 'Total number of HTTP errors', ['status'])
PROCESS_TIME = Summary('process_time_seconds', 'Time spent processing request')
CACHE_HITS = Counter('cache_hits_total', 'Total number of cache hits')
CACHE_MISSES = Counter('cache_misses_total', 'Total number of cache misses')

@app.route('/api/hello')
@RESPONSE_TIME.time()
@cache.cached(timeout=60)  # Cache for 60 seconds
def hello():
    REQUESTS.inc()
    start = time.time()
    
    # Introduce an artificial delay for timeout testing
    delay = int(request.args.get('delay', 0))
    time.sleep(delay)
    
    # New feature: personalized greeting
    name = request.args.get('name', 'World')
    
    response = {
        "message": f"Hello, {name}, from the enhanced backend v2!",
        "database_url": database_url,
        "api_url": api_url,
        "log_level": log_level,
        "version": "v2",
        "features": ["Personalized greeting", "Caching", "Enhanced metrics", "Timeout testing", "Retry testing"]
    }
    
    PROCESS_TIME.observe(time.time() - start)
    return jsonify(response)

@app.route('/api/data')
def get_data():
    # Simulate fetching data from a database
    time.sleep(0.5)
    data = [
        {"id": 1, "name": "Item 1", "value": random.randint(1, 100)},
        {"id": 2, "name": "Item 2", "value": random.randint(1, 100)},
        {"id": 3, "name": "Item 3", "value": random.randint(1, 100)}
    ]
    return jsonify(data)

@app.route('/api/status')
def get_status():
    return jsonify({
        "status": "healthy",
        "version": "v2",
        "cache_status": "enabled",
        "database_connection": "active"
    })

@metrics_app.route('/metrics')
def metrics():
    return Response(generate_latest(REGISTRY), mimetype=CONTENT_TYPE_LATEST)

@app.errorhandler(404)
def page_not_found(e):
    ERROR_COUNTER.labels(status='404').inc()
    return jsonify(error=str(e), version="v2"), 404

@app.errorhandler(500)
def internal_server_error(e):
    ERROR_COUNTER.labels(status='500').inc()
    return jsonify(error=str(e), version="v2"), 500

@app.route('/error')
def error():
    # Simulate random failures for retry testing
    if random.random() < 0.5:  # 50% chance of failure
        return jsonify({"message": "Success"}), 200
    else:
        return jsonify({"error": "Internal Server Error"}), 500

@app.before_request
def before_request():
    if cache.cached(request.endpoint, request):
        CACHE_HITS.inc()
    else:
        CACHE_MISSES.inc()

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
