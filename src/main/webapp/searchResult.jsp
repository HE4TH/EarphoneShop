<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.EarPhoneRepository"%>
<%@ page import="dto.EarPhone"%>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.text.DecimalFormat" %>
    
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>코드 사운드 - 검색 결과</title>
<link href="resource/style.css" rel="stylesheet" type="text/css">
<script src="resource/js/theme.js"></script>
</head>
<body>

    <jsp:include page="include/menu.jsp" />
    
    <%
        // 2. 검색창 input 값(name="searchKeyword") 및 브랜드/가격대 필터 수신
        request.setCharacterEncoding("UTF-8");

	    String keyword = request.getParameter("searchKeyword");
	    String brand = request.getParameter("brand");
	    String priceRange = request.getParameter("priceRange");
	    if (brand == null) brand = "ALL";
	    if (priceRange == null) priceRange = "";

	    Integer minPrice = null;
	    Integer maxPrice = null;
	    if (!priceRange.trim().isEmpty()) {
	        String[] rangeParts = priceRange.split("-");
	        try {
	            if (rangeParts.length > 0 && !rangeParts[0].isEmpty()) minPrice = Integer.parseInt(rangeParts[0]);
	            if (rangeParts.length > 1 && !rangeParts[1].isEmpty()) maxPrice = Integer.parseInt(rangeParts[1]);
	        } catch (NumberFormatException e) {
	            minPrice = null;
	            maxPrice = null;
	        }
	    }

	    DecimalFormat df = new DecimalFormat("#,###");

	    ArrayList<EarPhone> searchList = null;
	    if (keyword != null && !keyword.trim().isEmpty()) {
	        searchList = EarPhoneRepository.getInstance().getProductsBySearch(keyword);

	        // 브랜드/가격대 필터를 검색 결과에 추가로 적용
	        if (searchList != null && !searchList.isEmpty()) {
	            ArrayList<EarPhone> filtered = new ArrayList<EarPhone>();
	            for (EarPhone e : searchList) {
	                if (!brand.equals("ALL") && !brand.equals(e.getBrand())) continue;
	                if (minPrice != null && e.getPrice() < minPrice) continue;
	                if (maxPrice != null && e.getPrice() > maxPrice) continue;
	                filtered.add(e);
	            }
	            searchList = filtered;
	        }
	    }

	    ArrayList<String> brandList = EarPhoneRepository.getInstance().getDistinctBrands();

	    // 페이지네이션 계산
	    int pageSize = 12;
	    int totalItems = (searchList != null) ? searchList.size() : 0;
	    int totalPages = (int) Math.ceil(totalItems / (double) pageSize);
	    if (totalPages < 1) totalPages = 1;

	    int currentPage = 1;
	    try {
	        currentPage = Integer.parseInt(request.getParameter("page"));
	    } catch (Exception e) {
	        currentPage = 1;
	    }
	    if (currentPage < 1) currentPage = 1;
	    if (currentPage > totalPages) currentPage = totalPages;

	    int fromIndex = (currentPage - 1) * pageSize;
	    int toIndex = Math.min(fromIndex + pageSize, totalItems);
	    ArrayList<EarPhone> pagedList = (fromIndex < toIndex)
	            ? new ArrayList<EarPhone>(searchList.subList(fromIndex, toIndex))
	            : new ArrayList<EarPhone>();

	    String pageLinkSuffix = "&brand=" + java.net.URLEncoder.encode(brand, "UTF-8")
	            + "&priceRange=" + java.net.URLEncoder.encode(priceRange, "UTF-8")
	            + "&searchKeyword=" + java.net.URLEncoder.encode(keyword != null ? keyword.trim() : "", "UTF-8");
    %>

    <div class="page-header">
        <%
            // 검색어가 정상적으로 들어왔을 때 (null이 아니고, 공백을 제거해도 글자가 있을 때)
            if (keyword != null && !keyword.trim().isEmpty()) {
        %>
            <h2>'<%= util.HtmlUtil.escape(keyword.trim()) %>' 검색 결과</h2>

            <form action="searchResult.jsp" method="get" class="filter-group" style="margin-top: 12px;">
                <input type="hidden" name="searchKeyword" value="<%= util.HtmlUtil.escape(keyword.trim()) %>">

                <select name="brand" onchange="this.form.submit()">
                    <option value="ALL" <%= brand.equals("ALL") ? "selected" : "" %>>전체 브랜드</option>
                    <% for (String b : brandList) { %>
                        <option value="<%= util.HtmlUtil.escape(b) %>" <%= brand.equals(b) ? "selected" : "" %>><%= util.HtmlUtil.escape(b) %></option>
                    <% } %>
                </select>

                <select name="priceRange" onchange="this.form.submit()">
                    <option value="" <%= priceRange.isEmpty() ? "selected" : "" %>>전체 가격대</option>
                    <option value="0-50000" <%= priceRange.equals("0-50000") ? "selected" : "" %>>5만원 이하</option>
                    <option value="50000-100000" <%= priceRange.equals("50000-100000") ? "selected" : "" %>>5~10만원</option>
                    <option value="100000-200000" <%= priceRange.equals("100000-200000") ? "selected" : "" %>>10~20만원</option>
                    <option value="200000-300000" <%= priceRange.equals("200000-300000") ? "selected" : "" %>>20~30만원</option>
                    <option value="300000-" <%= priceRange.equals("300000-") ? "selected" : "" %>>30만원 이상</option>
                </select>
            </form>
        <%
            } else {
            // 검색창을 비우고 들어왔거나 스페이스바만 쳤을 때
        %>
            <h2>올바른 검색어를 입력해 주세요</h2>
        <%
            }
        %>
    </div>

    <div class="products-container">
        <%
            // 검색 결과가 존재하고 비어있지 않은 경우
            if (searchList != null && !searchList.isEmpty()) {
                for (EarPhone earphone : pagedList) {
                    String formattedPrice = df.format(earphone.getPrice());
        %>
            <a href="detail.jsp?productId=<%= earphone.getProductId() %>" class="shop-product-card"> 
               
                <div class="shop-img-box">
                    <img src="resource/main/<%= util.HtmlUtil.escape(earphone.getpImage()) %>" alt="<%= util.HtmlUtil.escape(earphone.getpName()) %>">
                </div>

                <p class="prod-brand"><%= util.HtmlUtil.escape(earphone.getBrand()) %></p>
                <h3 class="prod-title"><%= util.HtmlUtil.escape(earphone.getpName()) %></h3>
                <p class="prod-price"><%= formattedPrice %>원</p>
              
            </a>
        <%
                }
            } else {
                // 4. 검색 결과가 없을 때 안내 메시지 표시
        %>
            <div class="detail-section-placeholder" style="width: 100%; margin: 50px auto;">
                <h3>🔍 검색 결과가 없습니다.</h3>
                <p>철자나 띄어쓰기를 확인하시거나 다른 상품명으로 다시 검색해 보세요.</p>
            </div>
        <%
            }
        %>
    </div>

    <% if (searchList != null && !searchList.isEmpty() && totalPages > 1) { %>
    <div class="pagination-group">
        <% if (currentPage > 1) { %>
            <a href="searchResult.jsp?page=<%= currentPage - 1 %><%= pageLinkSuffix %>" class="page-item">이전</a>
        <% } %>
        <% for (int p = 1; p <= totalPages; p++) { %>
            <a href="searchResult.jsp?page=<%= p %><%= pageLinkSuffix %>" class="page-item <%= p == currentPage ? "active" : "" %>"><%= p %></a>
        <% } %>
        <% if (currentPage < totalPages) { %>
            <a href="searchResult.jsp?page=<%= currentPage + 1 %><%= pageLinkSuffix %>" class="page-item">다음</a>
        <% } %>
    </div>
    <% } %>

    <button type="button" id="scrollTopBtn" onclick="scrollToTop()">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" class="bi bi-arrow-up" viewBox="0 0 16 16">
            <path fill-rule="evenodd" d="M8 15a.5.5 0 0 0 .5-.5V2.707l3.146 3.147a.5.5 0 0 0 .708-.708l-4-4a.5.5 0 0 0-.708 0l-4 4a.5.5 0 1 0 .708.708L7.5 2.707V14.5a.5.5 0 0 0 .5.5"/>
        </svg>
    </button>
    
    <script>
        window.onscroll = function() {
            var topBtn = document.getElementById("scrollTopBtn");
            if (document.body.scrollTop > 300 || document.documentElement.scrollTop > 300) {
                topBtn.classList.add("show");
            } else {
                topBtn.classList.remove("show");
            }
        };
    
        function scrollToTop() {
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }
    </script>
</body>
</html>