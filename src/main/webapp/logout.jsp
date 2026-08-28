<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // 🎯 1. 로그인 세션 정보 정밀 삭제
    session.removeAttribute("userId");
    session.removeAttribute("userName");
    
    // 🎯 2. [추가] 화면에서 비워주기 위해 세션에 담긴 임시 장바구니 리스트도 함께 제거
    // (승민님이 세션에 장바구니를 담을 때 쓴 이름이 다르면 "cartList" 대신 그 이름을 적어주세요!)
    session.removeAttribute("cartList");
    
    // 3. 직전 주소 가로채서 제자리 리턴
    String prevPage = request.getParameter("prevPage");
    if (prevPage == null || prevPage.trim().isEmpty()) {
        prevPage = "main.jsp";
    }
    
    response.sendRedirect(prevPage);
%>