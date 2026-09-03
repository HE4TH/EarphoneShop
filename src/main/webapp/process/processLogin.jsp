<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="dto.EarPhone" %>
<%@ page import="dao.EarPhoneRepository" %>

<%
    // 1. 한글 인코딩 설정
    request.setCharacterEncoding("UTF-8");

    String mId = request.getParameter("mId");
    String passwd = request.getParameter("passwd");

    if (mId == null || mId.trim().isEmpty() || passwd == null || passwd.trim().isEmpty()) {
%>
        <script>
            alert("아이디와 비밀번호를 입력해 주세요.");
            history.back();
        </script>
<%
        return;
    }

    // login.jsp의 hidden 필드로 전달된 로그인 직전 페이지 주소
    String prevPage = request.getParameter("prevPage");
    if (prevPage == null || prevPage.trim().isEmpty()
            || prevPage.contains("://") || prevPage.startsWith("//")) {
        prevPage = "../main.jsp";
    }

    // 무차별 대입 공격 방지: 접속 IP + 아이디 조합으로 5분에 5회까지만 로그인 시도 허용
    String clientIp = request.getRemoteAddr();
    String rateLimitKey = "login:" + clientIp + ":" + (mId != null ? mId.trim() : "");
    if (!util.RateLimiter.isAllowed(rateLimitKey, 5, 5 * 60 * 1000L)) {
%>
        <script>
            alert("로그인 시도가 너무 많습니다. 5분 후 다시 시도해 주세요.");
            history.back();
        </script>
<%
        return;
    }

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // 로그인 성공 여부와 관리자 여부를 체크할 플래그 변수
    boolean isLoginSuccess = false;
    boolean isAdmin = false;
    
    try {
        conn = util.DBConnection.getConnection();
        
        String sql = "SELECT mName, passwd FROM member WHERE mId = ?";

        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, mId.trim());

        rs = pstmt.executeQuery();

        // 3. 인증 결과 처리
        if (rs.next() && util.PasswordUtil.verify(passwd.trim(), rs.getString("passwd"))) {
            isLoginSuccess = true;
            String mName = rs.getString("mName");

            // 로그인 성공 시 시도 횟수 제한 초기화
            util.RateLimiter.reset(rateLimitKey);

            // 세션 고정(Session Fixation) 공격 방지: 인증 성공 시 세션 ID 재발급
            request.changeSessionId();

            // 로그인 전역 세션 바인딩
            session.setAttribute("userId", mId.trim());
            session.setAttribute("userName", mName.trim());
            
            // 관리자 여부 확인
            if (mId.trim().equals("admin")) {
                isAdmin = true;
            }
            
            // 세션에 장바구니 데이터 복원
            PreparedStatement pstmtCart = null;
            ResultSet rsCart = null;
            
            ArrayList<EarPhone> dbCartList = new ArrayList<EarPhone>();
            EarPhoneRepository repository = EarPhoneRepository.getInstance();
            
            try {
                // 이 회원(mId)의 DB 장바구니 데이터 조회
                String sqlCart = "SELECT pId, pCount FROM cart WHERE mId = ? ORDER BY cartId DESC";
                pstmtCart = conn.prepareStatement(sqlCart);
                pstmtCart.setString(1, mId.trim());
                rsCart = pstmtCart.executeQuery();
                
                while (rsCart.next()) {
                    long dbPid = Long.parseLong(rsCart.getString("pId"));
                    int dbCount = rsCart.getInt("pCount");
                    
                    EarPhone dbGoods = repository.getEarPhoneById(dbPid);
                    
                    if (dbGoods != null) {
                        EarPhone cartItem = new EarPhone();
                        cartItem.setProductId(dbGoods.getProductId());
                        cartItem.setpName(dbGoods.getpName());
                        cartItem.setpNameKn(dbGoods.getpNameKn());
                        cartItem.setPrice(dbGoods.getPrice());
                        cartItem.setBrand(dbGoods.getBrand());
                        cartItem.setpImage(dbGoods.getpImage());
                        cartItem.setCategory(dbGoods.getCategory());
                        cartItem.setStock(dbCount); // DB 누적 수량
                        
                        dbCartList.add(cartItem);
                    }
                }
                
                if (!dbCartList.isEmpty()) {
                    session.setAttribute("cartList", dbCartList);
                }
                
            } catch (Exception e) {
                e.printStackTrace(); 
            } finally {
                if (rsCart != null) try { rsCart.close(); } catch(Exception e) {}
                if (pstmtCart != null) try { pstmtCart.close(); } catch(Exception e) {}
            }
        }

        // 4. 로그인 결과에 따른 화면 리다이렉트
        if (isLoginSuccess) {
            if (isAdmin) {
%>
                <script>
                    alert("👑 마스터 관리자님, 환영합니다. 관리 대시보드로 이동합니다.");
                    location.href = "../adminMain.jsp";
                </script>
<%
            } else {
%>
                <script>
                    location.href = "<%= util.HtmlUtil.escapeJs(prevPage) %>"; // 일반 회원은 구경하던 페이지로 복귀
                </script>
<%
            }
        } else {
            // 로그인 실패
%>
            <script>
                alert("아이디 또는 비밀번호가 일치하지 않습니다. 다시 확인해 주세요.");
                history.back();
            </script>
<%
        }

    } catch (Exception e) {
        e.printStackTrace();
%>
        <script>
            alert("서버 연결 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.");
            history.back();
        </script>
<%
    } finally {
        // 자원 반납
        if (rs != null) try { rs.close(); } catch(SQLException e) {}
        if (pstmt != null) try { pstmt.close(); } catch(SQLException e) {}
        if (conn != null) try { conn.close(); } catch(SQLException e) {}
    }
%>