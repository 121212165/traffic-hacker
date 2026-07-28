# traffic-hacker 可AI重构文档（上游基线+自研增量型）

> **一句话定位**：traffic-hacker（流量黑客）是第三方开源短链归因平台 Dub（github.com/dubinc/dub，AGPL-3.0）monorepo 的白标 fork，目标是在 Vercel Hobby 计划上完成自部署（含 21 个部署适配提交），并附自研 video/ 宣传视频生成流水线与 3 个 Vercel 部署运维 PowerShell 脚本。
> **生成日期**：2026-07-28
> **文档类型声明**：本项目主体（4296 个被跟踪文件、约 43 万行）为第三方开源 Dub 的副本，上游公开可得，本文档**不做**上游全量文档化，只做"上游基线声明 + 自研增量部分的精确级复现"。
> **密钥零收录声明**：本文档不含任何真实密钥/token/连接串。部署脚本中出现的 Vercel 资源标识（prj_/team_/dpl_ 前缀 ID）已统一以 `<占位>` 替代并标注；仅收录 `.env.example`（空模板）；全程未读取 `apps/web/.env`、`apps/web/.vercel/.env.production.local` 及任何真实环境文件。

---

## 1. 项目定位与上游基线

### 1.1 上游项目

| 项 | 值 |
|---|---|
| 上游仓库 | https://github.com/dubinc/dub |
| 上游许可证 | AGPL-3.0-or-later（根 `LICENSE.md` 完整保留；`apps/web/app/(ee)/` 下另有 Dub EE 商业许可） |
| monorepo 名 | `dub-monorepo`（根 package.json name 未改，license 字段 `AGPL-3.0-or-later`） |
| 包管理器 | `pnpm@9.15.9`（packageManager 字段锁定），turbo ^1.12.5 编排 |
| 主应用 | `apps/web`（Next.js App Router，本地端口 8888）；packages/ 含 @dub/ui、@dub/utils、@dub/email 等 10 个工作区包 |
| 上游基线版本 | **无法精确到上游 commit**：根提交 6c4088a（2026-07-24）为 squash 导入，未保留上游历史。判定为 dubinc/dub main 于 **2026-07-24 前后**的状态（旁证：Stripe apiVersion `2025-05-28.basil`） |

### 1.2 git 探查结论（只读探查，2026-07-28 执行）

```
$ git remote -v
origin  https://github.com/121212165/traffic-hacker.git (fetch/push)

$ git log --oneline --all --not --remotes -20
（空 —— 无本地独有提交，本地与 origin 完全同步）

$ git rev-list --count HEAD
22（= 1 个上游 squash 导入根提交 + 21 个本地增量提交，全部已推送）
```

**完整提交史（22 个，旧→新，即"本地修改过程日志"）**：
```
6c4088a 2026-07-24 TrafficHacker: self-hosted short-link + UTM + attribution platform
                   (based on Dub) with promo video pipeline   ← 上游快照 + video/ 一并导入
e4a3726 build: ignore TS/ESLint errors during build for white-label fork deploy
7daf26e chore: trigger Vercel cloud build with rootDirectory=apps/web
b9d7017 chore: trigger cloud build (git connected, rootDirectory set)
2d36c5b build: reduce webpack peak memory (parallelism=1, memory opt, no fs cache) to fix Vercel build OOM
bccaad0 chore: redeploy with corrected env values + webpack memory fix
5b2ff65 chore: redeploy with populated production env vars
266818c fix(stripe): guard empty key to avoid build-time page-data crash (white-label)
713409d fix(vector): guard missing Upstash Vector creds to avoid build crash (white-label)
af0b357 fix(build): getProgramSlugs falls back to [] when DB unreachable at build
3ef3d49 fix(build): force marketplace dynamic + guard DB in static params (white-label)
cc96e22 fix(build): serialize static page generation (cpus=1) to avoid export OOM
0598ce7 fix(build): run /api/links/exists on nodejs to avoid Edge 1MB limit
c50e3a1 fix(build): move all remaining Edge API routes to nodejs (avoid 1MB Edge limit)
1511bfc fix(build): move password/inspect pages to nodejs; drop stray build logs
dd41382 fix(build): move og-image (qr, avatar) routes to nodejs (Edge 1MB limit)
86693ab fix(deploy): minimal middleware to fit Hobby Edge 1MB limit
8534ed9 fix: remove explicit runtime exports so routes bundle into shared functions (Hobby 12-function limit)
1eda4f2 fix: cap maxDuration at 300s for Hobby plan (was 600)
80e4ad8 feat: restore full middleware and route vercel.app domain to app (white-label)
b291ea6 fix: re-encode middleware.ts as UTF-8
28b400f 2026-07-26 fix: exempt APP_HOSTNAMES from vercel.app domain rewrite in middleware parse  ← HEAD
```

