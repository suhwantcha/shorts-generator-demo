# 🚀 Tech Shorts 자동화 시스템 - 실행 가이드

---

## 📋 목차

1. [사전 준비 체크리스트](#1-사전-준비-체크리스트)
2. [로컬 테스트 실행](#2-로컬-테스트-실행)
3. [GCP 클라우드 배포](#3-gcp-클라우드-배포)
4. [전체 워크플로우 실행](#4-전체-워크플로우-실행)
5. [문제 해결](#5-문제-해결)

---

## 1. 사전 준비 체크리스트

### ✅ 1.1 필수 소프트웨어 설치

```bash
# Python 3.11 확인
python --version  # 또는 python3 --version
# 출력: Python 3.11.x

# pip 확인
pip --version

# Google Cloud SDK 설치 (필수)
# Windows: https://cloud.google.com/sdk/docs/install
# Mac: brew install google-cloud-sdk
# Linux: curl https://sdk.cloud.google.com | bash

# gcloud 확인
gcloud --version
```

### ✅ 1.2 GCP 프로젝트 생성

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 새 프로젝트 생성 (예: `tech-shorts-prod`)
3. 프로젝트 ID 복사 (예: `tech-shorts-prod-123456`)
4. 결제 계정 연결 (필수)

### ✅ 1.3 필수 API 활성화

```bash
# gcloud 로그인
gcloud auth login

# 프로젝트 설정
gcloud config set project YOUR_PROJECT_ID

# 필수 API 활성화
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable texttospeech.googleapis.com
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable gmail.googleapis.com
```

### ✅ 1.4 API 키 발급

#### 📌 OpenAI API 키
1. [OpenAI Platform](https://platform.openai.com/api-keys) 접속
2. `Create new secret key` 클릭
3. 키 복사 (sk-...)

#### 📌 Pexels API 키
1. [Pexels API](https://www.pexels.com/api/) 접속
2. 무료 계정 생성
3. API 키 복사

#### 📌 Reddit API 키
1. [Reddit Apps](https://www.reddit.com/prefs/apps) 접속
2. `Create App` → `script` 선택
3. Client ID, Client Secret 복사

#### 📌 YouTube API (OAuth)
1. [Google Cloud Console](https://console.cloud.google.com/) → API 및 서비스 → 사용자 인증 정보
2. `OAuth 클라이언트 ID 만들기` → 웹 애플리케이션
3. 승인된 리디렉션 URI: `http://localhost:8080`
4. Client ID, Client Secret 복사
5. [OAuth Playground](https://developers.google.com/oauthplayground/)에서 Refresh Token 발급
   - Settings → Use your own OAuth credentials 체크
   - YouTube Data API v3 선택
   - Authorize APIs → 코드 교환 → Refresh Token 복사

#### 📌 TikTok API
1. [TikTok for Developers](https://developers.tiktok.com/) 접속
2. 앱 등록 → Content Posting API 권한 요청
3. OAuth 인증 → Access Token 발급

#### 📌 Instagram API
1. [Meta for Developers](https://developers.facebook.com/) 접속
2. 앱 생성 → Instagram Graph API 추가
3. 비즈니스 계정 연결
4. User Access Token 발급

#### 📌 Gmail API (OAuth)
1. Google Cloud Console → Gmail API 활성화
2. OAuth 클라이언트 ID 생성 (위 YouTube와 동일)
3. Refresh Token 발급

---

## 2. 로컬 테스트 실행

### 🔧 2.1 환경 설정

```bash
# VSCode 터미널에서 실행

# 1. 프로젝트 루트로 이동
cd tech-shorts-production

# 2. .env 파일 생성
cp .env.example .env

# 3. .env 파일 편집 (VSCode에서 열기)
code .env
```

**`.env` 파일 내용**:
```bash
# GCP 설정
GCP_PROJECT_ID=your-project-id
STORAGE_BUCKET_NAME=your-bucket-name
REGION=asia-northeast3

# OpenAI
OPENAI_API_KEY=sk-...

# Pexels
PEXELS_API_KEY=...

# Reddit
REDDIT_CLIENT_ID=...
REDDIT_CLIENT_SECRET=...

# YouTube
YOUTUBE_CLIENT_ID=...
YOUTUBE_CLIENT_SECRET=...
YOUTUBE_REFRESH_TOKEN=...

# TikTok
TIKTOK_ACCESS_TOKEN=...

# Instagram
INSTAGRAM_ACCESS_TOKEN=...
INSTAGRAM_ACCOUNT_ID=...

# Gmail
GMAIL_CLIENT_ID=...
GMAIL_CLIENT_SECRET=...
GMAIL_REFRESH_TOKEN=...
ADMIN_EMAIL=your-email@gmail.com

# Phase 5 승인 시스템 (배포 후 설정)
APPROVAL_BASE_URL=https://your-function-url

# 기타
SALES_MODE_PROBABILITY=0.25
```

### 🧪 2.2 Phase별 로컬 테스트

#### Phase 2: 스크립트 생성기 테스트

```bash
cd 2-script-generator

# 가상환경 생성 (권장)
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 패키지 설치
pip install -r requirements.txt

# 로컬 테스트 실행
python main.py

# 출력 예시:
# Phase 2: Script Generator
# ==================================================
# 모드: info
# 스크립트 길이: 487자
# 예상 시간: 73.1초
# ...
```

#### Phase 3: 음성 생성기 테스트

```bash
cd ../3-audio-generator

# 가상환경 및 패키지 설치
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# GCP 인증 설정 (중요!)
gcloud auth application-default login

# Cloud Storage 버킷 생성
gsutil mb -p $GCP_PROJECT_ID -l $REGION gs://$STORAGE_BUCKET_NAME

# 로컬 테스트 실행
python main.py

# 출력 예시:
# Phase 3: Audio Generator
# ==================================================
# 음성 생성 시작: 134 글자
# TTS API 호출 성공: 89562 bytes
# 음성 생성 완료: gs://bucket/audios/test_audio.mp3, 22.3초, $0.0021
```

#### Phase 4: 영상 편집기 테스트

```bash
cd ../4-video-editor

# 가상환경 및 패키지 설치
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# FFmpeg 설치 확인
ffmpeg -version

# FFmpeg 없으면 설치
# Mac: brew install ffmpeg
# Ubuntu: sudo apt install ffmpeg
# Windows: https://ffmpeg.org/download.html

# 한글 폰트 설치 확인 (Linux)
fc-list :lang=ko

# 한글 폰트 없으면 설치
# Ubuntu: sudo apt install fonts-noto-cjk
# Mac: 기본 설치됨
# Windows: 기본 설치됨

# 로컬 테스트 (main.py의 if __name__ == '__main__' 부분 실행)
python main.py
```

**주의**: Phase 4는 음성 파일과 Pexels 영상이 필요하므로, 실제로는 Phase 2-3 실행 후 테스트해야 합니다.

#### Phase 5: 품질 검수 테스트

```bash
cd ../5-quality-checker

python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Gmail OAuth credentials.json 다운로드
# Google Cloud Console → API 및 서비스 → 사용자 인증 정보
# OAuth 클라이언트 ID → JSON 다운로드 → credentials.json로 저장

# Refresh Token 발급
python << 'EOF'
from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = ['https://www.googleapis.com/auth/gmail.send']

flow = InstalledAppFlow.from_client_secrets_file(
    'credentials.json',
    SCOPES
)

creds = flow.run_local_server(port=8080)
print(f"\n✅ Refresh Token:\n{creds.refresh_token}")
EOF

# 출력된 Refresh Token을 .env에 추가

# 로컬 테스트
python main.py
```

---

## 3. GCP 클라우드 배포

### 🚀 3.1 전체 배포 (권장)

```bash
# 프로젝트 루트로 이동
cd tech-shorts-production

# 환경 변수 로드
export $(cat .env | grep -v '^#' | xargs)

# 전체 Phase 순차 배포
./deploy_all_phases.sh
```

**`deploy_all_phases.sh` 스크립트** (새로 생성):
```bash
#!/bin/bash

set -e

echo "========================================="
echo "전체 Phase 배포 시작"
echo "========================================="

# Phase 1: Content Collector
echo "[1/6] Phase 1 배포 중..."
cd 1-content-collector
./deploy.sh
cd ..

# Phase 2: Script Generator
echo "[2/6] Phase 2 배포 중..."
cd 2-script-generator
./deploy.sh
cd ..

# Phase 3: Audio Generator
echo "[3/6] Phase 3 배포 중..."
cd 3-audio-generator
./deploy.sh
cd ..

# Phase 4: Video Editor
echo "[4/6] Phase 4 배포 중..."
cd 4-video-editor
./deploy.sh
cd ..

# Phase 5: Quality Checker
echo "[5/6] Phase 5 배포 중..."
cd 5-quality-checker
./deploy.sh

# Phase 5 URL을 .env에 추가
FUNCTION_URL=$(gcloud functions describe quality-checker --gen2 --region=asia-northeast3 --format='value(serviceConfig.uri)')
echo "APPROVAL_BASE_URL=$FUNCTION_URL" >> ../.env
cd ..

# Phase 6: Platform Uploader
echo "[6/6] Phase 6 배포 중..."
cd 6-platform-uploader
./deploy.sh
cd ..

echo ""
echo "========================================="
echo "✅ 전체 배포 완료!"
echo "========================================="
```

### 🔧 3.2 Phase별 개별 배포

```bash
# Phase 1
cd 1-content-collector
chmod +x deploy.sh
./deploy.sh

# Phase 2
cd ../2-script-generator
chmod +x deploy.sh
./deploy.sh

# Phase 3
cd ../3-audio-generator
chmod +x deploy.sh
./deploy.sh

# Phase 4 (Docker 기반 Cloud Run)
cd ../4-video-editor
chmod +x deploy.sh
./deploy.sh

# Phase 5
cd ../5-quality-checker
chmod +x deploy.sh
./deploy.sh

# Phase 6
cd ../6-platform-uploader
chmod +x deploy.sh
./deploy.sh
```

### 📝 3.3 Firestore 데이터베이스 설정

```bash
# Firestore 생성
gcloud firestore databases create --region=asia-northeast1

# 컬렉션 생성 (자동으로 생성되지만 미리 확인)
# Firebase Console에서 확인: https://console.firebase.google.com/
# - scripts 컬렉션
# - videos 컬렉션
```

### ⏰ 3.4 Cloud Scheduler 설정 (자동 실행)

```bash
# 매일 오전 9시에 자동 실행
gcloud scheduler jobs create pubsub daily-content-generator \
    --schedule="0 9 * * *" \
    --topic=content-trigger \
    --message-body='{"action": "generate"}' \
    --time-zone="Asia/Seoul"

# 스케줄러 확인
gcloud scheduler jobs list

# 수동 실행 테스트
gcloud scheduler jobs run daily-content-generator
```

---

## 4. 전체 워크플로우 실행

### 🎬 4.1 수동 실행 (테스트용)

```bash
# 1. Pub/Sub으로 Phase 1 트리거
gcloud pubsub topics publish content-trigger --message '{"action": "generate"}'

# 2. Phase 1 로그 확인
gcloud functions logs read content-collector --gen2 --region=asia-northeast3 --limit=50

# 3. Firestore에서 생성된 스크립트 확인
gcloud firestore collections documents list scripts

# 4. Phase 2 로그 확인
gcloud functions logs read script-generator --gen2 --region=asia-northeast3 --limit=50

# 5. Phase 3 로그 확인
gcloud functions logs read audio-generator --gen2 --region=asia-northeast3 --limit=50

# 6. Phase 4 로그 확인
gcloud run logs read video-editor --region=asia-northeast3 --limit=50

# 7. 이메일 수신함 확인 (Phase 5)
# Gmail에서 승인/거부 버튼 클릭

# 8. Phase 6 로그 확인 (승인 후)
gcloud run logs read platform-uploader --region=asia-northeast3 --limit=50

# 9. 최종 결과 확인
# YouTube Shorts: https://studio.youtube.com
# TikTok: https://www.tiktok.com/creator-center
# Instagram: https://www.instagram.com
```

### 📊 4.2 실시간 모니터링

```bash
# Cloud Console에서 모니터링
# https://console.cloud.google.com/

# Logs Explorer에서 실시간 로그 보기
gcloud logging tail "resource.type=cloud_function OR resource.type=cloud_run_revision"

# Firestore 실시간 변경사항 보기
# Firebase Console: https://console.firebase.google.com/
```

---

## 🎯 빠른 시작 체크리스트

- [ ] Python 3.11 설치
- [ ] Google Cloud SDK 설치
- [ ] GCP 프로젝트 생성 및 결제 활성화
- [ ] 필수 API 활성화 (Firestore, Cloud Functions, Cloud Run 등)
- [ ] API 키 발급 (OpenAI, Pexels, Reddit, YouTube, TikTok, Instagram, Gmail)
- [ ] `.env` 파일 작성
- [ ] FFmpeg 설치
- [ ] 한글 폰트 설치 (Linux)
- [ ] Firestore 데이터베이스 생성
- [ ] Cloud Storage 버킷 생성
- [ ] Phase별 배포 실행
- [ ] Cloud Scheduler 설정
- [ ] 첫 실행 테스트

---

## 📞 추가 도움말

### 📖 공식 문서
- [Google Cloud Functions](https://cloud.google.com/functions/docs)
- [Cloud Run](https://cloud.google.com/run/docs)
- [Firestore](https://cloud.google.com/firestore/docs)
- [OpenAI API](https://platform.openai.com/docs)
- [Pexels API](https://www.pexels.com/api/documentation/)

### 🔍 디버깅 팁
```bash
# 상세 로그 보기
gcloud functions logs read FUNCTION_NAME --gen2 --region=asia-northeast3 --limit=100 --format=json

# 환경 변수 확인
gcloud functions describe FUNCTION_NAME --gen2 --region=asia-northeast3 --format='value(serviceConfig.environmentVariables)'

# Cloud Storage 파일 확인
gsutil ls -r gs://$STORAGE_BUCKET_NAME/

# Firestore 데이터 확인
gcloud firestore collections documents list scripts --limit=10
```

---
