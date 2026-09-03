<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.OrderRepository" %>
<%@ page import="dto.Order" %>
<%@ page import="dto.OrderItem" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    String sessionUserId = (String) session.getAttribute("userId");
    if (sessionUserId == null || !sessionUserId.equals("admin")) {
%>
        <script>
            alert("관리자만 접근할 수 있는 페이지입니다.");
            location.href = "login.jsp";
        </script>
<%
        return;
    }

    ArrayList<Order> orderList = OrderRepository.getInstance().getAllOrders();
    DecimalFormat df = new DecimalFormat("#,###");
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm");

    String[] statusOptions = { "배송준비중", "배송중", "배송완료", "취소됨" };
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>코드 사운드 | 주문 관리</title>
    <link rel="stylesheet" href="resource/style.css">
    <style>
        body { background-color: #f8fafc; margin: 0; padding: 0; font-family: 'Pretendard', sans-serif; }
        .admin-container { width: 92%; max-width: 1200px; margin: 40px auto; padding-bottom: 60px; }
        .admin-card { background: #ffffff; padding: 30px; border-radius: 14px; box-shadow: 0 4px 20px rgba(15, 23, 42, 0.05); border: 1px solid #e2e8f0; margin-bottom: 24px; }
        .admin-table { width: 100%; border-collapse: collapse; }
        .admin-table th, .admin-table td { padding: 12px; border-bottom: 1px solid #e2e8f0; text-align: left; font-size: 13px; vertical-align: top; }
        .admin-table th { background-color: #f1f5f9; color: #475569; font-weight: 600; }
        .order-items-list { list-style: none; padding: 0; margin: 0; font-size: 12px; color: #64748b; }
        .status-form { display: flex; gap: 6px; align-items: center; }
        .status-form select { padding: 6px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 12px; }
        .status-form button { background: #007bff; color: #fff; border: none; border-radius: 6px; padding: 6px 12px; font-size: 12px; font-weight: 700; cursor: pointer; }
    </style>
</head>
<body>

    <jsp:include page="include/menu.jsp" />

    <div class="admin-container">
        <h2 style="color: #0f172a; font-size: 24px; margin-bottom: 20px; font-weight: 800;">📦 주문 관리</h2>

        <div class="admin-card">
            <table class="admin-table">
                <thead>
                    <tr>
                        <th>주문번호</th>
                        <th>주문자</th>
                        <th>주문일시</th>
                        <th>구매품목</th>
                        <th>금액</th>
                        <th>배송지</th>
                        <th>상태 변경</th>
                    </tr>
                </thead>
                <tbody>
                <% for (Order order : orderList) {
                    ArrayList<OrderItem> items = OrderRepository.getInstance().getOrderItems(order.getOrderId());
                %>
                    <tr>
                        <td>No.<%= order.getOrderId() %></td>
                        <td><%= util.HtmlUtil.escape(order.getmId()) %><br><span style="color:#94a3b8;"><%= util.HtmlUtil.escape(order.getOrderName()) %></span></td>
                        <td><%= sdf.format(order.getOrderDate()) %></td>
                        <td>
                            <ul class="order-items-list">
                            <% for (OrderItem item : items) { %>
                                <li><%= util.HtmlUtil.escape(item.getpName()) %> × <%= item.getQuantity() %></li>
                            <% } %>
                            </ul>
                        </td>
                        <td><%= df.format(order.getTotalPrice()) %>원</td>
                        <td><%= util.HtmlUtil.escape(order.getAddress()) %> <%= util.HtmlUtil.escape(order.getAddressDetail()) %></td>
                        <td>
                            <form class="status-form" action="process/updateOrderStatus.jsp" method="post">
                                <input type="hidden" name="csrfToken" value="<%= util.CsrfUtil.getToken(session) %>">
                                <input type="hidden" name="orderId" value="<%= order.getOrderId() %>">
                                <select name="orderStatus">
                                    <% for (String option : statusOptions) { %>
                                        <option value="<%= option %>" <%= option.equals(order.getOrderStatus()) ? "selected" : "" %>><%= option %></option>
                                    <% } %>
                                </select>
                                <button type="submit">변경</button>
                            </form>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>

</body>
</html>
