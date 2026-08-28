# Code Sound (코드 사운드)

Java(JSP/Servlet) 기반으로 제작한 이어폰 전문 쇼핑몰 웹 애플리케이션입니다. 상품 조회/검색, 장바구니, 주문/결제, 회원 관리, AI 챗봇 상담, AI 상품 추천 등 커머스 사이트의 핵심 흐름을 직접 구현했습니다.

## 기술 스택

- **Language**: Java 21
- **Web**: JSP, Servlet (Jakarta EE 6.0, `web.xml` 기반)
- **Server**: Apache Tomcat 11.0
- **Database**: Microsoft SQL Server (MSSQL), JDBC (`mssql-jdbc-13.4.0`)
- **View**: JSP + JSTL(`taglibs-standard`), 모듈화된 CSS
- **파일 업로드**: `commons-fileupload`, `cos.jar` (상품 등록 시 이미지 업로드, `multipart/form-data`)
- **외부 API 연동**:
  - [Mistral AI](https://mistral.ai/) Chat Completions API — 상품 상세 페이지 AI 챗봇
  - Google Gemini API — 연관 상품 AI 추천
  - Daum(카카오) Postcode 서비스 — 회원가입/주문/마이페이지 주소 검색

## 핵심 기능

### 1. 세션-DB 동기화 장바구니
- 장바구니는 우선 `HttpSession`(`cartList`)에 담겨 즉시 화면에 반영되고, 로그인 상태라면 `addCart.jsp` / `updateCart.jsp` / `deleteCart.jsp` / `removeCart.jsp` / `removeSelected.jsp`가 동시에 DB의 `cart` 테이블에도 반영되어 세션과 DB 상태를 동기화합니다.
- 비로그인 사용자도 세션 기반으로 장바구니 이용이 가능하고, 로그인 시 DB에 저장된 장바구니 내역과 합쳐지는 구조입니다.

### 2. 2단계 재고 검증 트랜잭션
- 주문 처리(`process/processOrder.jsp`)는 (1) 주문 INSERT → (2) 상품별 재고 차감 → (3) 장바구니 DELETE 순으로 하나의 커넥션(`conn`) 안에서 처리됩니다.
- 재고 차감은 `EarPhoneRepository.updateStock()`에서 **현재 재고를 먼저 SELECT로 확인한 뒤, 요청 수량보다 재고가 충분할 때만 UPDATE로 차감**하는 2단계 검증(조회 → 조건부 갱신) 방식으로 동작하여 재고 부족 상태에서의 초과 판매를 방지합니다.

### 3. Mistral AI 챗봇
- `process/aiChatBotApi.jsp`가 Mistral AI의 `chat/completions` 엔드포인트(`mistral-small-latest` 모델)를 직접 HTTP로 호출합니다.
- 현재 보고 있는 상품 정보와 DB에 저장된 전체 상품 목록을 시스템 프롬프트에 실시간으로 주입해, 챗봇이 실제 판매 중인 상품 안에서만 추천하도록 컨텍스트를 구성합니다.
- 대화 이력은 상품별로 세션(`mistral_chat_history_{productId}`)에 누적 저장되어 문맥이 유지됩니다.

### 4. Kakao(Daum) 주소 API 연동
- `join.jsp`, `order.jsp`, `myPage.jsp`에서 Daum Postcode 스크립트(`t1.daumcdn.net/mapjsapi/bundle/postcode`)를 팝업으로 띄워 우편번호/지번·도로명 주소를 검색해 폼에 자동 입력합니다.

### 5. CSS 모듈화
- `resource/style.css`가 진입점 역할을 하며 `@import`로 `common.css`, `main.css`, `products.css`, `detail.css`, `cart.css`, `member.css`, `chatbot.css`를 페이지 성격별로 분리해 관리합니다.

### 그 외 기능
- 회원가입/로그인/로그아웃/회원정보 수정/회원 탈퇴 (`join.jsp`, `login.jsp`, `myPage.jsp` 등)
- 아이디 중복 확인(`process/checkId.jsp`, 비동기 fetch)
- 카테고리별 상품 목록(유선/무선) 및 검색(`products.jsp`, `searchResult.jsp`)
- 관리자 페이지에서 상품 등록/삭제(`adminMain.jsp`, `process/processAddProduct.jsp`, `process/processDeleteProduct.jsp`)
- Gemini API를 활용한 상세페이지 연관 상품 AI 추천(`dao/EarPhoneRecommendation.java`)

## 프로젝트 구조

```
src/main/java/
├── dao/                     # EarPhoneRepository(DB 접근), EarPhoneRecommendation(AI 추천)
├── dto/                     # EarPhone
├── util/                    # DBConnection, ConfigLoader
└── config.properties.example  # 설정 파일 템플릿

src/main/webapp/
├── include/                 # 공통 헤더/푸터
├── process/                 # 회원가입, 로그인, 장바구니, 주문, AI 챗봇 등 처리용 JSP
├── resource/                # 모듈화된 CSS, 상품 이미지
└── *.jsp                    # 메인/상품목록/상세/장바구니/주문/마이페이지 등 화면
```

## 실행 방법

1. **사전 준비**
   - JDK 21, Apache Tomcat 11.0, MSSQL Server가 설치되어 있어야 합니다.
   - MSSQL에 `earphone_shop` 데이터베이스와 `member`, `earphone`, `cart`, `orders` 테이블을 준비합니다.

2. **설정 파일 생성**
   - `src/main/java/config.properties.example`을 같은 위치에 `config.properties`로 복사한 뒤, 본인의 DB 접속 정보와 API 키를 입력합니다.
   ```properties
   db.url=jdbc:sqlserver://localhost:1433;databaseName=earphone_shop;encrypt=true;trustServerCertificate=true;loginTimeout=30;
   db.user=YOUR_DB_USER
   db.password=YOUR_DB_PASSWORD

   mistral.api.key=YOUR_MISTRAL_API_KEY
   gemini.api.key=YOUR_GEMINI_API_KEY

   upload.base.path=C:\\path\\to\\EarPhoneMarket\\src\\main\\webapp\\resource
   ```
   - `upload.base.path`는 관리자 페이지에서 상품 이미지를 업로드할 때 저장되는 절대경로입니다. 본인의 로컬 프로젝트 경로에 맞게 지정해 주세요.
   - `config.properties`는 `.gitignore`에 등록되어 있어 저장소에는 올라가지 않습니다.

3. **Eclipse에서 실행**
   - Eclipse에서 `File > Import > Existing Projects into Workspace`로 프로젝트를 불러옵니다.
   - Tomcat 11.0 서버 런타임을 등록하고, 이 프로젝트를 서버에 추가합니다.
   - 서버를 실행하면 `http://localhost:8080/EarPhoneMarket/main.jsp`에서 접속할 수 있습니다.

4. **의존 라이브러리**
   - `src/main/webapp/WEB-INF/lib`에 필요한 jar(`mssql-jdbc`, `commons-fileupload`, `commons-io`, `cos`, `taglibs-standard-*`)를 직접 배치해야 합니다(라이브러리 jar는 저장소에 포함되어 있지 않습니다).
