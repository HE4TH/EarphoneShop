<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // 1. 로그인 세션 정보 삭제
    session.removeAttribute("userId");
    session.removeAttribute("userName");
    
    // 2. 세션에 담긴 장바구니 리스트도 함께 제거
    session.removeAttribute("cartList");
    
    // 3. 직전 페이지로 리다이렉트
    String prevPage = request.getParameter("prevPage");
    if (prevPage == null || prevPage.trim().isEmpty()) {
        prevPage = "main.jsp";
    }
    
    response.sendRedirect(prevPage);
%>