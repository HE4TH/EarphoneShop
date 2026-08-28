<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="dto.EarPhone" %>

<%
    // 1. 한글 인코딩 설정 및 로그인 세션 조회
    request.setCharacterEncoding("UTF-8");
    String sessionUserId = (String) session.getAttribute("userId");
    
    // 장바구니 화면에서 던진 파라미터 수신 (productId와 quantity)
    String productId = request.getParameter("productId");
    String quantityStr = request.getParameter("quantity");

    if (productId == null || quantityStr == null) {
        response.sendRedirect("../cart.jsp");
        return;
    }

    int newQty = Integer.parseInt(quantityStr.trim());
    ArrayList<EarPhone> cartList = (ArrayList<EarPhone>) session.getAttribute("cartList");

    // 2. 세션 장바구니 리스트의 수량 먼저 변경
    if (cartList != null) {
        for (EarPhone item : cartList) {
            if (String.valueOf(item.getProductId()).equals(productId.trim())) {
                item.setStock(newQty);
                break;
            }
        }
    }

    // 3. 로그인 상태라면 DB의 cart 테이블도 함께 갱신
    if (sessionUserId != null && !sessionUserId.trim().isEmpty()) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = util.DBConnection.getConnection();
            
            String sql = "UPDATE dbo.cart SET pCount = ? WHERE TRIM(mId) = ? AND TRIM(pId) = ?";

            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, newQty);
            pstmt.setString(2, sessionUserId.trim());
            pstmt.setString(3, productId.trim());

            pstmt.executeUpdate();
            
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
            if (conn != null) try { conn.close(); } catch(Exception e) {}
        }
    }

    // 4. 처리 완료 후 장바구니 화면으로 이동
    response.sendRedirect("../cart.jsp");
%>