package util;

import java.sql.Connection;
import java.sql.DriverManager;


public class DBConnection {
    public static Connection getConnection() {
        Connection conn = null;
        try {
            // 1. MSSQL 드라이버 클래스 로드
			Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
			            
            // 2. 접속 정보 설정 (config.properties에서 로드)
			String url = ConfigLoader.get("db.url");
			String user = ConfigLoader.get("db.user");
			String password = ConfigLoader.get("db.password");
            
            // 3. DB 연결
            conn = DriverManager.getConnection(url, user, password);
            
        }catch (ClassNotFoundException e) {
			System.out.println("드라이버 로드 오류!");
			
		}catch (Exception e) {
            System.out.println("❌ DB 연결 실패! 주소나 계정 비밀번호를 확인하세요.");
            e.printStackTrace();
        }
        return conn;
    }
}