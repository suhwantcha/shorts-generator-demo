# 🎬 Automated Tech Shorts Generation & Distribution System

This project is a **fully automated pipeline** that generates short-form tech videos and publishes them to **YouTube Shorts, TikTok, and Instagram Reels**.

It covers the entire workflow from **trend discovery → script generation → video creation → human approval → multi-platform publishing**.

---

## Core System Architecture

**End-to-end pipeline :**

1. **Trend Collection**

   * Fetches high-performing tech topics from **Reddit** and **Hacker News**

2. **Script Generation**

   * Generates short-form scripts using LLMs
   * Supports:

     * Informational storytelling
     * Persuasive (sales-style) scripts
   * Extracts visual search keywords for stock videos

3. **Audio Generation**

   * Converts scripts into high-quality Korean narration using **Google Cloud TTS**

4. **Video Assembly**

   * Downloads copyright-free vertical videos from **Pexels**
   * Matches video length to audio
   * Generates accurate subtitles
   * Renders final 9:16 video using **FFmpeg**

5. **Human Quality Check**

   * Sends an approval request via **Gmail**
   * Admin can approve or reject with one click

6. **Multi-Platform Publishing**

   * Automatically uploads approved videos to:

     * YouTube Shorts
     * TikTok
     * Instagram Reels
   * Upload results are stored for tracking

---

## Project Structure

```
tech-shorts-production/
├── content-collector/      # Trend scraping (Reddit, HN)
├── script-generator/       # LLM-based script & keyword generation
├── audio-generator/        # Google Cloud TTS
├── video-editor/           # Pexels + subtitles + FFmpeg (Docker)
├── quality-checker/        # Gmail-based approval system
├── platform-uploader/      # YouTube / TikTok / Instagram uploaders
├── .env.example            # Environment variables
└── README.md
```

Each module is deployed as an independent service and connected through a pipeline trigger.

---

## 🚀 How to Run

### 1. Prepare API Keys

You will need API access for:

* OpenAI (script generation)
* Google Cloud (TTS, Gmail, infrastructure)
* Pexels (stock videos)
* Reddit / Hacker News (trend sources)
* YouTube, TikTok, Instagram (publishing)

All credentials are managed via environment variables.

---

### 2. Configure Environment Variables

```bash
cp .env.example .env
```

Fill in required API keys and configuration values in `.env`.

---

### 3. Deploy Services

Each phase is deployed independently (e.g., Cloud Run / serverless):

```bash
cd content-collector && ./deploy.sh
cd script-generator && ./deploy.sh
cd audio-generator && ./deploy.sh
cd video-editor && ./deploy.sh
cd quality-checker && ./deploy.sh
cd platform-uploader && ./deploy.sh
```

---

### 4. Trigger the Pipeline

Send a trigger message to start the full automation flow:

```bash
gcloud pubsub topics publish content-trigger --message '{}'
```

* The system generates a video
* Sends an approval email
* Publishes automatically upon approval

---

## Key Design Principles

* **Fully automated**, but with a **human-in-the-loop** safety gate
* **Modular architecture** (each phase can be replaced or scaled)
* **Platform-agnostic publishing**
* Optimized for **short-form vertical video (9:16)**

---
