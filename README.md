# test_terraform

Terraformを使用したAWSインフラストラクチャのテストプロジェクト

## 概要

このリポジトリには以下のAWSリソースのTerraform定義が含まれています：

- **API Gateway**: テスト用のREST API
- **Lambda関数**: `/test`エンドポイントでJSON応答を返す関数
- **VPC**: ネットワークインフラストラクチャ
- **CloudWatch Logs**: ログ管理

## 前提条件

- [Terraform](https://www.terraform.io/downloads) 1.0以上
- AWS CLI（認証情報を設定済み）
- AWS アカウント

## AWS認証情報の設定

Terraformを実行する前に、AWS認証情報を設定してください：

```bash
aws configure
```

または環境変数で設定：

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="ap-northeast-1"
```

## デプロイ手順

### 1. リポジトリのクローン

```bash
git clone https://github.com/tsaeki/test_terraform.git
cd test_terraform
```

### 2. Terraformの初期化

```bash
terraform init
```

### 3. 変更内容の確認

```bash
terraform plan
```

### 4. リソースのデプロイ

```bash
terraform apply
```

確認プロンプトで `yes` と入力してください。

### 5. エンドポイントURLの取得

```bash
terraform output
```

出力例：
```
api_url = "https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com/test"
test_url = "https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com/test/test"
error_01_url = "https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com/test/error_01"
error_02_url = "https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com/test/error_02"
error_03_url = "https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com/test/error_03"
```

## API Gatewayエンドポイントのテスト

### `/test` エンドポイント（Lambda統合）

Lambda関数がJSON応答を返します：

```bash
TEST_URL=$(terraform output -raw test_url)
curl $TEST_URL
```

期待される応答：
```json
{
  "message": "Hello from Lambda!",
  "timestamp": "2025-10-05T01:17:00.000Z",
  "status": "success"
}
```

### エラーエンドポイント（MOCKインテグレーション）

以下のエンドポイントは500エラーを返すMOCKエンドポイントです：

```bash
# /error_01
ERROR_01_URL=$(terraform output -raw error_01_url)
curl $ERROR_01_URL

# /error_02
ERROR_02_URL=$(terraform output -raw error_02_url)
curl $ERROR_02_URL

# /error_03
ERROR_03_URL=$(terraform output -raw error_03_url)
curl $ERROR_03_URL
```

期待される応答（例：error_01）：
```json
{
  "message": "Error 01: Internal Server Error"
}
```

### すべてのエンドポイントをテスト

```bash
# すべてのURLを取得
TEST_URL=$(terraform output -raw test_url)
ERROR_01_URL=$(terraform output -raw error_01_url)
ERROR_02_URL=$(terraform output -raw error_02_url)
ERROR_03_URL=$(terraform output -raw error_03_url)

# 一括テスト
echo "Testing /test endpoint..."
curl -s $TEST_URL | jq .

echo -e "\nTesting /error_01 endpoint..."
curl -s $ERROR_01_URL | jq .

echo -e "\nTesting /error_02 endpoint..."
curl -s $ERROR_02_URL | jq .

echo -e "\nTesting /error_03 endpoint..."
curl -s $ERROR_03_URL | jq .
```

## プロジェクト構成

```
.
├── api_gateway.tf          # API Gatewayの定義
├── lambda.tf               # Lambda関数の定義
├── vpc.tf                  # VPCの定義
├── locals.tf               # ローカル変数
├── variables.tf            # 入力変数
├── outputs.tf              # 出力値
├── terraform.tf            # Terraformとプロバイダーの設定
├── providor.tf             # AWSプロバイダーの設定
├── src/
│   ├── lambda/
│   │   ├── test-handler.js    # Lambda関数のコード
│   │   └── test-handler.zip   # Lambda関数のZIPパッケージ
│   └── app.js              # ECSアプリケーション（無効化）
├── ecr.tf_                 # ECR（無効化）
├── ecs.tf_                 # ECS（無効化）
├── lambda.tf_              # Lambda Docker版（無効化）
└── ssm.tf_                 # SSM（無効化）
```

## リソースの削除

すべてのリソースを削除する場合：

```bash
terraform destroy
```

確認プロンプトで `yes` と入力してください。

## 注意事項

- API Gatewayのステージ名は `test` です
- Lambda関数は Node.js 20.x ランタイムを使用しています
- CloudWatch Logsにログが記録されます（保持期間：14日）
- 無効化されたファイル（`.tf_`拡張子）はTerraformによって読み込まれません

## トラブルシューティング

### AWS認証エラー

```bash
# 認証情報の確認
aws sts get-caller-identity

# 認証情報が設定されていない場合
aws configure
```

### Terraformエラー

```bash
# 状態ファイルの確認
terraform show

# 構文チェック
terraform validate

# フォーマット
terraform fmt
```

## 参考資料

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS API Gateway](https://docs.aws.amazon.com/apigateway/)
- [AWS Lambda](https://docs.aws.amazon.com/lambda/)
