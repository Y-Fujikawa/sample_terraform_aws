# sample_terraform_aws
Terraform練習場

# Usage

## Initialize

1. `Amazon Routes53` で独自ドメインを設定
2. `AWS Certificate Manager` でSSL証明書を取得
3. Terraform実行
    ```
    $ terraform init
    $ terraform plan
    $ terraform apply
    ```
4. `Amazon Routes53` にELBのAレコードを設定