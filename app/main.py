import os
import time
import platform
from flask import Flask, jsonify
from prometheus_flask_instrumentator import Instrumentator

app = Flask(__name__)

START_TIME = time.time()

Instrumentator().instrument(app).expose(app)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy", "service": "devops-portfolio-api"}), 200


@app.route("/status", methods=["GET"])
def status():
    uptime_seconds = int(time.time() - START_TIME)
    return jsonify({
        "status": "running",
        "uptime_seconds": uptime_seconds,
        "environment": os.getenv("ENVIRONMENT", "development"),
    }), 200


@app.route("/info", methods=["GET"])
def info():
    return jsonify({
        "app": "DevOps Portfolio API",
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "python_version": platform.python_version(),
        "author": "ToubaSlam",
        "description": "Health check API demonstrating DevOps practices with Docker, Terraform, and CI/CD.",
    }), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)), debug=False)
