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
import logging

from ou_path_resolver import (
    OuPathResolver,
    create_organizations_client,
    terraform_json_output,
)

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
        help="Optional role ARN to assume",
        default=None,
    )
    parser.add_argument(
        "--endpoint-url",
        dest="endpoint_url",
        help="AWS Organizations API endpoint URL override",
        default=None,
    )
    return parser.parse_args()


def main():
    args = _parse_args()
    org_client = create_organizations_client(args.endpoint_url, args.role_arn)
    resolver = OuPathResolver(logger, org_client)
    resolver.validate_org(args.expected_org_id, args.expected_root_ou_id)
    terraform_json_output(resolver.resolve_ou_tree())


if __name__ == "__main__":
    main()
