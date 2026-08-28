package dao;

import java.io.OutputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.List;
import dto.EarPhone;
import dao.EarPhoneRepository;
import util.ConfigLoader;

public class EarPhoneRecommendation {

    // config.properties에서 로드
	private static final String API_KEY = ConfigLoader.get("gemini.api.key");

	// ⭐️ [최종 고정] 방금 cmd 테스트 성공한 2.5-flash 주소로 셋팅합니다.
	private static final String API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + API_KEY;
	
    public static String getAiRecommendations(EarPhone currentProduct) {
        try {
            // 1. 전체 상품 목록 가져오기 (비교 대상군)
            EarPhoneRepository dao = EarPhoneRepository.getInstance();
            List<EarPhone> allProducts = dao.getAllEarPhone();
            
            // 2. Gemini에게 던질 프롬프트(질문) 조립하기
            StringBuilder prompt = new StringBuilder();
            prompt.append("You are a professional audio equipment recommendation system.\n");
            prompt.append("Based on the following 'Current Product', select exactly 4 most similar or highly recommended alternative products from the 'Product List'.\n\n");
            
            // 현재 상품 정보 제공
            prompt.append("[Current Product]\n");
            prompt.append("ID: ").append(currentProduct.getProductId()).append(", ");
            prompt.append("Name: ").append(currentProduct.getpName()).append(", ");
            prompt.append("Brand: ").append(currentProduct.getBrand()).append(", ");
            prompt.append("Category: ").append(currentProduct.getCategory()).append("\n\n");
            
            // 전체 후보 리스트 제공
            prompt.append("[Product List]\n");
            for (EarPhone p : allProducts) {
                if (p.getProductId() != currentProduct.getProductId()) { // 현재 상품은 제외
                    prompt.append("ID: ").append(p.getProductId()).append(", ");
                    prompt.append("Name: ").append(p.getpName()).append(", ");
                    prompt.append("Brand: ").append(p.getBrand()).append("\n");
                }
            }
            
            prompt.append("\nCRITICAL INSTRUCTION: Respond ONLY with the 4 selected Product IDs separated by commas, without any spaces, letters, markdown, or explanations. (e.g., 2,5,7,12)");

            // 3. JSON 요청 바디 구성 (Gemini API 규격)
            // 실제 프로젝트에서는 Gson 라이브러리를 쓰면 훨씬 깔끔합니다.
            String jsonInputString = "{\"contents\": [{\"parts\": [{\"text\": \"" + prompt.toString().replace("\n", "\\n").replace("\"", "\\\"") + "\"}]}]}";

            // 4. HTTP POST 연결 및 데이터 전송
            URL url = new URL(API_URL);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; utf-8");
            conn.setDoOutput(true);

            try (OutputStream os = conn.getOutputStream()) {
                byte[] input = jsonInputString.getBytes("utf-8");
                os.write(input, 0, input.length);
            }

            // 5. 응답 결과 읽기
            int code = conn.getResponseCode();
            if (code == 200) {
                BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream(), "utf-8"));
                StringBuilder response = new StringBuilder();
                String responseLine;
                while ((responseLine = br.readLine()) != null) {
                    response.append(responseLine.trim());
                }
                
                // Gemini 리턴 JSON에서 "text" 부분의 값만 추출 (단순 파싱 예시)
                String resStr = response.toString();
                int textIdx = resStr.indexOf("\"text\": \"");
                if (textIdx != -1) {
                    int start = textIdx + 9;
                    int end = resStr.indexOf("\"", start);
                    return resStr.substring(start, end).trim(); // "2,5,7,12" 형태 반환
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return ""; // 실패 시 빈 문자열 반환
    }
}