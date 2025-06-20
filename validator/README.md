# AWS setup

## Create KMS key

1. Go to KMS https://console.aws.amazon.com/kms/home and login with your espresso credentials.
2. Click Create Key.
3. Choose Key Type: Asymmetric
4. Choose Key Usage: Sign and verify
5. Choose Key Spec: ECC_SECG_P256K1
6. Click next and finish key creation.
7. Save key alias and save key id (UUID) in .env with var names VALIDATOR_KEY_ALIAS and AWS_KMS_KEY_ID

## Create IAM key policy

1. Go to IAM https://us-east-1.console.aws.amazon.com/iam/home.
2. Go to policies.
3. Click Create policy.
4. Choose policy editor JSON.
5. Set AWS_REGION, $AWS_ACCOUNT_ID, AWS_KMS_KEY_ID in ./config/key-policy.json and apply policy to the editor.
6. Create policy

## Create IAM user and apply policy
1. Go to IAM https://us-east-1.console.aws.amazon.com/iam/home.
2. Go to users.
3. Click create user.
4. Find policy that was created during `Create IAM key policy` and apply id directly.
5. Press next and Create user.
6. Open created IAM user
7. Scroll down to access keys and create access key.
8. Choose key "will be used outside the AWS".
9. Get AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY and paste it to your .env


# Run a validator.
1. Create and fill .env file according to env.example.
2. Load env files by `export $(grep -v '^#' .env | xargs)`
3. Run ./update-agent.sh to apply your AWS env to the hyperlane agent.json config.
4. Run docker-compose up.




