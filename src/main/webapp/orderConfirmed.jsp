<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.text.DecimalFormat" %>
<%
    // 1. 한글 인코딩 설정
    request.setCharacterEncoding("UTF-8");

    String orderName = request.getParameter("orderName");

    // 2. URL 파라미터로 전달된 한글 이름 디코딩
    if (orderName != null) {
        try {
            orderName = java.net.URLDecoder.decode(orderName, "UTF-8");
        } catch(Exception e) {
            orderName = request.getParameter("orderName");
        }
    } else {
        orderName = "고객";
    }

    // 3. 결제 금액 파라미터 수신
    String totalPriceStr = request.getParameter("totalPrice");
    int totalPrice = 0;
    if (totalPriceStr != null) {
        totalPrice = Integer.parseInt(totalPriceStr);
    }
    
    DecimalFormat df = new DecimalFormat("#,###");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>코드 사운드 | 주문 완료</title>
    <link rel="stylesheet" href="resource/style.css">
</head>
<body>

    <jsp:include page="include/menu.jsp" />

    <div class="member-container">
        <div class="member-card" style="max-width: 550px; text-align: center; padding: 40px 30px;">
            
            <div class="confirm-icon-zone" style="margin-bottom: 20px;">
                <span style="font-size: 60px;">🎉</span>
            </div>

            <div class="member-header" style="margin-bottom: 30px;">
                <h2 style="font-size: 28px; font-weight: 800; color: #1e293b; letter-spacing: -1px;">주문이 완료되었습니다!</h2>
                <p style="color: #64748b; font-size: 14px; margin-top: 8px;">코드 사운드를 이용해 주셔서 진심으로 감사합니다.</p>
            </div>

            <!-- 🎯 테두리 오타 구역을 깔끔한 정석 라이트 실선(#e2e8f0)으로 전면 교정 완료! -->
            <div class="order-summary-zone" style="background-color: #f8fafc; border-radius: 12px; padding: 24px; text-align: left; margin-bottom: 35px; border: 1px solid #e2e8f0;">
                <h4 style="font-size: 15px; font-weight: 700; color: #334155; margin-bottom: 15px; border-bottom: 1px solid #e2e8f0; padding-bottom: 10px;">결제 명세서</h4>
                
                <div style="display: flex; justify-content: space-between; margin-bottom: 12px; font-size: 14px;">
                    <span style="color: #64748b;">주문자명</span>
                    <strong style="color: #1e293b;"><%= util.HtmlUtil.escape(orderName) %>님</strong>
                </div>
                
                <div style="display: flex; justify-content: space-between; margin-bottom: 12px; font-size: 14px;">
                    <span style="color: #64748b;">배송 정보</span>
                    <span style="color: #334155; font-weight: 500;">한진택배 (무료배송)</span>
                </div>
                
                <hr style="border: 0; height: 1px; background: #e2e8f0; margin: 15px 0;">
                
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <span style="font-weight: 700; color: #1e293b; font-size: 15px;">최종 결제 금액</span>
                    <strong style="color: #007bff; font-size: 20px; font-weight: 800;"><%= df.format(totalPrice) %>원</strong>
                </div>
            </div>

            <div style="display: flex; gap: 12px; justify-content: center;">
                <button type="button" class="btn-submit-member" onclick="location.href='products.jsp?category=all'" style="background-color: #1e293b !important; flex: 1; margin: 0; height: 48px; font-size: 14px;">
                    쇼핑 계속하기
                </button>
                <button type="button" class="btn-submit-member" onclick="location.href='myPage.jsp'" style="background-color: #ffffff !important; color: #1e293b !important; border: 1px solid #cbd5e1 !important; flex: 1; margin: 0; height: 48px; font-size: 14px; font-weight: 700;">
                    주문 내역 확인
                </button>
            </div>

        </div>
    </div>

</body>
</html>