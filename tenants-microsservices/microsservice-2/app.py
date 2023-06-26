from flask import Flask
from flask import jsonify
import os

app = Flask(__name__)

@app.route("/")
def index():
    # tenant_id = os.environ.get("TENANT_ID")
    microsservice_version = "1.1.0"
    response = {"message":f"Hello from Microservice 2 Version: {microsservice_version}"}
    print(response)
    return jsonify(response)

if __name__ == "__main__":
    # run in 0.0.0.0 so that it can be accessed from outside the container
    app.run(host="0.0.0.0")