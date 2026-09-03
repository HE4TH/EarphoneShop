# CHANGELOG

이 문서는 Code Sound(EarPhoneMarket) 프로젝트에 가해진 변경사항을 시간순으로 기록합니다.
다른 AI 세션이 이 문서만 읽고도 프로젝트의 현재 상태와 맥락을 파악할 수 있도록 작성되었습니다.
기능 설명 자체는 `README.md`를 참고하고, 이 문서는 **"왜 이렇게 바뀌었는지"와 "무엇이 아직 안 끝났는지"** 에 집중합니다.

## 프로젝트 기본 정보

- 이클립스 Dynamic Web Project (Java 21 / JSP·Servlet / Jakarta EE 6.0 / Tomcat 11.0 / MSSQL)
- 로컬 경로: `C:\Users\tmdal\eclipse-workspace\EarPhoneMarket`
- GitHub: `https://github.com/HE4TH/EarphoneShop` (main 브랜치)
- 빌드 도구 없음(순수 Eclipse + javac). `src/main/java`가 소스 루트, 출력은 `build/classes` (Tomcat이 이 경로를 `WEB-INF/classes`로 직접 매핑해서 서빙 — `server.xml`의 `PreResources` 참고)
- 새 Java 클래스를 추가/수정했는데 반영이 안 되면: Eclipse에서 **프로젝트 Refresh → Clean → 서버 Clean/재시작**. (수동으로 `javac`를 돌려 `build/classes`에 넣어 반영시킨 적도 있음 — `--release 21`로 컴파일해야 함, 최신 JDK로 그냥 컴파일하면 class version 불일치로 서버가 로드를 거부함)

## 커밋 이력 (오래된 순)

### 1. `b522894` 초기 커밋
- GitHub 공개를 위해 하드코딩된 DB 접속정보 / Mistral·Gemini API 키를 `src/main/java/config.properties`(gitignore 대상)로 분리, `util/ConfigLoader.java` 도입
- `config.properties.example`(템플릿, 커밋됨)과 `config.properties`(실제 값, 미커밋) 분리 패턴 확립
- `.gitignore` 작성 (`.settings/`, `.classpath`, `.project`, `build/`, `WEB-INF/lib/`, `config.properties`)

### 2. `54a139b` 실명 언급 제거
- 코드 주석에 남아있던 사용자 실명 제거

### 3. `a485e0a` 어투 정리
- AI가 생성한 이모지/과장 말투 주석을 전체 파일에 걸쳐 담백하게 정리

### 4. `4687ca4` 업로드 경로 분리
- `processAddProduct.jsp`에 하드코딩돼 있던 Windows 절대경로(사용자명 노출)를 `config.properties`의 `upload.base.path`로 이동

### 5. `2cfd976` 보안 강화 + 대규모 기능 추가 (가장 큰 커밋)

**보안 (요청 기반 코드 리뷰 → 항목별 순차 적용)**
- `util/PasswordUtil.java`: PBKDF2WithHmacSHA256(120,000 iterations) 비밀번호 해싱. **기존에 평문으로 저장된 계정은 이 변경 이후 로그인 불가 — 재가입 필요.** `member.passwd` 컬럼도 `VARCHAR(255)`로 늘려야 함(해시값이 70~80자).
- `util/HtmlUtil.java`: `escape()`(HTML 속성/본문용) / `escapeJs()`(`<script>` 내부 JS 문자열용) — DB/세션/쿼리파라미터 출력 전 구간에 적용
- `util/CsrfUtil.java`: 세션 기반 동기화 토큰. 주문/취소/탈퇴/리뷰작성/상품등록·수정/주문상태변경에 적용
- `util/RateLimiter.java`: 인메모리 IP/계정 기반 요청 제한 (로그인 5분5회, 가입 1시간3회, 리뷰 1분3회). **단일 인스턴스 전제 — 서버를 여러 대로 늘리면 Redis 등 공유 저장소로 교체 필요**
- `util/ValidationUtil.java`: 이메일 형식, 비밀번호 규칙(영문+숫자 8자+), 가격/재고 음수 방지
- `request.changeSessionId()`로 로그인 시 세션 고정 공격 방지
- `logout.jsp`/`processLogin.jsp`의 `prevPage` 파라미터에 외부 URL 필터링 추가 (오픈 리다이렉트 방지)

