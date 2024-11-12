import os
from datetime import datetime
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient

AZ_BLOB_ACCOUNT = os.getenv("AZ_BLOB_ACCOUNT")  
AZ_BLOB_CONNECTION = os.getenv("AZ_BLOB_CONNECTION")  
AZURE_STORAGE_CONTAINER = "samplefile"  
AZURE_SUBFOLDER = "OpenAi"  
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))

if not AZ_BLOB_ACCOUNT or not AZ_BLOB_CONNECTION:
    raise ValueError("Azure Blob Storage account name or connection string not set in environment variables.")

# Define file paths
DATE = datetime.now().strftime("%Y%m%d")
YEAR = datetime.now().strftime("%Y")
MONTH = datetime.now().strftime("%m")
#OUTPUT_FILE = f"/home/aishock/Dev/open-webui/src/etl/output_{DATE}.txt"
OUTPUT_FILE = os.path.join(SCRIPT_DIR, f"output_{DATE}.txt")

BLOB_NAME = f"{AZURE_SUBFOLDER}/{YEAR}/{MONTH}/{os.path.basename(OUTPUT_FILE)}"
blob_service_client = BlobServiceClient.from_connection_string(AZ_BLOB_CONNECTION)
container_client = blob_service_client.get_container_client(AZURE_STORAGE_CONTAINER)

blob_client = container_client.get_blob_client(BLOB_NAME)
print(f"Uploading {os.path.basename(OUTPUT_FILE)} to Azure Blob Storage at {BLOB_NAME}...")

with open(OUTPUT_FILE, "rb") as data:
    blob_client.upload_blob(data, overwrite=True)

print("Output file uploaded successfully.")

