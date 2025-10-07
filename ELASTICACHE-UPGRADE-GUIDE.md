# ElastiCache Upgrade Guide: t3.micro → r7g.large

## 📊 업그레이드 개요

**목적:** 30k RPS를 안정적으로 처리하기 위한 ElastiCache 성능 향상

| 항목 | 변경 전 | 변경 후 | 개선 |
|-----|---------|---------|------|
| **노드 타입** | cache.t3.micro | **cache.r7g.large** | - |
| **메모리** | 512MB | **13.07GB** | **26배** ⬆️ |
| **vCPU** | 2 cores (x86) | **2 cores (Graviton3)** | **2-3배 성능** ⬆️ |
| **예상 비용** | ~$9/month | **~$115/month** | +$106/month |
| **RPS 지원** | ~10k (불안정) | **30-40k (안정)** | ✅ |

## 🔧 Terraform 변경 사항

### 수정된 파일
```bash
📝 var.tf
  - Line 40: cache.t3.micro → cache.r7g.large
```

### 변경 내용 확인
```bash
cd ../traffic-tacos-infra-iac

# Git diff로 변경사항 확인
git diff var.tf
```

## 🚀 업그레이드 실행 순서

### Step 0: 사전 준비 (필수!)

```bash
cd ../traffic-tacos-infra-iac

# 1. 현재 상태 백업 (선택사항)
terraform state pull > terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)

# 2. AWS 인증 확인
aws sts get-caller-identity --profile tacos

# 3. Terraform 초기화 확인
terraform init
```

### Step 1: Terraform Plan (변경 사항 미리보기)

```bash
terraform plan

# 예상 출력:
# ~ resource "aws_elasticache_replication_group" "redis" {
#     ~ node_type = "cache.t3.micro" -> "cache.r7g.large"
#   }
# 
# Plan: 0 to add, 1 to change, 0 to destroy.
```

**확인 사항:**
- ✅ `1 to change` (ElastiCache만 변경)
- ✅ `0 to destroy` (삭제 없음)
- ⚠️ 만약 다른 리소스가 변경되면 신중히 검토!

### Step 2: ElastiCache 수동 백업 생성 (안전장치)

```bash
# 백업 생성 (5-10분 소요)
aws elasticache create-snapshot \
  --replication-group-id traffic-tacos-redis \
  --snapshot-name traffic-tacos-redis-pre-upgrade-$(date +%Y%m%d) \
  --region ap-northeast-2 \
  --profile tacos

# 백업 상태 확인
aws elasticache describe-snapshots \
  --snapshot-name traffic-tacos-redis-pre-upgrade-$(date +%Y%m%d) \
  --region ap-northeast-2 \
  --profile tacos \
  --query 'Snapshots[0].[SnapshotName,SnapshotStatus,NodeSnapshots[0].SnapshotCreateTime]' \
  --output table
```

**백업이 `available` 상태가 될 때까지 대기하세요!**

### Step 3: Terraform Apply (실제 업그레이드)

```bash
# 업그레이드 실행
terraform apply

# 또는 자동 승인 (권장하지 않음)
# terraform apply -auto-approve
```

**예상 출력:**
```
aws_elasticache_replication_group.redis: Modifying...
aws_elasticache_replication_group.redis: Still modifying... [10s elapsed]
aws_elasticache_replication_group.redis: Still modifying... [1m0s elapsed]
...
aws_elasticache_replication_group.redis: Modifications complete after 15m23s
```

**소요 시간:** 약 **15-30분** (Multi-AZ 환경에서 롤링 업그레이드)

### Step 4: 업그레이드 확인

```bash
# 1. AWS CLI로 확인
aws elasticache describe-replication-groups \
  --replication-group-id traffic-tacos-redis \
  --region ap-northeast-2 \
  --profile tacos \
  --query 'ReplicationGroups[0].[CacheNodeType,Status]' \
  --output table

# 예상 출력:
# --------------------------------
# |  cache.r7g.large | available |
# --------------------------------

# 2. 상태 모니터링 스크립트
cd ../../deployment-repo
./check-redis-status.sh
```

### Step 5: 애플리케이션 동작 확인

```bash
# gateway-api 파드 상태 확인
kubectl get pods -n tacos-app -l app=gateway-api

# 로그에서 Redis 연결 확인
kubectl logs -n tacos-app -l app=gateway-api --tail=50 | grep -i redis

# 에러 로그 확인 (connection timeout이 없어야 함!)
kubectl logs -n tacos-app -l app=gateway-api --tail=100 | grep -i "redis.*error"
```

## ⏱️ 다운타임 예상

### Multi-AZ 환경 (현재 설정)
- **예상 다운타임:** **없음** (또는 최소)
- **롤링 업그레이드:** Replica → Primary 순으로 업그레이드
- **서비스 영향:** 일시적 성능 저하 가능 (수초~수분)

### 업그레이드 중 발생 가능한 현상
1. **일시적 연결 끊김** (수초)
2. **Failover 발생** (Primary → Replica 전환)
3. **성능 저하** (롤링 업그레이드 중)

## 🔄 롤백 방법 (문제 발생 시)

### Option 1: Terraform으로 롤백

```bash
cd ../traffic-tacos-infra-iac

# var.tf 수정 (cache.r7g.large → cache.t3.micro)
# 또는 git revert
git revert HEAD

terraform plan
terraform apply
```

### Option 2: AWS CLI로 롤백

```bash
aws elasticache modify-replication-group \
  --replication-group-id traffic-tacos-redis \
  --cache-node-type cache.t3.micro \
  --apply-immediately \
  --region ap-northeast-2 \
  --profile tacos
```

### Option 3: 백업에서 복구 (최후의 수단)

