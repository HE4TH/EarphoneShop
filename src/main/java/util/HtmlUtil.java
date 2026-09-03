package util;

public class HtmlUtil {

    public static String escape(String input) {
        if (input == null) {
            return "";
        }
        return input
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    // <script> 안에서 JS 문자열 리터럴로 값을 출력할 때 사용 (따옴표/개행/태그 탈출 방지)
    public static String escapeJs(String input) {
        if (input == null) {
            return "";
        }
        return input
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("'", "\\'")
                .replace("\r", "")
                .replace("\n", "\\n")
                .replace("<", "\\u003C")
                .replace(">", "\\u003E");
    }
}
