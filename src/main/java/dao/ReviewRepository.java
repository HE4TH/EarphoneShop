package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import dto.Review;
import util.DBConnection;

public class ReviewRepository {

    private static ReviewRepository instance = new ReviewRepository();

    private ReviewRepository() {}

    public static ReviewRepository getInstance() {
        return instance;
    }

    public boolean insertReview(long productId, String mId, int rating, String content) {
        String sql = "INSERT INTO dbo.review (productId, mId, rating, content) VALUES (?, ?, ?, ?)";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setLong(1, productId);
            pstmt.setString(2, mId);
            pstmt.setInt(3, rating);
            pstmt.setString(4, content);

            return pstmt.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public ArrayList<Review> getReviewsByProduct(long productId) {
        ArrayList<Review> list = new ArrayList<>();
        String sql = "SELECT reviewId, productId, mId, rating, content, createDate "
                + "FROM dbo.review WHERE productId = ? ORDER BY createDate DESC";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setLong(1, productId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    Review review = new Review();
                    review.setReviewId(rs.getInt("reviewId"));
                    review.setProductId(rs.getLong("productId"));
                    review.setmId(rs.getString("mId"));
                    review.setRating(rs.getInt("rating"));
                    review.setContent(rs.getString("content"));
                    review.setCreateDate(rs.getTimestamp("createDate"));
                    list.add(review);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public int getReviewCount(long productId) {
        String sql = "SELECT COUNT(*) FROM dbo.review WHERE productId = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setLong(1, productId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    public double getAverageRating(long productId) {
        String sql = "SELECT AVG(CAST(rating AS FLOAT)) FROM dbo.review WHERE productId = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setLong(1, productId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getDouble(1);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0.0;
    }

    // 상품 목록 정렬(리뷰 많은순)에 쓰이는 productId -> 리뷰 개수 매핑 일괄 조회
    public Map<Long, Integer> getReviewCountMap() {
        Map<Long, Integer> countMap = new HashMap<>();
        String sql = "SELECT productId, COUNT(*) AS cnt FROM dbo.review GROUP BY productId";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {

            while (rs.next()) {
                countMap.put(rs.getLong("productId"), rs.getInt("cnt"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return countMap;
    }
}
