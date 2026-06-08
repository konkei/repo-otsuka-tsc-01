# GitHub Actions + OIDC + Azure Lighthouse による Azure 自動展開手順

# 1. 概要

## 1.1 本書の目的
GitHub Actions、OIDC、および Azure Lighthouse を利用し、複数顧客の Azure 環境へ Bicep を利用して自動展開するための構成および運用手順をまとめる。

---

## 1.2 システム構成概要

```
GitHub Actions
↓
OIDC認証
↓
管理テナント
↓
Azure Lighthouse
↓
顧客サブスクリプション
↓
Azure Resource Manager
↓
Bicepデプロイ
```

---

## 1.3 特徴

- GitHub Actions から Azure へ自動展開
- OIDC認証により Client Secret 不要
- Azure Lighthouse により別テナント・別サブスクリプションへ展開可能
- 共通 Bicep テンプレートを利用
- 顧客ごとの差異はサブスクリプション単位で管理
- 顧客追加時に Workflow 修正不要
- サブスクリプションID、リソースグループ、リージョンを実行時に指定可能

---

## 1.4 目次

```
1. 概要
2. 前提条件

3. 事前準備（構築担当）
4. リポジトリ構成（構築担当）

5. デプロイ対象追加手順（開発担当）

6. デプロイ手順（運用担当）
7. 顧客追加手順（運用担当）
8. 顧客削除手順（運用担当）

9. 今後の拡張候補
```

---

# 2. 前提条件

## Azure

- Microsoft Entra ID
- Azure Subscription
- Azure Lighthouse
- Azure Resource Manager
- Azure CLI

## GitHub

- GitHub Repository
- GitHub Actions

## 運用端末

- Visual Studio Code
- Git for Windows
- Azure CLI

---

# 3. 事前準備（構築担当）

## 3.1 Entra ID アプリ登録
取得する情報

```
アプリケーション (クライアント) ID
テナント ID
```

---

## 3.2 Federated Credential 作成
設定例

```
Organization : KeitaKondou-Otsuka
Repository   : repo-16427-01
Branch       : main
```
Subject

```
repo:KeitaKondou-Otsuka/repo-16427-01:ref:refs/heads/main
```

---

## 3.3 Azure RBAC設定
推奨ロール

```
Network Contributor
```

---

## 3.4 Azure Lighthouse設定
顧客サブスクリプションを管理テナントへ委任する。

---

## 3.5 GitHub Secrets設定
登録

```
AZURE_CLIENT_ID
AZURE_TENANT_ID
```

---

# 4. リポジトリ構成（構築担当）

## 4.1 GitHub Repository作成

```
repo-16427-01
```

---

## 4.2 リポジトリ構成

```
repo-16427-01
│
├─ .github
│  └─ workflows
│     ├─ deploy-azure-vnet.yml
│     ├─ deploy-azure-nsg.yml
│     ├─ deploy-azure-route.yml
│     └─ deploy-azure-firewall.yml
│
├─ infra
│  ├─ azure-vnet.bicep
│  ├─ azure-nsg.bicep
│  ├─ azure-route.bicep
│  └─ azure-firewall.bicep
│
└─ parameters
   └─ 
      ├─ azure-vnet.bicepparam
      ├─ azure-nsg.bicepparam
      ├─ azure-route.bicepparam
      └─ azure-firewall.bicepparam
```

---

## 4.3 Bicepファイル例
ファイル

```
infra/azure-vnet.bicep
```

```
param location string = resourceGroup().location

param vnetName string
param vnetAddressPrefix string

param subnetName string
param subnetAddressPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location

  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }

    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}
```

---

## 4.4 Bicep Parameterファイル例
ファイル

```
parameters//azure-vnet.bicepparam
```
例

```
parameters/960812fb-xxxx-xxxx-xxxx-xxxxxxxxxxxx/azure-vnet.bicepparam
```

```
using '../../infra/azure-vnet.bicep'

param vnetName = 'vnet-16427-hama'
param vnetAddressPrefix = '10.10.0.0/16'

param subnetName = 'snet-16427-hama'
param subnetAddressPrefix = '10.10.1.0/24'
```

---

## 4.5 GitHub Actions Workflow例
ファイル

```
.github/workflows/deploy-azure-vnet.yml
```
（現在利用中の Workflow を配置）

---

# 5. デプロイ対象追加手順（開発担当）

## 5.1 Bicepファイル作成

```
infra
├─ azure-vnet.bicep
├─ azure-nsg.bicep
├─ azure-route.bicep
└─ azure-firewall.bicep
```

---

## 5.2 Bicep Parameterファイル作成

```
parameters
└─ 
   ├─ azure-vnet.bicepparam
   ├─ azure-nsg.bicepparam
   ├─ azure-route.bicepparam
   └─ azure-firewall.bicepparam
```

---

## 5.3 GitHub Actions Workflow作成

```
.github
└─ workflows
   ├─ deploy-azure-vnet.yml
   ├─ deploy-azure-nsg.yml
   ├─ deploy-azure-route.yml
   └─ deploy-azure-firewall.yml
```

---

## 5.4 GitHubへ反映

```
git add .
git commit -m "Add deployment template"
git push
```

---

# 6. デプロイ手順（運用担当）

## 6.1 リソースグループ作成
Azure Portal にてリソースグループを作成する。

控える情報

```
サブスクリプションID
リソースグループ名
リージョン
```
確認ファイル

```
parameters//azure-vnet.bicepparam
```

---

## 6.2 GitHub Actions実行
入力

```
subscriptionId
resourceGroup
location
```

---

## 6.3 デプロイ結果確認
確認項目

```
Azure Login with OIDC
Deploy VNet
```
Azure Portal にて VNet および Subnet が作成されていることを確認する。

---

# 7. 顧客追加手順（運用担当）

## 7.1 Azure Lighthouse委任
顧客サブスクリプションを管理テナントへ委任する。

---

## 7.2 RBAC確認
GitHubActions-repo16427 が対象サブスクリプションへアクセスできることを確認する。

---

## 7.3 パラメータファイル追加

```
parameters
└─ 
   ├─ azure-vnet.bicepparam
   ├─ azure-nsg.bicepparam
   ├─ azure-route.bicepparam
   └─ azure-firewall.bicepparam
```
必要なサービスのみ作成する。

---

## 7.4 GitHubへ反映

```
git add .
git commit -m "Add new customer"
git push
```

---

## 7.5 顧客利用開始
Workflow 実行時に対象サブスクリプションIDを指定してデプロイする。

---

# 8. 顧客削除手順（運用担当）

## 8.1 Lighthouse委任解除
対象顧客サブスクリプションの委任を解除する。

---

## 8.2 パラメータファイル削除

```
parameters
└─ 
   ├─ azure-vnet.bicepparam
   ├─ azure-nsg.bicepparam
   ├─ azure-route.bicepparam
   └─ azure-firewall.bicepparam
```
不要なファイルを削除する。

---

## 8.3 GitHubへ反映

```
git add .
git commit -m "Remove customer"
git push
```

---

# 9. 今後の拡張候補

- What-If 実装
- Bastion展開
- Hub-Spoke構成展開
- Azure Policy適用
- タグ標準化
- Front Door展開
- Application Gateway展開
- Azure Monitor展開
- Log Analytics Workspace展開
- Azure Backup展開
