import java.util.ArrayList;

import dao.EarPhoneRepository;
import dto.EarPhone;

public class EarPhoneTest {

	public static void main(String[] args) {
		// TODO Auto-generated method stub

		ArrayList<EarPhone> list = EarPhoneRepository.getInstance().getProductsByCategory("WIRED");
		
		for(int i=0; i<list.size(); i++) {
			
			System.out.println(list.get(i).getBrand() + " " +  list.get(i).getpName());
		}
		
	}

}