**工作区状态**（`git status --porcelain`，共 15 个未跟踪文件，无已跟踪文件改动）：
```
?? apps/web/{api,dbg,inspect1,list,patch,whoami}.log   # 部署排障日志（要点见 §6）
?? apps/web/body.json                                   # vercel api PATCH 请求体草稿
?? apps/web/check-url.js  parse-api-log.js  parse-deploys.js   # 排障辅助 JS（§4.8）
?? disable-protection.ps1  get-deploy-error.ps1  refresh-and-inspect.ps1  # 部署脚本（§4.7）
?? screenshot_login_live.jpg  screenshot_register_live.jpg     # 线上验证截图
```

### 1.3 与 flus 项目的关系

本机 flus 项目（ModelScope 创空间副本）的全部被跟踪文件与本仓库 HEAD=28b400f **逐字节一致**（已哈希比对验证，flus 仅多一个平台生成的 .gitattributes）。本仓库是"源"，flus 是其 squash 快照。

---

## 2. 上游复原方法

### 2.1 获取同版本上游

```bash
# 精确复现本仓库：直接 clone fork（含全部 22 个提交）
git clone https://github.com/121212165/traffic-hacker.git
cd traffic-hacker && git checkout 28b400f

# 从上游 Dub 复原基线（再手工应用第 3 节修改）：
git clone https://github.com/dubinc/dub.git traffic-hacker
cd traffic-hacker
git checkout $(git rev-list -1 --before="2026-07-24" main)
```

### 2.2 环境要求

```bash
node >= 18（建议 20 LTS）
corepack enable && corepack prepare pnpm@9.15.9 --activate   # 必须 pnpm 9.15.9
pnpm install
pnpm build:packages          # 先构建 packages/**（本仓库留有 build-packages.log 佐证此步骤）
cd apps/web && pnpm dev      # http://localhost:8888
```

### 2.3 apps/web/.env.example 逐字收录（192 行，空模板值，非真实密钥）

