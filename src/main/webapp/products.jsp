<%@ page import="dao.EarPhoneRepository"%>
<%@ page import="dto.EarPhone"%>
<%@ page import="java.util.ArrayList, java.util.Collections, java.util.Comparator" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.text.DecimalFormat" %>
    
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>코드 사운드 - 상품 목록</title>
<link href="resource/style.css" rel="stylesheet" type="text/css">
</head>
<body>

	<jsp:include page="include/menu.jsp" />
	
	<%
	    // 1. 카테고리와 정렬 파라미터 수신
	    String category = request.getParameter("category");
	    String sort = request.getParameter("sort");
	
	    // 카테고리 기본값 세팅
	    if (category == null || category.trim().isEmpty()) {
	        category = "ALL";
	    }
	    
	    // sort 파라미터가 없으면 '최신등록순(latest)'을 기본값으로 지정
	    if (sort == null || sort.trim().isEmpty()) {
	        sort = "latest";
	    }
	    
	    // 2. Repository를 통해 상품 목록 조회
	    ArrayList<EarPhone> list = EarPhoneRepository.getInstance().getProductsByCategory(category);
	    
	    // DB에서 가져온 목록을 사용자가 선택한 기준에 맞게 정렬
	    if (list != null && !list.isEmpty()) {
	        if (sort.equals("price_low")) {
	            // 낮은 가격순 정렬 (오름차순)
	            Collections.sort(list, new Comparator<EarPhone>() {
	                @Override
	                public int compare(EarPhone e1, EarPhone e2) {
	                    return Integer.compare(e1.getPrice(), e2.getPrice());
	                }
	            });
	        } else if (sort.equals("price_high")) {
	            // 높은 가격순 정렬 (내림차순)
	            Collections.sort(list, new Comparator<EarPhone>() {
	                @Override
	                public int compare(EarPhone e1, EarPhone e2) {
	                    return Integer.compare(e2.getPrice(), e1.getPrice());
	                }
	            });
	        } else if (sort.equals("review")) {
	            // 리뷰 많은순 정렬 (내림차순)
	            // TODO: DTO에 getReviewCount()가 추가되면 해당 메서드로 교체
	            // 현재는 상품 ID 역순으로 임시 대체
	            Collections.sort(list, new Comparator<EarPhone>() {
	                @Override
	                public int compare(EarPhone e1, EarPhone e2) {
	                    // DTO에 리뷰 개수 컬럼이 추가되면 e2.getReviewCount() - e1.getReviewCount()로 교체
	                    return Long.compare(e2.getProductId(), e1.getProductId()); 
	                }
	            });
	        } else {
	            // 기본값: 최신등록순 (상품 ID 역순 정렬)
	            Collections.sort(list, new Comparator<EarPhone>() {
	                @Override
	                public int compare(EarPhone e1, EarPhone e2) {
	                    return Long.compare(e2.getProductId(), e1.getProductId());
	                }
	            });
	        }
	    }
	    
	    // 3. 타이틀 분기문
	    String pageTitle = "";
	    if (category.equalsIgnoreCase("ALL")) {
	        pageTitle = "전체 상품 목록";
	    } else if (category.equalsIgnoreCase("WIRELESS")) {
	        pageTitle = "무선 이어폰";
	    } else {
	        pageTitle = "유선 이어폰";
	    }
	%>	
	
	<div class="product-list-header">
	    <h2 class="list-title"><%= pageTitle %></h2>
	    
	    <div class="sort-filter-group">
	        <a href="products.jsp?category=<%= category %>&sort=latest" class="sort-item <%= sort.equals("latest") ? "active" : "" %>">최신등록순</a>
	        <span class="sort-divider">|</span>
	        <a href="products.jsp?category=<%= category %>&sort=price_low" class="sort-item <%= sort.equals("price_low") ? "active" : "" %>">낮은가격순</a>
	        <span class="sort-divider">|</span>
	        <a href="products.jsp?category=<%= category %>&sort=price_high" class="sort-item <%= sort.equals("price_high") ? "active" : "" %>">높은가격순</a>
	        <span class="sort-divider">|</span>
	        <a href="products.jsp?category=<%= category %>&sort=review" class="sort-item <%= sort.equals("review") ? "active" : "" %>">리뷰많은순</a>
	    </div>
	</div>
	
	<div class="products-container">

		<%
			DecimalFormat df = new DecimalFormat("#,###");
		
		    if (list != null) {
		        for(EarPhone earphone : list) {
		            String formattedPrice = df.format(earphone.getPrice());
		%>
		
        <a href="detail.jsp?productId=<%=earphone.getProductId() %>" class="shop-product-card" style="text-decoration: none; color: inherit; display: inline-block;"> 
       
	        <div class="shop-img-box">
                <img src="resource/main/<%= earphone.getpImage() %>" alt="<%= earphone.getpName() %>">
            </div>
            
            <p class="prod-brand"><%= earphone.getBrand() %></p>
            
            <h3 class="prod-title"><%= earphone.getpName() %></h3>
            
            <p class="prod-price"><%= formattedPrice %>원</p>
	      
	    </a>
   	
		<%
		        }
		    }
		%>
	
	</div>
	
	<script>
	    window.onscroll = function() {
	        scrollFunction();
	    };
	
	    function scrollFunction() {
	        var topBtn = document.getElementById("scrollTopBtn");
	        
	        if (document.body.scrollTop > 300 || document.documentElement.scrollTop > 300) {
	            topBtn.classList.add("show");
	        } else {
	            topBtn.classList.remove("show");
	        }
	    }
	
	    function scrollToTop() {
	        window.scrollTo({
	            top: 0,
	            behavior: 'smooth'
	        });
	    }
	</script>
	
	<jsp:include page="include/footer.jsp" />
	
</body>
</html>