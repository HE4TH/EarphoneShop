<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.*" %>
<%@ page import="jakarta.servlet.http.*" %>
<%
    request.setCharacterEncoding("UTF-8");

    String sessionUserId = (String) session.getAttribute("userId");
    if (sessionUserId == null || !sessionUserId.equals("admin")) {
        response.sendRedirect("../login.jsp");
        return;
    }

    String baseWorkspacePath = util.ConfigLoader.get("upload.base.path");
    String mainUploadPath = baseWorkspacePath + "\\main";
    String descUploadPath = baseWorkspacePath + "\\description";

    File mainDir = new File(mainUploadPath);
    if (!mainDir.exists()) mainDir.mkdir();

    File descDir = new File(descUploadPath);
    if (!descDir.exists()) descDir.mkdir();

    long productId = 0;
    String category = "";
    String brand = "";
    String pName = "";
    int price = -1;
    int stock = -1;
    String currentPImage = "";
    String currentPDescriptionImage1 = "";
    String pImage = null;
    String pDescriptionImage1 = null;
    String csrfToken = "";

    for (Part part : request.getParts()) {
        String name = part.getName();

        if (part.getContentType() == null) {
            BufferedReader reader = new BufferedReader(new InputStreamReader(part.getInputStream(), "UTF-8"));
            String value = reader.readLine();
            if (value != null) value = value.trim();

            if (name.equals("productId")) { try { productId = Long.parseLong(value); } catch (Exception e) {} }
            else if (name.equals("category")) category = value;
            else if (name.equals("brand")) brand = value;
            else if (name.equals("pName")) pName = value;
            else if (name.equals("price")) { try { price = Integer.parseInt(value); } catch (Exception e) { price = -1; } }
            else if (name.equals("stock")) { try { stock = Integer.parseInt(value); } catch (Exception e) { stock = -1; } }
            else if (name.equals("currentPImage")) currentPImage = value;
            else if (name.equals("currentPDescriptionImage1")) currentPDescriptionImage1 = value;
            else if (name.equals("csrfToken")) csrfToken = value;
        } else {
            String disposition = part.getHeader("Content-Disposition");
            String fileName = "";
            for (String content : disposition.split(";")) {
                if (content.trim().startsWith("filename")) {
                    fileName = content.substring(content.indexOf('=') + 1).trim().replace("\"", "");
                    if (fileName.contains("\\")) {
                        fileName = fileName.substring(fileName.lastIndexOf("\\") + 1);
                    }
                }
            }

            if (!fileName.isEmpty()) {
                if (name.equals("pImageFile")) {
                    pImage = fileName;
                    part.write(mainUploadPath + File.separator + pImage);
                } else if (name.equals("pDescriptionImage1File")) {
                    pDescriptionImage1 = fileName;
                    part.write(descUploadPath + File.separator + pDescriptionImage1);
                }
            }
        }
    }

    // 새 이미지를 업로드하지 않았으면 기존 파일명 유지
    if (pImage == null) pImage = currentPImage;
    if (pDescriptionImage1 == null) pDescriptionImage1 = currentPDescriptionImage1;

    // CSRF 토큰 검증
    String sessionCsrfToken = (String) session.getAttribute("csrfToken");
    if (sessionCsrfToken == null || !sessionCsrfToken.equals(csrfToken)) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN, "잘못된 요청입니다.");
        return;
    }

    // 입력 검증
    if (productId <= 0 || category == null || category.trim().isEmpty()
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

    dao.EarPhoneRepository.getInstance().updateProduct(productId, category, brand, pName, price, stock, pImage, pDescriptionImage1);

    response.sendRedirect("../adminMain.jsp");
%>
