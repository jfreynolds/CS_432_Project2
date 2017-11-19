import java.util.Scanner;
import java.io.Console;

public class Driver{
	public static void main(String args[]){
		Scanner sc = new Scanner(System.in);
		Console con = System.console();
		System.out.println("enter username:");
		String user = sc.nextLine();
		String pass = new String(con.readPassword("enter password:\n"));
		instructions inst = new instructions(user, pass);

		/*inst.showTable("customers");
		System.out.println(inst.showTable("purchases"));
		System.out.println(inst.getSavings("100000"));
		System.out.println(inst.getSaleActivity("e01"));
		inst.addCustomer("e03", "firt mcgee", "607-888-8888");
		System.out.println(inst.showTable("customers"));*/
	}
}
