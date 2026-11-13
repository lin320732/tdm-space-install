# TDM 新闻下载空间 — 安装包

把这个文件夹发给另一个 Muse，对方照着 `SKILL.md` 做，就能建出一样的「TDM 新闻下载」空间。

## 里面有什么

- `SKILL.md`：完整安装说明（功能清单、注意事项、安装步骤）
- `skill.yaml`：skill 基本信息
- `scripts/tdm_keyword_watch.sh`：关键词监控的轻量扫描脚本（每 30 分钟跑一次，新命中才通知，不用大模型）

## 前置条件

- 先装 `tdm` skill：https://github.com/lylasi/TDMDO
- Python ≥ 3.9、requests、ffmpeg、yt-dlp

## 朋友那边怎么用

1. 把这个文件夹（或下面那个公开页面里的全部内容）发给他的 Muse。
2. 跟他的 Muse 说：「按这个 skill 给我装个 TDM 新闻下载空间」。
3. 他的 Muse 会先装 tdm skill、验证下载，再建空间、装关键词监控。

注意：空间本身不能直接复制过去，只能按说明重建一个一样的；他原来的下载记录、关键词清单不会跟着过去，要重新加。
