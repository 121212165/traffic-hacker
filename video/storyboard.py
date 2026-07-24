# 分镜数据：每个镜头的画面来源 + 旁白文本
# image 字段：
#   - "static/xxx.html"  静态 HTML，Playwright file:// 截图后存 shots/XX.png (1280x720)
#   - "frontend:login"   真实前端页面，Playwright 访问 localhost:8888 截图 (880x720，留白居中)
# 音频文件在 audio/ 下（同名 .mp3），序号即文件名前缀：01.png / 01.mp3 ...

SHOTS = [
    {
        "id": "01",
        "image": "static/title.html",
        "narration": "流量黑客，TrafficHacker。一套自建的短链归因平台，把每一次点击的来路和转化，都攥在自己手里。",
    },
    {
        "id": "02",
        "image": "static/problem.html",
        "narration": "投放花了钱，转化却算不清。渠道、活动、落地页，数据散落各处，归因全靠猜。",
    },
    {
        "id": "03",
        "image": "static/features.html",
        "narration": "流量黑客把三件事合成一件：短链管理、UTM追踪、转化归因，一个看板全搞定。",
    },
    {
        "id": "04",
        "image": "frontend:login",
        "narration": "打开应用，这是你自己的登录入口。数据自建自控，不经过任何第三方。",
    },
    {
        "id": "05",
        "image": "frontend:register",
        "narration": "三十秒注册，创建你的专属工作区，马上开始建链。",
    },
    {
        "id": "06",
        "image": "static/shortlink.html",
        "narration": "为每条投放生成品牌短链。自定义域名、二维码、备注标签，一键复制分发。",
    },
    {
        "id": "07",
        "image": "static/utm.html",
        "narration": "自动带上UTM参数，点击实时入库。地域、设备、来源渠道，清清楚楚。",
    },
    {
        "id": "08",
        "image": "static/attribution.html",
        "narration": "从点击，到注册，到付费，全链路归因。哪个渠道真正带来收入，一眼看穿。",
    },
    {
        "id": "09",
        "image": "static/ending.html",
        "narration": "开源、自建、可一键部署到Vercel。流量黑客，让你的增长数据，真正属于你。",
    },
]
