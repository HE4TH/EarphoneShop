<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.time.LocalDateTime" %>
<%@ page import="java.time.format.DateTimeFormatter" %>

<%
    // 1. 한글 인코딩 설정
    request.setCharacterEncoding("UTF-8");

	// 2. join.jsp form 데이터 수집
	String mId = request.getParameter("mId");
	String passwd = request.getParameter("passwd");
	String mName = request.getParameter("mName");
	String gender = request.getParameter("gender");
	String birth = request.getParameter("birth"); // 자바스크립트가 YYYY/MM/DD로 합쳐준 값
	String mail = request.getParameter("mail");
	String phone = request.getParameter("phone");
	
	String zipCode = request.getParameter("zipCode");             // 우편번호
	String address = request.getParameter("address");             // 시/구/동 기본주소
	String addressDetail = request.getParameter("addressDetail"); // 아파트 동/호수 상세주소

    // 3. 현재 가입하는 순간의 날짜/시간을 "YYYY-MM-DD HH:mm:ss" 포맷 문자열로 생성
    LocalDateTime now = LocalDateTime.now();
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    String regist_day = now.format(formatter);

    // 4. JDBC 변수 초기화
    Connection conn = null;
    PreparedStatement pstmt = null;

    try {
        conn = util.DBConnection.getConnection();
        
        String sql = "INSERT INTO member (mId, passwd, mName, gender, birth, mail, phone, address, regist_day, zipCode, addressDetail) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        pstmt = conn.prepareStatement(sql);
        
        // PreparedStatement 파라미터 바인딩 (SQL 인젝션 방어)
      	pstmt.setString(1, mId.trim());
        pstmt.setString(2, passwd.trim());
        pstmt.setString(3, mName.trim());
        pstmt.setString(4, gender);
        pstmt.setString(5, birth);
        pstmt.setString(6, mail.trim());
        pstmt.setString(7, phone.trim());
        pstmt.setString(8, address.trim()); // 시/구/동 기본주소
        pstmt.setString(9, regist_day);
        pstmt.setString(10, zipCode != null ? zipCode.trim() : "");
        pstmt.setString(11, addressDetail != null ? addressDetail.trim() : "");

        pstmt.executeUpdate();

        // 가입 완료 후 로그인 페이지로 이동 (success=true로 안내 메시지 표시)
        response.sendRedirect("../login.jsp?success=true");

    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        // 7. DB 자원 반납
        if (pstmt != null) try { pstmt.close(); } catch(SQLException e) {}
        if (conn != null) try { conn.close(); } catch(SQLException e) {}
    }
%>