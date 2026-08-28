<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dto.EarPhone"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.sql.*" %>

<%
    // 1. 캐릭터 인코딩 및 삭제할 상품 ID 파라미터 수집
    request.setCharacterEncoding("UTF-8");
    String pId = request.getParameter("pId");
    
    // 세션에서 로그인한 회원 아이디 추출
    String sessionUserId = (String) session.getAttribute("userId");
    
    if (sessionUserId == null || sessionUserId.trim().isEmpty() || pId == null || pId.trim().isEmpty()) {
        response.sendRedirect("cart.jsp");
        return;
    }

    Connection conn = null;
    PreparedStatement pstmt = null;

    try {
        conn = util.DBConnection.getConnection();
        
        String sql = "DELETE FROM cart WHERE mId = ? AND pId = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, sessionUserId.trim());
        pstmt.setString(2, pId.trim());
        pstmt.executeUpdate();

        // DB만 지우면 세션의 cartList에는 예전 데이터가 남으므로 세션에서도 삭제
        ArrayList<EarPhone> cartList = (ArrayList<EarPhone>) session.getAttribute("cartList");
        if (cartList != null) {
            for (int i = 0; i < cartList.size(); i++) {
                EarPhone item = cartList.get(i);
                // long 타입을 비교하기 위해 문자열로 변환하여 대조
                if (String.valueOf(item.getProductId()).equals(pId.trim())) {
                    cartList.remove(i);
                    break;
                }
            }
        }
        
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (pstmt != null) try { pstmt.close(); } catch(SQLException e) {}
        if (conn != null) try { conn.close(); } catch(SQLException e) {}
    }

    // 2. 삭제 완료 후 장바구니 목록 화면으로 이동
    response.sendRedirect("cart.jsp");
%>