# Java Application with JMX Monitoring

このディレクトリには、JMXメトリクスを有効にしたサンプルのSpring BootアプリケーションとECSサイドカー設定が含まれています。

## 概要

- **Java Application**: Spring Boot 3.2.0を使用したシンプルなRESTful API
- **JMX有効化**: Java Management Extensions (JMX)を使用してアプリケーションメトリクスを公開
- **サイドカーコンテナ**: Prometheus JMX Exporterを使用してJMXメトリクスをHTTPエンドポイントとして公開

## アーキテクチャ

```
ECS Task
├── Java Application Container
│   ├── Port 8080: HTTP API
│   └── Port 9010: JMX Remote Port
├── JMX Exporter Sidecar Container
│   └── Port 5556: Prometheus Metrics Endpoint
└── CloudWatch Agent Sidecar Container
    └── Scrapes metrics from JMX Exporter and sends to CloudWatch Metrics
```

## エンドポイント

### Java Application (Port 8080)
- `GET /` - Hello World エンドポイント
- `GET /health` - ヘルスチェックエンドポイント（メモリ使用状況を含む）
- `GET /metrics` - アプリケーションメトリクス

### JMX Exporter (Port 5556)
- `GET /metrics` - Prometheus形式のJMXメトリクス

### CloudWatch Metrics
- **Namespace**: `JavaApp/JMX`
- JVMメモリ、GC、スレッド、クラスローディングなどのメトリクスがCloudWatchに送信されます

## ローカルでのビルドとテスト

### Maven を使用したビルド
```bash
cd java-app
mvn clean package
java -jar target/demo-1.0.0.jar
```

### Docker を使用したビルド
```bash
cd java-app
docker build -t java-jmx-app .
docker run -p 8080:8080 -p 9010:9010 java-jmx-app
```

### 動作確認
```bash
curl http://localhost:8080/
curl http://localhost:8080/health
curl http://localhost:8080/metrics
```

## ECSへのデプロイ

### 1. ECRリポジトリの作成
```bash
cd /path/to/test_terraform
terraform init
terraform apply -target=module.ecr_java
```

### 2. Dockerイメージのビルドとプッシュ
```bash
./deploy-java-to-ecr.sh latest
```

### 3. ECS タスク定義とサービスのデプロイ
```bash
terraform apply
```

## 検証方法

### 1. ECSタスクの状態確認
```bash
aws ecs describe-services \
  --cluster tsaeki-dev-cluster \
  --services tsaeki-dev-java-service \
  --region ap-northeast-1
```

### 2. CloudWatch ログの確認
```bash
aws logs tail /ecs/tsaeki-dev-java --follow --region ap-northeast-1
aws logs tail /ecs/tsaeki-dev-jmx-exporter --follow --region ap-northeast-1
```

### 3. アプリケーションへのアクセス
ALB DNS名を取得:
```bash
terraform output alb_dns_name
```

エンドポイントにアクセス:
```bash
ALB_DNS="<your-alb-dns-name>"
curl http://${ALB_DNS}:8080/
curl http://${ALB_DNS}:8080/health
curl http://${ALB_DNS}:9090/metrics  # JMX Exporter metrics
```

### 4. CloudWatch Metricsの確認
AWS Management ConsoleまたはCLIでメトリクスを確認:

```bash
# メトリクス一覧を取得
aws cloudwatch list-metrics \
  --namespace JavaApp/JMX \
  --region ap-northeast-1

# 特定のメトリクスデータを取得（例：JVMヒープメモリ使用量）
aws cloudwatch get-metric-statistics \
  --namespace JavaApp/JMX \
  --metric-name jvm_memory_bytes_used \
  --dimensions Name=area,Value=heap \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --region ap-northeast-1
```

または、AWS Management Consoleで:
1. CloudWatchコンソールを開く
2. 「メトリクス」→「すべてのメトリクス」を選択
3. カスタム名前空間「JavaApp/JMX」を選択
4. 利用可能なメトリクスを確認・グラフ化

## JMX設定

### Java Application
以下のJVMオプションでJMXを有効化:
```
-Dcom.sun.management.jmxremote
-Dcom.sun.management.jmxremote.port=9010
-Dcom.sun.management.jmxremote.rmi.port=9010
-Dcom.sun.management.jmxremote.local.only=false
-Dcom.sun.management.jmxremote.authenticate=false
-Dcom.sun.management.jmxremote.ssl=false
```

### JMX Exporter Sidecar
- Bitnami JMX Exporterイメージを使用
- Port 5556でPrometheus形式のメトリクスを公開
- Java Applicationコンテナの起動後に開始

### CloudWatch Agent Sidecar
- Amazon CloudWatch Agentイメージを使用
- JMX ExporterからPrometheus形式のメトリクスをスクレイプ
- CloudWatch Metricsに名前空間 `JavaApp/JMX` でメトリクスを送信
- スクレイプ間隔: 1分
- 収集メトリクス: JVM、Java、プロセス関連のすべてのメトリクス

## トラブルシューティング

### タスクが起動しない場合
1. CloudWatch Logsを確認
2. セキュリティグループの設定を確認
3. ECRイメージが正しくプッシュされているか確認

### JMXメトリクスが取得できない場合
1. JMX Exporterのログを確認
2. Javaアプリケーションが正しくJMXを有効化しているか確認
3. コンテナ間通信が正しく設定されているか確認

### CloudWatch Metricsにメトリクスが表示されない場合
1. CloudWatch Agentのログを確認:
   ```bash
   aws logs tail /ecs/tsaeki-dev-cloudwatch-agent --follow --region ap-northeast-1
   ```
2. IAMロールに `cloudwatch:PutMetricData` 権限があるか確認
3. JMX Exporterが正しくメトリクスを公開しているか確認
4. タスク定義でCloudWatch Agentの環境変数が正しく設定されているか確認

## 参考リンク

- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Prometheus JMX Exporter](https://github.com/prometheus/jmx_exporter)
- [AWS ECS Task Definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)
