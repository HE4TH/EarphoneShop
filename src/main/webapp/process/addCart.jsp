<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.EarPhoneRepository"%>
<%@ page import="dto.EarPhone"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.sql.*" %>

<%
    // 1. 주소창에서 넘어온 파라미터 문자열을 가로챕니다.
    String productIdStr = request.getParameter("productId");
    String qtyParam = request.getParameter("quantity");
    
    // 수량(int) 파라미터 숫자로 변환 (기본값 1개)
    int quantity = 1;
    if (qtyParam != null && !qtyParam.trim().isEmpty()) {
        quantity = Integer.parseInt(qtyParam.trim());
    }

    // [방어 코드] 상품 ID 파라미터가 비어있다면 목록으로 강제 리다이렉트
    if (productIdStr == null || productIdStr.trim().isEmpty()) {
        response.sendRedirect("../products.jsp");
        return;
    }

    // 🎯 String 타입을 승민님이 설계하신 진짜 long 자료형으로 변환합니다.
    long productId = Long.parseLong(productIdStr.trim());

    // 2. 상품이 실제로 존재하는지 1차 검증
    EarPhoneRepository repository = EarPhoneRepository.getInstance();
    EarPhone goods = repository.getEarPhoneById(productId); 

    if (goods == null) {
        response.sendRedirect("../products.jsp");
        return;
    }

    // ==========================================================================
    // 🚀 [대수술 구역] 세션 저장 방식을 폐기하고, SQL Server DB 영구 적재 가동!
    // ==========================================================================
    
    // 🎯 [보안선] 현재 로그인한 유저의 아이디를 세션에서 꺼냅니다.
    String sessionUserId = (String) session.getAttribute("userId");
    
    // 🚨 만약 로그인을 안 한 상태(비회원)에서 장바구니 담기를 누르면 로그인창으로 유도합니다.
    if (sessionUserId == null || sessionUserId.trim().isEmpty()) {
%>
        <script>
            alert("로그인 후 장바구니 이용이 가능합니다.");
            location.href = "../login.jsp";
        </script>
<%
        return; 
    } // 🎯 자바의 if문 괄호를 자바 영역 안에서 안전하게 닫아줍니다!
%>
<%
    Connection conn = null;
    PreparedStatement pstmtCheck = null;
    PreparedStatement pstmtUpdate = null;
    PreparedStatement pstmtInsert = null;
    ResultSet rsCheck = null;

    try {
        // 🎯 [검증 쿼리] 이미 이 유저(mId)가 해당 상품(pId)을 장바구니 테이블에 담아놓았는지 체크
        String sqlCheck = "SELECT cartId, pCount FROM cart WHERE mId = ? AND pId = ?";

        conn = util.DBConnection.getConnection();
        
        pstmtCheck = conn.prepareStatement(sqlCheck);
        pstmtCheck.setString(1, sessionUserId.trim());
        pstmtCheck.setString(2, String.valueOf(productId)); 
        rsCheck = pstmtCheck.executeQuery();
        
        if (rsCheck.next()) {
            // [시나리오 A] 이미 동일한 이어폰이 테이블에 존재한다면? 기존 수량에 누적 더하기!
            int currentCount = rsCheck.getInt("pCount");
            String sqlUpdate = "UPDATE cart SET pCount = ? WHERE cartId = ?";
            
            pstmtUpdate = conn.prepareStatement(sqlUpdate);
            pstmtUpdate.setInt(1, currentCount + quantity); 
            pstmtUpdate.setInt(2, rsCheck.getInt("cartId"));
            pstmtUpdate.executeUpdate();
        } else {
            // [시나리오 B] 장바구니 테이블에 없는 새로운 상품이라면? 새 행으로 인서트!
            String sqlInsert = "INSERT INTO cart (mId, pId, pCount) VALUES (?, ?, ?)";
            
            pstmtInsert = conn.prepareStatement(sqlInsert);
            pstmtInsert.setString(1, sessionUserId.trim());
            pstmtInsert.setString(2, String.valueOf(productId));
            pstmtInsert.setInt(3, quantity); 
            pstmtInsert.executeUpdate();
        }
        
        // ==========================================================================
        // 🧩 [실종됐던 구역 수리 복구 1] 현재 세션 주머니(cartList)도 DB 데이터와 실시간 싱크 동기화
        // ==========================================================================
        PreparedStatement pstmtCart = null;
        ResultSet rsCart = null;
        ArrayList<EarPhone> sessionCartList = new ArrayList<EarPhone>();
        
        try {
            String sqlCart = "SELECT pId, pCount FROM cart WHERE mId = ? ORDER BY cartId DESC";
            pstmtCart = conn.prepareStatement(sqlCart);
            pstmtCart.setString(1, sessionUserId.trim());
            rsCart = pstmtCart.executeQuery();
            
            while (rsCart.next()) {
                long dbPid = Long.parseLong(rsCart.getString("pId"));
                int dbCount = rsCart.getInt("pCount");
                
                // 싱글톤 저장소에서 매칭되는 진짜 이어폰 상세 정보 호출
                EarPhone dbGoods = repository.getEarPhoneById(dbPid);
                if (dbGoods != null) {
                    EarPhone cartItem = new EarPhone();
                    cartItem.setProductId(dbGoods.getProductId());
                    cartItem.setpName(dbGoods.getpName());
                    cartItem.setpNameKn(dbGoods.getpNameKn());
                    cartItem.setPrice(dbGoods.getPrice()); // 오타 교정 (goods -> dbGoods)
                    cartItem.setBrand(dbGoods.getBrand());
                    cartItem.setpImage(dbGoods.getpImage());
                    cartItem.setCategory(dbGoods.getCategory());
                    cartItem.setStock(dbCount); // DB 누적 수량 매핑
                    
                    sessionCartList.add(cartItem);
                }
            }
            // 최신화된 리스트를 세션 주머니에 강제 주입
            session.setAttribute("cartList", sessionCartList);
            
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (rsCart != null) rsCart.close();
            if (pstmtCart != null) pstmtCart.close();
        }

        // 4. 모든 처리가 깔끔하게 끝났으니 내 장바구니 화면(cart.jsp)으로 슛!
        response.sendRedirect("../cart.jsp");

    } catch (Exception e) {
        e.printStackTrace();
%>
        <script>
            alert("장바구니 담기 처리 중 서버 오류가 발생했습니다.");
            history.back();
        </script>
<%
    } finally {
        // 🧩 [실종됐던 구역 수리 복구 2] 자원 안전 해제 처리
        if (rsCheck != null) try { rsCheck.close(); } catch(SQLException e) {}
        if (pstmtCheck != null) try { pstmtCheck.close(); } catch(SQLException e) {}
        if (pstmtUpdate != null) try { pstmtUpdate.close(); } catch(SQLException e) {}
        if (pstmtInsert != null) try { pstmtInsert.close(); } catch(SQLException e) {}
        if (conn != null) try { conn.close(); } catch(SQLException e) {}
    }
%>