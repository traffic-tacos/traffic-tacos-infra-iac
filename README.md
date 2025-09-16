# Traffic Tacos Infrastructure as Code

Traffic Tacos 프로젝트의 AWS 인프라를 Terraform으로 관리하는 Infrastructure as Code 레포지토리입니다.

## 아키텍처 개요

이 프로젝트는 AWS 기반의 3-tier 아키텍처를 구성합니다:

- **Public Tier**: 인터넷 게이트웨이를 통한 외부 접근이 가능한 서브넷
- **Private App Tier**: 애플리케이션 서버를 위한 프라이빗 서브넷 (NAT 게이트웨이 통해 인터넷 접근)
- **Private DB Tier**: 데이터베이스 서버를 위한 격리된 프라이빗 서브넷

## 지원되는 클라우드 프로바이더

- **AWS**: 기본 인프라 프로비저닝
- **Kubernetes**: 컨테이너 오케스트레이션
- **Helm**: Kubernetes 패키지 관리

## 프로젝트 구조

```bash

├── README.md                
├── backend.tf               # Terraform 백엔드 설정 (S3)
├── main.tf                  # 메인 Terraform 구성  
├── atlantis.yaml            # 아틀란티스 프로젝트 구성
├── providers.tf             # 프로바이더 설정
└── modules/
    ├── ec2/                 # EC2 모듈
    │   ├── ec2.tf          # EC2 인스턴스 리소스 정의
    │   ├── out.tf          # EC2 모듈 출력
    │   ├── sg.tf           # Security Group 정의
    │   └── var.tf          # EC2 모듈 변수
    ├── eks/                 # EKS 모듈
    │   ├── eks.tf          # EKS 클러스터 리소스 정의
    │   ├── iam.tf          # EKS IAM 역할 및 정책
    │   ├── sg.tf           # EKS Security Group 정의
    │   └── var.tf          # EKS 모듈 변수
    ├── rds/                 # RDS 모듈 (개발 예정)
    └── vpc/                 # VPC 모듈
        ├── out.tf          # VPC 모듈 출력
        ├── var.tf          # VPC 모듈 변수
        └── vpc.tf          # VPC 리소스 정의
```

## 네트워크 구성

### 기본 설정

- **VPC CIDR**: 10.180.0.0/20
- **리전**: ap-northeast-2 (서울)
- **가용 영역**: ap-northeast-2a, ap-northeast-2c

### 서브넷 구성

| Tier | CIDR 범위 | 용도 |
|------|-----------|------|
| Public | 10.180.0.0/24, 10.180.1.0/24 | ALB, Bastion 호스트 |
| Private App | 10.180.4.0/22, 10.180.8.0/22 | 애플리케이션 서버, EKS 노드 |
| Private DB | 10.180.2.0/24, 10.180.3.0/24 | RDS, ElastiCache |

### 네트워킹 기능

- 인터넷 게이트웨이 (Public 서브넷 인터넷 접근)
- NAT 게이트웨이 (Private 서브넷 아웃바운드 트래픽)
- VPC 엔드포인트 (필요시 추가 예정)

## 전제 조건

- Terraform >= 1.5.0
- AWS CLI 설정 및 인증
- AWS 프로필 설정 (`tacos` 프로필 권장)

## 초기 설정

1. **AWS 프로필 설정**:

   ```bash
   aws configure --profile tacos
   ```

2. **Terraform 초기화**:

   ```bash
   terraform init
   ```

3. **워크스페이스 선택** (필요시):

   ```bash
   terraform workspace select <workspace> || terraform workspace new <workspace>
   ```

## 배포

1. **계획 확인**:

   ```bash
   terraform plan
   ```

2. **인프라 배포**:

   ```bash
   terraform apply
   ```

3. **리소스 확인**:

   ```bash
   terraform output
   ```

## 모듈 설명

### VPC 모듈 (`modules/vpc/`)

완전한 VPC 인프라를 프로비저닝합니다:

- VPC, 서브넷 (Public/Private), 라우팅 테이블
- 인터넷 게이트웨이 및 NAT 게이트웨이
- 보안 그룹 및 네트워크 ACL
- Kubernetes 태그 지원

**입력 변수**:

- `vpc_cidr`: VPC CIDR 블록
- `name`: 리소스 이름 접두사
- `azs`: 가용 영역 목록
- `public_cidrs`: Public 서브넷 CIDR 목록
- `private_app_cidrs`: Private App 서브넷 CIDR 목록
- `private_db_cidrs`: Private DB 서브넷 CIDR 목록

### RDS 모듈 (`modules/rds/`)

개발 예정 기능:

- Aurora MySQL 클러스터
- RDS 서브넷 그룹
- 보안 그룹 및 파라미터 그룹
- 모니터링 및 백업 설정

## 태그 정책

모든 리소스는 다음과 같은 태그를 포함합니다:
-  `Project` : ticket-traffic
- `ManagedBy`: Terraform
- 추가 사용자 정의 태그

## 보안 고려사항

- Private 서브넷은 인터넷 직접 접근 불가
- NAT 게이트웨이를 통한 아웃바운드 트래픽만 허용
- 보안 그룹을 통한 세부적인 트래픽 제어
- VPC 엔드포인트를 통한 AWS 서비스 접근 (추후 구현)

## 모니터링 및 로깅

- AWS CloudTrail을 통한 API 호출 로깅
- VPC Flow Logs를 통한 네트워크 트래픽 로깅
- CloudWatch를 통한 메트릭 및 알람

## 개발자 가이드

### 새로운 모듈 추가

1. `modules/` 디렉토리에 새 모듈 디렉토리 생성
2. `main.tf`, `var.tf`, `out.tf` 파일 생성
3. `main.tf`에서 모듈 호출
4. README.md 작성

### 코드 포맷팅

```bash
terraform fmt -recursive
```

### 유효성 검증

```bash
terraform validate
   ```

## 트러블슈팅

### 일반적인 문제

1. **백엔드 설정 오류**
   - S3 버킷이 존재하는지 확인
   - IAM 권한이 올바르게 설정되었는지 확인

2. **리소스 생성 실패**
   - AWS 서비스 제한 확인 (예: VPC 수 제한)
   - 가용 영역별 리소스 할당량 확인

3. **네트워크 연결 문제**
   - 보안 그룹 규칙 확인
   - 라우팅 테이블 설정 검증

## 기여 가이드

1. Fork 및 브랜치 생성
2. 변경사항 구현
3. 테스트 및 유효성 검증
4. Pull Request 생성

## 라이선스

이 프로젝트는 Traffic Tacos 팀의 내부 사용을 위한 프로젝트입니다.
