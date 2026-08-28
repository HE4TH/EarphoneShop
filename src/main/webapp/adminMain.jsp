<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.EarPhoneRepository" %>
<%@ page import="dto.EarPhone" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    // 🔒 관리자 세션 보안 검증
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

    EarPhoneRepository repo = EarPhoneRepository.getInstance();
    ArrayList<EarPhone> productList = repo.getAllEarPhones();
    DecimalFormat df = new DecimalFormat("#,###");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>코드 사운드 | 관리자 모드</title>
    <link rel="stylesheet" href="resource/style.css">
    
    <style>
        body { background-color: #f8fafc; margin: 0; padding: 0; font-family: 'Pretendard', sans-serif; box-sizing: border-box; }
        .admin-container { width: 90%; max-width: 1200px; margin: 40px auto; padding-bottom: 60px; box-sizing: border-box; }
        .admin-card { background: #ffffff; padding: 35px; border-radius: 14px; box-shadow: 0 4px 20px rgba(15, 23, 42, 0.05); margin-bottom: 35px; border: 1px solid #e2e8f0; box-sizing: border-box; }
        .admin-card h3 { margin-top: 0; margin-bottom: 25px; color: #0f172a; font-size: 20px; font-weight: 700; border-left: 4px solid #007bff; padding-left: 10px; }
        
        .flex-row { display: flex; gap: 24px; margin-bottom: 18px; width: 100%; box-sizing: border-box; }
        .flex-child { flex: 1; display: flex; flex-direction: column; box-sizing: border-box; }
        
        .form-group label { display: block; margin-bottom: 8px; font-weight: 600; color: #334155; font-size: 14px; }
        .form-group input, .form-group select, .form-group textarea { 
            width: 100%; padding: 12px; border: 1px solid #cbd5e1; border-radius: 8px; 
            box-sizing: border-box; font-size: 14px; background-color: #fff; transition: border 0.2s;
        }
        .form-group input:focus, .form-group select:focus { border-color: #007bff; outline: none; }
        
        .drop-zone {
            width: 100%; height: 180px; border: 2px dashed #cbd5e1; border-radius: 10px;
            display: flex; flex-direction: column; align-items: center; justify-content: center;
            background-color: #f8fafc; cursor: pointer; transition: all 0.25s ease; box-sizing: border-box;
        }
        .drop-zone:hover { background-color: #f1f5f9; border-color: #94a3b8; }
        .drop-zone.drag-over { border-color: #007bff; background-color: #eff6ff; }
        .drop-zone-text { color: #64748b; font-size: 13px; margin-top: 8px; text-align: center; margin-bottom: 0; }
        .preview-img { max-height: 140px; max-width: 90%; border-radius: 6px; display: none; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
        
        .btn-admin { background: #007bff; color: white; padding: 14px; border: none; border-radius: 8px; cursor: pointer; font-weight: 700; font-size: 15px; transition: background 0.2s; width: 100%; box-sizing: border-box; }
        .btn-admin:hover { background: #0056b3; }
        
        .admin-table { width: 100%; border-collapse: collapse; margin-top: 15px; box-sizing: border-box; }
        .admin-table th, .admin-table td { padding: 14px; border-bottom: 1px solid #e2e8f0; text-align: left; font-size: 14px; }
        .admin-table th { background-color: #f1f5f9; color: #475569; font-weight: 600; }
        .btn-delete { background: #ef4444; color: white; padding: 6px 14px; border: none; border-radius: 6px; cursor: pointer; text-decoration: none; font-size: 13px; font-weight: 600; transition: background 0.2s; display: inline-block; }
        .btn-delete:hover { background: #dc2626; }
    </style>
</head>
<body>

    <jsp:include page="include/menu.jsp" />

    <div class="admin-container">
        <h2 style="color: #0f172a; font-size: 26px; margin-bottom: 5px; font-weight: 800;">🛠️ 코드 사운드 마스터 관리자 페이지</h2>
        <p style="color: #64748b; font-size: 14px; margin-top: 0; margin-bottom: 35px;">
            현재 계정: <span style="color: #0f172a; font-weight: 600;"><%= sessionUserId %></span> |
            <a href="logout.jsp" style="color: #ef4444; text-decoration: none; font-weight: 600;">마스터 로그아웃</a>
        </p>

        <div class="admin-card">
            <h3>📦이어폰 신규 상품 출시</h3>
            <form action="process/processAddProduct.jsp" method="post" enctype="multipart/form-data">
                
                <div class="flex-row">
                    <div class="form-group flex-child">
                        <label>상품 카테고리</label>
                        <select name="category" required>
                            <option value="WIRELESS">WIRELESS (무선)</option>
                            <option value="WIRED">WIRED (유선)</option>
                        </select>
                    </div>
                    <div class="form-group flex-child">
                        <label>브랜드명</label>
                        <input type="text" name="brand" placeholder="예: Sony, Apple" required>
                    </div>
                </div>

                <div class="flex-row">
                    <div class="form-group flex-child">
                        <label>상품 영문 이름</label>
                        <input type="text" name="pName" placeholder="예: WF-1000XM5" required>
                    </div>
                    <div class="form-group flex-child">
                        <label>상품 한국어 이름</label>
                        <input type="text" name="pNameKn" placeholder="예: 소니 무선 이어폰 5세대" required>
                    </div>
                </div>

                <div class="flex-row">
                    <div class="form-group flex-child">
                        <label>판매 가격</label>
                        <input type="number" name="price" placeholder="숫자만 입력" required>
                    </div>
                    <div class="form-group flex-child">
                        <label>초기 입고 수량</label>
                        <input type="number" name="stock" value="50" required>
                    </div>
                </div>
                
                <div class="flex-row" style="margin-bottom: 25px;">
                    <div class="form-group flex-child">
                        <label>📸 대표 상품 이미지 (목록 출력용)</label>
                        <div id="drop-zone-main" class="drop-zone" onclick="document.getElementById('file-main').click()">
                            <div id="prompt-main" style="text-align: center;">
                                <span style="font-size: 28px;">🖼️</span>
                                <p class="drop-zone-text">대표 사진을 드래그하거나 영역을 클릭하세요.</p>
                            </div>
                            <img id="preview-main" class="preview-img" alt="대표 이미지 미리보기">
                        </div>
                        <input type="file" id="file-main" name="pImageFile" accept="image/*" style="display: none;" required>
                    </div>

                    <div class="form-group flex-child">
                        <label>📝 상세 설명 이미지 (본문 삽입용)</label>
                        <div id="drop-zone-detail" class="drop-zone" onclick="document.getElementById('file-detail').click()">
                            <div id="prompt-detail" style="text-align: center;">
                                <span style="font-size: 28px;">📄</span>
                                <p class="drop-zone-text">상세 정보 이미지를 드래그하거나 영역을 클릭하세요.</p>
                            </div>
                            <img id="preview-detail" class="preview-img" alt="상세 이미지 미리보기">
                        </div>
                        <input type="file" id="file-detail" name="pDescriptionImage1File" accept="image/*" style="display: none;" required>
                    </div>
                </div>

                <button type="submit" class="btn-admin">🚀 신규 상품 추가</button>
            </form>
        </div>

        <div class="admin-card">
            <h3>📊 매장 등록 상품 실시간 제어 목록</h3>
            <table class="admin-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>카테고리</th>
                        <th>브랜드</th>
                        <th>모델명(영문)</th>
                        <th>가격</th>
                        <th>재고</th>
                        <th>제어</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    for(EarPhone p : productList) {
                %>
                    <tr>
                        <td><%= p.getProductId() %></td>
                        <td style="color: #64748b; font-size: 13px;"><%= p.getCategory() %></td>
                        <td><%= p.getBrand() %></td>
                        <td><strong><%= p.getpName() %></strong></td>
                        <td style="color: #007bff; font-weight: 600;"><%= df.format(p.getPrice()) %>원</td>
                        <td><%= p.getStock() %>개</td>
                        <td>
                            <a href="process/processDeleteProduct.jsp?productId=<%= p.getProductId() %>" 
                               class="btn-delete" 
                               onclick="return confirm('이 상품을 제거하시겠습니까?');">
                               제거
                            </a>
                        </td>
                    </tr>
                <%
                    }
                %>
                </tbody>
            </table>
        </div>
    </div>
    
    <jsp:include page="include/footer.jsp" />

    <script>
        function setupDropZone(zoneId, inputId, previewId, promptId) {
            const zone = document.getElementById(zoneId);
            const input = document.getElementById(inputId);
            const preview = document.getElementById(previewId);
            const prompt = document.getElementById(promptId);

            zone.addEventListener('dragover', (e) => { e.preventDefault(); zone.classList.add('drag-over'); });
            zone.addEventListener('dragleave', () => { zone.classList.remove('drag-over'); });
            zone.addEventListener('drop', (e) => {
                e.preventDefault();
                zone.classList.remove('drag-over');
                const files = e.dataTransfer.files;
                if(files.length > 0 && files[0].type.startsWith('image/')) {
                    input.files = files;
                    renderPreview(files[0], preview, prompt);
                }
            });
            input.addEventListener('change', (e) => {
                if(e.target.files.length > 0) {
                    renderPreview(e.target.files[0], preview, prompt);
                }
            });
        }

        function renderPreview(file, previewImg, promptZone) {
            const reader = new FileReader();
            reader.onload = (e) => {
                previewImg.src = e.target.result;
                previewImg.style.display = 'block';
                promptZone.style.display = 'none';
            };
            reader.readAsDataURL(file);
        }

        setupDropZone('drop-zone-main', 'file-main', 'preview-main', 'prompt-main');
        setupDropZone('drop-zone-detail', 'file-detail', 'preview-detail', 'prompt-detail');
    </script>
    
    
</body>
</html>