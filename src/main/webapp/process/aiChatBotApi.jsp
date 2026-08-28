<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.*, java.net.*, java.util.*" %>
<%@ page import="dao.EarPhoneRepository" %>
<%@ page import="dto.EarPhone" %>
<%
    // 1. 한글 파라미터 및 캐릭터셋 인코딩 인프라 세팅
    request.setCharacterEncoding("UTF-8");
    String productId = request.getParameter("productId");
    String userMessage = request.getParameter("message");

    if (userMessage == null || userMessage.trim().isEmpty()) {
        out.print("🤖 어떤 내용이든 편하게 물어보세요!");
        return;
    }

    String prodInfoContext = "";
    String databaseRecommendationContext = ""; // DB 내 다른 상품들을 담을 바구니

    try {
        EarPhoneRepository repo = EarPhoneRepository.getInstance();
        
        // (1) 현재 구경 중인 상품 정보 가져오기
        EarPhone currentGoods = null;
        if (productId != null && !productId.equals("0") && !productId.equals("null")) {
            currentGoods = repo.getEarPhoneById(Long.parseLong(productId.trim()));
            if (currentGoods != null) {
                prodInfoContext = "[현재 고객이 구경 중인 상품 정보 - 브랜드: " + currentGoods.getBrand() + ", 모델명: " + currentGoods.getpName() + ", 가격: " + currentGoods.getPrice() + "원] ";
            }
        }

        // (2) 💥 조건문 필터를 완전 제거하고, 챗봇이 가동되면 무조건 DB부터 안전하게 긁어옵니다!
        ArrayList<EarPhone> allProducts = repo.getAllEarPhones(); 
        
        // 🚨 톰캣 콘솔창에 진짜로 DB 어레이리스트가 넘어오는지 감시 카메라 가동
        System.out.println("=== [AI 엔진 콘솔] DB에서 넘겨받은 객체 상태: " + allProducts);
        if(allProducts != null) {
            System.out.println("=== [AI 엔진 콘솔] 읽어온 리스트의 순수 데이터 개수: " + allProducts.size() + "개 ===");
        }
        
        if (allProducts != null && !allProducts.isEmpty()) {
            StringBuilder recommendBuilder = new StringBuilder(" [우리 쇼핑몰에서 판매 중인 전체 상품 리스트(추천 후보)]: ");
            int count = 1;
            
            for (EarPhone p : allProducts) {
                // 현재 구경 중인 상품은 제외
                if (currentGoods != null && p.getProductId() == currentGoods.getProductId()) {
                    continue; 
                }
                
                // 🚨 1번 포인트: 여기서 혹시 에러가 나서 튕기는지 감시
                recommendBuilder.append(count == 1 ? "" : ", ")
                                .append("{브랜드: ").append(p.getBrand())
                                .append(", 제품명: ").append(p.getpName()) 
                                .append(", 가격: ").append(p.getPrice()).append("원}");
                count++;
            }
            databaseRecommendationContext = recommendBuilder.toString();
            System.out.println("=== [AI 엔진 콘솔] 최종 조립 성공한 프롬프트 문맥: " + databaseRecommendationContext);
        }
    } catch(Exception e) {
        // 🚨 [가장 중요] 그동안 숨어있던 빨간책 에러 원인을 이클립스 콘솔창에 붉은 글씨로 통째로 다 뿜어내게 만듭니다!
        System.out.println("❌❌❌ [AI 핵심 비상] 자바 로직 구동 중 크래시 발생! 원인 아래 확인 ❌❌❌");
        e.printStackTrace(); 
        prodInfoContext = "";
        databaseRecommendationContext = "";
    }

    // 3. 🧠 글로벌 표준 배열 구조용 세션 빌더 가동
    String chatHistoryKey = "mistral_chat_history_" + productId;
    ArrayList<String> messagesList = (ArrayList<String>) session.getAttribute(chatHistoryKey);
    
    if (messagesList == null) {
        messagesList = new ArrayList<String>();
        
        // 시스템 프롬프트에 실시간 DB 정보를 주동으로 결합하여 주입
        String sysPrompt = "당신은 음향기기 쇼핑몰 '코드 사운드'의 친절하고 전문적인 AI 쇼핑 매니저입니다. "
                         + "절대 다른 사이트의 가짜 제품을 지어내지 마세요. "
                         + "유저가 다른 제품 추천을 요구하면, 제공되는 [우리 쇼핑몰에서 판매 중인 전체 상품 리스트] 중에서만 골라서 공손한 한국어로 추천 리스트를 만들어 답변하세요. "
                         + prodInfoContext 
                         + databaseRecommendationContext;
        
        // JSON 파싱 규칙 파괴 방지를 위한 이스케이프 안전 가드 처리
        String cleanSysPrompt = sysPrompt.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
        messagesList.add("{\"role\": \"system\", \"content\": \"" + cleanSysPrompt + "\"}");
    }

    // 🎯 [완치 포인트 1] 유저의 신규 질문 문장도 항상 리스트에 정상 적치되도록 수정
    String cleanUserMsg = userMessage.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    messagesList.add("{\"role\": \"user\", \"content\": \"" + cleanUserMsg + "\"}");

    // 4. 🎯 Mistral AI 공식 엔드포인트 및 API 키 세팅 (config.properties에서 로드)
    String apiKey = util.ConfigLoader.get("mistral.api.key");
    String apiURL = "https://api.mistral.ai/v1/chat/completions";

    BufferedReader br = null;
    OutputStream os = null;
    HttpURLConnection conn = null;

    try {
        URL url = new URL(apiURL);
        conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
        conn.setRequestProperty("Authorization", "Bearer " + apiKey); 
        conn.setDoOutput(true);

        // 세션 내부 배열 요소 결합
        StringBuilder jsonMessages = new StringBuilder("[");
        for (int i = 0; i < messagesList.size(); i++) {
            jsonMessages.append(messagesList.get(i));
            if (i < messagesList.size() - 1) jsonMessages.append(",");
        }
        jsonMessages.append("]");

        String jsonPayload = "{"
            + "\"model\": \"mistral-small-latest\","
            + "\"messages\": " + jsonMessages.toString() + ","
            + "\"stream\": false"
            + "}";

        // 데이터 전송
        os = conn.getOutputStream();
        os.write(jsonPayload.getBytes("UTF-8"));
        os.flush();

        int responseCode = conn.getResponseCode();
        if (responseCode == 200) { 
            br = new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"));
            StringBuilder responseSB = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) {
                responseSB.append(line);
            }

            String rawJson = responseSB.toString();
            
            // 🎯 [Mistral 표준 파싱 구역]
            if (rawJson.contains("\"content\":\"")) {
                int startIdx = rawJson.indexOf("\"content\":\"") + 11;
                
                int endIdx = rawJson.indexOf("\",\"tool_calls\"", startIdx);
                if (endIdx < 0) endIdx = rawJson.indexOf("\"},\"finish_reason\"", startIdx);
                if (endIdx < 0) endIdx = rawJson.indexOf("\"}", startIdx);

                String aiAnswer = rawJson.substring(startIdx, endIdx);

                // 이스케이프 문자 복원 및 HTML 줄바꿈 태그 변환
                aiAnswer = aiAnswer.replace("\\u0026", "&")
                                   .replace("\\n", "<br>")
                                   .replace("\\\"", "\"")
                                   .replace("\\\'", "'")
                                   .replace("**", ""); 

                // AI 답변 누적 시에도 안전 가드 처리 후 적치
                String cleanAiAnswer = aiAnswer.replace("<br>", " ").replace("\\", "\\\\").replace("\"", "\\\"");
                messagesList.add("{\"role\": \"assistant\", \"content\": \"" + cleanAiAnswer + "\"}");
                session.setAttribute(chatHistoryKey, messagesList);
                                   
                out.print(aiAnswer.trim());
            } else {
                out.print("🤖 미스트랄 응답 데이터 파싱 중 규격 꼬임이 발생했습니다.");
            }
        } else {
            System.out.println("❌ Mistral API 거절 발생! 에러 응답 코드: " + responseCode);
            out.print("⚠️ [Mistral 에러 " + responseCode + "] API 요청이 거절되었습니다. 콘솔 로그를 확인해 주세요.");
        }

    } catch (Exception e) {
        e.printStackTrace();
        out.print("⚠️ 미스트랄 클라우드 신경망 인프라 네트워크 연결에 실패했습니다.");
    } finally {
        if (os != null) try { os.close(); } catch(Exception e) {}
        if (br != null) try { br.close(); } catch(Exception e) {}
        if (conn != null) conn.disconnect();
    }
%>