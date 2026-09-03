<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="dto.EarPhone"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.text.DecimalFormat"%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>코드 사운드 - 장바구니</title>
<link href="resource/style.css" rel="stylesheet" type="text/css">
</head>
<body>

	<jsp:include page="include/menu.jsp" />

	<div class="cart-container">
		<div class="cart-header">
			<h2>장바구니 목록</h2>
		</div>

		<%
            // 세션에서 장바구니 리스트 꺼내기
            ArrayList<EarPhone> cartList = (ArrayList<EarPhone>) session.getAttribute("cartList");
            DecimalFormat df = new DecimalFormat("#,###");
            int totalSum = 0;

            if (cartList == null || cartList.isEmpty()) {
        %>
		<div class="detail-section-placeholder">
			<h3>🛒 장바구니가 비어 있습니다.</h3>
			<p>코드 사운드가 엄선한 최고의 이어폰들을 바구니에 담아보세요!</p>
			<div class="cart-empty-btn-zone">
				<a href="products.jsp?category=all" class="btn-continue-shopping">상품
					보러 가기</a>
			</div>
		</div>
		<%
            } else {
            	// 장바구니 상품이 있을 때 렌더링
        %>
		<form id="cartForm" method="post">

			<div class="cart-flex-wrapper">

				<div class="cart-main-content">

					<div class="cart-select-control-bar">
						<label class="check-label"> <input type="checkbox"
							id="selectAllTop" onclick="toggleAllCheckboxes(this)" checked>
							<span>전체선택</span>
						</label>
						<button type="button" class="btn-select-delete"
							onclick="submitCartAction('delete')">선택 삭제</button>
					</div>

					<table class="cart-table">
						<thead>
							<tr>
								<th class="col-check"></th>
								<th class="col-img">상품 이미지</th>
								<th class="col-info">상품 정보</th>
								<th class="col-price">판매 금액</th>
								<th class="col-qty">배송 정보</th>
								<th class="col-subtotal">수량</th>
								<th class="col-action"></th>
							</tr>
						</thead>
						<tbody>
							<%
                                    for (int i = 0; i < cartList.size(); i++) {
                                        EarPhone item = cartList.get(i);
                                        int subTotal = item.getPrice() * item.getStock();
                                        totalSum += subTotal;
                                %>
							<tr>
								<td><input type="checkbox" name="selectedProducts"
									value="<%= item.getProductId() %>" class="cart-item-checkbox"
									data-price="<%= item.getPrice() * item.getStock() %>"
									onchange="updateReceiptAmount()" checked></td>
								<td><a
									href="detail.jsp?productId=<%= item.getProductId() %>"
									class="cart-img-link">
										<div class="cart-img-box">
											<img src="resource/main/<%= util.HtmlUtil.escape(item.getpImage()) %>"
												alt="<%= util.HtmlUtil.escape(item.getpName()) %>">
										</div>
								</a></td>

								<td class="text-left"><span class="cart-item-brand"><%= util.HtmlUtil.escape(item.getBrand()) %></span>

									<a href="detail.jsp?productId=<%= item.getProductId() %>"
									class="cart-item-name-link">
										<h4 class="cart-item-name"><%= util.HtmlUtil.escape(item.getpName()) %></h4>
								</a></td>
								<td><span class="txt-bold"><%= df.format(item.getPrice()) %>원</span></td>
								<td><span class="txt-free">무료배송</span></td>
								<td>
									<div class="cart-qty-control-box">
										<button type="button" class="btn-qty-minus"
											onclick="updateCartQty('<%= item.getProductId() %>', <%= item.getStock() - 1 %>)">-</button>
										<input type="number" class="input-cart-qty"
											value="<%= item.getStock() %>" min="1"
											onchange="updateCartQty('<%= item.getProductId() %>', this.value)">
										<button type="button" class="btn-qty-plus"
											onclick="updateCartQty('<%= item.getProductId() %>', <%= item.getStock() + 1 %>)">+</button>
									</div>
								</td>
								<td><a href="process/deleteCart.jsp?pId=<%= item.getProductId() %>"
									class="btn-delete-item"
									onclick="return confirm('이 상품을 장바구니에서 삭제하시겠습니까?');"
									style="text-decoration: none; color: #94a3b8; font-weight: bold;">&times;</a>
								</td>
							</tr>
							<%
                                    }
                                %>
						</tbody>
					</table>
				</div>

				<div class="cart-summary-box">
					<div class="summary-row">
						<span>총 상품 금액</span> <span id="receiptProductSum"><%= df.format(totalSum) %>원</span>
					</div>
					<div class="summary-row">
						<span>배송비</span> <span class="txt-free">무료 배송</span>
					</div>
					<hr class="summary-divider">
					<div class="summary-row total-row">
						<span>최종 결제 예상 금액</span> <span class="txt-total-sum"
							id="receiptTotalSum"><%= df.format(totalSum) %>원</span>
					</div>

					<div class="cart-action-group">
						<button type="button" class="btn-order-selected"
							onclick="submitCartAction('orderSelect')">선택 상품 주문</button>
						<button type="button" class="btn-order-all"
							onclick="submitCartAction('orderAll')">전체 상품 주문</button>
					</div>
				</div>

			</div>
		</form>
		<%
            }
        %>
	</div>

	<script>
        // 페이지 로드 시 이전 스크롤 위치 복원
        window.addEventListener('DOMContentLoaded', () => {
            const savedScrollTop = sessionStorage.getItem('cartScrollPos');
            if (savedScrollTop) {
                window.scrollTo(0, parseInt(savedScrollTop, 10));
                sessionStorage.removeItem('cartScrollPos');
            }
            updateReceiptAmount();
        });

        // 수량 변경 처리
        function updateCartQty(productId, newQty) {
            if (newQty < 1) { 
                alert("최소 주문 수량은 1개입니다."); 
                return; 
            }
            sessionStorage.setItem('cartScrollPos', window.scrollY);
            location.href = "process/updateCart.jsp?productId=" + productId + "&quantity=" + newQty;
        }

        // 전체선택 체크박스 제어
        function toggleAllCheckboxes(master) {
        	const checkboxes = document.querySelectorAll('.cart-item-checkbox');
            checkboxes.forEach(cb => {
                cb.checked = master.checked;
            });
            updateReceiptAmount();
        }

     	// 버튼 액션 타입에 따라 form action 분기
        function submitCartAction(actionType) {
		    const checkboxes = document.querySelectorAll('.cart-item-checkbox');
		    
		    // 1. 선택 상품 주문 분기
		    if (actionType === 'orderSelect') {
		        let checkedCount = 0;
		        checkboxes.forEach(cb => {
		            if (cb.checked) checkedCount++;
		        });
		        
		        if (checkedCount === 0) {
			        alert("주문할 상품을 최소 한 개 이상 선택해 주세요.");
			        return; 
		        }
		    }
		    
		    // 2. 전체 상품 주문 분기: 모든 체크박스를 활성화
		    if (actionType === 'orderAll') {
		        checkboxes.forEach(cb => {
		            cb.checked = true;
		        });
		    }
		    
		    // 3. 선택 삭제 분기 처리
		    if (actionType === 'delete') {
		        const form = document.getElementById('cartForm');
		        if(form) {
		            form.action = "process/deleteSelectedCart.jsp";
		            form.submit();
		            return;
		        }
		    }
		
		    // 4. 주문 처리 (id로 cartForm을 찾아 제출)
		    const form = document.getElementById('cartForm'); 
		    if (form) {
		        form.action = "order.jsp";
		        form.method = "post"; 
		        form.submit(); 
		    }
		}
        
        // 스크롤 위치에 따라 맨 위로 버튼 표시 여부 제어
        window.addEventListener('scroll', () => {
            const topBtn = document.getElementById('scrollTopBtn');
            if (topBtn) {
                if (window.scrollY > 200) {
                    topBtn.classList.add('show');
                } else {
                    topBtn.classList.remove('show');
                }
            }
        });

        // 맨 위로 스크롤 이동
        function scrollToTop() {
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        }
        
        // 선택된 상품의 금액 합산
        function updateReceiptAmount() {
            const checkboxes = document.querySelectorAll('.cart-item-checkbox');
            let dynamicTotal = 0;
            
            checkboxes.forEach(function(cb) {
                if (cb.checked) {
                    dynamicTotal += parseInt(cb.getAttribute('data-price'), 10);
                }
            });
            
            const productSumField = document.getElementById('receiptProductSum');
            if (productSumField) {
                productSumField.innerText = dynamicTotal.toLocaleString() + "원";
            }
            
            const receiptField = document.getElementById('receiptTotalSum');
            if (receiptField) {
                receiptField.innerText = dynamicTotal.toLocaleString() + "원";
            }
        }
    </script>

</body>
</html>