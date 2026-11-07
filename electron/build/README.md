# 应用图标说明

## 需要的图标文件

### Windows
- **文件名**: `icon.ico`
- **尺寸**: 256x256 像素（推荐包含 16x16, 32x32, 48x48, 64x64, 256x256）
- **格式**: ICO（Windows 图标格式）
- **用途**: 应用程序图标、任务栏图标、文件关联图标

### macOS
- **文件名**: `icon.icns`
- **尺寸**: 1024x1024 像素（包含 16x16, 32x32, 128x128, 256x256, 512x512, 1024x1024）
- **格式**: ICNS（macOS 图标格式）
- **用途**: 应用程序图标、Dock 图标

### Linux
- **文件名**: `icon.png`
- **尺寸**: 512x512 像素（推荐 256x256 或 512x512）
- **格式**: PNG（支持透明度）
- **用途**: 应用程序图标、桌面图标

---

## 如何生成图标

### 方法 1: 在线工具

1. **准备源图片**
   - 尺寸: 1024x1024 像素或更大
   - 格式: PNG（透明背景）
   - 内容: 应用 Logo

2. **使用在线转换工具**
   - Windows ICO: https://convertico.com/
   - macOS ICNS: https://iconverticons.com/
   - 多平台: https://www.iconify.it/

3. **下载并放置**
   - 将生成的图标文件放到 `electron/build/` 目录
   - 确保文件名与上述要求一致

### 方法 2: 使用 ImageMagick（命令行）

```bash
# 安装 ImageMagick
# Windows: choco install imagemagick
# macOS: brew install imagemagick
# Linux: sudo apt-get install imagemagick

# 从 PNG 生成 ICO
convert logo.png -define icon:auto-resize=256,128,64,48,32,16 icon.ico

# 从 PNG 生成 ICNS（macOS）
convert logo.png -define icon:auto-resize=1024,512,256,128,64,32,16 icon.icns

# 调整 PNG 尺寸（Linux）
convert logo.png -resize 512x512 icon.png
```

### 方法 3: 使用专业设计工具

1. **Adobe Photoshop**
   - 导出为 PNG
   - 使用插件导出 ICO/ICNS

2. **Sketch / Figma**
   - 导出为 PNG（多尺寸）
   - 使用在线工具转换

3. **GIMP（免费）**
   - 文件 → 导出为
   - 选择 ICO 或 PNG 格式

---

## 图标设计规范

### 视觉要求
- ✅ 清晰可辨，即使在小尺寸下也能识别
- ✅ 使用简单形状和鲜明色彩
- ✅ 避免过多细节和文字
- ✅ 考虑透明背景（PNG/ICO）

### 尺寸建议
- **最小可用尺寸**: 256x256 像素
- **推荐源图尺寸**: 1024x1024 像素
- **分辨率**: 72 DPI（屏幕显示）或 300 DPI（打印）

### 配色建议
- 主色调: 中国红 (#C0392B) - 体现公文特色
- 辅助色: 白色、深灰
- 对比度: 确保在浅色和深色背景下都可见

---

## 当前状态

⚠️ **需要手动添加图标文件**

请按照上述方法生成或获取图标，然后放置到以下位置：

```
electron/build/
├── icon.ico      # Windows 图标
├── icon.icns     # macOS 图标
└── icon.png      # Linux 图标
```

---

## 临时解决方案

如果暂时没有图标，Electron 会使用默认图标，应用仍可正常运行。

在 `electron/main.js` 中，图标配置是可选的：

```javascript
const win = new BrowserWindow({
  // icon: path.join(__dirname, 'build/icon.png'),  // 注释掉这行
  // ... 其他配置
})
```

---

## 参考资源

- [Electron 应用图标文档](https://www.electronjs.org/docs/latest/tutorial/application-distribution#application-packaging)
- [Windows ICO 规范](https://docs.microsoft.com/en-us/windows/win32/menurx/icon-formats)
- [macOS ICNS 规范](https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/Capturing/Capturing.html)
- [App Icon 设计指南](https://developer.apple.com/design/human-interface-guidelines/icons#app-icons)
