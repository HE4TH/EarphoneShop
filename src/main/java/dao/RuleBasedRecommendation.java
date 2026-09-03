package dao;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import dto.EarPhone;

// 같은 카테고리 내에서 가격이 가장 비슷한 상품 4개를 추천 (Gemini 기반 추천 대체 — 비교 근거는 README 참고)
public class RuleBasedRecommendation {

    public static List<EarPhone> recommendProducts(EarPhone currentProduct) {
        EarPhoneRepository dao = EarPhoneRepository.getInstance();
        List<EarPhone> allProducts = dao.getAllEarPhone();

        List<EarPhone> candidates = new ArrayList<>();
        for (EarPhone p : allProducts) {
            if (p.getProductId().equals(currentProduct.getProductId())) continue;
            if (currentProduct.getCategory() != null
                    && !currentProduct.getCategory().equalsIgnoreCase(p.getCategory())) continue;
            candidates.add(p);
        }

        // 카테고리 내 상품이 4개 미만이면 전체 상품군에서 보충
        if (candidates.size() < 4) {
            for (EarPhone p : allProducts) {
                if (p.getProductId().equals(currentProduct.getProductId())) continue;
                if (!candidates.contains(p)) candidates.add(p);
            }
        }

        candidates.sort(Comparator.comparingInt(p -> Math.abs(p.getPrice() - currentProduct.getPrice())));

        return candidates.subList(0, Math.min(4, candidates.size()));
    }

    // 콤마로 구분된 productId 문자열("2,5,7,12") 형태가 필요할 때 사용
    public static String recommend(EarPhone currentProduct) {
        List<EarPhone> top4 = recommendProducts(currentProduct);
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < top4.size(); i++) {
            if (i > 0) sb.append(",");
            sb.append(top4.get(i).getProductId());
        }
        return sb.toString();
    }
}
