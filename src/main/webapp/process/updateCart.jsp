<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="dto.EarPhone" %>

<%
    // 1. 한글 깨짐 방지 및 로그인 세션 가로채기
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

    // 2. [메모리 갱신] 우선 현재 켜져있는 세션 장바구니 리스트의 수량을 먼저 바꿉니다.
    if (cartList != null) {
        for (EarPhone item : cartList) {
            if (String.valueOf(item.getProductId()).equals(productId.trim())) {
                item.setStock(newQty); // 세션 수량 변경 완료
                break;
            }
        }
    }

    // 3. 🎯 [핵심 가동: DB 동기화] 로그인을 한 상태라면 SQL Server의 cart 테이블도 실시간 UPDATE 칩니다!
    if (sessionUserId != null && !sessionUserId.trim().isEmpty()) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = util.DBConnection.getConnection();
            
            // 이 회원(mId)이 담은 특정 상품(pId)의 수량(pCount)을 새 수량으로 갱신하는 정석 쿼리!
            String sql = "UPDATE dbo.cart SET pCount = ? WHERE TRIM(mId) = ? AND TRIM(pId) = ?";
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, newQty);
            pstmt.setString(2, sessionUserId.trim());
            pstmt.setString(3, productId.trim());
            
            pstmt.executeUpdate(); // 💥 DB 영구 박제 완료!
            
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
            if (conn != null) try { conn.close(); } catch(Exception e) {}
        }
    }

    // 4. 후처리: 작업이 끝났으므로 한 단계 위(..)에 있는 장바구니 화면으로 스무스하게 회항!
    response.sendRedirect("../cart.jsp");
%>