<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // 로그인 성공 시 processLogin.jsp가 세션에 저장한 아이디와 이름을 조회
    String sessionUserId = (String) session.getAttribute("userId");
    String sessionUserName = (String) session.getAttribute("userName");

    // 현재 페이지의 category 파라미터로 카테고리 탭 active 여부 판별 (없으면 "전체"로 간주)
    String currentCategory = request.getParameter("category");
    if (currentCategory == null || currentCategory.trim().isEmpty()) {
        currentCategory = "ALL";
    }
%>

    <div class="header">
    
        <a href="main.jsp" class="logo-link">
            <svg class="logo-icon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path d="M3 12c0-5 4-9 9-9s9 4 9 9" />
                <path d="M6 9L2 12l4 3" />
                <rect x="1" y="11" width="3" height="4" rx="1" fill="#1e293b" class="icon-cup" />
                <path d="M18 9l4 3-4 3" />
                <rect x="20" y="11" width="3" height="4" rx="1" fill="#1e293b" class="icon-cup" />
                <path d="M12 9v6M9 11v2M15 11v2" stroke-width="2" />
            </svg>
            <span>Code Sound</span>
        </a>
        
        <form action="searchResult.jsp" method="get" class="search-form">
            <input type="text" name="searchKeyword" placeholder="상품명을 입력하세요..." class="search-input">
            <button type="submit" class="search-btn">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-search" viewBox="0 0 16 16">  
                    <path d="M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001q.044.06.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1 1 0 0 0-.115-.1zM12 6.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0"/>
                </svg>
            </button>
        </form>
        
        <%
            // [A 시나리오] 비로그인 상태: 평소처럼 로그인/회원가입 버튼 출력
            if (sessionUserId == null || sessionUserId.trim().isEmpty()) {
        %>
            <a href="login.jsp" class="nav-user-link" onclick="this.href='login.jsp?prevPage=' + encodeURIComponent(window.location.href);"> 
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-person" viewBox="0 0 16 16">
                  <path d="M8 8a3 3 0 1 0 0-6 3 3 0 0 0 0 6m2-3a2 2 0 1 1-4 0 2 2 0 0 1 4 0m4 8c0 1-1 1-1 1H3s-1 0-1-1 1-4 6-4 6 3 6 4m-1-.004c-.001-.246-.154-.986-.832-1.664C11.516 10.68 10.289 10 8 10s-3.516.68-4.168 1.332c-.678.678-.83 1.418-.832 1.664z"/>
                </svg>
                <span>로그인 / 회원가입</span>
            </a>
        <%
            } else { 
                // [B 시나리오] 로그인 완료 상태
                String displayName = sessionUserId.trim().equals("admin") ? "관리자" : sessionUserName;
        %>
            <div class="user-status-wrapper" style="display: flex; align-items: center; gap: 12px;">
			    <span class="user-welcome-info" style="font-size: 13px; color: #475569;">
			        <strong class="user-name-text" style="font-weight: 800; color: #0f172a;"><%= util.HtmlUtil.escape(displayName) %>님</strong> 환영합니다
			    </span>
			    
			    <% if (sessionUserId.trim().equals("admin")) { %>
				    <a href="adminMain.jsp" class="logout-action-btn" style="color: #ffffff !important; border-color: #ef4444 !important; background-color: #ef4444 !important; font-weight: bold;">
				        👑 관리자 모드
				    </a>
			    <% } %>
			    
			    <a href="myPage.jsp" class="logout-action-btn" style="color: #475569 !important; border-color: #e2e8f0 !important; background-color: #f8fafc;">
			        마이페이지
			    </a>
			    
			    <span style="color: #e2e8f0;">|</span>
			    
			    <a href="logout.jsp" class="logout-action-btn" onclick="this.href='logout.jsp?prevPage=' + encodeURIComponent(window.location.href);">로그아웃</a>
			</div>
        <%
            }
        %>
        
        <a href="cart.jsp"> 
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-cart4" viewBox="0 0 16 16">
              <path d="M0 2.5A.5.5 0 0 1 .5 2H2a.5.5 0 0 1 .485.379L2.89 4H14.5a.5.5 0 0 1 .485.621l-1.5 6A.5.5 0 0 1 13 11H4a.5.5 0 0 1-.485-.379L1.61 3H.5a.5.5 0 0 1-.5-.5M3.14 5l.5 2H5V5zM6 5v2h2V5zm3 0v2h2V5zm3 0v2h1.36l.5-2zm1.11 3H12v2h.61zM11 8H9v2h2zM8 8H6v2h2zM5 8H3.89l.5 2H5zm0 5a1 1 0 1 0 0 2 1 1 0 0 0 0-2m-2 1a2 2 0 1 1 4 0 2 2 0 0 1-4 0m9-1a1 1 0 1 0 0 2 1 1 0 0 0 0-2m-2 1a2 2 0 1 1 4 0 2 2 0 0 1-4 0"/>
            </svg>
            <span>장바구니</span>
        </a>

        <button type="button" id="themeToggleBtn" class="theme-toggle-btn" onclick="toggleTheme()" aria-label="다크모드 전환">🌙</button>
    </div>

    <nav class="category-nav">
        <a href="products.jsp" class="category-nav-item <%= currentCategory.equalsIgnoreCase("ALL") ? "active" : "" %>">전체</a>
        <a href="products.jsp?category=WIRED" class="category-nav-item <%= currentCategory.equalsIgnoreCase("WIRED") ? "active" : "" %>">유선</a>
        <a href="products.jsp?category=WIRELESS" class="category-nav-item <%= currentCategory.equalsIgnoreCase("WIRELESS") ? "active" : "" %>">무선</a>
        <a href="products.jsp?category=ANC" class="category-nav-item <%= currentCategory.equalsIgnoreCase("ANC") ? "active" : "" %>">노이즈캔슬링</a>
    </nav>