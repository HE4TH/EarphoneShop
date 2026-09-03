<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="dto.EarPhone" %>

<%
    // 1. 로그인 검증
    String sessionUserId = (String) session.getAttribute("userId");
    if (sessionUserId == null || sessionUserId.trim().isEmpty()) {
%>
        <script>
            alert("주문은 로그인 후 가능합니다.");
            location.href = "login.jsp";
        </script>
<%
        return;
    }

    // 2. 장바구니 원본 리스트 수신
    ArrayList<EarPhone> originCartList = (ArrayList<EarPhone>) session.getAttribute("cartList");
    if (originCartList == null || originCartList.isEmpty()) {
%>
        <script>
            alert("장바구니가 비어 있습니다.");
            location.href = "cart.jsp";
        </script>
<%
        return;
    }

    // 3. 선택된 상품만 필터링 (selectedProducts 수신)
    String[] checkedProducts = request.getParameterValues("selectedProducts");
    ArrayList<EarPhone> cartList = new ArrayList<EarPhone>();

    if (checkedProducts == null || checkedProducts.length == 0) {
        cartList = originCartList; 
    } else {
        for (int i = 0; i < originCartList.size(); i++) {
            EarPhone item = originCartList.get(i);
            for (int j = 0; j < checkedProducts.length; j++) {
                if (String.valueOf(item.getProductId()).equals(checkedProducts[j].trim())) {
                    cartList.add(item); 
                    break;
                }
            }
        }
    }

    
    String mName = "";
    String mail = "";
    String phone = "";
    String zipCode = "";
    String address = "";         // 시/구/동 기본주소
    String addressDetail = "";   // 동/호수 상세주소

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        conn = util.DBConnection.getConnection();
        
        String sql = "SELECT mName, mail, phone, zipCode, address, addressDetail FROM member WHERE TRIM(mId) = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, sessionUserId.trim());
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            mName = rs.getString("mName");
            mail = rs.getString("mail");
            phone = rs.getString("phone");
            
            // null 방어 처리
            zipCode       = rs.getString("zipCode");
            address       = rs.getString("address");
            addressDetail = rs.getString("addressDetail");
            
            if(zipCode == null) zipCode = "";
            if(address == null) address = "";
            if(addressDetail == null) addressDetail = "";
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch(SQLException e) {}
        if (pstmt != null) try { pstmt.close(); } catch(SQLException e) {}
        if (conn != null) try { conn.close(); } catch(SQLException e) {}
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Code Sound | ORDER</title>
    <link rel="stylesheet" href="resource/style.css">
</head>
<body>

    <jsp:include page="include/menu.jsp" />

    <div class="member-container">
        <div class="member-card" style="max-width: 600px;"> <div class="member-header">
                <h2>CHECKOUT</h2>
                <p>주문 내역을 확인하신 후 결제를 진행해 주세요.</p>
            </div>

            <div class="order-summary-zone">
                <h3 class="order-sub-title">주문 상품 정보</h3>
                <table class="order-mini-table">
                    <thead>
                        <tr>
                            <th>상품명</th>
                            <th style="text-align: center;">수량</th>
                            <th style="text-align: right;">금액</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            int totalSum = 0;
                            for (int i = 0; i < cartList.size(); i++) {
                                EarPhone item = cartList.get(i);
                                int subTotal = item.getPrice() * item.getStock();
                                totalSum += subTotal;
                        %>
                            <tr>
                                <td><strong><%= util.HtmlUtil.escape(item.getpName()) %></strong></td>
                                <td style="text-align: center;"><%= item.getStock() %>개</td>
                                <td style="text-align: right; font-weight: 700;"><%= String.format("%,d", subTotal) %>원</td>
                            </tr>
                        <%
                            }
                        %>
                        <tr class="order-total-row">
                            <td colspan="2">최종 결제 금액</td>
                            <td style="text-align: right; color: #007bff; font-size: 18px; font-weight: 800;"><%= String.format("%,d", totalSum) %>원</td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <hr style="border: 0; height: 1px; background: #e2e8f0; margin: 30px 0;">

            <form id="orderForm" action="process/processOrder.jsp" method="post" onsubmit="return validateOrderForm()">
                <input type="hidden" name="csrfToken" value="<%= util.CsrfUtil.getToken(session) %>">
                <h3 class="order-sub-title">배송 정보</h3>
                
                <div class="input-group">
                    <label>주문자명</label>
                    <input type="text" name="orderName" value="<%= util.HtmlUtil.escape(mName) %>" required>
                </div>

                <div class="input-group">
                    <label>연락처</label>
                    <input type="text" name="orderPhone" value="<%= util.HtmlUtil.escape(phone) %>" placeholder="010-0000-0000" required>
                </div>

                <div class="input-group">
                    <label>이메일</label>
                    <input type="text" name="orderMail" value="<%= util.HtmlUtil.escape(mail) %>" required>
                </div>

                <div class="input-group">
				    <label>배송지 주소</label>
				    <div class="address-zip-zone">
				        <input type="text" id="sample6_postcode" name="zipCode" value="<%= util.HtmlUtil.escape(zipCode) %>" placeholder="우편번호" readonly required>
				        <button type="button" class="btn-search-address" onclick="execDaumPostcode()">주소 검색/변경</button>
				    </div>
				    <input type="text" id="sample6_address" name="address" value="<%= util.HtmlUtil.escape(address) %>" placeholder="기본 배송지 주소" required>
				    <input type="text" id="sample6_detailAddress" name="addressDetail" value="<%= util.HtmlUtil.escape(addressDetail) %>" placeholder="나머지 상세 주소를 입력해 주세요">
				    <input type="hidden" id="sample6_extraAddress">
				</div>

                <div class="member-action-zone" style="margin-top: 40px;">
                    <button type="submit" class="btn-submit-member" style="background-color: #007bff !important;">최종 결제하기</button>
                </div>
            </form>
        </div>
    </div>

    <script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
    <script>
        function execDaumPostcode() {
            new daum.Postcode({
                oncomplete: function(data) {
                    var addr = data.userSelectedType === 'R' ? data.roadAddress : data.jibunAddress;
                    document.getElementById('sample6_postcode').value = data.zonecode;
                    document.getElementById("sample6_address").value = addr;
                    document.getElementById("sample6_detailAddress").focus();
                }
            }).open();
        }

        function validateOrderForm() {
            return confirm("정말로 결제를 진행하시겠습니까?");
        }
    </script>
</body>
</html>