import os
import argparse
import requests
import psycopg2
import io
import json
import base64
from datetime import datetime
from minio import Minio
from pymilvus import connections, Collection, utility

print("Starting InsuranceGuard KYC setup script...")

# Configurations - defaults to port-forwarded localhost addresses
MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "localhost:9010")
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "minioadmin")
MINIO_BUCKET = os.getenv("MINIO_BUCKET", "kyc-data")

POSTGRES_DSN = os.getenv("POSTGRES_DSN", "postgresql://postgres:postgres_password@localhost:5432/kyc_db")

MILVUS_HOST = os.getenv("MILVUS_HOST", "localhost")
MILVUS_PORT = os.getenv("MILVUS_PORT", "19530")
MILVUS_COLLECTION = os.getenv("MILVUS_COLLECTION", "kyc_face_embeddings")

KYC_VERIFIER_URL = os.getenv("KYC_VERIFIER_URL", "http://localhost:8000")
FACE_EMBEDDING_URL = os.getenv("FACE_EMBEDDING_URL", "http://localhost:8090/embed")
OCR_URL = os.getenv("OCR_URL", "http://localhost:8001/v1/chat/completions")

def setup_minio():
    minio_client = Minio(
        MINIO_ENDPOINT,
        access_key=MINIO_ACCESS_KEY,
        secret_key=MINIO_SECRET_KEY,
        secure=False
    )
    if not minio_client.bucket_exists(MINIO_BUCKET):
        minio_client.make_bucket(MINIO_BUCKET)
        print(f"✅ Created Minio bucket: {MINIO_BUCKET}")
    else:
        print(f"✅ Minio Bucket exists: {MINIO_BUCKET}")
    return minio_client

def get_image_bytes(minio_client, path):
    if path.startswith("s3://"):
        path_parts = path[5:].split("/", 1)
        bucket, key = path_parts
        response = None
        try:
            response = minio_client.get_object(bucket, key)
            return response.read()
        finally:
            if response:
                response.close()
                response.release_conn()
    return None

def main(id_path, face_path):
    print(f"Processing ID: {id_path} and Face: {face_path}")
    minio_client = setup_minio()

    id_object_name = os.path.basename(id_path)
    face_object_name = os.path.basename(face_path)

    # 1. Upload ID Image
    with open(id_path, "rb") as f:
        id_data = f.read()
    minio_client.put_object(MINIO_BUCKET, id_object_name, io.BytesIO(id_data), len(id_data), content_type="image/jpeg")
    id_s3_uri = f"s3://{MINIO_BUCKET}/{id_object_name}"
    print(f"✅ Uploaded ID to: {id_s3_uri}")

    # 2. Upload Face Image
    with open(face_path, "rb") as f:
        face_data = f.read()
    minio_client.put_object(MINIO_BUCKET, face_object_name, io.BytesIO(face_data), len(face_data), content_type="image/jpeg")
    face_s3_uri = f"s3://{MINIO_BUCKET}/{face_object_name}"
    print(f"✅ Uploaded Face to: {face_s3_uri}")

    # 3. Request KYC Verification to parse and confirm matching details
    print("🔐 Running full KYC verification (OCR + matching)...")
    verify_payload = {
        "client_request_id": f"script-{datetime.now().strftime('%Y%m%d-%H%M%S')}",
        "live_image_s3": face_s3_uri,
        "id_image_s3": id_s3_uri
    }
    verify_resp = requests.post(f"{KYC_VERIFIER_URL}/verify", json=verify_payload)
    if verify_resp.status_code == 200:
        res = verify_resp.json()
        print(f"✅ Verification Success! User ID: {res.get('matched_user_id')} Status: {res.get('status')}")
    else:
        print(f"❌ Verification failed: {verify_resp.text}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Upload and register KYC documents")
    parser.add_argument("--id", required=True, help="Path to the ID card image")
    parser.add_argument("--face", required=True, help="Path to the user's live face image")
    args = parser.parse_args()
    main(args.id, args.face)
