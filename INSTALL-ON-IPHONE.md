# 在 iPhone 17 Pro 上运行「词屿」

iPhone 17 Pro 运行的是 iOS 26，而「词屿」原生工程最低支持 iOS 17，因此系统版本没有问题。真正需要解决的是 **安装方式**。

下面按「最省事」到「最原生」排列。

> 不会 GitHub / 不想注册 GitHub？看 [INSTALL-WITHOUT-GITHUB.md](INSTALL-WITHOUT-GITHUB.md)，里面有同一 Wi-Fi 本地运行和 Netlify 拖拽上传两种办法。

---

## 方案 A：网页版 + 添加到主屏幕（推荐，不需要 Mac、不需要签名）

这是最快、最稳的办法。iPhone 17 Pro 的 Safari 对 PWA 支持很好，添加主屏幕后会以接近全屏的方式运行，支持离线、朗读和本地学习记录。

### 1. 把项目传到 GitHub

1. 解压 `词屿-WordIsle.zip`。
2. 登录 GitHub，新建一个 **Public** 仓库（例如 `word-isle`）。
3. 把解压后 **里面的内容** 上传到仓库根目录，确保能看到：
   - `wordisle/`
   - `ios/`
   - `.github/`
   - `README.md`
4. 提交。

> 注意：要上传 `.github` 文件夹，后面的自动部署才会生效。

### 2. 打开 GitHub Pages

1. 进入仓库的 **Settings → Pages**。
2. 在 **Build and deployment → Source** 选择 **GitHub Actions**。
3. 打开仓库的 **Actions** 标签，找到 **Deploy Word Isle PWA**。
4. 如果它没有自动运行，点 **Run workflow**。
5. 等 1–2 分钟，部署成功后会得到地址：

```
https://你的用户名.github.io/word-isle/
```

### 3. 在 iPhone 17 Pro 上安装

1. 用 Safari 打开上面的地址。
2. 点 Safari 底部的 **分享** 按钮。
3. 选择 **添加到主屏幕** → **添加**。
4. 从桌面打开「词屿」。

第一次打开后，Service Worker 会缓存词库和页面；之后即使断网，也能继续背单词。

> 如果仓库是 Private，GitHub Pages 需要付费计划。用 Public 仓库最省事。
> 如果打开是 404，等 1–2 分钟，确认 Pages 的 Source 是 GitHub Actions。

---

## 方案 B：Windows 本地服务器 + 同一 Wi-Fi（不经过 GitHub）

适合只想在同一个 Wi-Fi 下试用、不想上传代码的情况。

1. 在 Windows 解压交付包。
2. 双击 `wordisle/start-server.bat`。
3. 在 Windows 运行 `ipconfig`，找到「IPv4 地址」，例如 `192.168.1.23`。
4. iPhone 17 Pro 用 Safari 打开：

```
http://192.168.1.23:8137/
```

5. 分享 → 添加到主屏幕。

限制：

- 电脑必须开着服务器，iPhone 才能打开。
- 局域网 HTTP 下，Safari 的 Service Worker 可能不启用，因此**离线缓存不保证**。
- 不需要 Mac，不需要 Apple ID，不需要签名。

---

## 方案 C：Windows 上安装原生 IPA（Sideloadly 免费签名）

如果你想要真正的原生 App（不是网页 App），可以通过 GitHub 的 macOS 云构建生成未签名 IPA，再在 Windows 上用 Sideloadly 用你的 Apple ID 签名安装。

这条路线**不需要 Mac**，但需要 Apple ID，免费账号有 7 天有效期限制。

### 1. 云端构建未签名 IPA

1. 把项目传到 GitHub（同方案 A）。
2. 打开 **Actions → Build unsigned IPA → Run workflow**。
3. 等 macOS runner 构建完成（通常 2–5 分钟）。
4. 在 run 页面底部下载 **Artifacts → WordIsle-unsigned-ipa**。
5. 解压得到 `WordIsle-unsigned.ipa`。

> 这个 IPA 是未签名的，不能直接安装，必须用 Sideloadly / AltStore 用你的 Apple ID 重签。

### 2. Windows 上安装 Sideloadly

1. 下载并安装 [Sideloadly](https://sideloadly.io/)。
2. 如果 Windows 缺少 Apple 驱动，安装 Apple 官网版 iTunes（不要只用 Microsoft Store 精简版）或 iCloud。
3. 用数据线连接 iPhone 17 Pro，解锁并点「信任此电脑」。
4. 打开 Sideloadly：
   - IPA 选择 `WordIsle-unsigned.ipa`
   - 设备选择你的 iPhone
   - Apple ID 填你的 Apple ID
5. 点 **Start**，输入 Apple ID 密码 / 双重认证验证码。
6. 安装完成后，在 iPhone 上：

**设置 → 通用 → VPN 与设备管理 → 开发者 App → 信任你的 Apple ID**

7. iOS 16 及以上还需要打开：

**设置 → 隐私与安全性 → 开发者模式 → 打开 → 重启 iPhone**

8. 从桌面打开「词屿」。

### 免费 Apple ID 的限制

- 签名 **7 天** 后过期，需要重新用 Sideloadly 安装。
- 免费账号同时最多 3 个自签 App。
- 需要保持 Apple ID 正常，Apple 可能调整免费签名政策。
- 不适合长期日常使用；长期使用建议 Apple Developer Program（$99/年），可用 TestFlight 或 Ad Hoc 分发，签名 1 年。

### 有付费开发者账号时

- 用 TestFlight 分发给自己的设备最省心；
- 或在 Xcode 里用 Ad Hoc 导出，安装到已登记的设备；
- 或直接上架 App Store。

---

## 方案 D：有 Mac 的话

1. 用 Xcode 15+ 打开 `ios/WordIsle.xcodeproj`。
2. 选择 `WordIsle` target → Signing & Capabilities → 选择 Team。
3. 连接 iPhone 17 Pro，选择真机，Run。

这是最标准的原生开发方式。

---

## 怎么选？

| 需求 | 推荐 |
|---|---|
| 现在就想用，不折腾签名 | **方案 A：GitHub Pages PWA** |
| 只想在同一 Wi-Fi 下试用 | 方案 B：Windows 本地服务器 |
| 一定要原生 App，且没有 Mac | 方案 C：云端 IPA + Sideloadly |
| 有 Mac / 想长期使用 / 上架 | 方案 D 或付费开发者账号 |

如果你只是想在 iPhone 17 Pro 上背单词，**方案 A 完全够用**：不需要 Mac、不需要 Apple ID 开发者账号、不需要 7 天重签，而且支持离线。
