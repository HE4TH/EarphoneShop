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
        
        // 🎯 [핵심: DB 영구 삭제 쿼리] 누구의(mId) 어떤 상품(pId)을 지울 것인지 조준 사격!
        String sql = "DELETE FROM cart WHERE mId = ? AND pId = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, sessionUserId.trim());
        pstmt.setString(2, pId.trim());
        
        // DB 데이터 삭제 집행
        pstmt.executeUpdate();
        
        // 🎯 [세션 동기화 보정] DB만 지우면 톰캣 세션 주머니에 예전 흔적이 남아있으므로 세션에서도 삭제 처리
        ArrayList<EarPhone> cartList = (ArrayList<EarPhone>) session.getAttribute("cartList");
        if (cartList != null) {
            for (int i = 0; i < cartList.size(); i++) {
                EarPhone item = cartList.get(i);
                // long 타입을 비교하기 위해 문자열로 변환하여 대조
                if (String.valueOf(item.getProductId()).equals(pId.trim())) {
                    cartList.remove(i); // 세션 바구니에서 제거 완료
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

    // 2. 모든 영구 삭제 절차가 완공되었으므로 다시 장바구니 목록 화면으로 리턴!
    response.sendRedirect("cart.jsp");
%>