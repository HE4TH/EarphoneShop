<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // 🎯 메인 메뉴바가 던져준 "직전 페이지 주소"를 가로챕니다.
    String prevPage = request.getParameter("prevPage");
    if (prevPage == null) {
        prevPage = "main.jsp"; // 혹시나 주소가 안 넘어왔다면 기본 메인페이지로 백업 설정
    }
    String checkSessionId = (String) session.getAttribute("userId");
    if (checkSessionId != null && !checkSessionId.trim().isEmpty()) {
%>
<script>
    alert("이미 로그인된 상태입니다.");
    location.href = "main.jsp";
</script>

<%
    return; // ❌ 밑에 있는 로그인 폼 HTML 코드를 톰캣이 읽지 못하도록 강제 종료!
}
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Code Sound | 로그인</title>
    <link rel="stylesheet" href="resource/style.css">
</head>
<body>

    <jsp:include page="include/menu.jsp" />

    <div class="member-container">
        <div class="member-card">
            <div class="member-header">
                <h2>SIGN IN</h2>
                <p>하이엔드 오디오 세상을 만나보세요.</p>
            </div>

            <form id="loginForm" action="process/processLogin.jsp" method="post" onsubmit="return validateLoginForm()">
                
                <input type="hidden" name="prevPage" value="<%= prevPage %>">
                
                <div class="input-group">
                    <label for="mId">아이디</label>
                    <input type="text" id="mId" name="mId" placeholder="아이디를 입력해 주세요" required>
                </div>

                <div class="input-group">
                    <label for="passwd">비밀번호</label>
                    <input type="password" id="passwd" name="passwd" placeholder="비밀번호를 입력해 주세요" required>
                </div>

                <div class="member-action-zone">
                    <button type="submit" class="btn-submit-member">로그인</button>
                    <a href="join.jsp" class="btn-link-login">아직 계정이 없으신가요? 회원가입하기</a>
                </div>
            </form>
        </div>
    </div>

    <div id="joinSuccessModal" class="join-modal-overlay"> ... </div>
    <script> ... </script>
</body>
</html>