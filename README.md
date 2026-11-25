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
  - [OpenRouter](https://openrouter.ai/) 경유 Claude Haiku 4.5 (`anthropic/claude-haiku-4.5`) — 상품 상세 페이지 AI 챗봇
  - Daum(카카오) Postcode 서비스 — 회원가입/주문/마이페이지 주소 검색

## 핵심 기능

### 1. 세션-DB 동기화 장바구니
- 장바구니는 우선 `HttpSession`(`cartList`)에 담겨 즉시 화면에 반영되고, 로그인 상태라면 `addCart.jsp` / `updateCart.jsp` / `deleteCart.jsp` / `removeCart.jsp` / `removeSelected.jsp`가 동시에 DB의 `cart` 테이블에도 반영되어 세션과 DB 상태를 동기화합니다.
- 장바구니 담기는 로그인 후 가능하며, DB의 `cart` 테이블이 기준이고 세션의 `cartList`는 화면 표시용 복사본입니다. 로그인하면 DB에 저장된 장바구니를 세션으로 불러와, 로그아웃·세션 만료·기기 변경 후에도 장바구니가 유지됩니다.

### 2. 재고 차감 트랜잭션 (조건부 UPDATE + 롤백)
- 주문 처리(`process/processOrder.jsp`)는 (1) 주문 INSERT → (2) 구매 품목 스냅샷 저장 → (3) 상품별 재고 차감 → (4) 장바구니 DELETE를 **하나의 트랜잭션**으로 묶어 처리하고, 어느 단계에서든 실패하면 전체를 롤백합니다.
- 재고 차감(`EarPhoneRepository.decreaseStock()`)은 `UPDATE ... SET stock = stock - ? WHERE productId = ? AND stock >= ?` 한 문장으로 **확인과 차감을 DB가 한 번에** 처리합니다. 재고가 부족하면 바뀐 행이 0개가 되고, 주문 전체를 취소한 뒤 사용자에게 재고 부족 상품을 안내합니다.
- 예전에는 SELECT로 재고를 확인한 뒤 따로 UPDATE해서, 동시 주문 시 둘 다 "재고 있음"을 보고 차감해 초과 판매가 날 수 있었고, 차감 결과도 주문 처리에서 확인하지 않았습니다. 이를 발견해 위 구조로 고쳤습니다(CHANGELOG 7번).

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

### 7. AI 챗봇 (OpenRouter · Claude Haiku 4.5)
- `process/aiChatBotApi.jsp`가 OpenRouter의 `chat/completions` 엔드포인트(`anthropic/claude-haiku-4.5` 모델)를 OpenAI 호환 스키마로 직접 HTTP 호출합니다.
- 원래는 Mistral AI(`mistral-small-latest`)를 직접 호출했으나, 무료 티어 rate limit(429)이 실서비스에서 지속적으로 발생해(수일간 성공률 0%) Gemini(구글 무료 티어, 프로젝트당 일일 20회 하드 캡)와 OpenRouter 경유 여러 모델(Qwen, Llama, DeepSeek, Claude 등)을 추가로 실측 비교 후 Claude Haiku 4.5로 교체했습니다. 자세한 수치는 아래 "모델 비교 벤치마크" 참고.
- 현재 보고 있는 상품 정보와 DB에 저장된 전체 상품 목록을 시스템 프롬프트에 실시간으로 주입해, 챗봇이 실제 판매 중인 상품 안에서만 추천하도록 컨텍스트를 구성합니다. 카탈로그에 없는 제품이 언급되면 추가 설명(스펙·출처 등) 없이 "취급하지 않는다"고만 답하도록 프롬프트로 제약하지만, 이는 100% 강제되지는 않아(알려진 한계, 아래 참고) 향후 코드 단 필터링으로 보강할 수 있습니다.
- 대화 이력은 상품별로 세션(`openrouter_chat_history_{productId}`)에 누적 저장되어 문맥이 유지되며, 채팅 메시지는 `textContent` 기반으로 DOM에 삽입되어 사용자 입력이 스크립트로 실행되지 않도록 처리됩니다.
- 최대 3회 지수 백오프(1→2초) 재시도 로직이 포함되어 있어 일시적인 API 실패에 대응합니다.

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

## 모델 비교 벤치마크 (`src/main/java/bench/`)

AI 챗봇/연관상품 추천에 어떤 모델·방식을 쓸지 실측 데이터로 결정하기 위해 만든 독립 실행 스크립트입니다. 웹앱 배포와는 무관하며, 커맨드라인에서 직접 실행합니다.

- `ChatbotBenchmark.java` — 고정 질문 8개(음향성향/기기매칭/가격/스펙/배송/환각유도/범위이탈/오타) × 3회 반복으로 여러 모델을 동일 시스템 프롬프트로 호출해 응답시간·토큰 사용량·환각 여부를 CSV로 기록합니다.
- `RetryBenchmark.java` — Mistral/Gemini 호출 간 딜레이를 두고 재실행할 때 사용(무료 티어 rate limit 회피 검증용).
- `QwenCheapTest.java` — OpenRouter 모델 하나를 `args[0]`으로 지정해 단독 실측(예: `java -cp build/classes bench.QwenCheapTest anthropic/claude-haiku-4.5`).
- 실행하려면 `config.properties`에 `mistral.api.key`, `gemini.api.key`, `openrouter.api.key`가 필요합니다(앱 실행 자체에는 `openrouter.api.key`만 필요).
- 결과는 `benchmark_results/*.csv`에 저장되며 저장소에는 커밋되지 않습니다(`.gitignore`).

**측정 결과 요약** (2026-09-06~09 기준, 상품 6개 소규모 카탈로그, 질문 8개 × 3회 = 24콜 기준):

| 모델 | 성공률 | 평균 응답시간 | 비용(메시지당) | 환각 |
|---|---|---|---|---|
| Mistral Small | **0%** | — | 무료 | — |
| Gemini 2.5 Flash (구글 직접) | 4~42% (변동) | 4.8초 | 무료 | 없음 |
| Qwen 2.5 72B (OpenRouter) | 100% | 21.3초 | 유료 | **있음** (24건 중 17건) |
| Llama 3.3 70B (OpenRouter) | 100% | 9.2초 | 유료(저가) | **있음** (24건 중 37건, 언어 혼입 동반) |
| Qwen3.7-flash (OpenRouter) | 71% | 11.2초 | ~$0.0000 | 없음 |
| Qwen3.8-27b (OpenRouter) | 100% | 14.7초 | ~$0.0023 | 없음 |
| DeepSeek V4 Flash (OpenRouter) | 100% | 36.0초 | ~$0.0002 | 소량(2건) |
| Gemini 3.8 Flash (OpenRouter) | 100% | 8.9초 | ~$0.0029 | 없음 |
| Claude Sonnet 5 (OpenRouter) | 100% | 9.0초 | ~$0.0066 | 없음 |
| **Claude Haiku 4.5 (OpenRouter)** | **100%** | **3.7초** | **~$0.0022** | 없음(벤치마크 기준) |

**주요 발견**:
- Mistral Small은 벤치마크 시점(2026-09-06~08)에 24콜 전부 429로 실패 — Mistral 공식 지원팀 확인 결과 무료 티어는 계정별이 아닌 전체 공유 용량 풀이라 새 계정/키로도 해결되지 않음.
- Gemini 2.5 Flash(구글 API 직접 호출)의 실패는 `GenerateRequestsPerDayPerProjectPerModel-FreeTier` 쿼터(**프로젝트당 하루 20회**) 소진이 원인 — 분당 요청 제한이 아니라 일일 하드 캡이라 실서비스엔 부적합.
- 성공률 100%였던 Qwen 2.5 72B, Llama 3.3 70B는 실제로는 카탈로그에 없는 경쟁사 제품명(소니 WF-1000XM4, 삼성 갤럭시 버즈 프로 등)을 실존하는 것처럼 지어내는 환각이 다수 발생 — 성공률만으로는 답변 신뢰도를 판단할 수 없음을 확인.
- 최종적으로 **성공률·환각·속도·비용 전 항목에서 가장 균형 잡힌 Claude Haiku 4.5**(OpenRouter 경유)를 채택.
- **알려진 한계**: 프롬프트로 "카탈로그 밖 제품은 부연 설명 없이 거절"을 지시해도 100% 강제되지 않음 — 실서비스에서 존재하지 않는 출처 URL을 인용하며 답변한 사례가 관측됨(프롬프트만으로는 불완전, 코드 단 필터링 보강이 필요할 수 있음).

연관 상품 추천은 Gemini API 호출 대비 규칙 기반(같은 카테고리+가격 근접)이 **성공률 100% vs 33%, 응답속도 65배 이상 빠름(0.2초 vs 13~23초), 결과 결정적(동일 입력 → 항상 동일 출력)**으로 나타나 규칙 기반으로 채택했습니다(`dao/RuleBasedRecommendation.java`).

## 프로젝트 구조

```
src/main/java/
├── dao/                     # EarPhoneRepository, ReviewRepository, OrderRepository, RuleBasedRecommendation(연관상품)
├── dto/                     # EarPhone, Review, Order, OrderItem
├── util/                    # DBConnection, ConfigLoader, PasswordUtil, HtmlUtil, CsrfUtil, RateLimiter, ValidationUtil
├── bench/                   # 챗봇/추천 모델 비교 벤치마크 스크립트 (위 "모델 비교 벤치마크" 참고)
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

   openrouter.api.key=YOUR_OPENROUTER_API_KEY

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
