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

    if (!util.CsrfUtil.isValid(request)) {
        response.sendError(jakarta.servlet.http.HttpServletResponse.SC_FORBIDDEN, "잘못된 요청입니다.");
        return;
    }

    Connection conn = null;
    PreparedStatement pstmtCheck = null;
    PreparedStatement pstmtDelete = null;
    ResultSet rs = null;
    
    try {
        conn = util.DBConnection.getConnection();

        // 1. 입력한 비밀번호가 가입된 비밀번호와 일치하는지 검증
        String sqlCheck = "SELECT passwd FROM dbo.member WHERE TRIM(mId) = ?";
        pstmtCheck = conn.prepareStatement(sqlCheck);
        pstmtCheck.setString(1, sessionUserId.trim());
        rs = pstmtCheck.executeQuery();

        if (rs.next()) {
            String dbPasswd = rs.getString("passwd");
            
            if (util.PasswordUtil.verify(inputPasswd.trim(), dbPasswd)) {
                // 2. 비밀번호 일치 시 member 테이블에서 삭제
                String sqlDelete = "DELETE FROM dbo.member WHERE TRIM(mId) = ?";
                pstmtDelete = conn.prepareStatement(sqlDelete);
                pstmtDelete.setString(1, sessionUserId.trim());
                pstmtDelete.executeUpdate();

                // 3. 세션 무효화 (로그아웃 처리)
                session.invalidate();
%>
                <script>
                    alert("회원 탈퇴가 정상적으로 처리되었습니다. 그동안 코드 사운드를 이용해 주셔서 감사합니다.");
                    location.href = "../main.jsp";
                </script>
<%
            } else {
                // 비밀번호 불일치
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