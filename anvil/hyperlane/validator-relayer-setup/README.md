Reference https://github.com/EspressoSystems/hyperlane-integration-poc

# AWS setup

## Create KMS key

1. Go to  [KMS](https://console.aws.amazon.com/kms/home) and login with your espresso credentials.
2. Click Create Key.
3. Choose Key Type: Asymmetric
4. Choose Key Usage: Sign and verify
5. Choose Key Spec: ECC_SECG_P256K1
6. Click next and finish key creation.
7. Save key alias and save key id (UUID) in .env with var names VALIDATOR_KEY_ALIAS and AWS_KMS_KEY_ID

## Create IAM key policy

1. Go to [IAM](https://us-east-1.console.aws.amazon.com/iam/home)
2. Go to policies.
3. Click Create policy.
4. Choose policy editor JSON.
5. Set AWS_REGION, $AWS_ACCOUNT_ID, AWS_KMS_KEY_ID in .env.
6. Run `./scripts/update-configs-and-policy.sh` and apply generated `./config/key-policy.json` to the aws editor.
7. Create policy

## Create IAM user and apply key policy
1. Go to [IAM](https://us-east-1.console.aws.amazon.com/iam/home)
2. Go to users.
3. Click create user.
4. Find policy that was created during `Create IAM key policy` and apply id directly.
5. Press next and Create user.
6. Open created IAM user
7. Scroll down to access keys and create access key.
8. Choose key "will be used outside the AWS".
9. Get AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY and paste it to your .env

## Crete S3 bucket, configure bucket policy
1. Go to [S3  service](https://eu-north-1.console.aws.amazon.com/s3)
2. Run `./scripts/update-configs-and-policy.sh` and apply generated `./config/bucket-policy.json` to the aws editor.
3. Create S3 bucket according to the [Hyperlane docs](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)

## Update Mailbox contracts with ISM multisig (1 of 1).
1. Go to ./contracts folder.
2. Create and fill .env file according to env.example.
3. Run `./deploy-ism-multisig-2-chains.sh`

# Run a validator and relayer.
1. Create and fill .env file according to the env.example.
2. Load env files by `export $(grep -v '^#' .env | xargs)`
3. Run `./scripts/update-configs-and-policy.sh` to apply your AWS env to the hyperlane agent.json config.
4. Fund all signers/accounts by executing `./scripts/fund-addresses.sh`
5. Execute `Update Mailbox contracts with ISM multisig (1 of 1).` step
5. Run docker-compose up.




