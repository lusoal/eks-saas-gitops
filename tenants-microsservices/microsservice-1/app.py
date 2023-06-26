from flask import Flask
from flask import jsonify
import os
import requests

app = Flask(__name__)

@app.route("/")
def index():
    microsservice_2_url = os.environ.get("MICROSSERVICE_2_URL")
    tenant_id = os.environ.get("TENANT_ID")
    microsservice_version = "1.0.0"
    
    print("Requesting microsservice 2")
    microsservice_2 = requests.get(microsservice_2_url)
    message = {"tenant_id" : tenant_id, "microsservice_version" : microsservice_version, "microsservice_2_reponse": microsservice_2.json()}
    
    return jsonify(message)
    
if __name__ == "__main__":
    # run in 0.0.0.0 so that it can be accessed from outside the container
    app.run(host="0.0.0.0", port=80)