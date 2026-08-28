<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="dto.EarPhone" %>
<%@ page import="dao.EarPhoneRepository" %>

<%
    // 1. 한글 인코딩 설정 및 로그인 세션 검증
    request.setCharacterEncoding("UTF-8");
    String sessionUserId = (String) session.getAttribute("userId");
    
    if (sessionUserId == null || sessionUserId.trim().isEmpty()) {
%>
        <script>
            alert("세션이 만료되었습니다. 다시 로그인해 주세요.");
            location.href = "../login.jsp";
        </script>
<%
        return;
    }

    // 2. order.jsp에서 전달된 배송지 파라미터 수신
    String orderName = request.getParameter("orderName");
    String orderPhone = request.getParameter("orderPhone");
    String orderMail = request.getParameter("orderMail");
    String zipCode = request.getParameter("zipCode");
    String address = request.getParameter("address");
    String addressDetail = request.getParameter("addressDetail");

    // 3. 결제할 장바구니 리스트 조회
    // (order.jsp에서 필터링된 cartList를 세션에 따로 담지 않았다면 기본 cartList 사용)
    ArrayList<EarPhone> cartList = (ArrayList<EarPhone>) session.getAttribute("cartList");
    
    if (cartList == null || cartList.isEmpty()) {
%>
        <script>
            alert("결제할 상품이 없습니다.");
            location.href = "../cart.jsp";
        </script>
<%
        return;
    }

    // 4. 총 결제 금액 계산
    int totalPrice = 0;
    EarPhoneRepository repository = EarPhoneRepository.getInstance();
    
    for (EarPhone item : cartList) {
        totalPrice += (item.getPrice() * item.getStock());
    }

    Connection conn = null;
    PreparedStatement pstmt = null;
    boolean isOrderSuccess = false;
    PreparedStatement pstmtDel = null;
    
    try {
        conn = util.DBConnection.getConnection();
        
        // (1) dbo.orders 테이블에 주문 내역 저장
        String sql = "INSERT INTO dbo.orders (mId, orderName, orderPhone, orderMail, zipCode, address, addressDetail, totalPrice) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, sessionUserId.trim());
        pstmt.setString(2, orderName.trim());
        pstmt.setString(3, orderPhone.trim());
        pstmt.setString(4, orderMail.trim());
        pstmt.setString(5, zipCode);
        pstmt.setString(6, address);
        pstmt.setString(7, addressDetail);
        pstmt.setInt(8, totalPrice);
        
        int rows = pstmt.executeUpdate();
        
        if (rows > 0) {
            // (2) 상품별 DB 재고 차감
            for (EarPhone item : cartList) {
                repository.updateStock(item.getStock(), item.getProductId());
            }

            // (3) 같은 커넥션 안에서 장바구니 삭제
            String sqlDel = "DELETE FROM dbo.cart WHERE TRIM(mId) = ?";
            pstmtDel = conn.prepareStatement(sqlDel);
            pstmtDel.setString(1, sessionUserId.trim());
            pstmtDel.executeUpdate();
            
            isOrderSuccess = true;
        }
        
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        // 자원 반납
        if (pstmtDel != null) try { pstmtDel.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (conn != null) try { conn.close(); } catch(Exception e) {}
    }

 // 5. 결과에 따른 후처리
    if (isOrderSuccess) {
        session.removeAttribute("cartList");

        // 주문 완료 페이지로 이동
        response.sendRedirect("../orderConfirmed.jsp?orderName=" + java.net.URLEncoder.encode(orderName, "UTF-8") + "&totalPrice=" + totalPrice);
    } else {
%>
        <script>
            alert("❌ 결제 처리 중 오류가 발생했습니다. 다시 시도해 주세요.");
            history.back();
        </script>
<%
    }
%>