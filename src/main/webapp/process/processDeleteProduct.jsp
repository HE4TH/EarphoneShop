<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // 관리자 권한 검증
    String sessionUserId = (String) session.getAttribute("userId");
    if (sessionUserId == null || !sessionUserId.equals("admin")) {
        response.sendRedirect("../login.jsp");
        return;
    }

    String productId = request.getParameter("productId");
    if (productId == null || productId.trim().isEmpty()) {
        response.sendRedirect("../adminMain.jsp");
        return;
    }

    Connection conn = null;
    PreparedStatement pstmt = null;

    try {
        conn = util.DBConnection.getConnection();

        String sql = "DELETE FROM dbo.earphone WHERE productId = ?";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setLong(1, Long.parseLong(productId.trim()));
        pstmt.executeUpdate();
%>
        <script>
            alert("🗑️ 선택하신 상품이 삭제되었습니다.");
            location.href = "../adminMain.jsp";
        </script>
<%
    } catch(Exception e) {
        e.printStackTrace();
%>
        <script>
            alert("❌ 상품 삭제 실패! 장바구니나 주문 기록에 이미 묶여있는 상품은 참조 무결성 제약조건에 의해 삭제할 수 없습니다.");
            history.back();
        </script>
<%
    } finally {
        if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if(conn != null) try { conn.close(); } catch(Exception e) {}
    }
%>