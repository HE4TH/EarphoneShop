<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="jakarta.servlet.http.HttpServletResponse" %>
<%
    request.setCharacterEncoding("UTF-8");

    String sessionUserId = (String) session.getAttribute("userId");
    if (sessionUserId == null || sessionUserId.trim().isEmpty()) {
        response.sendRedirect("../login.jsp");
        return;
    }

    if (!util.CsrfUtil.isValid(request)) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN, "잘못된 요청입니다.");
        return;
    }

    int orderId;
    try {
        orderId = Integer.parseInt(request.getParameter("orderId"));
    } catch (Exception e) {
        response.sendError(HttpServletResponse.SC_BAD_REQUEST, "잘못된 요청입니다.");
        return;
    }

    boolean cancelled = dao.OrderRepository.getInstance().cancelOrder(orderId, sessionUserId.trim());

    if (!cancelled) {
%>
        <script>
            alert("주문을 취소할 수 없습니다. (이미 처리 중이거나 취소된 주문일 수 있습니다)");
            history.back();
        </script>
<%
        return;
    }

    response.sendRedirect("../myPage.jsp");
%>
