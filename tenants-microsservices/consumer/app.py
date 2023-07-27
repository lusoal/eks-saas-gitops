from flask import Flask
from flask import jsonify
import os

app = Flask(__name__)

@app.route("/")
def index():
    tenant_id = os.environ.get("TENANT_ID")
    microsservice_version = "1.0.0"

    message = {"tenant_id": tenant_id, "microsservice_version": microsservice_version, "microserice": "consumer"}

    return jsonify(message)

if __name__ == "__main__":
    # run in 0.0.0.0 so that it can be accessed from outside the container
    app.run(host="0.0.0.0")