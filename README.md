# Code Sound (코드 사운드)

Java(JSP/Servlet) 기반으로 제작한 이어폰 전문 쇼핑몰 웹 애플리케이션입니다. 상품 조회/검색/필터링, 장바구니, 주문/결제/배송상태/취소, 리뷰, 연관 상품 추천, 회원 관리, 관리자 페이지, AI 챗봇 상담 등 커머스 사이트의 핵심 흐름을 직접 구현했습니다.

## 기술 스택

- **Language**: Java 21
- **Web**: JSP, Servlet (Jakarta EE 6.0, `web.xml` 기반)
- **Server**: Apache Tomcat 11.0
- **Database**: Microsoft SQL Server (MSSQL), JDBC (`mssql-jdbc-13.4.0`)
- **View**: JSP + JSTL(`taglibs-standard`), 모듈화된 CSS, 반응형 레이아웃(`@media` 브레이크포인트)
- **파일 업로드**: `commons-fileupload`, `cos.jar` (상품 등록/수정 시 이미지 업로드, `multipart/form-data`)
- **보안**: PBKDF2 비밀번호 해싱, HTML/JS 컨텍스트별 출력 이스케이프, CSRF 동기화 토큰, 인메모리 rate limiting (모두 JDK 표준 라이브러리만으로 직접 구현, 외부 의존성 없음)
- **외부 API 연동**:
  - [Mistral AI](https://mistral.ai/) Chat Completions API — 상품 상세 페이지 AI 챗봇
  - Daum(카카오) Postcode 서비스 — 회원가입/주문/마이페이지 주소 검색

## 핵심 기능

### 1. 세션-DB 동기화 장바구니
- 장바구니는 우선 `HttpSession`(`cartList`)에 담겨 즉시 화면에 반영되고, 로그인 상태라면 `addCart.jsp` / `updateCart.jsp` / `deleteCart.jsp` / `removeCart.jsp` / `removeSelected.jsp`가 동시에 DB의 `cart` 테이블에도 반영되어 세션과 DB 상태를 동기화합니다.
- 비로그인 사용자도 세션 기반으로 장바구니 이용이 가능하고, 로그인 시 DB에 저장된 장바구니 내역과 합쳐지는 구조입니다.

### 2. 2단계 재고 검증 트랜잭션
- 주문 처리(`process/processOrder.jsp`)는 (1) 주문 INSERT → (2) 구매 품목 스냅샷 저장 → (3) 상품별 재고 차감 → (4) 장바구니 DELETE 순으로 처리됩니다.
- 재고 차감은 `EarPhoneRepository.updateStock()`에서 **현재 재고를 먼저 SELECT로 확인한 뒤, 요청 수량보다 재고가 충분할 때만 UPDATE로 차감**하는 2단계 검증(조회 → 조건부 갱신) 방식으로 동작하여 재고 부족 상태에서의 초과 판매를 방지합니다.

### 3. 주문 상태 관리 / 주문 상세 / 주문 취소
- 주문 시 구매 품목이 `order_items` 테이블에 스냅샷으로 저장되어, 장바구니가 결제 후 삭제되더라도 마이페이지에서 무엇을 샀는지 확인할 수 있습니다.
- `orders.orderStatus` 컬럼으로 배송준비중 / 배송중 / 배송완료 / 취소됨 상태를 실제로 관리하며, 마이페이지에서 상태별 색상 배지로 표시됩니다.
- 배송준비중 상태의 주문은 사용자가 직접 취소할 수 있고(`process/cancelOrder.jsp`), 취소 시 차감됐던 재고가 자동 복원됩니다.

### 4. 상품 리뷰 / 평점
- 로그인한 사용자는 상품 상세 페이지에서 평점(1~5)과 후기를 남길 수 있습니다(`process/addReview.jsp`).
- 상품별 리뷰 목록, 평균 평점, 리뷰 개수가 상세 페이지에 표시되고, 상품 목록의 "리뷰많은순" 정렬도 실제 리뷰 개수 기준으로 동작합니다.

### 5. 연관 상품 추천 (규칙 기반)
- 상품 상세 페이지 하단에 같은 카테고리 내에서 가격이 가장 비슷한 상품 4개를 "함께 보면 좋은 상품"으로 추천합니다(`dao/RuleBasedRecommendation.java`).
- 원래는 Gemini API로 구현했었으나, `bench/` 패키지의 벤치마크 스크립트로 실측한 결과 무료 티어 rate limit으로 인한 잦은 실패(18회 중 12회, 67%), 호출마다 달라지는 비결정적 결과, 65배 느린 응답속도(13~23초 vs 0.2초)에 비해 추천 품질 차이가 거의 없어(성공 시 규칙기반과 결과 대부분 일치) 규칙 기반으로 교체했습니다.

### 6. 상품 필터링 / 페이지네이션
- 상품 목록과 검색 결과 모두 카테고리, 브랜드, 가격대(5만원 이하 ~ 30만원 이상 프리셋) 조합 필터링을 지원합니다(`EarPhoneRepository.getFilteredProducts()`).
- 정렬(최신순/낮은가격순/높은가격순/리뷰많은순)과 필터가 함께 적용되며, 결과는 12개 단위로 페이지네이션됩니다.

### 7. Mistral AI 챗봇
- `process/aiChatBotApi.jsp`가 Mistral AI의 `chat/completions` 엔드포인트(`mistral-small-latest` 모델)를 직접 HTTP로 호출합니다.
- 현재 보고 있는 상품 정보와 DB에 저장된 전체 상품 목록을 시스템 프롬프트에 실시간으로 주입해, 챗봇이 실제 판매 중인 상품 안에서만 추천하도록 컨텍스트를 구성합니다.
- 대화 이력은 상품별로 세션(`mistral_chat_history_{productId}`)에 누적 저장되어 문맥이 유지되며, 채팅 메시지는 `textContent` 기반으로 DOM에 삽입되어 사용자 입력이 스크립트로 실행되지 않도록 처리됩니다.

### 8. Kakao(Daum) 주소 API 연동
- `join.jsp`, `order.jsp`, `myPage.jsp`에서 Daum Postcode 스크립트(`t1.daumcdn.net/mapjsapi/bundle/postcode`)를 팝업으로 띄워 우편번호/지번·도로명 주소를 검색해 폼에 자동 입력합니다.

### 9. CSS 모듈화 / 반응형
- `resource/style.css`가 진입점 역할을 하며 `@import`로 `common.css`, `main.css`, `products.css`, `detail.css`, `cart.css`, `member.css`, `chatbot.css`를 페이지 성격별로 분리해 관리합니다.
- 각 CSS에 768px/480px 기준 `@media` 브레이크포인트가 적용되어 있어 모바일에서 헤더, 상품 그리드, 장바구니, 상세 페이지, 챗봇 창 등이 레이아웃을 재배치합니다.

### 10. 보안
- **비밀번호 해싱**: PBKDF2WithHmacSHA256(120,000 iterations)로 해싱 후 저장(`util/PasswordUtil.java`), 평문 저장/비교 없음.
- **XSS 방지**: DB/세션/쿼리파라미터에서 온 값을 출력할 때 `util/HtmlUtil.java`로 컨텍스트별(HTML 속성/본문, `<script>` 내부 JS 문자열) 이스케이프 처리.
- **CSRF 방지**: 주문/취소/회원탈퇴/리뷰작성/상품등록·수정/주문상태변경 등 상태 변경 요청에 세션 기반 동기화 토큰 적용(`util/CsrfUtil.java`).
- **세션 고정 공격 방지**: 로그인 성공 시 `request.changeSessionId()`로 세션 ID 재발급.
- **Rate Limiting**: 로그인(IP+아이디 조합, 5분 5회), 회원가입(IP, 1시간 3회), 리뷰 작성(계정당 1분 3회)에 인메모리 요청 제한 적용(`util/RateLimiter.java`).
- **오픈 리다이렉트 방지**: 로그인/로그아웃 후 이동 경로(`prevPage`)가 외부 URL이면 무시하고 내부 페이지로 강제.
- **서버단 입력 검증**: 이메일 형식, 비밀번호 규칙(영문+숫자 8자 이상), 상품 가격/재고 음수 방지 등(`util/ValidationUtil.java`).

### 11. 관리자 기능
- 상품 등록/수정/삭제 — 수정 시 이미지를 다시 올리지 않으면 기존 파일을 그대로 유지합니다(`adminEditProduct.jsp`, `process/processEditProduct.jsp`).
- 전체 주문 조회 및 상태 변경 — 주문자, 구매 품목, 금액, 배송지를 한 화면에서 확인하고 상태(배송준비중/배송중/배송완료/취소됨)를 변경할 수 있습니다(`adminOrders.jsp`).

### 그 외 기능
- 회원가입/로그인/로그아웃/회원정보 수정/회원 탈퇴 (`join.jsp`, `login.jsp`, `myPage.jsp` 등)
- 아이디 중복 확인(`process/checkId.jsp`, 비동기 fetch)
- 카테고리별 상품 목록(유선/무선) 및 검색(`products.jsp`, `searchResult.jsp`)

## 프로젝트 구조

```
src/main/java/
├── dao/                     # EarPhoneRepository, ReviewRepository, OrderRepository, RuleBasedRecommendation(연관상품)
├── dto/                     # EarPhone, Review, Order, OrderItem
├── util/                    # DBConnection, ConfigLoader, PasswordUtil, HtmlUtil, CsrfUtil, RateLimiter, ValidationUtil
├── bench/                   # 챗봇/추천 모델 비교 벤치마크 스크립트 (아래 "모델 비교 벤치마크" 참고)
└── config.properties.example  # 설정 파일 템플릿

src/main/webapp/
├── include/                 # 공통 헤더/푸터
├── process/                 # 회원가입, 로그인, 장바구니, 주문/취소, 리뷰, 관리자 처리 등 처리용 JSP
├── resource/                # 모듈화된 CSS(반응형 포함), 상품 이미지
├── adminMain.jsp            # 관리자: 상품 등록/삭제/수정 진입
├── adminEditProduct.jsp     # 관리자: 상품 수정
├── adminOrders.jsp          # 관리자: 주문 조회/상태 변경
└── *.jsp                    # 메인/상품목록/상세/장바구니/주문/마이페이지 등 화면
```

## 실행 방법

1. **사전 준비**
   - JDK 21, Apache Tomcat 11.0, MSSQL Server가 설치되어 있어야 합니다.
   - MSSQL에 `earphone_shop` 데이터베이스와 `member`, `earphone`, `cart`, `orders` 테이블을 준비합니다.
   - 아래 스키마도 추가로 필요합니다 (주문상태/주문상세/리뷰 기능):
     ```sql
     ALTER TABLE dbo.orders ADD orderStatus VARCHAR(20) NOT NULL DEFAULT N'배송준비중';

     CREATE TABLE dbo.order_items (
         orderItemId INT IDENTITY(1,1) PRIMARY KEY,
         orderId     INT NOT NULL,
         productId   BIGINT NOT NULL,
         pName       NVARCHAR(200) NOT NULL,
         price       INT NOT NULL,
         quantity    INT NOT NULL,
         FOREIGN KEY (orderId) REFERENCES dbo.orders(orderId)
     );

     CREATE TABLE dbo.review (
         reviewId   INT IDENTITY(1,1) PRIMARY KEY,
         productId  BIGINT NOT NULL,
         mId        VARCHAR(50) NOT NULL,
         rating     INT NOT NULL,
         content    NVARCHAR(1000) NOT NULL,
         createDate DATETIME NOT NULL DEFAULT GETDATE()
     );
     ```
   - `member.passwd` 컬럼은 해시값(70~80자)이 저장되므로 길이를 넉넉히 늘려야 합니다: `ALTER TABLE dbo.member ALTER COLUMN passwd VARCHAR(255) NOT NULL;` (기존에 평문으로 저장된 테스트 계정은 이후 로그인이 안 되므로 재가입 필요)

2. **설정 파일 생성**
   - `src/main/java/config.properties.example`을 같은 위치에 `config.properties`로 복사한 뒤, 본인의 DB 접속 정보와 API 키를 입력합니다.
   ```properties
   db.url=jdbc:sqlserver://localhost:1433;databaseName=earphone_shop;encrypt=true;trustServerCertificate=true;loginTimeout=30;
   db.user=YOUR_DB_USER
   db.password=YOUR_DB_PASSWORD

   mistral.api.key=YOUR_MISTRAL_API_KEY

   upload.base.path=C:\\path\\to\\EarPhoneMarket\\src\\main\\webapp\\resource
   ```
   - `upload.base.path`는 관리자 페이지에서 상품 이미지를 업로드할 때 저장되는 절대경로입니다. 본인의 로컬 프로젝트 경로에 맞게 지정해 주세요.
   - `config.properties`는 `.gitignore`에 등록되어 있어 저장소에는 올라가지 않습니다.

3. **Eclipse에서 실행**
   - Eclipse에서 `File > Import > Existing Projects into Workspace`로 프로젝트를 불러옵니다.
   - Tomcat 11.0 서버 런타임을 등록하고, 이 프로젝트를 서버에 추가합니다.
   - 서버를 실행하면 `http://localhost:8080/EarPhoneMarket/main.jsp`에서 접속할 수 있습니다.
   - `util` 패키지에 새 클래스를 추가한 직후에는 Eclipse가 아직 컴파일하지 못한 상태일 수 있으니, 이상 동작 시 프로젝트 **Clean** 후 서버를 **Clean/재시작**해 주세요.

4. **의존 라이브러리**
   - `src/main/webapp/WEB-INF/lib`에 필요한 jar(`mssql-jdbc`, `commons-fileupload`, `commons-io`, `cos`, `taglibs-standard-*`)를 직접 배치해야 합니다(라이브러리 jar는 저장소에 포함되어 있지 않습니다).

## 모델 비교 벤치마크 (`src/main/java/bench/`)

AI 챗봇/연관상품 추천에 어떤 모델·방식을 쓸지 실측 데이터로 결정하기 위해 만든 독립 실행 스크립트입니다. 웹앱 배포와는 무관하며, 커맨드라인에서 직접 실행합니다.

- `ChatbotBenchmark.java` — 고정 질문 8개(음향성향/기기매칭/가격/스펙/배송/환각유도/범위이탈/오타) × 3회 반복으로 **Mistral Small / Gemini 2.5 Flash / Qwen 2.5 72B / Llama 3.3 70B**(Qwen·Llama는 OpenRouter 경유)를 동일 시스템 프롬프트로 호출해 응답시간·토큰 사용량·환각 여부를 CSV로 기록합니다.
- `RetryBenchmark.java` — Mistral/Gemini 호출 간 딜레이를 두고 재실행할 때 사용(무료 티어 rate limit 회피).
- 실행 예: `java -cp "build/classes;src/main/webapp/WEB-INF/lib/mssql-jdbc-13.4.0.jre11.jar" bench.ChatbotBenchmark`
- 실행하려면 `config.properties`에 `mistral.api.key`, `gemini.api.key`, `openrouter.api.key`가 필요합니다(앱 실행 자체에는 `gemini.api.key`/`openrouter.api.key`가 불필요 — 벤치마크 전용).
- 결과는 `benchmark_results/*.csv`에 저장되며 저장소에는 커밋되지 않습니다(`.gitignore`).

**측정 결과 요약** (2026-09-03 기준, 상품 6개 소규모 카탈로그):

| 모델 | 성공률 | 평균 응답시간 | 비고 |
|---|---|---|---|
| Mistral Small | 100% | 3.6초 | 범위 이탈 질문 완벽 거절, 가장 균형 잡힘 |
| Gemini 2.5 Flash | 83% | 8.9초 | 무료 티어 rate limit으로 실패율 있음 |
| Qwen 2.5 72B (OpenRouter) | ~96% | 20.4초 | 응답 중 중국어 혼입 1건, 범위 이탈 대응 불안정 |
| Llama 3.3 70B (OpenRouter) | 100% | 12.0초 | 범위 이탈 질문에 실제 향수 브랜드를 추천(스코프 위반) |

환각 테스트(카탈로그에 없는 제품 문의)는 4개 모델 모두 지어내지 않고 정직하게 답변해 통과했습니다.

연관 상품 추천은 Gemini API 호출 대비 규칙 기반(같은 카테고리+가격 근접)이 **성공률 100% vs 33%, 응답속도 65배 이상 빠름(0.2초 vs 13~23초), 결과 결정적(동일 입력 → 항상 동일 출력)**으로 나타나 규칙 기반으로 채택했습니다(`dao/RuleBasedRecommendation.java`).