**신규 기능 (DB 스키마 변경 필요 — README "실행 방법" 섹션의 SQL 참고)**
- 리뷰/평점: `dbo.review` 테이블, `dao/ReviewRepository.java`, `process/addReview.jsp`, 상품목록 "리뷰많은순" 정렬을 실제 데이터 기반으로 변경
- 주문 상태/상세/취소: `orders.orderStatus` 컬럼, `dbo.order_items` 테이블(구매품목 스냅샷 — 기존엔 장바구니가 결제 후 삭제되면 뭘 샀는지 알 방법이 없었음), `dao/OrderRepository.java`, `process/cancelOrder.jsp`(취소 시 재고 자동 복원)
- 관리자: `adminEditProduct.jsp` + `process/processEditProduct.jsp`(상품 수정, 이미지 재업로드 안 하면 기존 파일 유지), `adminOrders.jsp` + `process/updateOrderStatus.jsp`(전체 주문 조회/상태변경)
- 상품 필터링(`EarPhoneRepository.getFilteredProducts()` — 카테고리+브랜드+가격대) + 페이지네이션(12개 단위, 상품목록/검색결과 둘 다)
- 반응형 CSS(`@media` 768px/480px) 전체 페이지 적용 + viewport 메타 태그 (이전엔 프로젝트 전체에 viewport 태그가 하나도 없어서 모바일에서 미디어쿼리 자체가 무의미했음)

**과정에서 발견/수정한 버그**
- 배포된 클래스가 최신 소스와 어긋나 있던 문제(신규 클래스 미컴파일) — 반복적으로 발생, Eclipse Clean 필요성 다수 언급
- `login.jsp`의 `prevPage` 기본값이 상대경로(`"main.jsp"`)라서, `login.jsp`를 직접 열어 로그인하면 `/process/main.jsp`(404)로 잘못 리다이렉트되던 버그 → `request.getContextPath() + "/main.jsp"`로 수정
- `processLogin.jsp`에 아이디/비밀번호 null 체크 추가 (없으면 NPE로 500 에러)

**실제 브라우저(Claude in Chrome)로 회원가입→로그인→리뷰→주문→취소→관리자기능까지 전체 플로우 검증 완료.** 테스트 후 남은 흔적(테스트 계정 `tester0902`, 가격 변경, 테스트 주문/리뷰)은 직접 DB 정리해서 원상복구함.

### 6. `df86a35` Gemini 연관상품 추천 → 규칙 기반 교체

- **배경**: `dao/EarPhoneRecommendation.java`(Gemini API 기반 연관상품 추천)가 README에는 기능으로 적혀있었지만 **실제로는 어떤 JSP에서도 호출되지 않는 죽은 코드**였음 (이번에 처음 발견).
- `src/main/java/bench/` 패키지에 독립 실행 벤치마크 스크립트 작성:
  - `ChatbotBenchmark.java` / `RetryBenchmark.java`: 챗봇용 Mistral Small vs Gemini 2.5 Flash vs Qwen 2.5 72B(OpenRouter) vs Llama 3.3 70B(OpenRouter) 비교. 고정 질문 8개(음향성향/기기매칭/가격/스펙/배송/환각유도/범위이탈/오타) × 3회.
  - 삭제됨: `RecommendationBenchmark.java`(Gemini vs 규칙기반 추천 비교용, 결론 낸 뒤 제거), `GeminiKeyTest.java`(스크래치 테스트)
