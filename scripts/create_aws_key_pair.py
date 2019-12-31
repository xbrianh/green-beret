#!/usr/bin/env python
import os
import boto3

def create_key_pair(key_pair_name: str) -> str:
    """
    Create an AWS EC2 key pair and return the private key in PEM format
    """
    client = boto3.client("ec2")
    resp = client.create_key_pair(KeyName=key_pair_name)
    print("Created aws key pair with id", resp['KeyPairId'])
    return resp['KeyMaterial']

def set_secret(secret_id: str, secret_string: str) -> str:
    """
    Store a string into AWS Secretsmanager
    """
    client = boto3.client('secretsmanager')
    try:
        resp = client.get_secret_value(SecretId=secret_id)
    except client.exceptions.ResourceNotFoundException:
        resp = client.create_secret(Name=secret_id, SecretString=secret_string)
        print("Created secret", resp['Name'])
    else:
        resp = client.update_secret(SecretId=secret_id, SecretString=secret_string)
        print("Updated secret", resp['Name'])

secret_key_pem = create_key_pair(os.environ['GREEN_BERET_AWS_KEY_PAIR_NAME'])
set_secret(os.environ['GREEN_BERET_AWS_KEY_PAIR_SECRET_ID'], secret_key_pem)
