package bench;

import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.nio.charset.StandardCharsets;

import util.ConfigLoader;

/**
 * Mistral(rate limit 회피용 호출 간 딜레이 포함) + Gemini(키 교체 후 검증) 재실행 전용.
 * ChatbotBenchmark와 동일한 CSV 스키마로 별도 파일에 기록 -> 기존 결과와 합쳐서 분석.
 * 실행: java -cp <classpath> bench.RetryBenchmark
 */
public class RetryBenchmark {

    private static final int REPEAT_PER_QUESTION = 3;
    private static final long MISTRAL_DELAY_MS = 3000; // rate limit(429) 회피용 호출 간 대기

    public static void main(String[] args) throws Exception {
        String mistralKey = ConfigLoader.get("mistral.api.key");
        String geminiKey = ConfigLoader.get("gemini.api.key");
        String systemPrompt = BenchmarkQuestions.buildSystemPrompt();

        String outPath = "benchmark_results/chatbot_retry_" + System.currentTimeMillis() + ".csv";
        new java.io.File("benchmark_results").mkdirs();

        try (Writer w = new OutputStreamWriter(new FileOutputStream(outPath), StandardCharsets.UTF_8)) {
            w.write("model,questionId,question,iteration,httpStatus,latencyMs,promptTokens,completionTokens,saysUnavailable,response\n");

            // 1. Mistral 재시도 (딜레이 포함)
            for (String[] q : BenchmarkQuestions.QUESTIONS) {
                for (int i = 1; i <= REPEAT_PER_QUESTION; i++) {
                    ModelResponse res = ChatModelClient.callMistral(mistralKey, systemPrompt, q[1]);
                    writeRow(w, "mistral-small-latest", q[0], q[1], i, res);
                    System.out.println("mistral | " + q[0] + " | iter " + i + " | " + res.latencyMs + "ms | http=" + res.httpStatus);
                    Thread.sleep(MISTRAL_DELAY_MS);
                }
            }

            // 2. Gemini 재검증 (새 키)
            for (String[] q : BenchmarkQuestions.QUESTIONS) {
                for (int i = 1; i <= REPEAT_PER_QUESTION; i++) {
                    ModelResponse res = ChatModelClient.callGemini(geminiKey, systemPrompt, q[1]);
                    writeRow(w, "gemini-2.5-flash", q[0], q[1], i, res);
                    System.out.println("gemini | " + q[0] + " | iter " + i + " | " + res.latencyMs + "ms | http=" + res.httpStatus);
                }
            }
        }

        System.out.println("완료: " + outPath);
    }

    private static void writeRow(Writer w, String modelId, String questionId, String question, int i, ModelResponse res) throws Exception {
        String content = res.content != null ? res.content : ("[ERROR] " + res.error);
        boolean saysUnavailable = BenchmarkQuestions.containsAny(content,
                "없습니다", "없어요", "판매하지 않", "취급하지 않", "찾을 수 없", "찾지 못");

        w.write(String.join(",",
                JsonUtil.csv(modelId),
                JsonUtil.csv(questionId),
                JsonUtil.csv(question),
                String.valueOf(i),
                String.valueOf(res.httpStatus),
                String.valueOf(res.latencyMs),
                res.promptTokens != null ? String.valueOf(res.promptTokens) : "",
                res.completionTokens != null ? String.valueOf(res.completionTokens) : "",
                String.valueOf(saysUnavailable),
                JsonUtil.csv(content)
        ));
        w.write("\n");
        w.flush();
    }
}
