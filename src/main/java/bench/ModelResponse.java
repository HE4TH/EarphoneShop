package bench;

public class ModelResponse {
    public int httpStatus;
    public String content;
    public Long promptTokens;
    public Long completionTokens;
    public long latencyMs;
    public String error;
}
