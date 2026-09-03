<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB" crossorigin="anonymous">
<title>코드 사운드</title>
<link href="resource/style.css" rel="stylesheet" type="text/css">
<script src="resource/js/theme.js"></script>
</head>
<body>

	<jsp:include page="include/menu.jsp" />

	<div class="container">
	
		<svg class="main-hero-icon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M3 12c0-5 4-9 9-9s9 4 9 9" />
            
            <path d="M6 9L2 12l4 3" />
            <rect x="1" y="11" width="3" height="4" rx="1" fill="#0f172a" />
            
            <path d="M18 9l4 3-4 3" />
            <rect x="20" y="11" width="3" height="4" rx="1" fill="#0f172a" />
            
            <path d="M12 9v6M9 11v2M15 11v2" stroke-width="2" />
        </svg>
	
		<h1>Code Sound Shop</h1>
	    <div class="button-group">
		    <a href="products.jsp?category=WIRELESS">무선 이어폰</a>
			<a href="products.jsp?category=WIRED">유선 이어폰</a>
	    </div>
	</div>

	<jsp:include page="include/footer.jsp" />

</body>
</html>