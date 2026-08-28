<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.EarPhoneRepository"%>
<%@ page import="dto.EarPhone"%>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.text.DecimalFormat" %>
    
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>코드 사운드 - 검색 결과</title>
<link href="resource/style.css" rel="stylesheet" type="text/css">
</head>
<body>

    <jsp:include page="include/menu.jsp" />
    
    <%
        // 2. 검색창 input 값(name="searchKeyword") 수신
        request.setCharacterEncoding("UTF-8");

	    String keyword = request.getParameter("searchKeyword");
	    
	    DecimalFormat df = new DecimalFormat("#,###");
	    
	    ArrayList<EarPhone> searchList = null;
	    if (keyword != null && !keyword.trim().isEmpty()) {
	        searchList = EarPhoneRepository.getInstance().getProductsBySearch(keyword);
	    }
    %>
    
    <div class="page-header">
        <% 
            // 검색어가 정상적으로 들어왔을 때 (null이 아니고, 공백을 제거해도 글자가 있을 때)
            if (keyword != null && !keyword.trim().isEmpty()) { 
        %>
            <h2>'<%= keyword.trim() %>' 검색 결과</h2>
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
                for (EarPhone earphone : searchList) {
                    String formattedPrice = df.format(earphone.getPrice());
        %>
            <a href="detail.jsp?productId=<%= earphone.getProductId() %>" class="shop-product-card"> 
               
                <div class="shop-img-box">
                    <img src="resource/main/<%= earphone.getpImage() %>" alt="<%= earphone.getpName() %>">
                </div>
                
                <p class="prod-brand"><%= earphone.getBrand() %></p>
                <h3 class="prod-title"><%= earphone.getpName() %></h3>
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