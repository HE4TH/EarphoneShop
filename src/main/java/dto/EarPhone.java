package dto;

public class EarPhone {
	
	
	private Long productId;            		// 상품 고유 식별 번호
    private String pName;               	// 상품명
    private String pNameKn;
    private int price;                  	// 가격
    private String brand;               	// 브랜드/제조사
    private String brandKn;
    private int stock;                  	// 재고량
    private String category;            	// 카테고리 ("WIRED" 또는 "WIRELESS")
    private String pImage;              	// 상품 이미지 파일명
    private String pDescriptionImage1;
    private String pDescriptionImage2;
	
	private String wDriverType; 			// 유선 드라이버
	private int wImpedance; 				// 유선 저항값
	private String wFrequencyResponse; 		// 유선 주파수
	private int wSensitivity; 				// 유선 감도
	private String wPlugType;				// 유선 플러그 타입
	private boolean isWiredDetachable; 		// 케이블 탈착 여부
	private boolean hasWiredMic; 			// 유선 마이크 여부
	private String wPackageContents; 		// 유선 구성품
	
	private String wlDriverType; 			// 무선 드라이버
	private String wlBluetoothVersion; 		// 무선 블루투스버전
	private String wlSupportedCodecs; 		// 무선 지원 코덱
	private String wlBatteryLife; 			// 무선 배터리 타임
	private boolean isWirelessAncSupported; // 노이즈 캔슬링 여부
	private String wlWaterResistance; 		// 무선 방수 등급
	private boolean hasWirelessCharging; 	// 무선 충전 여부
	private double wlWeight; 				// 무선 무게
	private String wlPackageContents; 		// 무선 구성품
	
	public EarPhone() {
		
	}
	
	public EarPhone(long productId, String pName, int price) {
		this.productId = productId;
		this.pName = pName;
		this.price = price;
	}

	public Long getProductId() {
		return productId;
	}

	public void setProductId(Long productId) {
		this.productId = productId;
	}

	public String getpName() {
		return pName;
	}

	public void setpName(String pName) {
		this.pName = pName;
	}

	public int getPrice() {
		return price;
	}

	public void setPrice(int price) {
		this.price = price;
	}

	public String getBrand() {
		return brand;
	}

	public void setBrand(String brand) {
		this.brand = brand;
	}

	public int getStock() {
		return stock;
	}

	public void setStock(int stock) {
		this.stock = stock;
	}

	public String getCategory() {
		return category;
	}

	public void setCategory(String category) {
		this.category = category;
	}

	public String getpImage() {
		return pImage;
	}

	public void setpImage(String pImage) {
		this.pImage = pImage;
	}

	public String getwDriverType() {
		return wDriverType;
	}

	public void setwDriverType(String wDriverType) {
		this.wDriverType = wDriverType;
	}

	public int getwImpedance() {
		return wImpedance;
	}

	public void setwImpedance(int wImpedance) {
		this.wImpedance = wImpedance;
	}

	public String getwFrequencyResponse() {
		return wFrequencyResponse;
	}

	public void setwFrequencyResponse(String wFrequencyResponse) {
		this.wFrequencyResponse = wFrequencyResponse;
	}

	public int getwSensitivity() {
		return wSensitivity;
	}

	public void setwSensitivity(int wSensitivity) {
		this.wSensitivity = wSensitivity;
	}

	public String getwPlugType() {
		return wPlugType;
	}

	public void setwPlugType(String wPlugType) {
		this.wPlugType = wPlugType;
	}

	public boolean isWiredDetachable() {
		return isWiredDetachable;
	}

	public void setWiredDetachable(boolean isWiredDetachable) {
		this.isWiredDetachable = isWiredDetachable;
	}

	public boolean isHasWiredMic() {
		return hasWiredMic;
	}

	public void setHasWiredMic(boolean hasWiredMic) {
		this.hasWiredMic = hasWiredMic;
	}

	public String getwPackageContents() {
		return wPackageContents;
	}

	public void setwPackageContents(String wPackageContents) {
		this.wPackageContents = wPackageContents;
	}

	public String getWlDriverType() {
		return wlDriverType;
	}

	public void setWlDriverType(String wlDriverType) {
		this.wlDriverType = wlDriverType;
	}

	public String getWlBluetoothVersion() {
		return wlBluetoothVersion;
	}

	public void setWlBluetoothVersion(String wlBluetoothVersion) {
		this.wlBluetoothVersion = wlBluetoothVersion;
	}

	public String getWlSupportedCodecs() {
		return wlSupportedCodecs;
	}

	public void setWlSupportedCodecs(String wlSupportedCodecs) {
		this.wlSupportedCodecs = wlSupportedCodecs;
	}

	public String getWlBatteryLife() {
		return wlBatteryLife;
	}

	public void setWlBatteryLife(String wlBatteryLife) {
		this.wlBatteryLife = wlBatteryLife;
	}

	public boolean isWirelessAncSupported() {
		return isWirelessAncSupported;
	}

	public void setWirelessAncSupported(boolean isWirelessAncSupported) {
		this.isWirelessAncSupported = isWirelessAncSupported;
	}

	public String getWlWaterResistance() {
		return wlWaterResistance;
	}

	public void setWlWaterResistance(String wlWaterResistance) {
		this.wlWaterResistance = wlWaterResistance;
	}

	public boolean isHasWirelessCharging() {
		return hasWirelessCharging;
	}

	public void setHasWirelessCharging(boolean hasWirelessCharging) {
		this.hasWirelessCharging = hasWirelessCharging;
	}

	public double getWlWeight() {
		return wlWeight;
	}

	public void setWlWeight(double wlWeight) {
		this.wlWeight = wlWeight;
	}

	public String getWlPackageContents() {
		return wlPackageContents;
	}

	public void setWlPackageContents(String wlPackageContents) {
		this.wlPackageContents = wlPackageContents;
	}

	public String getpDescriptionImage1() {
		return pDescriptionImage1;
	}

	public void setpDescriptionImage1(String pDescriptionImage1) {
		this.pDescriptionImage1 = pDescriptionImage1;
	}

	public String getpDescriptionImage2() {
		return pDescriptionImage2;
	}

	public void setpDescriptionImage2(String pDescriptionImage2) {
		this.pDescriptionImage2 = pDescriptionImage2;
	}

	public String getpNameKn() {
		return pNameKn;
	}

	public void setpNameKn(String pNameKn) {
		this.pNameKn = pNameKn;
	}

	public String getBrandKn() {
		return brandKn;
	}

	public void setBrandKn(String brandKn) {
		this.brandKn = brandKn;
	}
	
	
	
}
