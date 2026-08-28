package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import dto.EarPhone;
import util.DBConnection;

public class EarPhoneRepository {
    
    private static EarPhoneRepository instance = new EarPhoneRepository();
    
    // DB 연동형이므로 생성자에서 하드코딩 데이터를 만들 필요가 없습니다.
    public EarPhoneRepository() {}
    
    public static EarPhoneRepository getInstance() {
        return instance;
    }

    /**
     * 전체 상품 목록 가져오기
     */
    public ArrayList<EarPhone> getAllEarPhones() {
        ArrayList<EarPhone> list = new ArrayList<EarPhone>();
        String sql = "SELECT * FROM dbo.earphone";
        
        try {
        	
        	Connection conn = DBConnection.getConnection();
            PreparedStatement pstmt = conn.prepareStatement(sql);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                list.add(mapResultSetToEarPhone(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
    
    // JSP 파일들과의 호환성을 위해 복수형 이름 매핑 유지
    public ArrayList<EarPhone> getAllEarPhone() {
        return getAllEarPhones();
    }

    /**
     * 카테고리별 상품 목록 가져오기 (WIRED / WIRELESS)
     */
    public ArrayList<EarPhone> getProductsByCategory(String category) {
        ArrayList<EarPhone> listOfCategory = new ArrayList<EarPhone>();
        
        // 1. 만약 카테고리가 "ALL"로 들어오면? 고민할 필요 없이 우리가 미리 짜둔 전체 상품 메서드를 호출해 리턴합니다.
        if (category == null || category.equalsIgnoreCase("ALL")) {
            return getAllEarPhones(); 
        }
        
        // 2. "WIRED"나 "WIRELESS"가 들어오면 DB에서 해당 카테고리 행들만 핀포인트로 조준 인출합니다.
        String sql = "SELECT * FROM dbo.earphone WHERE UPPER(category) = UPPER(?)";
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DBConnection.getConnection(); // 커넥션 개통
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, category.trim());
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                // 승민님이 밑에 정성껏 빚어두신 헬퍼 매퍼를 호출해 DTO 조립 후 바구니에 수집!
                listOfCategory.add(mapResultSetToEarPhone(rs));
            }
        } catch (Exception e) {
            System.out.println("❌ 카테고리별 상품 인출 중 백엔드 쿼리 에러 발생!");
            e.printStackTrace();
        } finally {
            // DB 자원 안전 반납
            try { if (rs != null) rs.close(); } catch(Exception e) {}
            try { if (pstmt != null) pstmt.close(); } catch(Exception e) {}
            try { if (conn != null) conn.close(); } catch(Exception e) {}
        }
        
        return listOfCategory;
    }
    
    /**
     * 정렬 기능 결합용 목록 가져오기 메서드
     */
    public ArrayList<EarPhone> getEarPhonesWithSort(String category, String orderBySql) {
        ArrayList<EarPhone> list = new ArrayList<EarPhone>();
        String sql = "SELECT * FROM dbo.earphone WHERE UPPER(category) = UPPER(?) " + orderBySql;
        
        try {
            
        	Connection conn = DBConnection.getConnection();
            PreparedStatement pstmt = conn.prepareStatement(sql);
        	
            pstmt.setString(1, category);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSetToEarPhone(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * 단일 상품 상세 조회 (ID 기준)
     */
    public EarPhone getEarPhoneById(long productId) {
        String sql = "SELECT * FROM dbo.earphone WHERE productId = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setLong(1, productId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToEarPhone(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * 결제 및 주문 발생 시 실시간 재고 감소 기능
     */
    public boolean updateStock(int quantity, long productId) {
        Connection conn = null;
        PreparedStatement pstmtCheck = null;
        PreparedStatement pstmtUpdate = null;
        ResultSet rs = null;
        boolean result = false;
        
        try {
            conn = DBConnection.getConnection();
            
            String sqlCheck = "SELECT stock FROM dbo.earphone WHERE productId = ?";
            pstmtCheck = conn.prepareStatement(sqlCheck);
            pstmtCheck.setLong(1, productId);
            rs = pstmtCheck.executeQuery();
            
            if (rs.next()) {
                int currentStock = rs.getInt("stock");
                if (currentStock < quantity) {
                    System.out.println("재고 부족");
                } else {
                    String sqlUpdate = "UPDATE dbo.earphone SET stock = stock - ? WHERE productId = ?";
                    pstmtUpdate = conn.prepareStatement(sqlUpdate);
                    pstmtUpdate.setInt(1, quantity);
                    pstmtUpdate.setLong(2, productId);
                    
                    int rows = pstmtUpdate.executeUpdate();
                    if (rows > 0) result = true;
                }
            } else {
                System.out.println("존재하지 않는 상품");
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try { if (rs != null) rs.close(); } catch(Exception e) {}
            try { if (pstmtCheck != null) pstmtCheck.close(); } catch(Exception e) {}
            try { if (pstmtUpdate != null) pstmtUpdate.close(); } catch(Exception e) {}
            try { if (conn != null) conn.close(); } catch(Exception e) {}
        }
        return result;
    }

    /**
     * 🧱 DB의 데이터 한 행을 EarPhone DTO 객체에 완벽하게 바인딩해주는 헬퍼 매퍼 메서드
     */
    private EarPhone mapResultSetToEarPhone(ResultSet rs) throws Exception {
        long id = rs.getLong("productId");
        String name = rs.getString("pName");
        int price = rs.getInt("price");
        
        EarPhone p = new EarPhone(id, name, price);
        p.setBrand(rs.getString("brand"));
        p.setStock(rs.getInt("stock"));
        
        String cate = rs.getString("category");
        p.setCategory(cate);
        p.setpImage(rs.getString("pImage"));
        p.setpDescriptionImage1(rs.getString("pDescriptionImage1"));
        p.setpDescriptionImage2(rs.getString("pDescriptionImage2"));
        p.setBrandKn(rs.getString("brandKn"));
        p.setpNameKn(rs.getString("pNameKn"));
        
        // 유선 상세 규격 바인딩
        p.setwDriverType(rs.getString("wDriverType"));
        p.setwImpedance(rs.getInt("wImpedance"));
        p.setwFrequencyResponse(rs.getString("wFrequencyResponse"));
        p.setwSensitivity(rs.getInt("wSensitivity"));
        p.setwPlugType(rs.getString("wPlugType"));
        p.setWiredDetachable(rs.getBoolean("wiredDetachable"));
        p.setHasWiredMic(rs.getBoolean("hasWiredMic"));
        p.setwPackageContents(rs.getString("wPackageContents"));
        
        // 무선 상세 규격 바인딩
        p.setWlDriverType(rs.getString("wlDriverType"));
        p.setWlBluetoothVersion(rs.getString("wlBluetoothVersion"));
        p.setWlSupportedCodecs(rs.getString("wlSupportedCodecs"));
        p.setWlBatteryLife(rs.getString("wlBatteryLife"));
        p.setWirelessAncSupported(rs.getBoolean("wirelessAncSupported"));
        p.setWlWaterResistance(rs.getString("wlWaterResistance"));
        p.setHasWirelessCharging(rs.getBoolean("hasWirelessCharging"));
        p.setWlWeight(rs.getDouble("wlWeight"));
        p.setWlPackageContents(rs.getString("wlPackageContents"));
        
        return p;
    }
    
    
    public ArrayList<EarPhone> getProductsBySearch(String keyword) {
        ArrayList<EarPhone> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        // 🎯 SQL의 LIKE 연산자를 이용해 앞뒤 어디든 검색어가 포함되면 다 긁어옵니다.
        String sql = "SELECT * FROM earphone WHERE pName LIKE ? OR pNameKn LIKE ? OR brand LIKE ? OR brandKn LIKE ?";        
        try {
            conn = DBConnection.getConnection(); // 정석 커넥션 개통
            pstmt = conn.prepareStatement(sql);
            
            // ? 자리에 %검색어% 형태로 바인딩 처리
            String searchKey = "%" + keyword + "%";
            pstmt.setString(1, searchKey);
            pstmt.setString(2, searchKey);
            pstmt.setString(3, searchKey);
            pstmt.setString(4, searchKey);
            
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                EarPhone phone = new EarPhone();
                phone.setProductId(rs.getLong("productId"));
                phone.setpName(rs.getString("pName"));
                phone.setPrice(rs.getInt("price"));
                phone.setBrand(rs.getString("brand"));
                phone.setpImage(rs.getString("pImage"));
                phone.setCategory(rs.getString("category"));
                phone.setStock(rs.getInt("stock"));
                phone.setBrandKn(rs.getString("brandKn"));
                phone.setpNameKn(rs.getString("pNameKn"));
                // 만약 DTO에 정의해 두신 다른 컬럼 세터가 있다면 이 밑에 추가해 주세요!
                
                list.add(phone);
            }
        } catch (Exception e) {
            System.out.println("❌ 상품 검색 쿼리 실행 중 에러 발생!");
            e.printStackTrace();
        } finally {
            // 자원 반납 처리 (안전하게 역순으로 close)
            try { if (rs != null) rs.close(); } catch (Exception e) {}
            try { if (pstmt != null) pstmt.close(); } catch (Exception e) {}
            try { if (conn != null) conn.close(); } catch (Exception e) {}
        }
        
        return list;
    }
    
}