```bash
###############################
###### REQUIRED ENV VARS ######
###############################

# Generate secrets with: node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
NEXTAUTH_SECRET=
NEXTAUTH_URL=http://localhost:8888 # (only needed for localhost)
# Secret for Vercel cron jobs (https://vercel.com/docs/cron-jobs/manage-cron-jobs#securing-cron-jobs)
CRON_SECRET=
# Encryption key (AES-256-GCM) for encrypting sensitive data in the database
ENCRYPTION_KEY=
# Email unsubscribe token secret (optional, falls back to NEXTAUTH_SECRET)
UNSUBSCRIBE_TOKEN_SECRET=

# MySQL Database via Planetscale
# Get your MySQL Database URL here: https://planetscale.com/docs/tutorials/connect-nodejs-app
DATABASE_URL="mysql://root:@localhost:3306/planetscale"
# Set local development documentation for connecting to a local database: https://dub.co/docs/local-development#step-4-set-up-planetscale-mysql-database
PLANETSCALE_DATABASE_URL="http://root:unused@localhost:3900/planetscale"

# Upstash Redis – required for Redis caching
# Get your Redis REST URL and Token here: https://upstash.com/docs/redis/overall/getstarted
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=

# Upstash QStash – required for queues and background jobs
# Get your QStash Token here: https://upstash.com/docs/qstash/overall/getstarted
QSTASH_URL="https://qstash-us-east-1.upstash.io"
QSTASH_TOKEN=
QSTASH_CURRENT_SIGNING_KEY=
QSTASH_NEXT_SIGNING_KEY=

# Tinybird – required for analytics 
# Get your Tinybird Auth Token here: https://www.tinybird.co/docs/concepts/auth-tokens.html
TINYBIRD_API_KEY=
# Varies based on your Tinybird region: https://www.tinybird.co/docs/api-reference/api-reference.html#regions-and-endpoints
TINYBIRD_API_URL=https://api.tinybird.co

# Vercel's Domains API – required for adding and removing domains
# Learn how to set this up: https://vercel.com/templates/next.js/domains-api
TEAM_ID_VERCEL=
VERCEL_API_KEY=

# Required for email login
# Get your Resend API Key here: https://resend.com/api-keys
RESEND_API_KEY=
# Resend webhook secret for webhook verification
RESEND_WEBHOOK_SECRET=

# SMTP configuration (Recommended for local development)
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_USER=smtpUser
SMTP_PASSWORD=smtpPassword

###############################
###### OPTIONAL ENV VARS ######
###############################

# Stripe – used for subscriptions
# If you don't need this, you can also remove the `lib/stripe` folder and all instances of `stripe` from the codebase
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
STRIPE_CONNECT_WEBHOOK_SECRET=
STRIPE_CONNECT_V2_WEBHOOK_SECRET=

# Stripe Integration
STRIPE_APP_WEBHOOK_SECRET=
STRIPE_APP_SECRET_KEY=
STRIPE_APP_SECRET_KEY_TEST=
STRIPE_APP_SECRET_KEY_SANDBOX=

# Shopify App webhook events
SHOPIFY_WEBHOOK_SECRET=

# Used for Google Login
# Learn how to set this up here: https://next-auth.js.org/providers/google
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# Used for GitHub Login
# Learn how to set this up here: https://next-auth.js.org/providers/github
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=

# Edge Config – used for admin features like banning users, rate limiting etc.
# Create one here: https://vercel.com/docs/storage/edge-config
# Alternatively, if you don't need this, you can also remove `lib/edge-config.ts`
# and all instances of `EDGE_CONFIG` and `EDGE_CONFIG_ID` from the codebase
EDGE_CONFIG=
EDGE_CONFIG_ID=

# Bitly Importer: https://dub.co/blog/migration-assistants
# Apply for an API key here: https://dev.bitly.com/
BITLY_CLIENT_ID=
BITLY_CLIENT_SECRET=

# Used for Custom Link Previews feature
# Apply for an API key here: https://unsplash.com/developers
UNSPLASH_ACCESS_KEY=

# Use for storing image assets
STORAGE_ACCESS_KEY_ID=
STORAGE_SECRET_ACCESS_KEY=
STORAGE_ENDPOINT=
STORAGE_BASE_URL=
STORAGE_PUBLIC_BUCKET=
STORAGE_PRIVATE_BUCKET=

# Used for internal monitoring & paging
# You can remove this by removing `DUB_SLACK_HOOK_CRON` and `DUB_SLACK_HOOK_LINKS` from the codebase
DUB_SLACK_HOOK_CRON=
DUB_SLACK_HOOK_LINKS=

# Slack Dub Support integration
DUB_SLACK_ASSISTANT_BOT_TOKEN=

# Used for background jobs
# Get your ngrok URL here: https://ngrok.com/
NEXT_PUBLIC_NGROK_URL=

# For AI features
ANTHROPIC_API_KEY=

# Axiom – used for logging and monitoring
# Get your Axiom token here: https://axiom.co/docs/rest-api/authentication
AXIOM_TOKEN=
AXIOM_DATASET=

# Plain – used for customer support integration
# Get your Plain API key here: https://www.plain.com/docs/api
PLAIN_API_KEY=
PLAIN_WEBHOOK_SECRET=

######################################
###### DUB.CO INTERNAL USE ONLY ######
######################################

# For storing vector embeddings (/api/support/chat)
UPSTASH_VECTOR_REST_URL=
UPSTASH_VECTOR_REST_TOKEN=

# Slack integration
SLACK_CLIENT_ID=
SLACK_CLIENT_SECRET=
SLACK_SIGNING_SECRET=

# Dynadot API key for domain registration
DYNADOT_API_KEY=
DYNADOT_BASE_URL=
DYNADOT_COUPON=

# Partner Platforms Verification
TWITTER_CLIENT_ID=
TWITTER_CLIENT_SECRET=
TIKTOK_CLIENT_ID=
TIKTOK_CLIENT_SECRET=
YOUTUBE_API_KEY=

# Scrape Creators
SCRAPECREATORS_API_KEY=

# Paypal
PAYPAL_CLIENT_ID=
PAYPAL_CLIENT_SECRET=
PAYPAL_WEBHOOK_ID=

# Tremendous
TREMENDOUS_API_KEY=

# Program lander generation
FIRECRAWL_API_KEY=

# for generating planetscale backups (https://planetscale.com/docs/api/service-tokens)
PLANETSCALE_SERVICE_TOKEN=

# Hubspot integration
HUBSPOT_CLIENT_ID=
HUBSPOT_CLIENT_SECRET=

# Intercom integration
INTERCOM_CLIENT_ID=
INTERCOM_CLIENT_SECRET=

# E2E Playwright Tests
E2E_PARTNER_EMAIL=
E2E_PARTNER_PASSWORD=

# Veriff (Identity Verification)
VERIFF_API_KEY=
VERIFF_SHARED_SECRET=
```

---

## 3. 本地修改清单（HEAD 相对根提交 6c4088a，共 24 个文件，+94/-55 行）

`git diff --stat 6c4088a..HEAD` 确认改动全部集中在 apps/web 与 packages/utils，分三类：

### 3.1 白标域名改造（功能性）

**`packages/utils/src/constants/main.ts`**（把生产 APP 域指向自有 Vercel 部署）：
```diff
 export const APP_HOSTNAMES = new Set([
+  "traffic-hacker-l-jhs-projects.vercel.app",
+  "traffic-hacker-git-main-l-jhs-projects.vercel.app",
   "app.dub.co", "preview.dub.co", "localhost:8888", ...
 export const APP_DOMAIN = production
-    ? "https://app.dub.co"
+    ? "https://traffic-hacker-l-jhs-projects.vercel.app"
 export const APP_DOMAIN_WITH_NGROK = production（同样改为上述 vercel.app 域名）
```

