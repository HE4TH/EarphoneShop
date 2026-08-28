<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.time.LocalDateTime" %>
<%@ page import="java.time.format.DateTimeFormatter" %>

<%
    // 1. 한글 깨짐 방지를 위한 인코딩 차단막 설정
    request.setCharacterEncoding("UTF-8");

	//2. join.jsp의 form에서 날아온 핵심 데이터 수집 (중복 완벽 제거)
	String mId = request.getParameter("mId");
	String passwd = request.getParameter("passwd");
	String mName = request.getParameter("mName");
	String gender = request.getParameter("gender");
	String birth = request.getParameter("birth"); // 자바스크립트가 YYYY/MM/DD로 합쳐준 값
	String mail = request.getParameter("mail");
	String phone = request.getParameter("phone");
	
	// 🎯 카카오 주소창 삼형제를 독립된 변수로 딱 한 번씩만 정갈하게 가로챕니다.
	String zipCode = request.getParameter("zipCode");             // 우편번호 독립 수신
	String address = request.getParameter("address");             // 시/구/동 기본주소 독립 수신
	String addressDetail = request.getParameter("addressDetail"); // 아파트 동/호수 상세주소 독립 수신

    // 3. 현재 가입하는 순간의 날짜/시간을 "YYYY-MM-DD HH:mm:ss" 포맷 문자열로 생성
    LocalDateTime now = LocalDateTime.now();
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    String regist_day = now.format(formatter);

    // 4. JDBC 인프라 변수 초기화
    Connection conn = null;
    PreparedStatement pstmt = null;

    try {
        conn = util.DBConnection.getConnection();
        
        String sql = "INSERT INTO member (mId, passwd, mName, gender, birth, mail, phone, address, regist_day, zipCode, addressDetail) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        pstmt = conn.prepareStatement(sql);
        
        // ? 자리에 안전하게 데이터 매핑 (SQL 인젝션 해킹 방어)
      	pstmt.setString(1, mId.trim());
        pstmt.setString(2, passwd.trim());
        pstmt.setString(3, mName.trim());
        pstmt.setString(4, gender);
        pstmt.setString(5, birth);
        pstmt.setString(6, mail.trim());
        pstmt.setString(7, phone.trim());
        pstmt.setString(8, address.trim()); // 시/구/동 기본 주소 들어가는 자리
        pstmt.setString(9, regist_day);
        
        // 🎯 [여기에 10번, 11번을 순서대로 추가해 줍니다!]
        pstmt.setString(10, zipCode != null ? zipCode.trim() : "");          // 우편번호를 10번째 ? 자리에 배달
        pstmt.setString(11, addressDetail != null ? addressDetail.trim() : ""); // 상세주소를 11번째 ? 자리에 배달
        
        // 🚀 SQL Server로 쿼리 최종 슛발사! (행 추가 실행)
     // 🚀 SQL Server로 쿼리 최종 슛발사!
        pstmt.executeUpdate();
        
        // 🎯 [변경] 촌스러운 alert를 지우고, 주소창 뒤에 success=true를 묻혀서 로그인 창으로 이동!
        response.sendRedirect("../login.jsp?success=true");

    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        // 7. 사용이 끝난 DB 자원은 역순으로 안전하게 폐쇄 (메모리 누수 방지)
        if (pstmt != null) try { pstmt.close(); } catch(SQLException e) {}
        if (conn != null) try { conn.close(); } catch(SQLException e) {}
    }
%>