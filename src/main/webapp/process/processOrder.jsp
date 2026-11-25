<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="dto.EarPhone" %>
<%@ page import="dao.EarPhoneRepository" %>
<%@ page import="jakarta.servlet.http.HttpServletResponse" %>

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

    // 1-1. CSRF 토큰 검증
    if (!util.CsrfUtil.isValid(request)) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN, "잘못된 요청입니다.");
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
    String outOfStockName = null;   // 재고가 부족했던 상품명(있으면 안내 문구에 사용)

    try {
        conn = util.DBConnection.getConnection();
        // 주문 저장 → 품목 저장 → 재고 차감 → 장바구니 삭제를 하나의 트랜잭션으로 묶는다.
        // 중간에 하나라도 실패하면 rollback해서 일부만 반영되는 일이 없게 한다.
        conn.setAutoCommit(false);

        // (1) dbo.orders 테이블에 주문 내역 저장
        String sql = "INSERT INTO dbo.orders (mId, orderName, orderPhone, orderMail, zipCode, address, addressDetail, totalPrice) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
        pstmt.setString(1, sessionUserId.trim());
        pstmt.setString(2, orderName.trim());
        pstmt.setString(3, orderPhone.trim());
        pstmt.setString(4, orderMail.trim());
        pstmt.setString(5, zipCode);
        pstmt.setString(6, address);
        pstmt.setString(7, addressDetail);
        pstmt.setInt(8, totalPrice);

        int rows = pstmt.executeUpdate();
        if (rows <= 0) {
            throw new SQLException("주문 저장 실패");
        }

        // (1-1) 생성된 주문번호 확보 후 구매 품목 스냅샷 저장 (주문 상세/취소 시 필요)
        int generatedOrderId = -1;
        try (ResultSet keys = pstmt.getGeneratedKeys()) {
            if (keys.next()) {
                generatedOrderId = keys.getInt(1);
            }
        }
        if (generatedOrderId <= 0) {
            throw new SQLException("주문번호 생성 실패");
        }
        dao.OrderRepository.getInstance().insertOrderItems(conn, generatedOrderId, cartList);

        // (2) 상품별 DB 재고 차감 — 같은 트랜잭션 안에서 조건부 UPDATE
        //     재고가 부족한 상품이 하나라도 있으면 주문 전체를 취소한다.
        for (EarPhone item : cartList) {
            if (!repository.decreaseStock(conn, item.getStock(), item.getProductId())) {
                outOfStockName = item.getpName();
                throw new SQLException("재고 부족: productId=" + item.getProductId());
            }
        }

        // (3) 같은 트랜잭션 안에서 장바구니 삭제
        String sqlDel = "DELETE FROM dbo.cart WHERE TRIM(mId) = ?";
        pstmtDel = conn.prepareStatement(sqlDel);
        pstmtDel.setString(1, sessionUserId.trim());
        pstmtDel.executeUpdate();

        conn.commit();
        isOrderSuccess = true;

    } catch (Exception e) {
        // 어느 단계에서 실패하든 지금까지의 변경(주문·품목·재고)을 모두 되돌린다
        if (conn != null) try { conn.rollback(); } catch(Exception re) { re.printStackTrace(); }
        if (outOfStockName == null) {
            e.printStackTrace();
        }
    } finally {
        // 자원 반납 (커넥션은 자동 커밋 상태로 되돌린 뒤 닫는다)
        if (pstmtDel != null) try { pstmtDel.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (conn != null) {
            try { conn.setAutoCommit(true); } catch(Exception e) {}
            try { conn.close(); } catch(Exception e) {}
        }
    }

 // 5. 결과에 따른 후처리
    if (isOrderSuccess) {
        session.removeAttribute("cartList");

        // 주문 완료 페이지로 이동
        response.sendRedirect("../orderConfirmed.jsp?orderName=" + java.net.URLEncoder.encode(orderName, "UTF-8") + "&totalPrice=" + totalPrice);
    } else if (outOfStockName != null) {
        // 재고 부족: 주문은 만들어지지 않았고 장바구니도 그대로 남아 있다
%>
        <script>
            alert("재고가 부족해 주문할 수 없습니다: <%= util.HtmlUtil.escapeJs(outOfStockName) %>\n장바구니에서 수량을 확인해 주세요.");
            location.href = "../cart.jsp";
        </script>
<%
    } else {
%>
        <script>
            alert("❌ 결제 처리 중 오류가 발생했습니다. 다시 시도해 주세요.");
            history.back();
        </script>
<%
    }
%>