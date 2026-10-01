# 工程字体库

后端生成的 `.docx` **只写入字体族名（字符串），不读取任何字体文件**。
真正的字形渲染发生在两个地方，本目录服务的是第 1 个：

1. **浏览器实时预览**（`docx-preview` 用 HTML/CSS 渲染）——字体必须能被浏览器加载；
2. **Word / WPS 打开**——用打开文档那台机器上安装的字体。

所以本目录的作用是：**让浏览器预览用的字形和 Word 里一致，且不依赖访问者本机装了什么字体**。

## 当前状态：四个字体已全部就位

| 族名（后端写入 docx 的名字） | 文件 | 体积 | 开源来源 | 授权 |
|---|---|---|---|---|
| `宋体` | `songti.woff2` | 11.71 MB | 思源宋体 Noto Serif CJK SC | OFL-1.1 |
| `仿宋` | `fangsong.woff2` | 4.58 MB | [朱雀仿宋 Zhuque Fangsong](https://github.com/TrionesType/zhuque) v0.212 | OFL-1.1 |
| `黑体` | `heiti.woff2` | 8.11 MB | 思源黑体 Noto Sans CJK SC | OFL-1.1 |
| `楷体` | `kaiti.woff2` | 6.40 MB | [霞鹜文楷 LXGW WenKai](https://github.com/lxgw/LxgwWenKai) v1.235.2 | OFL-1.1 |

合计约 30.8 MB。这四个族名由 `WpsService` 的
`FONT_SONG / FONT_FANGSONG / FONT_HEI / FONT_KAI` 常量决定，
对应的 `@font-face` 别名写在 [`frontend/src/styles/fonts.css`](../../src/styles/fonts.css)。

## 子集化说明

四个文件都做过子集化，规则是「**保留全部汉字（含扩展区），剔除公文用不到的其它文字**」：

保留：ASCII、拉丁补充、常用符号/箭头/数学/几何、CJK 标点、CJK 兼容汉字、
全角字符、`U+4E00–U+9FFF`（CJK 统一汉字）、`U+20000–U+2FA1F`（CJK 扩展 B 及以后）。
剔除：日文假名、韩文谚文、以及其它与本项目无关的文字区块。

**不会丢任何一个汉字**，只是砍掉了非中文字形。若将来需要假名/谚文，
把上面的区间改掉重新子集化即可。

## 重建 / 替换字体怎么做

只改一个地方：`frontend/src/styles/fonts.css` 里对应 `@font-face` 的 `src` 顺序。
查找顺序是「本机原生字体 → 本目录文件 → 本机开源字体」：

```
local("FangSong") → url("/fonts/fangsong.woff2") → url("/fonts/fangsong.ttf") → local("Zhuque Fangsong (technical preview)")
```

想固定用工程字体库的文件、不让本机字体抢先，就把 `url()` 挪到最前面。

重新生成文件（需要 `fonttools`：`pip install fonttools brotli`）：

```bash
cd frontend/public/fonts

# ── 宋体 / 黑体：从系统思源 TTC 抽简体面（两个 TTC 的 SC 面都是 face 2）──
python3 - <<'EOF'
from fontTools.ttLib import TTFont
for src, out in (('/usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc','songti.woff2'),
                 ('/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc','heiti.woff2')):
    f = TTFont(src, fontNumber=2); f.flavor='woff2'; f.save(out)
EOF

# ── 仿宋：朱雀仿宋，官方只发 TTF，需自行转 woff2 ──
curl -L -o zq.zip https://github.com/TrionesType/zhuque/releases/download/v0.212/ZhuqueFangsong-v0.212.zip
unzip -j zq.zip ZhuqueFangsong-Regular.ttf
python3 -c "from fontTools.ttLib import TTFont; f=TTFont('ZhuqueFangsong-Regular.ttf'); f.flavor='woff2'; f.save('fangsong.woff2')"

# ── 楷体：霞鹜文楷。GitHub Release 直连在本机极不稳定，
#          改用 npm 包（内含完整原始 TTF）──
curl -L -o pkg.tgz https://registry.npmjs.org/lxgw-wenkai-subset/-/lxgw-wenkai-subset-1.235.2.tgz
tar xzf pkg.tgz
python3 -c "from fontTools.ttLib import TTFont; f=TTFont('package/ttf/lxgwwenkai-regular.original.v1.235.2.ttf'); f.flavor='woff2'; f.save('kaiti.woff2')"
```

> 上面是**不子集化**的简版命令，产物会明显更大（宋体 15.9MB / 黑体 10.9MB）。
> 需要子集化时，用 `fontTools.subset` 传入上文的 unicode 区间即可。

## 想换成 Windows 原生字体

| 族名 | Windows 文件 |
|---|---|
| 宋体 | `simsun.ttc` |
| 仿宋 | `simfang.ttf` |
| 黑体 | `simhei.ttf` |
| 楷体 | `simkai.ttf` |

注意：
- `simsun.ttc` 是**字体集合**，浏览器不支持 `.ttc`，必须先拆出单个 `.ttf`；
- 这四个是中易 / 微软的商用字体，**提交进 git 仓库（尤其公开仓库）有版权风险**，
  建议改名为 `songti.ttf` 等放入本目录并加入 `.gitignore`，只在本机使用。

## 已知问题：开发服务器会把缺失字体请求回成 200

`fonts.css` 里每个族名都带 `url(/fonts/*.woff2)` 和 `url(/fonts/*.ttf)` 两个候选。
若某个候选文件不存在，**Vite 开发服务器会因 SPA history fallback 返回
`200 text/html`（index.html）而不是 404**。浏览器拿到 HTML、按字体解析失败后
会继续走 `src` 链，所以渲染结果仍然正确，只是首屏多几个无用请求。

生产环境（nginx 等）会正常返回 404，无此现象。四个文件都到位后也不会再触发。
