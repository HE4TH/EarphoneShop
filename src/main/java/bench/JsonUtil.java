package bench;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

// 벤치마크 스크립트 전용 초경량 JSON 파서 (프로젝트 전체 방침상 외부 JSON 라이브러리 미사용)
public class JsonUtil {

    public static Long extractLong(String json, String key) {
        Matcher m = Pattern.compile("\"" + key + "\"\\s*:\\s*(\\d+)").matcher(json);
        return m.find() ? Long.parseLong(m.group(1)) : null;
    }

    // "message":{"content":"..."} 또는 "content":"..." 형태 모두에서 첫 content 문자열 값을 추출
    public static String extractStringValue(String json, String key) {
        Pattern p = Pattern.compile("\"" + key + "\"\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"");
        Matcher m = p.matcher(json);
        if (!m.find()) return null;
        return unescape(m.group(1));
    }

    private static String unescape(String s) {
        return s.replace("\\n", "\n")
                .replace("\\r", "")
                .replace("\\\"", "\"")
                .replace("\\\\", "\\");
    }

    public static String escapeJson(String s) {
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
    }

    // CSV 필드 이스케이프 (쉼표/줄바꿈/따옴표 포함 시 큰따옴표로 감싸기)
    public static String csv(String s) {
        if (s == null) return "";
        String escaped = s.replace("\"", "\"\"").replace("\r", " ").replace("\n", " ");
        return "\"" + escaped + "\"";
    }
}
