from flask import Flask
import os

app = Flask(__name__)

@app.route("/")
def index():
    tenant_id = os.environ.get("TENANT_ID")
    microsservice_version = "1.0.0"
    return f"Tenant ID: {tenant_id} \n Microservice Version: {microsservice_version} \n"

if __name__ == "__main__":
    # run in 0.0.0.0 so that it can be accessed from outside the container
    app.run(host="0.0.0.0", port=80)