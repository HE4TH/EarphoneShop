<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.EarPhoneRepository" %>
<%@ page import="dto.EarPhone" %>
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

    long productId = Long.parseLong(request.getParameter("productId"));
    EarPhone p = EarPhoneRepository.getInstance().getEarPhoneById(productId);
    if (p == null) {
        response.sendRedirect("adminMain.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>코드 사운드 | 상품 수정</title>
    <link rel="stylesheet" href="resource/style.css">
    <script src="resource/js/theme.js"></script>
    <style>
        body { background-color: #f8fafc; margin: 0; padding: 0; font-family: 'Pretendard', sans-serif; box-sizing: border-box; }
        .admin-container { width: 90%; max-width: 700px; margin: 40px auto; padding-bottom: 60px; box-sizing: border-box; }
        .admin-card { background: #ffffff; padding: 35px; border-radius: 14px; box-shadow: 0 4px 20px rgba(15, 23, 42, 0.05); border: 1px solid #e2e8f0; box-sizing: border-box; }
        .form-group { margin-bottom: 18px; }
        .form-group label { display: block; margin-bottom: 8px; font-weight: 600; color: #334155; font-size: 14px; }
        .form-group input, .form-group select {
            width: 100%; padding: 12px; border: 1px solid #cbd5e1; border-radius: 8px;
            box-sizing: border-box; font-size: 14px; background-color: #fff;
        }
        .current-file-note { font-size: 12px; color: #94a3b8; margin-top: 4px; }
        .btn-admin { background: #007bff; color: white; padding: 14px; border: none; border-radius: 8px; cursor: pointer; font-weight: 700; font-size: 15px; width: 100%; box-sizing: border-box; }
    </style>
</head>
<body>

    <jsp:include page="include/menu.jsp" />

    <div class="admin-container">
        <div class="admin-card">
            <h3 style="margin-top: 0; margin-bottom: 25px;">✏️ 상품 수정</h3>
            <form action="process/processEditProduct.jsp" method="post" enctype="multipart/form-data">
                <input type="hidden" name="csrfToken" value="<%= util.CsrfUtil.getToken(session) %>">
                <input type="hidden" name="productId" value="<%= p.getProductId() %>">
                <input type="hidden" name="currentPImage" value="<%= util.HtmlUtil.escape(p.getpImage()) %>">
                <input type="hidden" name="currentPDescriptionImage1" value="<%= util.HtmlUtil.escape(p.getpDescriptionImage1()) %>">

                <div class="form-group">
                    <label>상품 카테고리</label>
                    <select name="category" required>
                        <option value="WIRELESS" <%= "WIRELESS".equalsIgnoreCase(p.getCategory()) ? "selected" : "" %>>WIRELESS (무선)</option>
                        <option value="WIRED" <%= "WIRED".equalsIgnoreCase(p.getCategory()) ? "selected" : "" %>>WIRED (유선)</option>
                    </select>
                </div>

                <div class="form-group">
                    <label>브랜드명</label>
                    <input type="text" name="brand" value="<%= util.HtmlUtil.escape(p.getBrand()) %>" required>
                </div>

                <div class="form-group">
                    <label>상품 이름</label>
                    <input type="text" name="pName" value="<%= util.HtmlUtil.escape(p.getpName()) %>" required>
                </div>

                <div class="form-group">
                    <label>판매 가격</label>
                    <input type="number" name="price" value="<%= p.getPrice() %>" required>
                </div>

                <div class="form-group">
                    <label>재고 수량</label>
                    <input type="number" name="stock" value="<%= p.getStock() %>" required>
                </div>

                <div class="form-group">
                    <label>📸 대표 상품 이미지 (변경 시에만 선택)</label>
                    <input type="file" name="pImageFile" accept="image/*">
                    <p class="current-file-note">현재 파일: <%= util.HtmlUtil.escape(p.getpImage()) %></p>
                </div>

                <div class="form-group">
                    <label>📝 상세 설명 이미지 (변경 시에만 선택)</label>
                    <input type="file" name="pDescriptionImage1File" accept="image/*">
                    <p class="current-file-note">현재 파일: <%= util.HtmlUtil.escape(p.getpDescriptionImage1()) %></p>
                </div>

                <button type="submit" class="btn-admin">수정 저장</button>
            </form>
        </div>
    </div>

</body>
</html>
