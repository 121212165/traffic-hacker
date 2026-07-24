"""用 Playwright headless 截取 9 张分镜画面。
- 静态 HTML 卡片：视口 1280x720，file:// 截图
- 真实前端（login/register）：视口 880x720（低于 900px 断点 → 干净单列），
  注入 JS 去除残留的 dub.co 链接/条款，并加一个 TrafficHacker 文字标，保证品牌一致
"""
import os
from pathlib import Path
from playwright.sync_api import sync_playwright

BASE = Path(__file__).parent.resolve()
SHOTS = BASE / "shots"
STATIC = BASE / "static"
SHOTS.mkdir(exist_ok=True)

APP = os.environ.get("APP_URL", "http://localhost:8888")

# 去残留 + 注入品牌文字标（前端截图用）
CLEAN_JS = r"""() => {
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
}"""

def shot(page, name: str, w: int, h: int):
    out = SHOTS / f"{name}.png"
    page.screenshot(path=str(out), clip={"x": 0, "y": 0, "width": w, "height": h})
    print(f"[SHOT] {name}.png saved ({out.stat().st_size // 1024} KB)")

def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)

        # ===== 静态 HTML 卡片 1280x720 =====
        ctx = browser.new_context(viewport={"width": 1280, "height": 720}, device_scale_factor=1)
        page = ctx.new_page()
        for name, html in [
            ("01", "title.html"), ("02", "problem.html"), ("03", "features.html"),
            ("06", "shortlink.html"), ("07", "utm.html"), ("08", "attribution.html"),
            ("09", "ending.html"),
        ]:
            page.goto((STATIC / html).as_uri())
            page.wait_for_timeout(700)
            shot(page, name, 1280, 720)
            print(f"  -> {html} OK")
        ctx.close()

        # ===== 真实前端 880x720（单列干净）=====
        ctx2 = browser.new_context(viewport={"width": 880, "height": 720}, device_scale_factor=1)
        page2 = ctx2.new_page()
        for name, path in [("04", "/login"), ("05", "/register")]:
            page2.goto(f"{APP}{path}", wait_until="networkidle", timeout=120000)
            page2.wait_for_timeout(2500)
            try:
                page2.evaluate(CLEAN_JS)
            except Exception as e:
                print(f"  -> 注入清理失败({path}): {e}")
            page2.wait_for_timeout(400)
            shot(page2, name, 880, 720)
            print(f"  -> {path} OK")
        ctx2.close()

        browser.close()
        print("\n=== 全部 9 张截图完成 ===")

if __name__ == "__main__":
    main()
