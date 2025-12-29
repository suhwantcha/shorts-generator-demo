#!/bin/bash

# 전체 Phase 배포 스크립트
# 사용법: ./deploy_all_phases.sh

set -e

echo "========================================="
echo "Tech Shorts 전체 Phase 배포"
echo "========================================="
echo ""

# 환경 변수 확인
if [ -z "$GCP_PROJECT_ID" ]; then
    echo "❌ 오류: GCP_PROJECT_ID 환경 변수가 설정되지 않았습니다."
    echo ""
    echo "다음 명령어를 먼저 실행하세요:"
    echo "  export \$(cat .env | grep -v '^#' | xargs)"
    exit 1
fi

if [ -z "$STORAGE_BUCKET_NAME" ]; then
    echo "❌ 오류: STORAGE_BUCKET_NAME 환경 변수가 설정되지 않았습니다."
    exit 1
fi

echo "프로젝트 ID: $GCP_PROJECT_ID"
echo "버킷 이름: $STORAGE_BUCKET_NAME"
echo "리전: ${REGION:-asia-northeast3}"
echo ""

# gcloud 프로젝트 설정
gcloud config set project $GCP_PROJECT_ID

# Cloud Storage 버킷 생성 (이미 있으면 무시)
echo "Cloud Storage 버킷 확인 중..."
gsutil ls gs://$STORAGE_BUCKET_NAME 2>/dev/null || {
    echo "버킷 생성 중..."
    gsutil mb -p $GCP_PROJECT_ID -l ${REGION:-asia-northeast3} gs://$STORAGE_BUCKET_NAME
    echo "✅ 버킷 생성 완료"
}
echo ""

# Firestore 데이터베이스 생성 (이미 있으면 무시)
echo "Firestore 데이터베이스 확인 중..."
gcloud firestore databases describe --database='(default)' 2>/dev/null || {
    echo "Firestore 생성 중..."
    gcloud firestore databases create --region=asia-northeast1
    echo "✅ Firestore 생성 완료"
}
echo ""

# Phase 1: Content Collector
echo "========================================="
echo "[1/6] Phase 1: Content Collector 배포"
echo "========================================="
cd 1-content-collector
chmod +x deploy.sh
./deploy.sh
cd ..
echo ""

# Phase 2: Script Generator
echo "========================================="
echo "[2/6] Phase 2: Script Generator 배포"
echo "========================================="
cd 2-script-generator
chmod +x deploy.sh
./deploy.sh
cd ..
echo ""

# Phase 3: Audio Generator
echo "========================================="
echo "[3/6] Phase 3: Audio Generator 배포"
echo "========================================="
cd 3-audio-generator
chmod +x deploy.sh
./deploy.sh
cd ..
echo ""

# Phase 4: Video Editor (Cloud Run)
echo "========================================="
echo "[4/6] Phase 4: Video Editor 배포"
echo "========================================="
cd 4-video-editor
chmod +x deploy.sh
./deploy.sh
cd ..
echo ""

# Phase 5: Quality Checker
echo "========================================="
echo "[5/6] Phase 5: Quality Checker 배포"
echo "========================================="
cd 5-quality-checker
chmod +x deploy.sh
./deploy.sh

# Phase 5 Function URL 가져오기
APPROVAL_URL=$(gcloud functions describe quality-checker --gen2 --region=asia-northeast3 --format='value(serviceConfig.uri)' 2>/dev/null)
if [ ! -z "$APPROVAL_URL" ]; then
    echo ""
    echo "📧 Phase 5 Function URL: $APPROVAL_URL"
    echo ""
    echo "다음 라인을 .env 파일에 추가하세요:"
    echo "APPROVAL_BASE_URL=$APPROVAL_URL"
    
    # .env 파일에 자동 추가 (주석 제거 및 업데이트)
    if grep -q "^APPROVAL_BASE_URL=" ../.env 2>/dev/null; then
        # 이미 있으면 업데이트
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^APPROVAL_BASE_URL=.*|APPROVAL_BASE_URL=$APPROVAL_URL|" ../.env
        else
            sed -i "s|^APPROVAL_BASE_URL=.*|APPROVAL_BASE_URL=$APPROVAL_URL|" ../.env
        fi
        echo "✅ .env 파일 업데이트 완료"
    else
        # 없으면 추가
        echo "" >> ../.env
        echo "# Phase 5 승인 시스템 URL (자동 생성)" >> ../.env
        echo "APPROVAL_BASE_URL=$APPROVAL_URL" >> ../.env
        echo "✅ .env 파일에 추가 완료"
    fi
fi
cd ..
echo ""

# Phase 6: Platform Uploader
echo "========================================="
echo "[6/6] Phase 6: Platform Uploader 배포"
echo "========================================="
cd 6-platform-uploader
chmod +x deploy.sh
./deploy.sh
cd ..
echo ""

# Cloud Scheduler 설정 (선택)
echo "========================================="
echo "Cloud Scheduler 설정 (선택)"
echo "========================================="
read -p "매일 자동 실행을 위한 Cloud Scheduler를 설정하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Pub/Sub Topic 생성
    gcloud pubsub topics create content-trigger 2>/dev/null || echo "✅ Pub/Sub topic 이미 존재"
    
    # Cloud Scheduler Job 생성
    gcloud scheduler jobs create pubsub daily-content-generator \
        --schedule="0 9 * * *" \
        --topic=content-trigger \
        --message-body='{"action": "generate"}' \
        --time-zone="Asia/Seoul" \
        --location=${REGION:-asia-northeast3} 2>/dev/null || {
        
        # 이미 있으면 업데이트
        gcloud scheduler jobs update pubsub daily-content-generator \
            --schedule="0 9 * * *" \
            --topic=content-trigger \
            --message-body='{"action": "generate"}' \
            --time-zone="Asia/Seoul" \
            --location=${REGION:-asia-northeast3}
    }
    
    echo "✅ Cloud Scheduler 설정 완료 (매일 오전 9시 실행)"
else
    echo "⏭️  Cloud Scheduler 설정을 건너뜁니다."
fi
echo ""

# 배포 완료 요약
echo "========================================="
echo "🎉 전체 배포 완료!"
echo "========================================="
echo ""
echo "📋 배포된 서비스:"
echo "  [1] content-collector (Cloud Function)"
echo "  [2] script-generator (Cloud Function)"
echo "  [3] audio-generator (Cloud Function)"
echo "  [4] video-editor (Cloud Run)"
echo "  [5] quality-checker (Cloud Function)"
echo "  [6] platform-uploader (Cloud Run)"
echo ""
echo "📊 배포 상태 확인:"
echo "  gcloud functions list --gen2 --region=asia-northeast3"
echo "  gcloud run services list --region=asia-northeast3"
echo ""
echo "🧪 테스트 실행:"
echo "  gcloud pubsub topics publish content-trigger --message '{\"action\": \"generate\"}'"
echo ""
echo "📝 로그 확인:"
echo "  gcloud functions logs read content-collector --gen2 --region=asia-northeast3 --limit=50"
echo "  gcloud run logs read video-editor --region=asia-northeast3 --limit=50"
echo ""
echo "🔍 Firestore 데이터 확인:"
echo "  https://console.firebase.google.com/project/$GCP_PROJECT_ID/firestore"
echo ""
echo "⏰ Cloud Scheduler 확인:"
echo "  gcloud scheduler jobs list --location=${REGION:-asia-northeast3}"
echo ""
echo "🎬 이제 영상이 자동으로 생성됩니다!"
echo "========================================="
