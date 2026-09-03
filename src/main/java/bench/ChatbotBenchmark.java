package bench;

import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

import util.ConfigLoader;

/**
 * 챗봇 모델 비교 벤치마크: Mistral Small / Gemini 2.5 Flash / Qwen(OpenRouter) / Llama(OpenRouter)
 * 동일한 시스템 프롬프트(상품 목록 주입) + 동일 질문셋을 각 모델에 보내 latency/token/응답을 CSV로 기록한다.
 * 실행: java -cp <classpath> bench.ChatbotBenchmark
 */
public class ChatbotBenchmark {

    private static final int REPEAT_PER_QUESTION = 3;

    public static void main(String[] args) throws Exception {
        String mistralKey = ConfigLoader.get("mistral.api.key");
        String geminiKey = ConfigLoader.get("gemini.api.key");
        String openRouterKey = ConfigLoader.get("openrouter.api.key");

        Map<String, String> models = new LinkedHashMap<>();
        models.put("mistral-small-latest", "mistral");
        models.put("gemini-2.5-flash", "gemini");
        models.put("qwen/qwen-2.5-72b-instruct", "openrouter");
        models.put("meta-llama/llama-3.3-70b-instruct", "openrouter");

        String systemPrompt = BenchmarkQuestions.buildSystemPrompt();

        String outPath = "benchmark_results/chatbot_benchmark_" + System.currentTimeMillis() + ".csv";
        new java.io.File("benchmark_results").mkdirs();

        try (Writer w = new OutputStreamWriter(new FileOutputStream(outPath), StandardCharsets.UTF_8)) {
            w.write("model,questionId,question,iteration,httpStatus,latencyMs,promptTokens,completionTokens,saysUnavailable,response\n");

            for (Map.Entry<String, String> modelEntry : models.entrySet()) {
                String modelId = modelEntry.getKey();
                String provider = modelEntry.getValue();

                for (String[] q : BenchmarkQuestions.QUESTIONS) {
                    String questionId = q[0];
                    String question = q[1];

                    for (int i = 1; i <= REPEAT_PER_QUESTION; i++) {
                        ModelResponse res;
                        switch (provider) {
                            case "mistral":
                                res = ChatModelClient.callMistral(mistralKey, systemPrompt, question);
                                break;
                            case "gemini":
                                res = ChatModelClient.callGemini(geminiKey, systemPrompt, question);
                                break;
                            default:
                                res = ChatModelClient.callOpenRouter(openRouterKey, modelId, systemPrompt, question);
                        }

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

                        System.out.println(modelId + " | " + questionId + " | iter " + i
                                + " | " + res.latencyMs + "ms | http=" + res.httpStatus);
                    }
                }
            }
        }

        System.out.println("완료: " + outPath);
    }
}
