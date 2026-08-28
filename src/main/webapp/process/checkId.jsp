<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // 브라우저 캐시 방지 (실시간 동기화 필수)
    response.setHeader("Cache-Control", "no-cache");
    
    String mId = request.getParameter("mId");
    String result = "ERROR";
    
    if (mId != null && !mId.trim().isEmpty()) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = util.DBConnection.getConnection();
            
            // 2. 카멜케이스 처리된 mId 컬럼 개수 세기 쿼리 빌드
            String sql = "SELECT COUNT(*) FROM member WHERE mId = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, mId.trim());
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int count = rs.getInt(1);
                if (count == 0) {
                    result = "AVAILABLE";   // 중복 없음 -> 사용 가능
                } else {
                    result = "DUPLICATED";  // 중복 발생 -> 사용 불가
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            result = "SERVER_ERROR";
        } finally {
            if (rs != null) try { rs.close(); } catch(SQLException e) {}
            if (pstmt != null) try { pstmt.close(); } catch(SQLException e) {}
            if (conn != null) try { conn.close(); } catch(SQLException e) {}
        }
    }
    
    // Fetch 응답으로 결과 문자열만 반환
    out.print(result);
%>