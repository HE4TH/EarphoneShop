<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // 1. 로그인 세션 정보 삭제
    session.removeAttribute("userId");
    session.removeAttribute("userName");
    
    // 2. 세션에 담긴 장바구니 리스트도 함께 제거
    session.removeAttribute("cartList");
    
    // 3. 직전 페이지로 리다이렉트 (오픈 리다이렉트 방지: 외부 URL은 허용하지 않음)
    String prevPage = request.getParameter("prevPage");
    if (prevPage == null || prevPage.trim().isEmpty()
            || prevPage.contains("://") || prevPage.startsWith("//")) {
        prevPage = "main.jsp";
    }

    response.sendRedirect(prevPage);
%>