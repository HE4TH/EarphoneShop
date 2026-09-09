package bench;

import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.nio.charset.StandardCharsets;

import util.ConfigLoader;

/**
 * OpenRouter Qwen 모델 단독 테스트 (모델 ID를 args[0]으로 지정, 기본값 qwen/qwen3.7-flash).
 * ChatbotBenchmark와 동일한 CSV 스키마로 기록.
 * 실행: java -cp <classpath> bench.QwenCheapTest [modelId]
 */
public class QwenCheapTest {

    private static final int REPEAT_PER_QUESTION = 3;
    private static final long DELAY_MS = 2000;

    public static void main(String[] args) throws Exception {
        String MODEL_ID = args.length > 0 ? args[0] : "qwen/qwen3.7-flash";
        String openRouterKey = ConfigLoader.get("openrouter.api.key");
        String systemPrompt = BenchmarkQuestions.buildSystemPrompt();

        String outPath = "benchmark_results/qwen_cheap_" + MODEL_ID.replace("/", "_") + "_" + System.currentTimeMillis() + ".csv";
        new java.io.File("benchmark_results").mkdirs();

        try (Writer w = new OutputStreamWriter(new FileOutputStream(outPath), StandardCharsets.UTF_8)) {
            w.write("model,questionId,question,iteration,httpStatus,latencyMs,promptTokens,completionTokens,saysUnavailable,response\n");

            for (String[] q : BenchmarkQuestions.QUESTIONS) {
                for (int i = 1; i <= REPEAT_PER_QUESTION; i++) {
                    ModelResponse res = ChatModelClient.callOpenRouter(openRouterKey, MODEL_ID, systemPrompt, q[1]);

                    String content = res.content != null ? res.content : ("[ERROR] " + res.error);
                    boolean saysUnavailable = BenchmarkQuestions.containsAny(content,
                            "없습니다", "없어요", "판매하지 않", "취급하지 않", "찾을 수 없", "찾지 못");

                    w.write(String.join(",",
                            JsonUtil.csv(MODEL_ID),
                            JsonUtil.csv(q[0]),
                            JsonUtil.csv(q[1]),
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

                    System.out.println(MODEL_ID + " | " + q[0] + " | iter " + i + " | " + res.latencyMs + "ms | http=" + res.httpStatus);
                    Thread.sleep(DELAY_MS);
                }
            }
        }

        System.out.println("완료: " + outPath);
    }
}
