# sample_terraform_aws

Terraform練習場

## Usage

### 初回

1. 機微情報をParameterStoreへ登録する

    ```sh
    $ export AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
    $ export AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
    $ export AWS_DEFAULT_REGION=us-east-1
    $ export SERVICE_NAME=sample
    $ export STAGE=prd
    $ export APP_NAME=${STAGE}-${SERVICE_NAME}

    $ export DB_NAME=sample
    $ export DB_USERNAME=sample
    $ export DB_PASSWORD=mypassword

    $ aws ssm put-parameter --name "/${APP_NAME}/db/name" --value "${DB_NAME}" --type String
    $ aws ssm put-parameter --name "/${APP_NAME}/db/username" --value "${DB_USERNAME}" --type String
    $ aws ssm put-parameter --name "/${APP_NAME}/db/password" --value "${DB_PASSWORD}" --type SecureString
    ```

2. Provisioning

    ```sh
    $ export REGION=us-east-1
    $ export BUCKET_NAME=prd-${SERVICE_NAME}-terraform-state
    $ terraform init -backend-config="bucket=${BUCKET_NAME}" -backend-config="key=terraform.tfstate" -backend-config="region=${REGION}"
    $ terraform workspace new prd
    $ terraform plan -var-file=terraform.tfvars.${STAGE}
    $ terraform apply -var-file=terraform.tfvars.${STAGE}
    ```

3. DBホストをParameterStoreへ登録する

    ```sh
    $ export DB_HOST=$(aws rds describe-db-clusters --db-cluster-identifier ${APP_NAME} --query DBClusters[0].Endpoint --output text)
    $ aws ssm put-parameter --name "/${APP_PREFIX}/db/host" --value "${DB_HOST}" --type String
    ```

4. その他機微情報をParameterStoreへ登録する

    ```sh
    $ aws ssm put-parameter --name "/${APP_PREFIX}/app/${SAMPLE}" --value "${API_PASSWORD}" --type String
    ```

### 2回目以降

    ```sh
    $ export AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
    $ export AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
    $ export AWS_DEFAULT_REGION=us-east-1
    $ export STAGE=prd

    $ terraform plan -var-file=terraform.tfvars.${STAGE}
    $ terraform apply -var-file=terraform.tfvars.${STAGE}
    ```

## Tips

### 手動で設定するAWSサービス

- Amazon Route 53
- AWS Certificate Manager

### インフラ構成図

TBD
