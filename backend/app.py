from flask import Flask, jsonify, Response
import os
from prometheus_client import Counter, Histogram, generate_latest, REGISTRY
from prometheus_client.exposition import CONTENT_TYPE_LATEST
from werkzeug.middleware.dispatcher import DispatcherMiddleware
from prometheus_client import make_wsgi_app
from prometheus_client import Counter
# Fetch environment variables
database_url = os.getenv('DATABASE_URL')
api_url = os.getenv('API_URL')
log_level = os.getenv('LOG_LEVEL')

app = Flask(__name__)

# Step 3: Create custom metrics
REQUESTS = Counter('hello_requests_total', 'Total number of requests to /api/hello')
RESPONSE_TIME = Histogram('hello_response_time_seconds', 'Response time of /api/hello')

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

# Step 2: Expose a /metrics endpoint
@app.route('/metrics')
def metrics():
    return Response(generate_latest(REGISTRY), mimetype=CONTENT_TYPE_LATEST)


# Add prometheus wsgi middleware to route /metrics requests
app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
    '/metrics': make_wsgi_app()
})

ERROR_COUNTER = Counter('http_errors_total', 'Total number of HTTP errors', ['status'])

@app.errorhandler(404)
def page_not_found(e):
    ERROR_COUNTER.labels(status='404').inc()
    return jsonify(error=str(e)), 404

@app.errorhandler(500)
def internal_server_error(e):
    ERROR_COUNTER.labels(status='500').inc()
    return jsonify(error=str(e)), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
