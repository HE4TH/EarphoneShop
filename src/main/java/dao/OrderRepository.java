package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;

import dto.EarPhone;
import dto.Order;
import dto.OrderItem;
import util.DBConnection;

public class OrderRepository {

    private static OrderRepository instance = new OrderRepository();

    private OrderRepository() {}

    public static OrderRepository getInstance() {
        return instance;
    }

    // processOrder.jsp의 결제 트랜잭션(conn)에 이어서 구매 품목을 스냅샷으로 저장
    public void insertOrderItems(Connection conn, int orderId, ArrayList<EarPhone> cartList) throws Exception {
        String sql = "INSERT INTO dbo.order_items (orderId, productId, pName, price, quantity) VALUES (?, ?, ?, ?, ?)";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            for (EarPhone item : cartList) {
                pstmt.setInt(1, orderId);
                pstmt.setLong(2, item.getProductId());
                pstmt.setString(3, item.getpName());
                pstmt.setInt(4, item.getPrice());
                pstmt.setInt(5, item.getStock()); // cartList에서는 getStock()이 담긴 수량으로 쓰임
                pstmt.addBatch();
            }
            pstmt.executeBatch();
        }
    }

    public ArrayList<Order> getOrdersByMember(String mId) {
        ArrayList<Order> list = new ArrayList<>();
        String sql = "SELECT orderId, orderName, orderPhone, orderMail, zipCode, address, addressDetail, totalPrice, orderDate, orderStatus "
                + "FROM dbo.orders WHERE TRIM(mId) = ? ORDER BY orderId DESC";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, mId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSetToOrder(rs, mId));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public ArrayList<Order> getAllOrders() {
        ArrayList<Order> list = new ArrayList<>();
        String sql = "SELECT orderId, mId, orderName, orderPhone, orderMail, zipCode, address, addressDetail, totalPrice, orderDate, orderStatus "
                + "FROM dbo.orders ORDER BY orderId DESC";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {

            while (rs.next()) {
                list.add(mapResultSetToOrder(rs, rs.getString("mId")));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public ArrayList<OrderItem> getOrderItems(int orderId) {
        ArrayList<OrderItem> list = new ArrayList<>();
        String sql = "SELECT orderItemId, orderId, productId, pName, price, quantity FROM dbo.order_items WHERE orderId = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, orderId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    OrderItem item = new OrderItem();
                    item.setOrderItemId(rs.getInt("orderItemId"));
                    item.setOrderId(rs.getInt("orderId"));
                    item.setProductId(rs.getLong("productId"));
                    item.setpName(rs.getString("pName"));
                    item.setPrice(rs.getInt("price"));
                    item.setQuantity(rs.getInt("quantity"));
                    list.add(item);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // 특정 주문이 해당 회원 소유인지 + 현재 상태 조회
    public Order getOrderForOwner(int orderId, String mId) {
        String sql = "SELECT orderId, orderName, orderPhone, orderMail, zipCode, address, addressDetail, totalPrice, orderDate, orderStatus "
                + "FROM dbo.orders WHERE orderId = ? AND TRIM(mId) = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, orderId);
            pstmt.setString(2, mId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToOrder(rs, mId);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean updateOrderStatus(int orderId, String newStatus) {
        String sql = "UPDATE dbo.orders SET orderStatus = ? WHERE orderId = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, newStatus);
            pstmt.setInt(2, orderId);
            return pstmt.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // 배송준비중 상태의 본인 주문만 취소 + 재고 복원
    public boolean cancelOrder(int orderId, String mId) {
        Order order = getOrderForOwner(orderId, mId);
        if (order == null || !"배송준비중".equals(order.getOrderStatus())) {
            return false;
        }

        Connection conn = null;
        try {
            conn = DBConnection.getConnection();

            ArrayList<OrderItem> items = getOrderItems(orderId);
            String sqlRestock = "UPDATE dbo.earphone SET stock = stock + ? WHERE productId = ?";
            try (PreparedStatement pstmtRestock = conn.prepareStatement(sqlRestock)) {
                for (OrderItem item : items) {
                    pstmtRestock.setInt(1, item.getQuantity());
                    pstmtRestock.setLong(2, item.getProductId());
                    pstmtRestock.addBatch();
                }
                pstmtRestock.executeBatch();
            }

            String sqlCancel = "UPDATE dbo.orders SET orderStatus = N'취소됨' WHERE orderId = ? AND TRIM(mId) = ?";
            try (PreparedStatement pstmtCancel = conn.prepareStatement(sqlCancel)) {
                pstmtCancel.setInt(1, orderId);
                pstmtCancel.setString(2, mId);
                return pstmtCancel.executeUpdate() > 0;
            }
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            if (conn != null) try { conn.close(); } catch (Exception e) {}
        }
    }

    private Order mapResultSetToOrder(ResultSet rs, String mId) throws Exception {
        Order order = new Order();
        order.setOrderId(rs.getInt("orderId"));
        order.setmId(mId);
        order.setOrderName(rs.getString("orderName"));
        order.setOrderPhone(rs.getString("orderPhone"));
        order.setOrderMail(rs.getString("orderMail"));
        order.setZipCode(rs.getString("zipCode"));
        order.setAddress(rs.getString("address"));
        order.setAddressDetail(rs.getString("addressDetail"));
        order.setTotalPrice(rs.getInt("totalPrice"));
        order.setOrderDate(rs.getTimestamp("orderDate"));
        order.setOrderStatus(rs.getString("orderStatus"));
        return order;
    }
}
