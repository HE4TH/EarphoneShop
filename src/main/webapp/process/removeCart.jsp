<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dto.EarPhone"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.sql.*" %>

<%
    // 1. ?productId= 파라미터 수신
    String productIdStr = request.getParameter("productId");

    // ID 값이 없는 비정상 접근은 장바구니로 리다이렉트
    if (productIdStr == null || productIdStr.trim().isEmpty()) {
        response.sendRedirect("../cart.jsp");
        return;
    }

    long productId = Long.parseLong(productIdStr.trim());

    // 3. 세션의 장바구니 리스트 조회
    ArrayList<EarPhone> cartList = (ArrayList<EarPhone>) session.getAttribute("cartList");

    if (cartList != null) {
        // 4. productId가 일치하는 항목을 찾아 제거
        for (int i = 0; i < cartList.size(); i++) {
            EarPhone item = cartList.get(i);

            if (item.getProductId() == productId) {
                cartList.remove(i);
                break;
            }
        }
    }
    
    String sessionUserId = (String) session.getAttribute("userId");
    if (sessionUserId != null) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        try {
            conn = util.DBConnection.getConnection();
            pstmt = conn.prepareStatement("DELETE FROM cart WHERE mId = ? AND pId = ?");
            pstmt.setString(1, sessionUserId.trim());
            pstmt.setString(2, String.valueOf(productId));
            pstmt.executeUpdate();
        } catch(Exception e) { e.printStackTrace(); }
        finally {
            if(pstmt != null) pstmt.close();
            if(conn != null) conn.close();
        }
    }

    // 5. 처리 완료 후 장바구니 화면으로 이동
    response.sendRedirect("../cart.jsp");
%>