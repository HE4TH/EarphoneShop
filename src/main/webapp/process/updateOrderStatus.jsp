<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="jakarta.servlet.http.HttpServletResponse" %>
<%@ page import="java.util.Arrays" %>
<%
    request.setCharacterEncoding("UTF-8");

    String sessionUserId = (String) session.getAttribute("userId");
    if (sessionUserId == null || !sessionUserId.equals("admin")) {
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

    String newStatus = request.getParameter("orderStatus");
    java.util.List<String> allowedStatuses = Arrays.asList("배송준비중", "배송중", "배송완료", "취소됨");
    if (newStatus == null || !allowedStatuses.contains(newStatus)) {
        response.sendError(HttpServletResponse.SC_BAD_REQUEST, "잘못된 상태값입니다.");
        return;
    }

    dao.OrderRepository.getInstance().updateOrderStatus(orderId, newStatus);

    response.sendRedirect("../adminOrders.jsp");
%>
