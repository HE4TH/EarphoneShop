package util;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

public class ConfigLoader {
    private static final Properties props = new Properties();

    static {
        try (InputStream in = ConfigLoader.class.getResourceAsStream("/config.properties")) {
            if (in == null) {
                throw new RuntimeException("config.properties 파일을 classpath(src/main/java)에서 찾을 수 없습니다. "
                        + "config.properties.example을 복사해서 config.properties를 만들어 주세요.");
            }
            props.load(in);
        } catch (IOException e) {
            throw new RuntimeException("config.properties 로드 실패", e);
        }
    }

    public static String get(String key) {
        return props.getProperty(key);
    }
}
