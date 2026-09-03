<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String checkSessionId = (String) session.getAttribute("userId");
    if (checkSessionId != null && !checkSessionId.trim().isEmpty()) {
%>
<script>
    alert("이미 로그인된 상태입니다.");
    location.href = "main.jsp";
</script>

<%
    return; // 이미 로그인된 경우 페이지 렌더링 중단
}
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Code Sound | 회원가입</title>
    <link rel="stylesheet" href="resource/style.css">
    <script src="resource/js/theme.js"></script>
</head>
<body>

    <jsp:include page="include/menu.jsp" />

    <div class="member-container">
        <div class="member-card">
            <div class="member-header">
                <h2>CREATE ACCOUNT</h2>
                <p>코드 사운드의 멤버가 되어 하이엔드 사운드를 경험해 보세요.</p>
            </div>

            <form id="joinForm" action="process/processJoin.jsp" method="post" onsubmit="return validateJoinForm()">
                
                <div class="input-group">
                    <label for="mId">아이디</label>
                    
                    <div class="id-check-zone">
                        <input type="text" id="mId" name="mId" placeholder="영문, 숫자 4~12자" required>
                        <button type="button" class="btn-check-id" onclick="checkDuplicateId()">중복확인</button>
                    </div>
                    
                    <p id="idCheckMsg" class="id-check-msg"></p>
                </div>

                <div class="input-group">
                    <label for="passwd">비밀번호</label>
                    <input type="password" id="passwd" name="passwd" placeholder="비밀번호를 입력해 주세요" required>
                </div>

                <div class="input-group">
                    <label for="mName">이름</label>
                    <input type="text" id="mName" name="mName" placeholder="이름을 입력해 주세요" required>
                </div>

                <div class="input-group">
                    <label>성별</label>
                    <div class="gender-radio-group">
                        <label class="radio-label">
                            <input type="radio" name="gender" value="남성" checked> <span>남성</span>
                        </label>
                        <label class="radio-label">
                            <input type="radio" name="gender" value="여성"> <span>여성</span>
                        </label>
                    </div>
                </div>

                <div class="input-group">
                    <label>생년월일</label>
                    <div class="birth-select-zone">
                        <select id="birthYear" name="birthYear" required>
                            <option value="">년도</option>
                        </select>
                        
                        <select id="birthMonth" name="birthMonth" required>
                            <option value="">월</option>
                        </select>
                        
                        <select id="birthDay" name="birthDay" required>
                            <option value="">일</option>
                        </select>
                    </div>
                    
                    <input type="hidden" id="birth" name="birth">
                </div>

                <div class="input-group">
                    <label>이메일 주소</label>
                    <div class="email-input-zone">
                        <input type="text" id="emailId" placeholder="이메일 아이디" required>
                        
                        <span class="email-at">@</span>
                        
                        <input type="text" id="emailDomain" placeholder="도메인 주소" required>
                        
                        <select id="emailSelect" onchange="changeEmailDomain(this)">
                            <option value="">직접 입력</option>
                            <option value="naver.com">naver.com</option>
                            <option value="gmail.com">gmail.com</option>
                            <option value="daum.net">daum.net</option>
                            <option value="hanmail.net">hanmail.net</option>
                            <option value="nate.com">nate.com</option>
                        </select>
                    </div>
                    
                    <input type="hidden" id="mail" name="mail">
                </div>

                <div class="input-group">
                    <label>연락처</label>
                    <div class="phone-input-zone">
                        <!-- 앞자리 식별번호 선택 (가장 많이 쓰는 번호 라인업) -->
                        <select id="phone1" required>
                            <option value="010">010</option>
                            <option value="011">011</option>
                            <option value="016">016</option>
                            <option value="017">017</option>
                            <option value="019">019</option>
                        </select>
                        
                        <span class="phone-dash">-</span>
                        
                        <!-- 중간 4자리 번호 (최대 4글자 제한) -->
                        <input type="text" id="phone2" maxlength="4" placeholder="0000" required oninput="this.value=this.value.replace(/[^0-9]/g,'');">
                        
                        <span class="phone-dash">-</span>
                        
                        <!-- 마지막 4자리 번호 (최대 4글자 제한) -->
                        <input type="text" id="phone3" maxlength="4" placeholder="0000" required oninput="this.value=this.value.replace(/[^0-9]/g,'');">
                    </div>
                    
                    <!-- 히든 필드: 서버(processJoin.jsp)로는 "010-1234-5678" 형식으로 조립해서 전송 -->
                    <input type="hidden" id="phone" name="phone">
                </div>

                <div class="input-group">
                    <label>배송지 주소</label>
                    
                    <div class="address-zip-zone">
                        <input type="text" id="sample6_postcode" name="zipCode" placeholder="우편번호" readonly required>
                        <button type="button" class="btn-search-address" onclick="execDaumPostcode()">주소찾기</button>
                    </div>
                    
                    <input type="text" id="sample6_address" name="address" placeholder="기본 주소" readonly required>
                    
                    <input type="text" id="sample6_detailAddress" name="addressDetail" placeholder="상세 주소를 입력해 주세요" required>
                    
                    <input type="hidden" id="sample6_extraAddress" placeholder="참고항목">
                </div>

                <div class="member-action-zone">
                    <button type="submit" class="btn-submit-member">가입하기</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        // [글로벌 변수] 아이디 중복확인 인증 여부 기록 스위치
        let isIdChecked = false;

        // 1. 아이디 실시간 중복검사 (Fetch API)
        function checkDuplicateId() {
            const mIdInput = document.getElementById('mId');
            const mId = mIdInput.value.trim();
            const msgElement = document.getElementById('idCheckMsg');
            
            if (mId.length < 4 || mId.length > 12) {
                msgElement.textContent = "아이디는 4자 이상 12자 이하로 입력해 주세요.";
                msgElement.className = "id-check-msg error";
                mIdInput.focus();
                return;
            }
            
            fetch("process/checkId.jsp?mId=" + encodeURIComponent(mId))
                .then(response => response.text())
                .then(data => {
                    const result = data.trim();
                    if (result === "AVAILABLE") {
                        msgElement.textContent = "✓ 사용 가능한 아이디입니다.";
                        msgElement.className = "id-check-msg success";
                        isIdChecked = true; 
                    } else if (result === "DUPLICATED") {
                        msgElement.textContent = "✕ 이미 존재하는 아이디입니다.";
                        msgElement.className = "id-check-msg error";
                        isIdChecked = false;
                    } else {
                        msgElement.textContent = "⚙ 서버 통신 오류가 발생했습니다.";
                        msgElement.className = "id-check-msg error";
                        isIdChecked = false;
                    }
                })
                .catch(error => {
                    console.error("Error:", error);
                    msgElement.textContent = "⚙ 연결에 실패했습니다.";
                    msgElement.className = "id-check-msg error";
                    isIdChecked = false;
                });
        }

        // 아이디 입력창의 글자가 바뀌면 중복확인 스위치를 리셋
        document.getElementById('mId').addEventListener('input', () => {
            isIdChecked = false;
            document.getElementById('idCheckMsg').style.display = 'none';
        });
        
        // 2. 이메일 도메인 선택 상자 처리
        function changeEmailDomain(selectObj) {
            const domainInput = document.getElementById('emailDomain');
            if (selectObj.value === "") {
                domainInput.value = "";
                domainInput.readOnly = false;
                domainInput.style.backgroundColor = "#ffffff";
                domainInput.focus();
            } else {
                domainInput.value = selectObj.value;
                domainInput.readOnly = true;
                domainInput.style.backgroundColor = "#f1f5f9";
            }
        }

        // 3. DOM 로드 완료 시 생년월일 옵션 생성 및 연락처 자동 포커스 이동 설정
        window.addEventListener('DOMContentLoaded', () => {
            // [3-1] 생년월일 옵션 생성
            const yearSelect = document.getElementById('birthYear');
            const monthSelect = document.getElementById('birthMonth');
            const daySelect = document.getElementById('birthDay');
            
            const currentYear = 2026; 
            for (let y = currentYear; y >= currentYear - 100; y--) {
                yearSelect.add(new Option(y + "년", y));
            }
            for (let m = 1; m <= 12; m++) {
                const mStr = m < 10 ? "0" + m : m;
                monthSelect.add(new Option(m + "월", mStr));
            }
            for (let d = 1; d <= 31; d++) {
                const dStr = d < 10 ? "0" + d : d;
                daySelect.add(new Option(d + "일", dStr));
            }

            // [3-2] 연락처 가운데 4자리 입력 완료 시 마지막 칸으로 포커스 이동
            const phone2 = document.getElementById('phone2');
            const phone3 = document.getElementById('phone3');
            if (phone2 && phone3) {
                phone2.addEventListener('input', function() {
                    if (this.value.length >= 4) {
                        phone3.focus();
                    }
                });
            }
        });

        // 4. 가입하기 최종 통합 검증
        function validateJoinForm() {
            const mId = document.getElementById('mId').value.trim();
            const passwd = document.getElementById('passwd').value.trim();

            // [A] 기본 길이 검사
            if (mId.length < 4 || mId.length > 12) {
                alert("아이디는 4자 이상 12자 이하로 입력해 주세요.");
                return false;
            }
            if (passwd.length < 4) {
                alert("비밀번호는 최소 4자 이상이어야 합니다.");
                return false;
            }

            // [B] 아이디 중복확인 패스 여부 검증
            if (!isIdChecked) {
                alert("아이디 중복확인을 먼저 진행해 주세요.");
                return false;
            }
            
            // [C] 생년월일 결합 및 바인딩 (YYYY/MM/DD)
            const year = document.getElementById('birthYear').value;
            const month = document.getElementById('birthMonth').value;
            const day = document.getElementById('birthDay').value;
            if (!year || !month || !day) { 
                alert("생년월일을 모두 선택해 주세요."); 
                return false; 
            }
            document.getElementById('birth').value = year + "/" + month + "/" + day;
            
            // [D] 이메일 주소 결합 및 바인딩 (ID@도메인)
            const emailId = document.getElementById('emailId').value.trim();
            const emailDomain = document.getElementById('emailDomain').value.trim();
            if (!emailId || !emailDomain) { 
                alert("이메일 주소를 정확하게 입력해 주세요."); 
                return false; 
            }
            document.getElementById('mail').value = emailId + "@" + emailDomain;
            
            // [E] 연락처 결합 및 바인딩 (010-XXXX-XXXX)
            const p1 = document.getElementById('phone1').value;
            const p2 = document.getElementById('phone2').value.trim();
            const p3 = document.getElementById('phone3').value.trim();
            if (p2.length < 3 || p3.length < 4) {
                alert("연락처 번호를 올바르게 입력해 주세요.");
                if(p2.length < 3) document.getElementById('phone2').focus();
                else document.getElementById('phone3').focus();
                return false;
            }
            document.getElementById('phone').value = p1 + "-" + p2 + "-" + p3;
            
            // 모든 검증 통과, 백엔드(processJoin.jsp)로 데이터 전송
            return true;
        }
    </script>
    
    <script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
    <script>
        function execDaumPostcode() {
            new daum.Postcode({
                oncomplete: function(data) {
                    // 팝업에서 검색결과 항목을 클릭했을때 실행할 코드를 작성하는 부분.

                    // 각 주소의 노출 규칙에 따라 주소를 조합한다.
                    // 내려오는 변수가 값이 없는 경우엔 공백('')값을 가짐
                    var addr = ''; // 주소 변수
                    var extraAddr = ''; // 참고항목 변수

                    //사용자가 선택한 주소 타입에 따라 해당 주소 값을 가져온다.
                    if (data.userSelectedType === 'R') { // 사용자가 도로명 주소를 선택했을 경우
                        addr = data.roadAddress;
                    } else { // 사용자가 지번 주소를 선택했을 경우(J)
                        addr = data.jibunAddress;
                    }

                    // 사용자가 도로명 주소를 선택했을 때 참고항목을 조합한다.
                    if(data.userSelectedType === 'R'){
                        // 법정동명이 있을 경우 추가한다. (법정리는 제외)
                        // 법정동의 경우 마지막 문자가 "동/로/가"로 끝난다.
                        if(data.bname !== '' && /[동|로|가]$/g.test(data.bname)){
                            extraAddr += data.bname;
                        }
                        // 건물명이 있고, 공동주택일 경우 추가한다.
                        if(data.buildingName !== '' && data.apartment === 'Y'){
                            extraAddr += (extraAddr !== '' ? ', ' + data.buildingName : data.buildingName);
                        }
                        // 표시할 참고항목이 있을 경우, 괄호까지 추가한 최종 문자열을 만든다.
                        if(extraAddr !== ''){
                            extraAddr = ' (' + extraAddr + ')';
                        }
                        // 조합된 참고항목을 해당 필드에 넣는다.
                        document.getElementById("sample6_extraAddress").value = extraAddr;
                    
                    } else {
                        document.getElementById("sample6_extraAddress").value = '';
                    }

                    // 검색된 우편번호와 주소를 입력창에 반영
                    document.getElementById('sample6_postcode').value = data.zonecode;
                    document.getElementById("sample6_address").value = addr;
                    
                    // 커서를 상세주소 필드로 이동시켜서 유저가 동/호수를 바로 입력하게 유도
                    document.getElementById("sample6_detailAddress").focus();
                }
            }).open();
        }
    </script>
</body>
</html>