**`apps/web/lib/middleware/utils/parse.ts`**（上游把所有 `*.vercel.app` 当短链域重写；豁免 APP_HOSTNAMES 使自有 vercel.app 域名走应用面板，commit 28b400f）：
```diff
-import { SHORT_DOMAIN } from "@dub/utils";
+import { APP_HOSTNAMES, SHORT_DOMAIN } from "@dub/utils";
-  if (domain === "dub.localhost:8888" || domain.endsWith(".vercel.app")) {
+  if (
+    domain === "dub.localhost:8888" ||
+    (domain.endsWith(".vercel.app") && !APP_HOSTNAMES.has(domain))
+  ) {
```
（middleware.ts 本身曾为绕过 Edge 1MB 限制被精简（86693ab），后在 80e4ad8 完整恢复，最终与上游一致。）

### 3.2 Vercel Hobby 计划部署适配

**`apps/web/next.config.js`**（+29 行）：
```js
typescript: { ignoreBuildErrors: true },      // 跳过类型检查（偶发重复 @types/react 引用错）
eslint: { ignoreDuringBuilds: true },
experimental: {
  webpackMemoryOptimizations: true,           // 压低 webpack 峰值内存
  cpus: 1, workerThreads: false,              // 静态导出(~300页)串行化，防 8GB 容器 OOM
  ...
},
// webpack 回调内追加：
config.parallelism = 1; config.cache = false;
config.optimization.minimize = true;
// 所有 minimizer 的 options.parallel = false（单线程压缩，内存有界）
```

**删除 `export const runtime = "edge";`**（Edge 1MB 体积限制 + Hobby 12 函数限制），11 个文件：
```
apps/web/app/(ee)/api/shopify/pixel/route.ts     apps/web/app/api/qr/route.tsx
apps/web/app/[domain]/[key]/inspect/page.tsx     apps/web/app/api/route.ts
apps/web/app/api/links/exists/route.ts           apps/web/app/api/unsplash/search/route.ts
apps/web/app/api/links/iframeable/route.ts       apps/web/app/api/og/avatar/[[...seed]]/route.tsx
apps/web/app/api/links/metatags/route.ts         apps/web/app/password/[linkId]/page.tsx
apps/web/app/api/providers/route.ts
```

**`maxDuration` 600 → 300**（Hobby 上限 300s），4 个文件：
```
apps/web/app/(ee)/api/cron/domains/renewal-succeeded/route.ts
apps/web/app/(ee)/api/cron/payouts/charge-succeeded/route.ts
apps/web/app/(ee)/api/cron/payouts/process/route.ts        # 注释: Hobby plan cap (Pro allows up to 900)
apps/web/app/api/jobs/process/[jobName]/route.ts
```

### 3.3 构建期外部服务缺失防护（guard）

| 文件 | 改动要点 |
|---|---|
| `apps/web/lib/stripe/index.ts` | 空 key 回退 `"sk_test_placeholder_build_only"`（模块级 `new Stripe()` 构建期不抛错；stripeAppClient 同理） |
| `apps/web/lib/upstash/vector.ts` | url/token 回退 `"https://placeholder.upstash.io"` / `"placeholder_build_only"` |
| `apps/web/lib/fetchers/get-program-slugs.ts` | prisma 查询包 try/catch，DB 不可达返回 `[]` |
| `apps/web/ui/program-marketplace/pages/marketplace-program-page.tsx` | generateMarketplaceProgramStaticParams 的 prisma 查询包 try/catch，失败跳过预渲染（categoryPages 仍生成） |
| `apps/web/app/(ee)/.../marketplace/[[...segments]]/page.tsx` | 新增 `export const dynamic = "force-dynamic"`；generateStaticParams 直接 `return []` |
| `apps/web/.gitignore` | 新增文件，内容一行：`.vercel` |

---

## 4. 自研增量精确复现【主体】

自研资产两块：**video/ 宣传视频流水线**（已跟踪，随根提交入库）与**部署运维脚本**（未跟踪：3 个 ps1 + 3 个辅助 js）。

### 4.0 video/ 总览

三步流水线 `tts_gen.py → screenshot.py → make_video.py`，共享数据源 `storyboard.py`；素材 = static/ 7 张 1280×720 HTML 卡片 + 真实前端 login/register 截图；产物 `output.mp4`（1280×720、30fps、h264+aac、烧录中文字幕，2.1MB）。本仓库另存有全套中间产物（audio/ 9 个 mp3、shots/ 9 张 png、tmp/ 9+1 个分段 mp4、subtitles.srt），均可再生。
Python 依赖：`edge-tts`、`playwright`（chromium）、`imageio-ffmpeg`。

### 4.1 video/storyboard.py —— 分镜数据源（54 行）

用途：9 镜头的画面来源 + 旁白（唯一数据源）。结构：`SHOTS = [{id, image, narration}, ...]`，image 取值 `static/xxx.html`（file:// 截图 1280×720）或 `frontend:login|register`（真实前端 880×720）。9 条旁白逐字收录：

