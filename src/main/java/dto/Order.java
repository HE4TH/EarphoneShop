package dto;

import java.sql.Timestamp;

public class Order {

    private int orderId;
    private String mId;
    private String orderName;
    private String orderPhone;
    private String orderMail;
    private String zipCode;
    private String address;
    private String addressDetail;
    private int totalPrice;
    private Timestamp orderDate;
    private String orderStatus;

    public int getOrderId() { return orderId; }
    public void setOrderId(int orderId) { this.orderId = orderId; }

    public String getmId() { return mId; }
    public void setmId(String mId) { this.mId = mId; }

    public String getOrderName() { return orderName; }
    public void setOrderName(String orderName) { this.orderName = orderName; }

    public String getOrderPhone() { return orderPhone; }
    public void setOrderPhone(String orderPhone) { this.orderPhone = orderPhone; }

    public String getOrderMail() { return orderMail; }
    public void setOrderMail(String orderMail) { this.orderMail = orderMail; }

    public String getZipCode() { return zipCode; }
    public void setZipCode(String zipCode) { this.zipCode = zipCode; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getAddressDetail() { return addressDetail; }
    public void setAddressDetail(String addressDetail) { this.addressDetail = addressDetail; }

    public int getTotalPrice() { return totalPrice; }
    public void setTotalPrice(int totalPrice) { this.totalPrice = totalPrice; }

    public Timestamp getOrderDate() { return orderDate; }
    public void setOrderDate(Timestamp orderDate) { this.orderDate = orderDate; }

    public String getOrderStatus() { return orderStatus; }
    public void setOrderStatus(String orderStatus) { this.orderStatus = orderStatus; }
}
