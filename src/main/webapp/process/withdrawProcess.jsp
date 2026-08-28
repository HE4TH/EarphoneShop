<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    request.setCharacterEncoding("UTF-8");
    String sessionUserId = (String) session.getAttribute("userId");
    String inputPasswd = request.getParameter("passwd");

    if (sessionUserId == null || inputPasswd == null) {
        response.sendRedirect("../login.jsp");
        return;
    }

    Connection conn = null;
    PreparedStatement pstmtCheck = null;
    PreparedStatement pstmtDelete = null;
    ResultSet rs = null;
    
    try {
        conn = util.DBConnection.getConnection();

        // 1. 🔒 비밀번호가 가입된 정석 비밀번호와 일치하는지 먼저 검증합니다.
        String sqlCheck = "SELECT passwd FROM dbo.member WHERE TRIM(mId) = ?";
        pstmtCheck = conn.prepareStatement(sqlCheck);
        pstmtCheck.setString(1, sessionUserId.trim());
        rs = pstmtCheck.executeQuery();

        if (rs.next()) {
            String dbPasswd = rs.getString("passwd");
            
            if (dbPasswd != null && dbPasswd.trim().equals(inputPasswd.trim())) {
                // 2. 🎯 [탈퇴 집행] 비밀번호가 일치하므로 member 테이블에서 유저를 완벽하게 지워버립니다!
                String sqlDelete = "DELETE FROM dbo.member WHERE TRIM(mId) = ?";
                pstmtDelete = conn.prepareStatement(sqlDelete);
                pstmtDelete.setString(1, sessionUserId.trim());
                pstmtDelete.executeUpdate();

                // 3. 🧼 세션 주머니 완전 청소 (로그아웃 처리)
                session.invalidate(); 
%>
                <script>
                    alert("회원 탈퇴가 정상적으로 처리되었습니다. 그동안 코드 사운드를 이용해 주셔서 감사합니다.");
                    location.href = "../main.jsp"; // 메인화면으로 복귀
                </script>
<%
            } else {
                // 비밀번호 미스매칭 예외선
%>
                <script>
                    alert("❌ 비밀번호가 일치하지 않습니다. 다시 확인해 주세요.");
                    history.back();
                </script>
<%
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) rs.close();
        if (pstmtCheck != null) pstmtCheck.close();
        if (pstmtDelete != null) pstmtDelete.close();
        if (conn != null) conn.close();
    }
%>