public class Driver{
	public static void main(String args[]){
		instructions inst = new instructions();
		inst.showTable("customers");
		inst.showTable("purchases");
		System.out.println(inst.getSavings("100000"));
	}
}
