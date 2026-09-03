package bench;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;

// Mistral / Gemini / OpenRouter(Qwen, Llama 등) 챗 완성 API를 동일한 방식으로 호출하는 클라이언트
public class ChatModelClient {

    // Mistral AI (chat/completions, OpenAI 호환 스키마)
    public static ModelResponse callMistral(String apiKey, String systemPrompt, String userMessage) {
        String url = "https://api.mistral.ai/v1/chat/completions";
        String payload = "{"
                + "\"model\": \"mistral-small-latest\","
                + "\"messages\": ["
                + "{\"role\":\"system\",\"content\":\"" + JsonUtil.escapeJson(systemPrompt) + "\"},"
                + "{\"role\":\"user\",\"content\":\"" + JsonUtil.escapeJson(userMessage) + "\"}"
                + "],"
                + "\"stream\": false"
                + "}";
        return callOpenAiCompatible(url, apiKey, payload);
    }

    // OpenRouter (Qwen, Llama 등 다양한 모델을 동일 스키마로 호출)
    public static ModelResponse callOpenRouter(String apiKey, String model, String systemPrompt, String userMessage) {
        String url = "https://openrouter.ai/api/v1/chat/completions";
        String payload = "{"
                + "\"model\": \"" + model + "\","
                + "\"messages\": ["
                + "{\"role\":\"system\",\"content\":\"" + JsonUtil.escapeJson(systemPrompt) + "\"},"
                + "{\"role\":\"user\",\"content\":\"" + JsonUtil.escapeJson(userMessage) + "\"}"
                + "]"
                + "}";
        return callOpenAiCompatible(url, apiKey, payload);
    }

    private static ModelResponse callOpenAiCompatible(String urlStr, String apiKey, String jsonPayload) {
        ModelResponse result = new ModelResponse();
        long start = System.currentTimeMillis();
        HttpURLConnection conn = null;
        try {
            URL url = new URL(urlStr);
            conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            conn.setRequestProperty("Authorization", "Bearer " + apiKey);
            conn.setConnectTimeout(30000);
            conn.setReadTimeout(60000);
            conn.setDoOutput(true);

            try (OutputStream os = conn.getOutputStream()) {
                os.write(jsonPayload.getBytes("UTF-8"));
            }

            int code = conn.getResponseCode();
            result.httpStatus = code;
            InputStreamReader isr = new InputStreamReader(
                    code == 200 ? conn.getInputStream() : conn.getErrorStream(), "UTF-8");
            BufferedReader br = new BufferedReader(isr);
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) sb.append(line);
            br.close();

            String raw = sb.toString();
            if (code == 200) {
                result.content = JsonUtil.extractStringValue(raw, "content");
                result.promptTokens = JsonUtil.extractLong(raw, "prompt_tokens");
                result.completionTokens = JsonUtil.extractLong(raw, "completion_tokens");
            } else {
                result.error = raw;
            }
        } catch (Exception e) {
            result.error = e.toString();
        } finally {
            if (conn != null) conn.disconnect();
            result.latencyMs = System.currentTimeMillis() - start;
        }
        return result;
    }

    // Gemini (generateContent, 별도 스키마 - system+user를 하나의 텍스트로 합쳐서 전송)
    public static ModelResponse callGemini(String apiKey, String systemPrompt, String userMessage) {
        ModelResponse result = new ModelResponse();
        long start = System.currentTimeMillis();
        HttpURLConnection conn = null;
        try {
            String combinedPrompt = systemPrompt + "\n\n[사용자 질문]\n" + userMessage;
            String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + apiKey;
            String payload = "{\"contents\": [{\"parts\": [{\"text\": \"" + JsonUtil.escapeJson(combinedPrompt) + "\"}]}]}";

            URL u = new URL(url);
            conn = (HttpURLConnection) u.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            conn.setConnectTimeout(30000);
            conn.setReadTimeout(60000);
            conn.setDoOutput(true);

            try (OutputStream os = conn.getOutputStream()) {
                os.write(payload.getBytes("UTF-8"));
            }

            int code = conn.getResponseCode();
            result.httpStatus = code;
            InputStreamReader isr = new InputStreamReader(
                    code == 200 ? conn.getInputStream() : conn.getErrorStream(), "UTF-8");
            BufferedReader br = new BufferedReader(isr);
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) sb.append(line);
            br.close();

            String raw = sb.toString();
            if (code == 200) {
                result.content = JsonUtil.extractStringValue(raw, "text");
                result.promptTokens = JsonUtil.extractLong(raw, "promptTokenCount");
                result.completionTokens = JsonUtil.extractLong(raw, "candidatesTokenCount");
            } else {
                result.error = raw;
            }
        } catch (Exception e) {
            result.error = e.toString();
        } finally {
            if (conn != null) conn.disconnect();
            result.latencyMs = System.currentTimeMillis() - start;
        }
        return result;
    }
}
