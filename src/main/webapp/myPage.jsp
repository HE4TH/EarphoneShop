<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>

<%
    // 1. 로그인 검증
    String sessionUserId = (String) session.getAttribute("userId");
    if (sessionUserId == null || sessionUserId.trim().isEmpty()) {
%>
        <script>
            alert("마이페이지는 로그인 후 이용 가능합니다.");
            location.href = "login.jsp";
        </script>
<%
        return;
    }

    DecimalFormat df = new DecimalFormat("#,###");

    // 2. 회원 데이터 조회
    String mName = "";
    String mail = "";
    String phone = "";
    String zipCode = "";
    String address = "";
    String addressDetail = "";

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        conn = util.DBConnection.getConnection();

        String sql = "SELECT mName, mail, phone, zipCode, address, addressDetail FROM dbo.member WHERE TRIM(mId) = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, sessionUserId.trim());
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            mName = rs.getString("mName") != null ? rs.getString("mName") : "";
            mail = rs.getString("mail") != null ? rs.getString("mail") : "";
            phone = rs.getString("phone") != null ? rs.getString("phone") : "";
            zipCode = rs.getString("zipCode") != null ? rs.getString("zipCode") : "";
            address = rs.getString("address") != null ? rs.getString("address") : "";
            addressDetail = rs.getString("addressDetail") != null ? rs.getString("addressDetail") : "";
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (conn != null) try { conn.close(); } catch(Exception e) {}
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>코드 사운드 | 마이페이지</title>
    <link rel="stylesheet" href="resource/style.css">
    <style>
        .mypage-layout { display: flex; gap: 30px; margin-top: 30px; }
        .mypage-sidebar { width: 200px; flex-shrink: 0; }
        .mypage-menu-list { list-style: none; padding: 0; margin: 0; border: 1px solid #e2e8f0; border-radius: 10px; overflow: hidden; background: #fff; }
        .mypage-menu-item { padding: 15px 20px; font-size: 14px; font-weight: 600; color: #475569; cursor: pointer; border-bottom: 1px solid #f1f5f9; transition: all 0.2s; text-align: left; }
        .mypage-menu-item:last-child { border-bottom: none; }
        .mypage-menu-item:hover { background: #f8fafc; color: #1e293b; }
        .mypage-menu-item.active { background: #1e293b; color: #ffffff; }
        
        .mypage-content-area { flex-grow: 1; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 30px; min-height: 400px; }
        .tab-content { display: none; }
        .tab-content.active { display: block; }
        
        .my-form-group { margin-bottom: 20px; display: flex; flex-direction: column; gap: 8px; text-align: left; }
        .my-form-group label { font-size: 14px; font-weight: 700; color: #334155; }
        .my-form-group input[type="text"], .my-form-group input[type="password"] { padding: 10px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 14px; width: 100%; box-sizing: border-box; }
        .my-form-group input[readonly] { background-color: #f1f5f9; cursor: not-allowed; }
        
        /* 회원 탈퇴 경고 박스 */
        .withdraw-warning-box { background-color: #fff1f2; border: 1px solid #fecdd3; border-radius: 8px; padding: 15px; margin-bottom: 25px; text-align: left; }
        .withdraw-warning-box p { color: #be123c; font-size: 13px; margin: 4px 0; font-weight: 500; }

        @media (max-width: 768px) {
            .mypage-layout { flex-direction: column; gap: 16px; }
            .mypage-sidebar { width: 100%; }
            .mypage-menu-list { display: flex; overflow-x: auto; }
            .mypage-menu-item { white-space: nowrap; border-bottom: none; border-right: 1px solid #f1f5f9; }
            .mypage-content-area { padding: 18px; }
        }
    </style>
</head>
<body>

    <jsp:include page="include/menu.jsp" />

    <div class="cart-container" style="max-width: 1050px; margin-top: 40px;">
        <div class="cart-header" style="border-bottom: 2px solid #1e293b; padding-bottom: 15px; margin-bottom: 10px;">
            <h2 style="font-size: 26px; font-weight: 800; color: #1e293b;"><%= util.HtmlUtil.escape(sessionUserId) %>님의 대시보드</h2>
        </div>

        <div class="mypage-layout">
            <div class="mypage-sidebar">
                <ul class="mypage-menu-list">
                    <li class="mypage-menu-item active" onclick="switchMypageTab(this, 'tab-orders')">📦 주문/배송 조회</li>
                    <li class="mypage-menu-item" onclick="switchMypageTab(this, 'tab-profile')">🔒 회원 정보 수정</li>
                    <li class="mypage-menu-item" onclick="switchMypageTab(this, 'tab-address')">📍 배송지 관리</li>
                    <li class="mypage-menu-item" style="color: #e11d48;" onclick="switchMypageTab(this, 'tab-withdraw')">❌ 회원 탈퇴</li>
                </ul>
            </div>

            <div class="mypage-content-area">
                
                <div id="tab-orders" class="tab-content active">
                    <h3 style="font-size: 18px; font-weight: 700; color: #334155; margin-bottom: 20px; text-align: left;">주문/배송 내역</h3>
                    <%
                        java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm");
                        java.util.ArrayList<dto.Order> orderList = dao.OrderRepository.getInstance().getOrdersByMember(sessionUserId.trim());

                        if (orderList.isEmpty()) {
                    %>
                                <div class="detail-section-placeholder" style="text-align: center; padding: 60px 20px; background: #f8fafc; border-radius: 12px; border: 1px dashed #cbd5e1;">
                                    <span style="font-size: 40px; display: block; margin-bottom: 15px;">📦</span>
                                    <h3 style="color: #475569; font-size: 16px; font-weight: 700;">아직 주문하신 내역이 없습니다.</h3>
                                </div>
                    <%
                        } else {
                            for (dto.Order order : orderList) {
                                String status = order.getOrderStatus();
                                String badgeStyle = "background: #e0f2fe; color: #0369a1;";
                                if ("배송중".equals(status)) badgeStyle = "background: #fef9c3; color: #a16207;";
                                else if ("배송완료".equals(status)) badgeStyle = "background: #dcfce7; color: #15803d;";
                                else if ("취소됨".equals(status)) badgeStyle = "background: #fee2e2; color: #b91c1c;";
                                String fullAddress = order.getAddress() + " " + order.getAddressDetail();
                                java.util.ArrayList<dto.OrderItem> orderItems = dao.OrderRepository.getInstance().getOrderItems(order.getOrderId());
                    %>
                                <div class="order-history-card" style="background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 20px; margin-bottom: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.02); text-align: left;">
                                    <div style="display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #f1f5f9; padding-bottom: 12px; margin-bottom: 15px;">
                                        <div>
                                            <span style="color: #64748b; font-size: 13px; font-weight: 500;">주문일자 │ <%= sdf.format(order.getOrderDate()) %></span>
                                            <span style="margin: 0 10px; color: #cbd5e1;">|</span>
                                            <span style="color: #007bff; font-size: 13px; font-weight: 700;">주문번호 No.<%= order.getOrderId() %></span>
                                        </div>
                                        <span style="<%= badgeStyle %> font-size: 12px; font-weight: 700; padding: 4px 10px; border-radius: 20px;"><%= util.HtmlUtil.escape(status) %></span>
                                    </div>

                                    <ul style="list-style: none; padding: 0; margin: 0 0 12px 0;">
                                    <% for (dto.OrderItem item : orderItems) { %>
                                        <li style="font-size: 13px; color: #475569; padding: 4px 0;">
                                            <%= util.HtmlUtil.escape(item.getpName()) %> × <%= item.getQuantity() %>개 (<%= df.format(item.getPrice() * item.getQuantity()) %>원)
                                        </li>
                                    <% } %>
                                    </ul>

                                    <div style="display: flex; justify-content: space-between; align-items: flex-start;">
                                        <div>
                                            <h4 style="font-size: 16px; font-weight: 700; color: #1e293b; margin-bottom: 6px;"><%= util.HtmlUtil.escape(order.getOrderName()) %>님 결제 완료 건</h4>
                                            <p style="color: #64748b; font-size: 13px;">📍 배송지: <%= util.HtmlUtil.escape(fullAddress) %></p>
                                        </div>
                                        <div style="text-align: right;">
                                            <span style="color: #94a3b8; font-size: 12px; display: block; margin-bottom: 4px;">총 결제 금액</span>
                                            <strong style="font-size: 18px; color: #1e293b; font-weight: 800;"><%= df.format(order.getTotalPrice()) %>원</strong>
                                        </div>
                                    </div>

                                    <% if ("배송준비중".equals(status)) { %>
                                        <form action="process/cancelOrder.jsp" method="post" style="text-align: right; margin-top: 12px;" onsubmit="return confirm('이 주문을 취소하시겠습니까?');">
                                            <input type="hidden" name="csrfToken" value="<%= util.CsrfUtil.getToken(session) %>">
                                            <input type="hidden" name="orderId" value="<%= order.getOrderId() %>">
                                            <button type="submit" style="background: #fff1f2; color: #e11d48; border: 1px solid #fecdd3; border-radius: 8px; padding: 6px 14px; font-size: 13px; font-weight: 700; cursor: pointer;">주문 취소</button>
                                        </form>
                                    <% } %>
                                </div>
                    <%
                            }
                        }
                    %>
                </div>

                <div id="tab-profile" class="tab-content">
                    <h3 style="font-size: 18px; font-weight: 700; color: #334155; margin-bottom: 20px; text-align: left;">🔒 회원 정보 수정</h3>
                    <form action="process/updateProfileProcess.jsp" method="post" style="max-width: 500px;">
                        <div class="my-form-group">
                            <label>아이디</label>
                            <input type="text" name="mId" value="<%= util.HtmlUtil.escape(sessionUserId) %>" readonly>
                        </div>
                        <div class="my-form-group">
                            <label>새 비밀번호 변경</label>
                            <input type="password" name="passwd" placeholder="변경할 비밀번호를 입력해 주세요 (미변경시 기존 유지)">
                        </div>
                        <div class="my-form-group">
                            <label>이름</label>
                            <input type="text" name="mName" value="<%= util.HtmlUtil.escape(mName) %>" required>
                        </div>
                        <div class="my-form-group">
                            <label>이메일 주소</label>
                            <input type="text" name="mail" value="<%= util.HtmlUtil.escape(mail) %>" required>
                        </div>
                        <div class="my-form-group">
                            <label>연락처</label>
                            <input type="text" name="phone" value="<%= util.HtmlUtil.escape(phone) %>" required>
                        </div>
                        <div style="text-align: left; margin-top: 30px;">
                            <button type="submit" class="btn-submit-member" style="background-color: #1e293b !important; max-width: 180px; margin: 0; font-size: 14px; height: 45px;">
                                회원정보 저장하기
                            </button>
                        </div>
                    </form>
                </div>

                <div id="tab-address" class="tab-content">
                    <h3 style="font-size: 18px; font-weight: 700; color: #334155; margin-bottom: 20px; text-align: left;">📍 배송지 설정 관리</h3>
                    <form action="process/updateAddressProcess.jsp" method="post" style="max-width: 550px;">
                        <div class="my-form-group">
                            <label>기본 배송 주소지</label>
                            <div class="address-zip-zone" style="display: flex; gap: 10px; margin-bottom: 8px;">
                                <input type="text" id="mypage_postcode" name="zipCode" value="<%= util.HtmlUtil.escape(zipCode) %>" placeholder="우편번호" readonly style="flex: 1;">
                                <button type="button" class="btn-search-address" onclick="execMypagePostcode()" style="margin: 0; white-space: nowrap; padding: 0 15px; font-size: 13px;">주소 검색</button>
                            </div>
                            <input type="text" id="mypage_address" name="address" value="<%= util.HtmlUtil.escape(address) %>" placeholder="기본 주소" required style="margin-bottom: 8px;">
                            <input type="text" id="mypage_detailAddress" name="addressDetail" value="<%= util.HtmlUtil.escape(addressDetail) %>" placeholder="나머지 상세 주소 명시">
                        </div>
                        <div style="text-align: left; margin-top: 30px;">
                            <button type="submit" class="btn-submit-member" style="background-color: #007bff !important; max-width: 180px; margin: 0; font-size: 14px; height: 45px;">
                                배송지 주소 저장
                            </button>
                        </div>
                    </form>
                </div>

                <div id="tab-withdraw" class="tab-content">
                    <h3 style="font-size: 18px; font-weight: 700; color: #e11d48; margin-bottom: 20px; text-align: left;">❌ 코드 사운드 회원 탈퇴</h3>
                    
                    <div class="withdraw-warning-box">
                        <h4 style="margin: 0 0 8px 0; color: #9f1239; font-size: 14px; font-weight: 700;">⚠️ 탈퇴 전 반드시 확인해 주세요</h4>
                        <p>• 탈퇴 즉시 회원님의 가입 정보 및 주소록 데이터는 복구 불가능하게 모두 영구 삭제됩니다.</p>
                        <p>• 과거 구매하셨던 이어폰 주문 내역 확인 및 배송 조회가 전면 불가능해집니다.</p>
                    </div>

                    <form action="process/withdrawProcess.jsp" method="post" style="max-width: 500px;" onsubmit="return confirmWithdraw()">
                        <input type="hidden" name="csrfToken" value="<%= util.CsrfUtil.getToken(session) %>">
                        <div class="my-form-group">
                            <label>계정 확인</label>
                            <input type="text" value="<%= util.HtmlUtil.escape(sessionUserId) %>" readonly style="color: #94a3b8;">
                        </div>
                        
                        <div class="my-form-group">
                            <label>현재 비밀번호 인증</label>
                            <input type="password" id="withdraw_pass" name="passwd" placeholder="본인 인증을 위해 현재 비밀번호를 입력해 주세요" required>
                        </div>

                        <div style="text-align: left; margin-top: 35px;">
                            <button type="submit" class="btn-submit-member" style="background-color: #e11d48 !important; color: #ffffff !important; max-width: 180px; margin: 0; font-size: 14px; height: 45px; font-weight: 700;">
                                탈퇴 최종 확인
                            </button>
                        </div>
                    </form>
                </div>

            </div>
        </div>
    </div>

    <script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
    <script>
        function switchMypageTab(element, tabId) {
            document.querySelectorAll('.mypage-menu-item').forEach(item => {
                item.classList.remove('active');
            });
            element.classList.add('active');

            document.querySelectorAll('.tab-content').forEach(content => {
                content.classList.remove('active');
            });
            document.getElementById(tabId).classList.add('active');
        }

        function execMypagePostcode() {
            new daum.Postcode({
                oncomplete: function(data) {
                    var addr = data.userSelectedType === 'R' ? data.roadAddress : data.jibunAddress;
                    document.getElementById('mypage_postcode').value = data.zonecode;
                    document.getElementById("mypage_address").value = addr;
                    document.getElementById("mypage_detailAddress").focus();
                }
            }).open();
        }

        // 회원 탈퇴 전 비밀번호 및 2단계 확인
        function confirmWithdraw() {
            const passInput = document.getElementById('withdraw_pass').value;
            if(!passInput.trim()) {
                alert("비밀번호를 입력해 주세요.");
                return false;
            }
            
       		// 탈퇴 전 2단계 확인
            if (confirm("정말로 코드 사운드를 탈퇴하시겠습니까?\n모든 데이터가 영구히 소멸됩니다.")) {
                return confirm("마지막 확인입니다. 탈퇴 후 회원 정보는 절대 복구할 수 없습니다. 동의하십니까?");
            }
            return false;
        }
    </script>
</body>
</html>