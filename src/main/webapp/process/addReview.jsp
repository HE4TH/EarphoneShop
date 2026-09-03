<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="jakarta.servlet.http.HttpServletResponse" %>
<%
    request.setCharacterEncoding("UTF-8");

    // 1. 로그인 검증
    String sessionUserId = (String) session.getAttribute("userId");
    if (sessionUserId == null || sessionUserId.trim().isEmpty()) {
        response.sendRedirect("../login.jsp");
        return;
    }

    // 2. CSRF 토큰 검증
    if (!util.CsrfUtil.isValid(request)) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN, "잘못된 요청입니다.");
        return;
    }

    // 3. 리뷰 스팸 방지: 계정당 1분에 3회까지만 등록 허용
    if (!util.RateLimiter.isAllowed("review:" + sessionUserId.trim(), 3, 60 * 1000L)) {
        response.sendError(429, "잠시 후 다시 시도해 주세요.");
        return;
    }

    // 4. 파라미터 수신 및 검증
    String productIdStr = request.getParameter("productId");
    String ratingStr = request.getParameter("rating");
    String content = request.getParameter("content");

    long productId;
    int rating;
    try {
        productId = Long.parseLong(productIdStr);
        rating = Integer.parseInt(ratingStr);
    } catch (Exception e) {
        response.sendError(HttpServletResponse.SC_BAD_REQUEST, "잘못된 요청입니다.");
        return;
    }

    if (rating < 1 || rating > 5 || content == null || content.trim().isEmpty() || content.trim().length() > 1000) {
%>
        <script>
            alert("평점(1~5)과 내용(1~1000자)을 올바르게 입력해 주세요.");
            history.back();
        </script>
<%
        return;
    }

    // 5. 리뷰 저장
    dao.ReviewRepository.getInstance().insertReview(productId, sessionUserId.trim(), rating, content.trim());

    response.sendRedirect("../detail.jsp?productId=" + productId);
%>