| id | image | narration（逐字） |
|---|---|---|
| 01 | static/title.html | 流量黑客，TrafficHacker。一套自建的短链归因平台，把每一次点击的来路和转化，都攥在自己手里。 |
| 02 | static/problem.html | 投放花了钱，转化却算不清。渠道、活动、落地页，数据散落各处，归因全靠猜。 |
| 03 | static/features.html | 流量黑客把三件事合成一件：短链管理、UTM追踪、转化归因，一个看板全搞定。 |
| 04 | frontend:login | 打开应用，这是你自己的登录入口。数据自建自控，不经过任何第三方。 |
| 05 | frontend:register | 三十秒注册，创建你的专属工作区，马上开始建链。 |
| 06 | static/shortlink.html | 为每条投放生成品牌短链。自定义域名、二维码、备注标签，一键复制分发。 |
| 07 | static/utm.html | 自动带上UTM参数，点击实时入库。地域、设备、来源渠道，清清楚楚。 |
| 08 | static/attribution.html | 从点击，到注册，到付费，全链路归因。哪个渠道真正带来收入，一眼看穿。 |
| 09 | static/ending.html | 开源、自建、可一键部署到Vercel。流量黑客，让你的增长数据，真正属于你。 |

### 4.2 video/tts_gen.py —— edge-tts 配音（30 行，全文收录）

用途：为每条旁白生成 `audio/XX.mp3`。关键参数：`VOICE = "zh-CN-XiaoxiaoNeural"`（自然亲切女声）、`RATE = "-4%"`（略慢）。

```python
"""用 edge-tts 生成所有旁白音频。读 storyboard.py，输出 audio/XX.mp3"""
import asyncio, os, sys
import edge_tts
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from storyboard import SHOTS

AUDIO_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "audio")
os.makedirs(AUDIO_DIR, exist_ok=True)
VOICE = "zh-CN-XiaoxiaoNeural"
RATE = "-4%"

async def gen_one(text: str, out_path: str):
    communicate = edge_tts.Communicate(text, VOICE, rate=RATE)
    await communicate.save(out_path)

async def main():
    for shot in SHOTS:
        out = os.path.join(AUDIO_DIR, f"{shot['id']}.mp3")
        print(f"[TTS] {shot['id']} -> {out}")
        await gen_one(shot["narration"], out)
    print("all done.")

if __name__ == "__main__":
    asyncio.run(main())
```
（原文件 import 分行书写，逻辑与上文逐字一致。）

### 4.3 video/screenshot.py —— Playwright 分镜截图（78 行）

