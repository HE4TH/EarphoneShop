<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.EarPhoneRepository"%>
<%@ page import="dto.EarPhone"%>
<%@ page import="java.text.DecimalFormat"%>
<%@ page import="java.util.ArrayList"%>

<% 
	// 🎯 1. 중복 분산되어 있던 DB 조회를 페이지 최상단 한 곳으로 집약 및 단일화!
	long pId = Long.parseLong(request.getParameter("productId"));
	EarPhoneRepository dao = EarPhoneRepository.getInstance();
	EarPhone earphone = dao.getEarPhoneById(pId);
	
	// 3자리마다 콤마를 찍어주는 가격 포맷터 생성
	DecimalFormat df = new DecimalFormat("#,###");
	String formattedPrice = df.format(earphone.getPrice());
	
	String chatUserName = (String) session.getAttribute("userName");
    if (chatUserName == null || chatUserName.trim().isEmpty()) {
        chatUserName = "고객";
    }
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title><%= earphone.getpName() %></title>
<link href="resource/style.css" rel="stylesheet" type="text/css">
</head>
<body>

	<jsp:include page="include/menu.jsp" />

	<div class="detail-main-info">

		<div class="detail-main-img-box">
			<img src="resource/main/<%= earphone.getpImage() %>" alt="<%= earphone.getpName() %>">
			<span class="img-source-text">출처 : <%= earphone.getBrand() %></span>
		</div>

		<div class="detail-main-order-box">
			<span class="detail-brand"><%= earphone.getBrand() %></span>
			<h1 class="detail-name"><%= earphone.getpName() %></h1>

			<div class="detail-price-zone">
				<span class="detail-price"><%= formattedPrice %></span><span class="detail-won">원</span>
			</div>

			<div class="detail-delivery-info">
				<p><strong>배송 :</strong> 무료배송 (도서산간 제외)</p>
				<p><strong>재고 :</strong> <%= earphone.getStock() %>개 남음</p>
			</div>

			<div class="detail-quantity-zone">
				<div class="quantity-picker">
					<button type="button" class="btn-minus" onclick="decreaseQuantity()">
						<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-dash" viewBox="0 0 16 16">
				            <path d="M4 8a.5.5 0 0 1 .5-.5h7a.5.5 0 0 1 0 1h-7A.5.5 0 0 1 4 8" />
				        </svg>
					</button>

					<input type="text" id="p_quantity" name="quantity" value="1" oninput="validateQuantity(this)" onblur="checkEmptyQuantity(this)">

					<button type="button" class="btn-plus" onclick="increaseQuantity()">
						<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-plus" viewBox="0 0 16 16">
				            <path d="M8 4a.5.5 0 0 1 .5.5v3h3a.5.5 0 0 1 0 1h-3v3a.5.5 0 0 1-1 0v-3h-3a.5.5 0 0 1 0-1h3v-3A.5.5 0 0 1 8 4" />
				        </svg>
					</button>
				</div>
			</div>

			<div class="detail-total-price-zone" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; padding: 10px 0;">
				<span style="font-size: 16px; font-weight: bold; color: #475569;">총 상품금액</span>
				<div>
					<span id="total_price" style="font-size: 28px; font-weight: 800; color: #b92c2c;"><%= formattedPrice %></span>
					<span style="font-size: 18px; font-weight: 700; color: #b92c2c; margin-left: 2px;">원</span>
				</div>
			</div>

			<div class="detail-btn-group">
				<a href="order.jsp?productId=<%= earphone.getProductId() %>" class="btn-buy">구매하기</a> 
				<a href="addCart.jsp?productId=<%= earphone.getProductId() %>" class="btn-cart"> 
					<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" fill="currentColor" class="bi bi-cart3" viewBox="0 0 16 16">
	                    <path d="M0 1.5A.5.5 0 0 1 .5 1H2a.5.5 0 0 1 .485.379L2.89 3H14.5a.5.5 0 0 1 .49.598l-1 5a.5.5 0 0 1-.465.401l-9.397.472L4.415 11H13a.5.5 0 0 1 0 1H4a.5.5 0 0 1-.491-.408L2.01 3.607 1.61 2H.5a.5.5 0 0 1-.5-.5M3.102 4l.84 4.479 9.144-.459L13.89 4zM5 12a2 2 0 1 0 0 4 2 2 0 0 0 0-4zm7 0a2 2 0 1 0 0 4 2 2 0 0 0 0-4zm-7 1a1 1 0 1 1 0 2 1 1 0 0 1 0-2zm7 0a1 1 0 1 1 0 2 1 1 0 0 1 0-2" />
	                </svg> 장바구니 담기
				</a>
			</div>

		</div>

	</div>

	<div class="detail-tabs">
		<button type="button" class="tab-item active" onclick="moveToTab('#product-desc')">상품상세</button>
		<button type="button" class="tab-item" onclick="moveToTab('#product-review')">구매후기 (0)</button>
		<button type="button" class="tab-item" onclick="moveToTab('#product-qna')">Q&A (0)</button>
	</div>

	<div id="product-desc" class="detail-image-box">
		<img src="resource/description/<%= earphone.getpDescriptionImage1() %>" alt="<%=earphone.getpName()%>">
		<% if(earphone.getpDescriptionImage2() != null) { %>
		<img src="resource/description/<%= earphone.getpDescriptionImage2() %>" alt="상세설명2">
		<% } %>
	</div>

	<div id="product-review" class="detail-section-placeholder">
		<h3>구매후기</h3>
		<p>아직 작성된 구매후기가 없습니다. 이 제품을 먼저 구매하고 첫 후기를 남겨보세요!</p>
	</div>

	<div id="product-qna" class="detail-section-placeholder">
		<h3>상품문의 (Q&A)</h3>
		<p>상품에 대해 궁금한 점이 있으신가요? 문의글을 남겨주시면 판매자가 정성껏 답변해 드립니다.</p>
	</div>

	<button type="button" id="scrollTopBtn" onclick="scrollToTop()">
		<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" class="bi bi-arrow-up" viewBox="0 0 16 16">
	        <path fill-rule="evenodd" d="M8 15a.5.5 0 0 0 .5-.5V2.707l3.146 3.147a.5.5 0 0 0 .708-.708l-4-4a.5.5 0 0 0-.708 0l-4 4a.5.5 0 1 0 .708.708L7.5 2.707V14.5a.5.5 0 0 0 .5.5" />
	    </svg>
	</button>

	<button type="button" id="aiChatTriggerBtn" onclick="toggleAiChatBot()">
	    <span>🤖</span>
	</button>
	
	<div id="aiChatWindow">
	    <div class="chat-header-bar">
	        <div class="chat-header-title-zone">
	            <span>🤖</span>
	            <div>
	                <strong>코드 사운드 AI 어시스턴트</strong>
	                <span>실시간 이어폰 성향 분석 중</span>
	            </div>
	        </div>
	        <button type="button" class="chat-close-btn" onclick="toggleAiChatBot()">&times;</button>
	    </div>
	
	    <div id="chatMessageArea">
	        <div class="msg-bubble-ai">
				안녕하세요, <%= chatUserName %>님! 🎧 코드 사운드 AI 쇼핑 매니저입니다. 현재 보고 계신 제품에 대해 음향 성향이나 매칭기기 등 궁금한 점이 있으시면 편하게 물어보세요!
	        </div>
	    </div>
	
	    <div class="chat-input-zone">
	        <input type="text" id="chatUserInput" onkeydown="handleChatKeyPress(event)" placeholder="AI에게 물어볼 내용을 입력하세요...">
	        <button type="button" class="chat-send-btn" onclick="sendChatMessage()">전송</button>
	    </div>
	</div>

	<script>
	    var productPrice = <%= earphone.getPrice() %>;
	
	    function increaseQuantity() {
	        var qtyInput = document.getElementById("p_quantity");
	        var currentQty = parseInt(qtyInput.value) || 1;
	        qtyInput.value = currentQty + 1;
	        updateAllData(qtyInput.value);
	    }
	
	    function decreaseQuantity() {
	        var qtyInput = document.getElementById("p_quantity");
	        var currentQty = parseInt(qtyInput.value) || 1;
	        if (currentQty > 1) {
	            qtyInput.value = currentQty - 1;
	            updateAllData(qtyInput.value);
	        }
	    }
	    
	    function validateQuantity(input) {
	        input.value = input.value.replace(/[^0-9]/g, '');
	        if (input.value.startsWith('0')) {
	            input.value = parseInt(input.value) || '';
	        }
	        if (input.value !== '') {
	            updateAllData(input.value);
	        }
	    }
	
	    function checkEmptyQuantity(input) {
	        if (input.value === '' || parseInt(input.value) < 1) {
	            input.value = '1';
	            updateAllData(1);
	        }
	    }
	    
	    function updateAllData(qty) {
	        var quantity = parseInt(qty) || 1;
	        var productId = "<%= earphone.getProductId() %>";
	        
	        var buyBtn = document.querySelector(".btn-buy");
	        var cartBtn = document.querySelector(".btn-cart");
	        if(buyBtn) buyBtn.href = "order.jsp?productId=" + productId + "&quantity=" + quantity;
	        if(cartBtn) cartBtn.href = "process/addCart.jsp?productId=" + productId + "&quantity=" + quantity;
	        
	        var total = productPrice * quantity;
	        document.getElementById("total_price").innerText = formatNumberWithCommas(total);
	    }
	    
	    function formatNumberWithCommas(number) {
	        return number.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
	    }
	    
	    window.onload = function() {
	        updateAllData(1);
	    }
	
	    // 탭 이동 제어
	    function moveToTab(targetId) {
	        var targetElement = document.querySelector(targetId);
	        if (targetElement) {
	            var headerOffset = 80;
	            var elementPosition = targetElement.getBoundingClientRect().top;
	            var offsetPosition = elementPosition + window.pageYOffset - headerOffset;
	            
	            window.scrollTo({
	                top: offsetPosition,
	                behavior: 'smooth'
	            });
	        }
	        
	        var tabs = document.querySelectorAll('.tab-item');
	        tabs.forEach(function(tab) {
	            tab.classList.remove('active');
	        });
	        event.currentTarget.classList.add('active');
	    }

	    // 스크롤 탑 기능 제어
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

	    /* 💬 비동기 챗봇 통신 스크립트 파트 */
	    function toggleAiChatBot() {
	        const chatWin = document.getElementById("aiChatWindow");
	        if (chatWin.style.display === "none" || chatWin.style.display === "") {
	            chatWin.style.display = "flex";
	            const msgArea = document.getElementById("chatMessageArea");
	            msgArea.scrollTop = msgArea.scrollHeight;
	        } else {
	            chatWin.style.display = "none";
	        }
	    }
	
	    function handleChatKeyPress(event) {
	        if (event.key === 'Enter' || event.keyCode === 13) {
	            event.preventDefault();
	            sendChatMessage();
	        }
	    }
	
	    function sendChatMessage() {
	        const inputField = document.getElementById("chatUserInput");
	        const userText = inputField.value.trim();
	        
	        if(!userText || userText === "") return;

	        const msgArea = document.getElementById("chatMessageArea");
	        const urlParams = new URLSearchParams(window.location.search);
	        let currentProductId = urlParams.get('productId');
	        if(!currentProductId) currentProductId = "0";

	        const userMsgHtml = `<div class="msg-bubble-user" style="color: #ffffff !important; background-color: #1e293b !important;">\${userText}</div>`;
	        msgArea.insertAdjacentHTML('beforeend', userMsgHtml);
	        
	        inputField.value = ""; 
	        msgArea.scrollTop = msgArea.scrollHeight;

	        const loadingId = "ai-loading-" + Date.now();
	        const loadingMsgHtml = `<div id="\${loadingId}" class="msg-bubble-ai"><span class="ai-typing-text">🤖 입력 중...</span></div>`;
	        msgArea.insertAdjacentHTML('beforeend', loadingMsgHtml);
	        msgArea.scrollTop = msgArea.scrollHeight;

	        const formData = new URLSearchParams();
	        formData.append("productId", currentProductId);
	        formData.append("message", userText);

	        fetch("process/aiChatBotApi.jsp", {
	            method: "POST",
	            headers: {
	                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
	            },
	            body: formData.toString()
	        })
	        .then(response => {
	            if (!response.ok) throw new Error("통신 실패");
	            return response.text();
	        })
	        .then(aiReplyText => {
	            const loadingElement = document.getElementById(loadingId);
	            if(loadingElement) loadingElement.remove();
	            
	            const aiMsgHtml = `<div class="msg-bubble-ai">\${aiReplyText.trim()}</div>`;
	            msgArea.insertAdjacentHTML('beforeend', aiMsgHtml);
	            msgArea.scrollTop = msgArea.scrollHeight;
	        })
	        .catch(err => {
	            console.error("챗봇 통신 에러:", err);
	            const loadingElement = document.getElementById(loadingId);
	            if(loadingElement) {
	                loadingElement.innerHTML = "<span style='color:#ef4444;'>❌ 응답 실패 (API 키 또는 네트워크 확인)</span>";
	            }
	        });
	    }
	</script>

	<jsp:include page="include/footer.jsp" />

</body>
</html>