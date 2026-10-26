# macOS 签名与公证

## 本地开发

`scripts/build-app.sh` 按以下顺序选择签名身份：

1. 环境变量 `CODE_SIGN_IDENTITY`
2. 钥匙串中的 `Developer ID Application` 证书
3. 钥匙串中的 `Apple Development` 证书
4. ad-hoc 签名

如果已经通过 Xcode 登录 Apple 开发者账号，可以在 Xcode 的
`Settings → Accounts → Manage Certificates` 创建 `Apple Development`
证书，然后重新构建：

```bash
./scripts/build-app.sh
```

也可以显式指定证书名称：

```bash
CODE_SIGN_IDENTITY="Apple Development: Your Name (TEAMID)" \
  ./scripts/build-app.sh
```

稳定的签名身份可以让 macOS 的输入监控授权更容易跨构建保留。ad-hoc
签名不包含可公开验证的身份；重新构建后，如果 macOS 将其视为新程序，
需要在“隐私与安全性 → 输入监控”中重新授权。

## GitHub Release

面向其他用户分发时，需要 Apple Developer Program 账号和
`Developer ID Application` 证书。仓库内的 Release workflow 会：

1. 运行测试
2. 使用 Developer ID 签名并启用 Hardened Runtime
3. 提交 Apple notarization
4. 将公证票据 staple 到 `.app`
5. 创建 GitHub Release 并上传 ZIP

在仓库 `Settings → Secrets and variables → Actions` 添加：

| Secret | 内容 |
| --- | --- |
| `BUILD_CERTIFICATE_BASE64` | 导出的 Developer ID `.p12` 的 Base64 |
| `P12_PASSWORD` | `.p12` 导出密码 |
| `KEYCHAIN_PASSWORD` | CI 临时钥匙串密码，可随机生成 |
| `APPLE_ID` | Apple Developer 账号 |
| `APPLE_TEAM_ID` | Apple Developer Team ID |
| `APPLE_APP_SPECIFIC_PASSWORD` | Apple ID app-specific password |

本地导出证书的 Base64：

```bash
base64 -i DeveloperIDApplication.p12 | pbcopy
```

配置完成后，推送版本标签即可触发：

```bash
git tag v0.1.0
git push origin v0.1.0
```

如果未配置证书 Secrets，workflow 仍会生成 ad-hoc Release。用户可以
右键应用选择“打开”，或者从源码自行构建，但应用不会通过 Gatekeeper
的公证检查。
