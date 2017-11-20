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
		System.out.println("Connected. Type help for commands");
		while(true){
			String[] cmd = sc.nextLine().split(", ");
			if(cmd[0].equals("show")){
				if(cmd.length == 2)
					System.out.println(inst.showTable(cmd[1]));
				else
					System.out.println("Usage: show, tablename");
			}
			else if(cmd[0].equals("savings")){
				if(cmd.length == 2)
					System.out.println(inst.getSavings(cmd[1]));
				else
					System.out.println("Usage: savings, purchase#");
			}
			else if(cmd[0].equals("sales")){
				if(cmd.length == 2)
					System.out.println(inst.getSaleActivity(cmd[1]));
				else
					System.out.println("Usage: sales, eid");
			}
			else if(cmd[0].equals("add")){
				if(cmd.length == 4){
					inst.addCustomer(cmd[1], cmd[2], cmd[3]);
					System.out.println("Added customer " + cmd[1]);
				}
				else
					System.out.println("Usage: add, cid, name, telephone#");
			}
			else if(cmd[0].equals("exit")){
				break;
			}
			else if(cmd[0].equals("help")){
				System.out.println("show, tablename\n\t Display contents of table specified by tablename\n");
				System.out.println("savings, purchase#\n\t Calculate and display savings for a specific purchase\n");
				System.out.println("sales, eid\n\t Report the monthly sale activity of employee specified by eid\n");
				System.out.println("add, cid, name, telephone#\n\t Add customer with cid name and telephone# to customers table\n");
				System.out.println("exit\n\t Exit the program\n");
			}
			else{
				System.out.println("Incorrect command. Type help for commands");
			}
		}

		/*inst.showTable("customers");
		System.out.println(inst.showTable("purchases"));
		System.out.println(inst.getSavings("100000"));
		System.out.println(inst.getSaleActivity("e01"));
		inst.addCustomer("e03", "firt mcgee", "607-888-8888");
		System.out.println(inst.showTable("customers"));*/
	}
}