```bash
# 1. 현재 클러스터 삭제
terraform destroy -target=module.elasticache

# 2. 백업에서 복구
aws elasticache create-replication-group \
  --replication-group-id traffic-tacos-redis \
  --snapshot-name traffic-tacos-redis-pre-upgrade-$(date +%Y%m%d) \
  --region ap-northeast-2 \
  --profile tacos

# 3. Terraform import
terraform import module.elasticache.aws_elasticache_replication_group.redis traffic-tacos-redis
```

## 📊 업그레이드 후 모니터링

### CloudWatch 메트릭 확인 (24시간)

```bash
# CPU 사용률 (목표: < 50%)
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache \
  --metric-name CPUUtilization \
  --dimensions Name=CacheClusterId,Value=traffic-tacos-redis-001 \
  --start-time $(date -u -v-1H '+%Y-%m-%dT%H:%M:%S') \
  --end-time $(date -u '+%Y-%m-%dT%H:%M:%S') \
  --period 300 \
  --statistics Average Maximum \
  --region ap-northeast-2 \
  --profile tacos

# 메모리 사용률 (목표: < 70%)
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache \
  --metric-name DatabaseMemoryUsagePercentage \
  --dimensions Name=CacheClusterId,Value=traffic-tacos-redis-001 \
  --start-time $(date -u -v-1H '+%Y-%m-%dT%H:%M:%S') \
  --end-time $(date -u '+%Y-%m-%dT%H:%M:%S') \
  --period 300 \
  --statistics Average Maximum \
  --region ap-northeast-2 \
  --profile tacos
```

### 성능 개선 확인

**업그레이드 전 (cache.t3.micro):**
```
CPU: 53-54% (10k RPS 부하 중)
메모리: 78-90% (매우 높음!)
연결: 585-958개 (급증)
에러: connection pool timeout 다발
```

**업그레이드 후 (cache.r7g.large) 예상:**
```
CPU: 15-20% (10k RPS 부하 중) ✅ 60% 감소
메모리: 8-10% ✅ 80% 감소
연결: 안정적
에러: connection timeout 없음 ✅
```

## 🎯 업그레이드 성공 체크리스트

업그레이드 후 확인:
- [ ] ElastiCache 상태: `available`
- [ ] 노드 타입: `cache.r7g.large`
- [ ] 모든 노드 정상 작동 (Primary + Replica)
- [ ] gateway-api 파드 모두 `Running` 상태
- [ ] Redis 연결 에러 로그 없음
- [ ] CPU 사용률 < 30% (10k RPS 기준)
- [ ] 메모리 사용률 < 15% (10k RPS 기준)
- [ ] 연결 타임아웃 에러 없음

## 💰 비용 변화

### 월간 비용 (On-Demand)
```
변경 전: ~$9/month (cache.t3.micro × 2)
변경 후: ~$115/month (cache.r7g.large × 2)
증가: +$106/month
```

### 비용 최적화 옵션

**Reserved Instance (1년 약정):**
```bash
# 약 35% 할인
On-Demand: ~$115/month
Reserved (1yr): ~$75/month 💰 절약: $40/month
```

**Reserved Instance 구매 (업그레이드 안정화 후):**
```bash
aws elasticache purchase-reserved-cache-nodes-offering \
  --reserved-cache-nodes-offering-id <offering-id> \
  --reserved-cache-node-id traffic-tacos-redis-reserved-2025 \
  --cache-node-count 2 \
  --region ap-northeast-2 \
  --profile tacos
```

## 📝 변경 이력 관리

### Git Commit

```bash
cd ../traffic-tacos-infra-iac

git add var.tf ELASTICACHE-UPGRADE-GUIDE.md
git commit -m "feat(elasticache): Upgrade to cache.r7g.large for 30k RPS support

- Change node type from cache.t3.micro to cache.r7g.large
- Memory: 512MB → 13.07GB (26x increase)
- vCPU: 2 cores (x86) → 2 cores (Graviton3, 2-3x performance)
- Cost: ~$9/month → ~$115/month
- Expected RPS support: 10k → 30-40k
- Resolves Redis connection pool timeout issues

Related docs:
- deployment-repo/docs/ELASTICACHE-CAPACITY-PLANNING.md
- deployment-repo/check-redis-status.sh"

git push origin main
```

## 🔗 관련 문서

- **성능 분석 보고서**: `../../deployment-repo/docs/ELASTICACHE-CAPACITY-PLANNING.md`
- **상태 확인 스크립트**: `../../deployment-repo/check-redis-status.sh`
- **10k RPS 테스트**: `../../deployment-repo/manifests/k6/job/README-DISTRIBUTED-10K.md`
- **30k RPS 테스트**: `../../deployment-repo/manifests/k6/job/README-DISTRIBUTED-30K.md`

## ⚠️ 주의사항

1. **업그레이드 타이밍**
   - 🟢 권장: 평일 오전 (트래픽 낮은 시간)
   - 🔴 비권장: 주말, 이벤트 기간, 피크 시간

2. **모니터링**
   - 업그레이드 중: 5분 간격으로 상태 확인
   - 업그레이드 후: 24시간 집중 모니터링

3. **백업 보관**
   - 수동 백업: 최소 7일 보관
   - 자동 백업: 설정된 대로 (현재 1일)

4. **팀 공유**
   - 업그레이드 전: 팀에 사전 공지
   - 업그레이드 중: 실시간 상태 공유
   - 업그레이드 후: 결과 보고

---

**작성일:** 2025-10-07
**대상 클러스터:** traffic-tacos-redis
**예상 소요 시간:** 15-30분
**예상 다운타임:** 최소 (Multi-AZ 롤링 업그레이드)
