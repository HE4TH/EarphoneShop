<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dto.EarPhone"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.sql.*" %>

<%
    // 1. X 버튼을 누를 때 주소창 뒤에 달고 온 ?productId=번호 파라미터를 낚아챕니다.
    String productIdStr = request.getParameter("productId");

    // [방어 코드] 만약 비정상적인 접근으로 ID 값이 날아오지 않았다면 곧바로 컴백
    if (productIdStr == null || productIdStr.trim().isEmpty()) {
        response.sendRedirect("../cart.jsp");
        return;
    }

    // 2. 🎯 [승민님 스펙 맞춤형 파싱] String 주소 데이터를 진짜 long형 숫자로 변환합니다.
    long productId = Long.parseLong(productIdStr.trim());

    // 3. 서버 세션 사물함에 들어있는 유저의 장바구니 바구니(cartList)를 인출합니다.
    ArrayList<EarPhone> cartList = (ArrayList<EarPhone>) session.getAttribute("cartList");

    if (cartList != null) {
        // 4. 장바구니 내부를 순회하며 내가 지우려고 누른 long형 productId와 일치하는 객체를 추적합니다.
        for (int i = 0; i < cartList.size(); i++) {
            EarPhone item = cartList.get(i);
            
            // 🎯 long형 ID 일치 여부 정밀 검사
            if (item.getProductId() == productId) {
                // 일치하는 상품을 장바구니 리스트 안에서 통째로 파내어 솎아냅니다.
                cartList.remove(i);
                break; // 목적을 달성했으니 효율적인 연산을 위해 즉시 루프 탈출!
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

    // 5. 세션 메모리 청소가 끝났으니, 다시 깔끔해진 장바구니 화면으로 화면을 새로고침 시킵니다.
    response.sendRedirect("../cart.jsp");
%>