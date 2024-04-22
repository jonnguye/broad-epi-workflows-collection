import datetime
from google.cloud import storage
from google.oauth2 import service_account
from typing import Optional

def generate_download_signed_url_v4(bucket_name: str, blob_name: str, service_account_file: str, expiration_days: Optional[int] = 1) -> str:
    """
    Generates a v4 signed URL for downloading a blob.

    Args:
        bucket_name (str): The name of the bucket containing the blob.
        blob_name (str): The name of the blob to generate the signed URL for.
        service_account_file (str): The path to the service account key file.
        expiration_days (int, optional): The number of days until the signed URL expires. Defaults to 1.

    Returns:
        str: The generated signed URL.

    Note:
        This method requires a service account key file. You cannot use this if you are using Application Default
        Credentials from Google Compute Engine or from the Google Cloud SDK.
    """
    # Explicitly use service account credentials by specifying the private key file.
    credentials = service_account.Credentials.from_service_account_file(
        service_account_file
    )

    storage_client = storage.Client(credentials=credentials)
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(blob_name)

    url = blob.generate_signed_url(
        version="v4",
        # This URL is valid for 1 day
        expiration=datetime.timedelta(days=expiration_days),
        # Allow GET requests using this URL.
        method="GET"
    )

    return url

# Example usage
# print(generate_download_signed_url_v4("bucket-name", "object-name", "service-account-key.json"))