用途：headless Chromium 截 9 张 PNG 到 shots/。输入：static/*.html + 运行中的前端（`APP_URL` 环境变量，默认 `http://localhost:8888`）。

关键逻辑：
- 静态卡片 01/02/03/06/07/08/09：context 视口 1280×720、device_scale_factor=1；`page.goto((STATIC/html).as_uri())` → `wait_for_timeout(700)` → `page.screenshot(clip={"x":0,"y":0,"width":1280,"height":720})`；
- 前端页 04=/login、05=/register：**视口 880×720**（低于上游 900px 断点 → 单列布局），`goto(..., wait_until="networkidle", timeout=120000)` → 等 2500ms → `page.evaluate(CLEAN_JS)`（失败仅打印不中断）→ 等 400ms → 截 880×720。

CLEAN_JS（白标注入脚本，逐字收录）：
```javascript
() => {
  document.querySelectorAll('a[href*="dub.co"]').forEach(a => {
    const p = a.closest('p');
    if (p) p.remove(); else a.remove();
  });
  // 隐藏 Next.js dev 工具指示器（左下角 "N 1 Issue" 徽标）
  document.querySelectorAll('nextjs-portal,[data-nextjs-toast],#__next-build-watcher').forEach(e => e.remove());
  // 中性化 Dub 默认邮箱占位符
  document.querySelectorAll('input[placeholder*="thedis.co"]').forEach(i => { i.placeholder = 'you@company.com'; });
  const brand = document.createElement('div');
  brand.textContent = 'TrafficHacker';
  brand.style.cssText = 'position:fixed;top:16px;left:50%;transform:translateX(-50%);'
    + "font:800 22px -apple-system,'Microsoft YaHei',sans-serif;letter-spacing:1px;"
    + 'color:#111;z-index:9999;';
  document.body.appendChild(brand);
}
```

### 4.4 video/make_video.py —— FFmpeg 合成（149 行）

用途：`shots/XX.png + audio/XX.mp3` → 分段 mp4 → concat → 烧字幕 → `output.mp4`。ffmpeg 二进制经 `imageio_ffmpeg.get_ffmpeg_exe()` 获取。

1. 音频时长：`ffmpeg -i xx.mp3` 的 stderr 正则 `Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)`。
2. 分段合成命令（逐字参数）：
```
ffmpeg -y -loop 1 -i {png} -i {mp3} -c:v libx264 -tune stillimage
  -pix_fmt yuv420p -r 30 -t {dur:.3f} -c:a aac -b:a 192k -shortest
  -vf "scale=1280:720:force_original_aspect_ratio=decrease,
       pad=1280:720:(ow-iw)/2:(oh-ih)/2:color=white,format=yuv420p"  tmp/{id}.mp4
```
   PAD_FILTER 让 880×720 窄图白底居中，不拉伸（login/register 底色为白）。
3. SRT：段时长累加时间轴，`HH:MM:SS,mmm` 格式；`wrap_text(text, max_chars=24)`：先按 `(?<=[，。；！？——])` 分段拼行、超 24 字硬切。
4. 终合成（concat 列表 `tmp/list.txt`，行格式 `file '{posix路径}'`；srt 路径中 `:` 转义为 `\:`）：
```
ffmpeg -y -f concat -safe 0 -i tmp/list.txt
  -vf "subtitles='{srt}':force_style='FontName=Microsoft YaHei,FontSize=22,
       PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BackColour=&HAA000000,
       BorderStyle=4,Outline=0,Shadow=0,Alignment=2,MarginV=40'"
  -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -r 30 -c:a aac -b:a 192k output.mp4
```

### 4.5 video/static/*.html —— 7 张分镜卡片（规格 + 全部文案）

统一规格：1280×720、`overflow:hidden`；字体 `-apple-system,"PingFang SC","Microsoft YaHei",sans-serif` + `"JetBrains Mono",Consolas,monospace`；深色底径向渐变 `#12351f→#0a0e14→#05070b`（problem 页红调 `#331616`）；品牌绿 `#22e07a`/浅绿 `#8bf5b6`；48px 网格叠加（rgba(34,224,122,.06) 线 + radial mask）；kicker 前缀 `▎`。

| 文件 | 布局与全部文案（逐字） |
|---|---|
| title.html | 居中+绿 glow；`SELF-HOSTED LINK ATTRIBUTION`；H1 `流量黑客`(80px 渐变字)；`TrafficHacker`；`自建 · 短链归因平台`；tags `短链管理/UTM 追踪/转化归因` |
| problem.html | `THE PROBLEM`；H1 `投放花了钱，转化却算不清`；三卡：💸`预算在烧`-`多渠道同时投放，钱花出去了，却不知道哪一笔真正带来了增长。`；🧩`数据散落`-`渠道、活动、落地页各说各话，报表拼不到一起，口径永远对不上。`；🎲`归因靠猜`-`从点击到付费中间断了链路，谁的功劳全凭感觉，决策没有依据。` |
| features.html | `ALL-IN-ONE`；H1 `三件事，一个看板全搞定`；三卡带 01/02/03 角标、→ 相连：🔗`短链管理`-`品牌短链、自定义域名、二维码与标签，集中创建、集中分发。`；🎯`UTM 追踪`-`自动携带 UTM 参数，点击实时入库，地域设备来源一目了然。`；📊`转化归因`-`从点击到付费全链路打通，每个渠道的真实贡献看得清清楚楚。` |
| shortlink.html | 左文右 mock；`SHORT LINKS`；H1 `为每条投放/生成品牌短链`；feat `自定义域名，链接自带品牌`/`二维码一键生成，线下也能投`/`备注标签分组管理，一键复制分发`；mock：`th.link/spring → trafficker.app/landing/2026`、CSS 伪二维码、pill `春季campaign`+`微信`、`12,480 次点击`、`th.link/promo → trafficker.app/pricing` |
| utm.html | 左面板右文；urlbar `th.link/spring?utm_source=wechat&utm_medium=cpc&utm_campaign=spring2026`；柱图 微信4.2k(82%)/抖音3.1k(60%)/小红书2.3k(44%)/直接1.5k(30%)/其他980(20%)；`UTM TRACKING`；H1 `自动带上参数/点击实时入库`；feat `来源渠道：谁把人带来的`/`地域设备：在哪、用什么设备`/`实时看板：数据秒级刷新` |
| attribution.html | `FULL-FUNNEL ATTRIBUTION`；H1 `从点击到付费，全链路归因`；漏斗 `点击 12.4k 100%`→`注册 2,180 转化 17.6%`→`付费 396 付费率 18.2%`→`收入归因 ¥58k 按渠道拆分`（柱高 100/52/22/34%） |
| ending.html | tags `🔓 开源`/`🏠 自建自控`/`▲ 一键部署 Vercel`；H1 `让你的增长数据/真正属于你`；`流量黑客 · 短链归因平台`；按钮 `立即部署`(绿)+`查看源码`(描边)；`TrafficHacker` |

### 4.6 video/.gitignore（9 行，全文）

```gitignore
# 可重新生成的视频中间产物（跑 tts_gen/screenshot/make_video 会重建）
audio/
shots/
tmp/
__pycache__/
subtitles.srt

# 保留：*.py 脚本、static/*.html 卡片、output.mp4 成片
```

### 4.7 部署运维 PowerShell 脚本（3 个，未跟踪，位于仓库根）

以下资源 ID 已占位：`<占位:项目ID>`=原 `prj_****` 形式 Vercel 项目 ID；`<占位:团队ID>`=原 `team_****`；`<占位:部署ID>`=原 `dpl_****`。均为资源标识（非密钥），出于安全统一占位；复现者用 `vercel project ls` / `vercel ls` 查询自己的 ID 即可。**三个脚本均不内嵌任何密钥**，token 一律从 Vercel CLI 本机 auth.json 读取且明确"never prints tokens"。

**disable-protection.ps1**（7 行）—— 关闭 Vercel Deployment Protection (SSO)，否则预览/生产 URL 会被 Vercel 登录墙拦截：
```powershell
# Disable Vercel Deployment Protection (SSO) for the project via CLI api.
$ErrorActionPreference = "Continue"
Set-Location "<仓库路径>\apps\web"
$json = '{"ssoProtection":null}'
vercel api "/v9/projects/<占位:项目ID>?teamId=<占位:团队ID>" --method PATCH --body $json *> patch.log
Select-String -Path patch.log -Pattern 'ssoProtection|Error|error' | Select-Object -First 6 | ForEach-Object { $_.Line }
```

**get-deploy-error.ps1**（45 行）—— 读取 Vercel CLI 本机 OAuth token，经 REST API 查询失败部署的错误字段（只打印错误字段，绝不打印 token）。核心逻辑：
```powershell
# 依次探测 auth.json 位置：
#   %USERPROFILE%\AppData\Roaming\com.vercel.cli\Data\auth.json
#   %USERPROFILE%\AppData\Local\com.vercel.cli\auth.json
#   %USERPROFILE%\.vercel\auth.json
$token = (Get-Content $authPath -Raw | ConvertFrom-Json).token
# 仅打印 token 前 8 位与长度、expiresAt（诊断是否过期），绝不打印完整 token
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$headers = @{ Authorization = "Bearer $token" }
$deploymentId = "<占位:部署ID>"; $teamId = "<占位:团队ID>"
# 1) GET https://api.vercel.com/v2/user            → 验证 token 有效（打印 username）
# 2) GET https://api.vercel.com/v13/deployments/$deploymentId?teamId=$teamId
#    → 打印 readyState / errorCode / errorMessage / errorStep
# 两处均 try/catch，异常时输出 $_.ErrorDetails.Message
```

**refresh-and-inspect.ps1**（65 行）—— 当 CLI token 过期时，用 auth.json 内的 refresh_token 换取新 access_token，再查部署错误，最后把刷新后的 token 写回 auth.json（同样绝不打印明文 token）。核心逻辑：
```powershell
$auth = Get-Content $authPath -Raw | ConvertFrom-Json   # Roaming\com.vercel.cli\Data\auth.json
if (-not $auth.refreshToken) { "NO REFRESH TOKEN"; exit 1 }
# 从 CLI bundle 提取 OAuth client_id 与 token endpoint：
$vcjs = "$env:APPDATA\npm\node_modules\vercel\dist\vc.js"    # 实际路径按本机 npm 全局目录
$raw = Get-Content $vcjs -Raw
$clientId = ([regex]::Matches($raw,'cl_[A-Za-z0-9]{8,}') | % Value | Sort -Unique)[0]
$eps = [regex]::Matches($raw,'https://[a-z\.]*vercel\.com/[a-z/_\-]*token[a-z/_\-]*') | % Value | Sort -Unique
$body = @{ client_id=$clientId; grant_type="refresh_token"; refresh_token=$auth.refreshToken }
$tokenUrl = if ($eps) { $eps[0] } else { "https://vercel.com/api/login/oauth/token" }
$tk = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body   # 仅打印 access_token.Length
# 用新 token 查 GET /v13/deployments/<占位:部署ID>?teamId=<占位:团队ID>
#   → 打印 readyState / errorCode / errorMessage / errorStep / errorLink
# 回写：$auth.token / refreshToken / expiresAt → auth.json（UTF8）
```
> 安全说明：此脚本读取 CLI 凭据文件（含 refresh_token）并回写。文档不收录任何 token；复现者应确保 auth.json 仅本机可读，勿将其纳入版本控制。

### 4.8 排障辅助 JS（3 个，未跟踪，位于 apps/web/）

均为 Node 无依赖小工具，用于解析 Vercel API 返回（常见 UTF-16LE/BOM 编码）：
- **check-url.js**（14 行）：`https.get(url)` 探测线上 login 页，打印 status/location/body 前 300 字/`<title>`。默认 URL 为自有 vercel.app 域。
- **parse-api-log.js**（27 行）：读日志文件（自动识别 utf8/utf16le/BOM），提取首个 JSON 对象，打印 readyState/errorCode/errorMessage/errorStep/errorLink。
- **parse-deploys.js**（34 行）：解析部署列表/详情 JSON（含正则兜底），打印 uid/state/readySubstate/sha/url/errorCode。

---

## 5. 从零复现步骤

```bash
# 1. 获取基线
git clone https://github.com/121212165/traffic-hacker.git && cd traffic-hacker
git checkout 28b400f          # 或从 dubinc/dub 复原后手工应用第 3 节 24 处修改

# 2. Web 应用
corepack prepare pnpm@9.15.9 --activate
pnpm install && pnpm build:packages
cp apps/web/.env.example apps/web/.env    # 按 §2.3 键位填自己的凭据（切勿提交）
cd apps/web && pnpm dev                    # http://localhost:8888

# 3. 视频流水线（自研，脚本放入 video/）
pip install edge-tts playwright imageio-ffmpeg
playwright install chromium
cd video
python tts_gen.py     # audio/01-09.mp3（联网）
python screenshot.py  # shots/01-09.png（04/05 需前端已启动；APP_URL 可覆盖目标）
python make_video.py  # subtitles.srt + output.mp4

# 4. Vercel 部署（Hobby 计划）
#   - 第 3 节的 next.config.js/runtime/maxDuration/guard 修改必须就位
#   - Vercel 项目 rootDirectory 设为 apps/web
#   - 在 Vercel 面板逐项配置 §2.3 生产环境变量（勿写入仓库）
#   - 部署后如遇 SSO 登录墙，运行 disable-protection.ps1（填自己的 prj_/team_ ID）
#   - 部署失败排障：get-deploy-error.ps1 / refresh-and-inspect.ps1 + parse-*.js
```

---

## 6. 不可文本化资产与已知问题

### 6.1 不可文本化资产 / 未收录内容

| 资产 | 说明 |
|---|---|
| `video/output.mp4` | 2.1MB 成片（约 80s），由 §4 流水线再生 |
| `video/audio/ shots/ tmp/ subtitles.srt` | 中间产物（本仓库留有实体），可再生 |
| `screenshot_login_live.jpg` / `screenshot_register_live.jpg` | 线上部署验证截图（各约 100KB） |
| `apps/web/*.log`（api/dbg/inspect1/list/patch/whoami）、`build-packages.log`(74KB)、`dev-root.log`(148KB)、`pnpm-install.log`(158KB) | 构建/排障日志，**按要求仅提要点、不收录正文**（见 6.3） |
| `apps/web/body.json` | vercel api PATCH 请求体草稿（`{"ssoProtection":null}`） |
| `apps/web/.env`、`apps/web/.vercel/.env.production.local` | **真实环境文件，全程未读取、零收录**（安全红线） |

### 6.2 已知问题与缺口清单

1. **上游基线 commit 无法精确锁定**：squash 导入未留上游哈希，只能按 2026-07-24 前近似 checkout；以本仓库 6c4088a 为准可 100% 复现。
2. **部署脚本硬编码具体 Vercel 资源 ID**（prj_/team_/dpl_，已占位）与本机绝对路径（`c:\Users\lenovo\...\apps\web`、npm 全局 vc.js 路径）；复现者须替换为自身值。
3. **refresh-and-inspect.ps1 依赖 CLI 内部实现**：靠正则从 `vc.js` 提取 OAuth client_id 与 token endpoint，Vercel CLI 升级后可能失效，属临时排障手段。
4. **04/05 分镜依赖运行中的前端**：需先配好数据库/Redis 等必需环境变量并启动 dev server，否则 login/register 截图失败。
5. **edge-tts / Playwright 需联网**；音色 `zh-CN-XiaoxiaoNeural`、字幕字体 `Microsoft YaHei` 在非 Windows/无该字体环境需替换，否则字幕缺字。
6. **Hobby 计划限制是这些修改的根因**：Edge 1MB、12 函数、300s 时长、8GB 构建内存；迁 Pro 计划后大部分 §3.2 适配可回退到上游默认。
7. **AGPL-3.0 合规**：对外提供网络服务须开放源码；`app/(ee)` 目录受 Dub 商业许可约束，自部署商用需注意。

### 6.3 部署日志要点（仅提要，不收录正文）

- **构建 OOM**：Vercel 8GB 容器 `next build` 静态导出阶段被 SIGKILL → 由 `webpackMemoryOptimizations` + `cpus:1` + `parallelism:1` + `cache:false` + 单线程 minify 解决。
- **Edge 1MB 超限**：多条 API/页面路由打包体积超 Edge Function 1MB → 移除 `runtime="edge"` 改走 Node.js 共享函数（同时满足 Hobby 12 函数上限）。
- **构建期外部服务崩溃**：Stripe/Upstash Vector 空凭据、DB 不可达导致页面数据收集/generateStaticParams 抛错 → 占位符 + try/catch guard。
- **SSO 登录墙**：默认 Deployment Protection 拦截访客 → disable-protection.ps1 关闭。
- **白标域名重写**：自有 `*.vercel.app` 被中间件当短链域 → APP_HOSTNAMES 豁免修复。

### 6.4 安全确认

全程**未读取** `apps/web/.env`、`apps/web/.vercel/.env.production.local` 及任何 `.env` / `.env.*.local` 真实环境文件；本文档不含任何真实密钥、token、连接串；脚本中的 Vercel 资源 ID 已占位化。