- **실측 결과**: Mistral이 가장 균형(성공률100%, 3.6초, 범위이탈 질문 완벽 거절). Gemini는 무료티어 rate limit으로 실패율 있음(83%). Qwen/Llama는 OpenRouter 경유라 3~5배 느림, Llama는 범위 이탈 질문(향수 추천)에 실제 브랜드를 추천해버리는 스코프 위반 발견. 환각 테스트(카탈로그에 없는 제품 문의)는 4개 모델 전부 통과.
- 연관상품 추천 자체는 Gemini(성공률33%, 13~23초, 비결정적) vs 규칙기반(성공률100%, 0.2초, 결정적)을 비교해 **규칙기반 채택** → `dao/RuleBasedRecommendation.java` 신설, `detail.jsp`에 "함께 보면 좋은 상품" 섹션으로 **처음 실제 연결**.

## 아직 커밋 안 된 변경사항 (2026-09-03 기준)

1. **챗봇 `<br>` 노출 버그 수정**
   - 원인: XSS 방지 작업 때 `detail.jsp`의 채팅 렌더링을 `insertAdjacentHTML`→`textContent`로 바꿨는데, 서버(`process/aiChatBotApi.jsp`)는 여전히 개행을 `<br>` 문자열로 변환해서 보내고 있었음. `textContent`는 태그를 해석 안 하니 `<br>`이 글자 그대로 노출됨.
   - 수정: 서버는 `\n`(실제 개행)으로 복원, `resource/css/chatbot.css`의 `.msg-bubble-ai`/`.msg-bubble-user`에 `white-space: pre-line` 추가.

2. **상세페이지 탭 스크롤 자동 전환**
   - `detail.jsp`에 `updateActiveTabOnScroll()` 추가 — 스크롤 위치에 따라 상품상세/구매후기/Q&A 탭의 active 표시가 자동 전환됨.

### 시도했다가 원복한 것 (참고용, 현재 코드엔 없음)
- 헤더/메인페이지/상품목록에 "전체상품" 진입점을 추가하는 네비게이션 개편(헤더 nav, 상품목록 내 카테고리 탭, 메인 "전체 이어폰" 버튼)을 만들었으나 사용자 요청으로 전부 원복함. 원래 문제의식(전체상품 목록에 도달할 방법이 장바구니 경유밖에 없음)은 **아직 해결 안 됨** — 재작업 시 참고.

## 알려진 이슈 / 미해결 사항

- `processOrder.jsp`의 결제 트랜잭션에 명시적 commit/rollback이 없음 — 재고차감/주문삽입 중 하나가 실패해도 앞 단계는 이미 커밋됨 (MSSQL 기본 autocommit). 실서비스라면 손봐야 함.
- 전체상품 목록에 접근하는 진입점이 마땅치 않음(위 "시도했다가 원복한 것" 참고) — 재작업 필요 시 사용자와 디자인 먼저 합의할 것.
- 회원 관리(전체 회원 목록/강제 탈퇴 등) 관리자 화면 없음 — 논의됐지만 범위에서 제외됨.
- `bench/` 패키지는 프로덕션 배포와 무관한 실험용 스크립트 — `openrouter.api.key`, `gemini.api.key`는 앱 실행 자체엔 불필요, 벤치마크 재실행 시에만 필요.

## 재개 시 체크리스트

1. `git log --oneline`으로 현재 커밋 상태 확인, `git status`로 미커밋 변경 확인
2. DB 스키마가 README "실행 방법" 섹션의 SQL과 일치하는지 확인 (`orderStatus` 컬럼, `order_items`/`review` 테이블, `passwd` 컬럼 길이)
3. `config.properties`가 로컬에 존재하고 `build/classes/config.properties`에도 복사돼 있는지 확인 (ConfigLoader가 클래스패스 리소스로 로드함)
4. Eclipse에서 새 클래스 인식 안 될 때: Refresh → Clean → 서버 Clean/재시작
