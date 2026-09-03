<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="dao.EarPhoneRepository"%>
<%@ page import="dao.ReviewRepository"%>
<%@ page import="dto.EarPhone"%>
<%@ page import="java.text.DecimalFormat"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.util.Collections"%>
<%@ page import="java.util.Comparator"%>
<%@ page import="java.util.Map"%>
<%
    DecimalFormat df = new DecimalFormat("#,###");

    // 신상품 4개 (최신 등록순 = productId 역순), DB 조회 실패 시 빈 리스트로 graceful하게 처리
    ArrayList<EarPhone> newArrivals = new ArrayList<EarPhone>();
    try {
        ArrayList<EarPhone> all = EarPhoneRepository.getInstance().getAllEarPhones();
        Collections.sort(all, new Comparator<EarPhone>() {
            @Override
            public int compare(EarPhone e1, EarPhone e2) {
                return Long.compare(e2.getProductId(), e1.getProductId());
            }
        });
        newArrivals = new ArrayList<EarPhone>(all.subList(0, Math.min(4, all.size())));
    } catch (Exception e) {
        e.printStackTrace();
    }

    // 리뷰 많은 상품 4개, DB 조회 실패 시 빈 리스트로 graceful하게 처리
    ArrayList<EarPhone> popularProducts = new ArrayList<EarPhone>();
    try {
        ArrayList<EarPhone> all = EarPhoneRepository.getInstance().getAllEarPhones();
        final Map<Long, Integer> reviewCountMap = ReviewRepository.getInstance().getReviewCountMap();
        for (EarPhone e : all) {
            Integer count = reviewCountMap.get(e.getProductId());
            e.setReviewCount(count != null ? count : 0);
        }
        Collections.sort(all, new Comparator<EarPhone>() {
            @Override
            public int compare(EarPhone e1, EarPhone e2) {
                return Integer.compare(e2.getReviewCount(), e1.getReviewCount());
            }
        });
        popularProducts = new ArrayList<EarPhone>(all.subList(0, Math.min(4, all.size())));
    } catch (Exception e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>코드 사운드</title>
<link href="resource/style.css" rel="stylesheet" type="text/css">
</head>
<body>

	<jsp:include page="include/menu.jsp" />

	<div class="main-hero-banner">
		<h1>프리미엄 사운드를 경험하세요</h1>
		<p>Code Sound의 엄선된 이어폰 컬렉션</p>
		<a href="products.jsp" class="main-hero-btn">전체 상품 보기</a>
	</div>

	<div class="main-section">
		<h2 class="main-section-title">신상품</h2>
		<div class="products-container main-product-grid">
			<% for (EarPhone earphone : newArrivals) {
				String formattedPrice = df.format(earphone.getPrice());
			%>
				<a href="detail.jsp?productId=<%= earphone.getProductId() %>" class="shop-product-card" style="text-decoration: none; color: inherit; display: inline-block;">
					<div class="shop-img-box">
						<img src="resource/main/<%= util.HtmlUtil.escape(earphone.getpImage()) %>" alt="<%= util.HtmlUtil.escape(earphone.getpName()) %>">
					</div>
					<p class="prod-brand"><%= util.HtmlUtil.escape(earphone.getBrand()) %></p>
					<h3 class="prod-title"><%= util.HtmlUtil.escape(earphone.getpName()) %></h3>
					<p class="prod-price"><%= formattedPrice %>원</p>
				</a>
			<% } %>
			<% if (newArrivals.isEmpty()) { %>
				<p class="main-section-empty">등록된 상품이 없습니다.</p>
			<% } %>
		</div>
	</div>

	<div class="main-section">
		<h2 class="main-section-title">리뷰 많은 상품</h2>
		<div class="products-container main-product-grid">
			<% for (EarPhone earphone : popularProducts) {
				String formattedPrice = df.format(earphone.getPrice());
			%>
				<a href="detail.jsp?productId=<%= earphone.getProductId() %>" class="shop-product-card" style="text-decoration: none; color: inherit; display: inline-block;">
					<div class="shop-img-box">
						<img src="resource/main/<%= util.HtmlUtil.escape(earphone.getpImage()) %>" alt="<%= util.HtmlUtil.escape(earphone.getpName()) %>">
					</div>
					<p class="prod-brand"><%= util.HtmlUtil.escape(earphone.getBrand()) %></p>
					<h3 class="prod-title"><%= util.HtmlUtil.escape(earphone.getpName()) %></h3>
					<p class="prod-price"><%= formattedPrice %>원</p>
				</a>
			<% } %>
			<% if (popularProducts.isEmpty()) { %>
				<p class="main-section-empty">등록된 상품이 없습니다.</p>
			<% } %>
		</div>
	</div>

	<jsp:include page="include/footer.jsp" />

</body>
</html>
