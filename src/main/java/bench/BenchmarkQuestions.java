package bench;

import java.util.ArrayList;

import dao.EarPhoneRepository;
import dto.EarPhone;

public class BenchmarkQuestions {

    public static final long TARGET_PRODUCT_ID = 5L; // AirPods Pro 3

    public static final String[][] QUESTIONS = {
        {"Q1_sound", "밸런스 잡힌 음색의 무선 이어폰 추천해줘"},
        {"Q2_match", "아이폰이랑 잘 어울리는 이어폰 있어?"},
        {"Q3_price", "10만원대 이어폰 중에 제일 좋은 거 뭐야?"},
        {"Q4_spec", "노이즈캔슬링 되는 제품 있어?"},
        {"Q5_delivery", "지금 바로 배송되는 상품 있어?"},
        {"Q6_hallucination", "소니 WH-1000XM6 있어?"},
        {"Q7_scope", "이 이어폰이랑 어울리는 향수 추천해줘"},
        {"Q8_typo", "무선블투이어폰추천좀요오"}
    };

    // aiChatBotApi.jsp와 동일한 방식으로 시스템 프롬프트 구성 (공정한 비교를 위해 실제 서비스 프롬프트 재사용)
    public static String buildSystemPrompt() {
        EarPhoneRepository repo = EarPhoneRepository.getInstance();
        EarPhone currentGoods = repo.getEarPhoneById(TARGET_PRODUCT_ID);
        ArrayList<EarPhone> allProducts = repo.getAllEarPhones();

        String prodInfoContext = "";
        if (currentGoods != null) {
            prodInfoContext = "[현재 고객이 구경 중인 상품 정보 - 브랜드: " + currentGoods.getBrand()
                    + ", 모델명: " + currentGoods.getpName() + ", 가격: " + currentGoods.getPrice() + "원] ";
        }

        StringBuilder recommendBuilder = new StringBuilder(" [우리 쇼핑몰에서 판매 중인 전체 상품 리스트(추천 후보)]: ");
        int count = 1;
        for (EarPhone p : allProducts) {
            if (currentGoods != null && p.getProductId().equals(currentGoods.getProductId())) continue;
            recommendBuilder.append(count == 1 ? "" : ", ")
                    .append("{브랜드: ").append(p.getBrand())
                    .append(", 제품명: ").append(p.getpName())
                    .append(", 가격: ").append(p.getPrice()).append("원}");
            count++;
        }

        return "당신은 음향기기 쇼핑몰 '코드 사운드'의 친절하고 전문적인 AI 쇼핑 매니저입니다. "
                + "절대 다른 사이트의 가짜 제품을 지어내지 마세요. "
                + "유저가 다른 제품 추천을 요구하면, 제공되는 [우리 쇼핑몰에서 판매 중인 전체 상품 리스트] 중에서만 골라서 공손한 한국어로 추천 리스트를 만들어 답변하세요. "
                + prodInfoContext
                + recommendBuilder.toString();
    }

    public static boolean containsAny(String text, String... needles) {
        if (text == null) return false;
        for (String n : needles) {
            if (text.contains(n)) return true;
        }
        return false;
    }
}
