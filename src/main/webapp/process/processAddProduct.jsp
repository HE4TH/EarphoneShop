<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="jakarta.servlet.http.*" %>
<%
    request.setCharacterEncoding("UTF-8");

    // 관리자 권한 확인
    String sessionUserId = (String) session.getAttribute("userId");
    if (sessionUserId == null || !sessionUserId.equals("admin")) {
        response.sendRedirect("../login.jsp");
        return;
    }

    // 1. 이미지 저장소 절대경로 지정 (메인과 상세 분리, config.properties에서 로드)
    String baseWorkspacePath = util.ConfigLoader.get("upload.base.path");

    String mainUploadPath = baseWorkspacePath + "\\main";
    String descUploadPath = baseWorkspacePath + "\\description"; // 상세 이미지 전용 저장 폴더

    // 폴더가 없으면 자동 생성
    File mainDir = new File(mainUploadPath);
    if (!mainDir.exists()) mainDir.mkdir(); 
    
    File descDir = new File(descUploadPath);
    if (!descDir.exists()) descDir.mkdir(); 

    // 변수 초기화
    String category = "";
    String brand = "";
    String pName = "";
    int price = 0;
    int stock = 0;
    String pImage = "default.jpg";
    String pDescriptionImage1 = "default_detail.jpg";
    String description = "";
    String csrfToken = "";

    // 폼의 각 파트를 텍스트/파일로 분리해 처리
    for (Part part : request.getParts()) {
        String name = part.getName();

        if (part.getContentType() == null) {
            // 일반 텍스트 데이터 파싱
            BufferedReader reader = new BufferedReader(new InputStreamReader(part.getInputStream(), "UTF-8"));
            String value = reader.readLine();
            if (value != null) value = value.trim();

            if (name.equals("category")) category = value;
            else if (name.equals("brand")) brand = value;
            else if (name.equals("pName")) pName = value;
            else if (name.equals("price")) {
                try { price = Integer.parseInt(value); } catch (NumberFormatException e) { price = -1; }
            }
            else if (name.equals("stock")) {
                try { stock = Integer.parseInt(value); } catch (NumberFormatException e) { stock = -1; }
            }
            else if (name.equals("description")) description = value;
            else if (name.equals("csrfToken")) csrfToken = value;
        } else {
            // 파일 파트 처리
            String disposition = part.getHeader("Content-Disposition");
            String fileName = "";
            for (String content : disposition.split(";")) {
                if (content.trim().startsWith("filename")) {
                    fileName = content.substring(content.indexOf('=') + 1).trim().replace("\"", "");
                    if(fileName.contains("\\")) {
                        fileName = fileName.substring(fileName.lastIndexOf("\\") + 1);
                    }
                }
            }
            
            if (!fileName.isEmpty()) {
                // 파트 name에 따라 메인 이미지는 main 폴더, 상세 이미지는 description 폴더에 저장
                if (name.equals("file-main") || name.equals("pImageFile") || name.equals("pImage")) {
                    pImage = fileName;
                    part.write(mainUploadPath + File.separator + pImage);
                } else if (name.equals("file-detail") || name.equals("pDescriptionImage1File") || name.equals("pDescriptionImage1")) {
                    pDescriptionImage1 = fileName;
                    part.write(descUploadPath + File.separator + pDescriptionImage1);
                }
            }
        }
    }

    // 2-1. CSRF 토큰 검증
    String sessionCsrfToken = (String) session.getAttribute("csrfToken");
    if (sessionCsrfToken == null || !sessionCsrfToken.equals(csrfToken)) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN, "잘못된 요청입니다.");
        return;
    }

    // 2-2. 서버단 입력 검증 (필수값, 가격/재고 범위)
    if (category == null || category.trim().isEmpty()
            || brand == null || brand.trim().isEmpty()
            || pName == null || pName.trim().isEmpty()) {
%>
        <script>
            alert("필수 입력값이 누락되었습니다.");
            history.back();
        </script>
<%
        return;
    }

    if (price <= 0 || stock < 0) {
%>
        <script>
            alert("가격은 0보다 커야 하고, 재고는 음수일 수 없습니다.");
            history.back();
        </script>
<%
        return;
    }

    // 3. DB에 상품 정보 저장
    Connection conn = null;
    PreparedStatement pstmt = null;
    try {
        conn = util.DBConnection.getConnection();

        String sql = "INSERT INTO dbo.earphone (category, brand, pName, price, stock, pImage, pDescriptionImage1) VALUES (?, ?, ?, ?, ?, ?, ?)";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, category);
        pstmt.setString(2, brand);
        pstmt.setString(3, pName);
        pstmt.setInt(4, price);
        pstmt.setInt(5, stock);
        pstmt.setString(6, pImage); 
        pstmt.setString(7, pDescriptionImage1); 

        pstmt.executeUpdate();
%>
        <script>
            alert("🎉 상품 등록이 완료되었습니다!");
            location.href = "../adminMain.jsp";
        </script>
<%
    } catch(Exception e) {
        e.printStackTrace();
%>
        <script>
            alert("❌ 데이터베이스 인서트 오류 발생");
            history.back();
        </script>
<%
    } finally {
        if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if(conn != null) try { conn.close(); } catch(Exception e) {}
    }
%>