from flask import Flask, jsonify, Response, request
from flask_caching import Cache
import os
import time
import random
from prometheus_client import Counter, Histogram, generate_latest, REGISTRY, Summary
from prometheus_client.exposition import CONTENT_TYPE_LATEST
from multiprocessing import Process
import hvac
from hvac.api.auth_methods import Kubernetes
import psycopg2


app = Flask(__name__)
metrics_app = Flask(__name__)

# Configure caching
cache = Cache(app, config={'CACHE_TYPE': 'simple'})

# Environment variables
api_url = os.getenv('API_URL')
log_level = os.getenv('LOG_LEVEL')

# Metrics
REQUESTS = Counter('hello_requests_total', 'Total number of requests to /api/hello')
RESPONSE_TIME = Histogram('hello_response_time_seconds', 'Response time of /api/hello')
ERROR_COUNTER = Counter('http_errors_total', 'Total number of HTTP errors', ['status'])
PROCESS_TIME = Summary('process_time_seconds', 'Time spent processing request')
CACHE_HITS = Counter('cache_hits_total', 'Total number of cache hits')
CACHE_MISSES = Counter('cache_misses_total', 'Total number of cache misses')

def get_db_connection():
    client = hvac.Client(url="http://vault.vault.svc.cluster.local:8200")

    with open("/var/run/secrets/kubernetes.io/serviceaccount/token",'r') as f:
        jwt = f.read()
    try:
        Kubernetes(client.adapter).login(role="backend",jwt=jwt)
    except Exception as e:
        print(f"Exception {e} occurred for token {jwt}")
 
    # Request dynamic credentials for the database
    response = client.secrets.database.generate_credentials(name="readonly")
    
    # Extract the credentials
    username = response['data']['username']
    password = response['data']['password']
    
    # Connect to the database using the dynamic credentials
    conn = psycopg2.connect(
        host="postgres-postgresql",
        database="flaskdb",
        user=username,
        password=password
    )
    
    return conn

@app.route('/api/docs')
def get_api_docs():
    # Get current database connection info dynamically
    conn = get_db_connection()
    db_params = conn.get_dsn_parameters()
    conn.close()
    
    swagger_doc = {
        "openapi": "3.0.0",
        "info": {
            "title": "Enhanced Backend API",
            "description": "API documentation for the Flask backend service with metrics, caching, and database integration",
            "version": "2.0.0"
        },
        "servers": [
            {
                "url": "http://localhost:5000",
                "description": "Local development server"
            }
        ],
        "paths": {
            "/api/hello": {
                "get": {
                    "summary": "Get personalized greeting",
                    "description": "Returns a personalized greeting with backend configuration details",
                    "parameters": [
                        {
                            "name": "name",
                            "in": "query",
                            "description": "Name to personalize greeting",
                            "required": False,
                            "schema": {
                                "type": "string",
                                "default": "World"
                            }
                        },
                        {
                            "name": "delay",
                            "in": "query",
                            "description": "Artificial delay in seconds for timeout testing",
                            "required": False,
                            "schema": {
                                "type": "integer",
                                "default": 0
                            }
                        }
                    ],
                    "responses": {
                        "200": {
                            "description": "Successful response",
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "type": "object",
                                        "properties": {
                                            "message": {"type": "string"},
                                            "database_url": {"type": "string"},
                                            "api_url": {"type": "string"},
                                            "log_level": {"type": "string"},
                                            "version": {"type": "string"},
                                            "features": {
                                                "type": "array",
                                                "items": {"type": "string"}
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            "/users": {
                "get": {
                    "summary": "Get all users",
                    "description": "Retrieves all users from the database using dynamic vault credentials",
                    "responses": {
                        "200": {
                            "description": "List of users",
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "type": "array",
                                        "items": {
                                            "type": "object",
                                            "properties": {
                                                "id": {"type": "integer"},
                                                "username": {"type": "string"},
                                                "email": {"type": "string"}
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            "/api/data": {
                "get": {
                    "summary": "Get random data items",
                    "description": "Returns an array of items with random values",
                    "responses": {
                        "200": {
                            "description": "List of random items",
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "type": "array",
                                        "items": {
                                            "type": "object",
                                            "properties": {
                                                "id": {"type": "integer"},
                                                "name": {"type": "string"},
                                                "value": {"type": "integer"}
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            "/api/status": {
                "get": {
                    "summary": "Get service status",
                    "description": "Returns the current status of the service",
                    "responses": {
                        "200": {
                            "description": "Service status information",
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "type": "object",
                                        "properties": {
                                            "status": {"type": "string"},
                                            "version": {"type": "string"},
                                            "cache_status": {"type": "string"},
                                            "database_connection": {"type": "string"}
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            "/error": {
                "get": {
                    "summary": "Test error handling",
                    "description": "Endpoint that randomly succeeds or fails for testing retry logic",
                    "responses": {
                        "200": {
                            "description": "Successful response",
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "type": "object",
                                        "properties": {
                                            "message": {"type": "string"}
                                        }
                                    }
                                }
                            }
                        },
                        "500": {
                            "description": "Internal server error",
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "type": "object",
                                        "properties": {
                                            "error": {"type": "string"}
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            "/metrics": {
                "get": {
                    "summary": "Get service metrics",
                    "description": "Returns Prometheus metrics for monitoring",
                    "responses": {
                        "200": {
                            "description": "Prometheus metrics",
                            "content": {
                                "text/plain": {
                                    "schema": {
                                        "type": "string"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },
        "components": {
            "schemas": {
                "DatabaseInfo": {
                    "type": "object",
                    "properties": {
                        "host": {"type": "string", "example": "postgres-postgresql"},
                        "database": {"type": "string", "example": "flaskdb"},
                        "user": {"type": "string", "description": "Dynamic username from Vault"},
                        "port": {"type": "integer", "example": 5432}
                    }
                }
            }
        }
    }
    
    return jsonify(swagger_doc)

@app.route('/users')
def get_users():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM users")
    users = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify([{"id": user[0], "username": user[1], "email": user[2]} for user in users])

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
    
    # Get database connection info
    conn = get_db_connection()
    db_params = conn.get_dsn_parameters()
    conn.close()
    
    response = {
        "message": f"Hello, {name}, from the enhanced backend v2!",
        "database_url": f"postgresql://{db_params['host']}:{db_params['port']}/{db_params['dbname']}",
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
