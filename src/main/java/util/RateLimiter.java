package util;

import java.util.concurrent.ConcurrentHashMap;

public class RateLimiter {

    private static class Bucket {
        int count = 0;
        long windowStart = System.currentTimeMillis();
    }

    private static final ConcurrentHashMap<String, Bucket> buckets = new ConcurrentHashMap<>();

    // 주어진 key에 대해 windowMillis 시간 동안 maxAttempts 횟수만큼만 허용
    public static boolean isAllowed(String key, int maxAttempts, long windowMillis) {
        Bucket bucket = buckets.computeIfAbsent(key, k -> new Bucket());
        synchronized (bucket) {
            long now = System.currentTimeMillis();
            if (now - bucket.windowStart > windowMillis) {
                bucket.windowStart = now;
                bucket.count = 0;
            }
            if (bucket.count >= maxAttempts) {
                return false;
            }
            bucket.count++;
            return true;
        }
    }

    // 로그인 성공 등 정상 처리 시 카운트 초기화
    public static void reset(String key) {
        buckets.remove(key);
    }
}
