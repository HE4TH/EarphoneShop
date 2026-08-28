<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dto.EarPhone"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.sql.*" %>

<%
    request.setCharacterEncoding("UTF-8");

    String[] selectedIds = request.getParameterValues("selectedProducts");
    String sessionUserId = (String) session.getAttribute("userId");

    if (selectedIds != null && selectedIds.length > 0) {

        // 1. DB에서 선택된 것들 전부 삭제
        if (sessionUserId != null && !sessionUserId.trim().isEmpty()) {
            Connection conn = null;
            PreparedStatement pstmt = null;
            try {
                conn = util.DBConnection.getConnection();

                pstmt = conn.prepareStatement("DELETE FROM cart WHERE mId = ? AND pId = ?");

                for (String idStr : selectedIds) {
                    pstmt.setString(1, sessionUserId.trim());
                    pstmt.setString(2, idStr.trim());
                    pstmt.executeUpdate();
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            }
        }

        // 2. 세션에서도 선택된 것들 전부 삭제
        ArrayList<EarPhone> cartList = (ArrayList<EarPhone>) session.getAttribute("cartList");
        if (cartList != null) {
            for (String idStr : selectedIds) {
                long targetId = Long.parseLong(idStr.trim());
                for (int i = cartList.size() - 1; i >= 0; i--) {
                    if (cartList.get(i).getProductId() == targetId) {
                        cartList.remove(i);
                        break;
                    }
                }
            }
        }
    }

    response.sendRedirect("../cart.jsp");
%>