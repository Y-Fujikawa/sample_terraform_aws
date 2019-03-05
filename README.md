# sample_terraform_aws
Terraform練習場

# Usage

## Initialize

1. `Amazon Routes53` で独自ドメインを設定
2. `AWS Certificate Manager` でSSL証明書を取得
3. `terraform.tfvars.sample` を `terraform.tfvars` にリネーム
4. `terraform.tfvars` の `domain` に 2 で設定したドメイン名にする
5. Terraform実行
    ```
    $ terraform init
    $ terraform plan -var-file=terraform.tfvars
    $ terraform apply -var-file=terraform.tfvars
    ```
6. `Amazon Routes53` にCloudFrontのAレコードを設定
