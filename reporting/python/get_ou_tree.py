"""
ACAI Cloud Foundation (ACF)
Copyright (C) 2025 ACAI GmbH
Licensed under AGPL v3

This file is part of ACAI ACF.
Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.

For full license text, see LICENSE file in repository root.
For commercial licensing, contact: contact@acai.gmbh

Description:
    Walks the full AWS Organizations OU tree and outputs all OU paths
    with their IDs and nesting levels. Optionally assumes a cross-account
    IAM role before querying the Organizations API.

    Output JSON structure (printed to stdout, compatible with Terraform external data source):
    {
        "result": "<JSON-encoded string>"
    }

    Where the decoded "result" value is:
    {
        "/root/": { "ou_id": "r-xxxx", "level": 0 },
        "/root/CoreAccounts/": { "ou_id": "ou-xxxx-yyyy", "level": 1 },
        ...
    }

    Notes:
    - The outer wrapper {"result": "..."} satisfies the Terraform external data source
      requirement that all output values are strings.
    - The tree is walked recursively with no hardcoded depth limit, so future
      increases to the AWS OU nesting limit are handled automatically.
"""

import argparse
import json
import logging
from typing import Any, Dict, Optional

import boto3
from botocore.config import Config as boto3_config
from botocore.exceptions import BotoCoreError, ClientError

# Configure logging (stdout reserved for final JSON output)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger(__name__)


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Walk the full AWS Organizations OU tree."
    )
    parser.add_argument(
        "--expected_org_id",
        required=True,
        help="Expected AWS Organizations ID (e.g., o-xxxxxxxxxx)",
    )
    parser.add_argument(
        "--expected_root_ou_id",
        required=True,
        help="Expected Root OU ID (e.g., r-xxxx)",
    )
    parser.add_argument(
        "--role-arn",
        dest="role_arn",
        help="Optional role ARN to assume (e.g. arn:aws:iam::123456789012:role/MyRole)",
        default=None,
    )
    parser.add_argument(
        "--endpoint-url",
        dest="endpoint_url",
        help="AWS Organizations API endpoint URL override (e.g. for AWS ESC: https://organizations.eusc-de-east-1.amazonaws.eu)",
        default=None,
    )
    return parser.parse_args()


def main():
    args = _parse_args()
    expected_org_id = args.expected_org_id
    expected_root_ou_id = args.expected_root_ou_id
    role_arn = args.role_arn
    endpoint_url = args.endpoint_url

    session = _assume_remote_role(role_arn) if role_arn else boto3.Session()

    if session is None:
        raise Exception(f"Was not able to assume role {role_arn}")

    try:
        boto3_config_settings = boto3_config(
            retries={"max_attempts": 10, "mode": "standard"},
            connect_timeout=10,
            read_timeout=30,
        )
        client_kwargs = {"config": boto3_config_settings}
        if endpoint_url:
            client_kwargs["endpoint_url"] = endpoint_url
            # SigV4 signing requires region_name to match the endpoint region.
            # Extract it from the hostname: organizations.{region}.amazonaws.{tld}
            hostname = endpoint_url.split("://", 1)[-1].split("/")[0]
            client_kwargs["region_name"] = hostname.split(".")[1]
        boto3_client = session.client("organizations", **client_kwargs)

        found_org_id = boto3_client.describe_organization()["Organization"]["Id"]
        found_root_ou_id = boto3_client.list_roots()["Roots"][0]["Id"]
        if (expected_org_id != found_org_id) or (
            expected_root_ou_id != found_root_ou_id
        ):
            raise ValueError(
                f"Not in the correct AWS Org. Required: {expected_org_id}/{expected_root_ou_id} "
                f"Found: {found_org_id}/{found_root_ou_id}"
            )

        ou_tree: Dict[str, Any] = {"/root/": {"ou_id": found_root_ou_id, "level": 0}}
        _walk_ou_tree(boto3_client, found_root_ou_id, "/root", 1, ou_tree)

        # Keep Terraform external data format: values must be strings
        print(json.dumps({"result": json.dumps(ou_tree)}))
    except (ClientError, BotoCoreError) as e:
        logger.error("AWS Organizations error: %s", e)
        raise


def _walk_ou_tree(
    boto3_client,
    parent_id: str,
    parent_path: str,
    current_level: int,
    result: Dict[str, Any],
) -> None:
    """Recursively walk the OU tree, adding each OU to result."""
    paginator = boto3_client.get_paginator("list_organizational_units_for_parent")
    for page in paginator.paginate(ParentId=parent_id):
        for ou in page["OrganizationalUnits"]:
            ou_path = f"{parent_path}/{ou['Name']}/"
            result[ou_path] = {"ou_id": ou["Id"], "level": current_level}
            _walk_ou_tree(
                boto3_client,
                ou["Id"],
                f"{parent_path}/{ou['Name']}",
                current_level + 1,
                result,
            )


def _assume_remote_role(remote_role_arn: Optional[str]) -> Optional[boto3.Session]:
    try:
        sts_client = boto3.client("sts")
        response = sts_client.assume_role(
            RoleArn=remote_role_arn, RoleSessionName="RemoteSession"
        )
        return boto3.Session(
            aws_access_key_id=response["Credentials"]["AccessKeyId"],
            aws_secret_access_key=response["Credentials"]["SecretAccessKey"],
            aws_session_token=response["Credentials"]["SessionToken"],
        )
    except Exception as e:
        logger.error("Failed to assume role %s: %s", remote_role_arn, e)
        return None


if __name__ == "__main__":
    main()
