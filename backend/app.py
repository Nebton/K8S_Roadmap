from flask import Flask, jsonify
import os

# Fetch environment variables
database_url = os.getenv('DATABASE_URL')
api_url = os.getenv('API_URL')
log_level = os.getenv('LOG_LEVEL')

app = Flask(__name__)

@app.route('/api/hello')
def hello():
    # Include environment variables in the response
    return jsonify(
        message="Hello from the backend!",
        database_url=database_url,
        api_url=api_url,
        log_level=log_level
    )

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
