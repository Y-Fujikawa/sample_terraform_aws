# sample_terraform_aws
Terraform練習場

# Usage

## Initialize

1. `terraform.tfvars` 保存するためのバケットをS3に作成
2. `Amazon Routes53` で独自ドメインを設定
3. `AWS Certificate Manager` でSSL証明書を取得
4. `terraform.tfvars.sample` を `terraform.tfvars` にリネーム
5. `terraform.tfvars` の `domain` に 2 で設定したドメイン名にする
6. Terraform実行

    ```sh
    $ terraform workspace new dev
    $ terraform init -backend-config='bucket=fujiyasu-sample-terraform' -backend-config='key=terraform.tfstate' -backend-config="region=us-east-1"
    $ terraform plan -var-file=terraform.tfvars
    $ terraform apply -var-file=terraform.tfvars
    ```

7. `Amazon Routes53` にCloudFrontのAレコードを設定
