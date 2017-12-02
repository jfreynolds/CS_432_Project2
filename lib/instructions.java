import java.sql.*;
import oracle.jdbc.*;
import java.math.*;
import java.io.*;
import java.awt.*;
import oracle.jdbc.pool.OracleDataSource;

public class instructions{
	OracleDataSource ds;
	Connection conn;
	public boolean connected = true;

	//Instructions default constructor
	public instructions(){
		connected = false;
	}

	//Instructions constructor taking login info
	public instructions(String user, String pass){
		try{
			ds = new oracle.jdbc.pool.OracleDataSource();
			System.out.println("Attempting to connect...");
			ds.setURL("jdbc:oracle:thin:@castor.cc.binghamton.edu:1521:acad111");
			conn = ds.getConnection(user, pass);
			connected = true;
		}
		catch (SQLException ex) {connected = false; System.out.println ("\n*** SQLException caught ***\n" + ex.getMessage());}
   		catch (Exception e) {connected = false; System.out.println ("\n*** other Exception caught ***\n");}
	}

	//Print a table specified by name
	public String showTable(String tblname){
		try{
			CallableStatement cs = conn.prepareCall("begin ? := instructions.showTable(?); end;");
			cs.setString(2, tblname);
			cs.registerOutParameter(1, OracleTypes.CURSOR);
			cs.execute();
			ResultSet rs = (ResultSet)cs.getObject(1);
			ResultSetMetaData rsmd = rs.getMetaData();
			int numColumns = rsmd.getColumnCount();
			String output = "";

			// print the column headers
			for(int i = 1; i <= numColumns; i++){
				output += String.format("%-20s", rsmd.getColumnName(i) + " ");
			}
			output += "\n";
			//print the row data
			while (rs.next()) {
				for(int i = 1; i <= numColumns; i++){
					output += String.format("%-20s", rs.getString(i) + " ");
				}
				output += "\n";
			}

			//close the result set, statement, and the connection
			cs.close();
			return output;
		}
		catch (SQLException ex) { System.out.println ("\n*** SQLException caught ***\n" + ex.getMessage());}
   		catch (Exception e) {System.out.println ("\n*** other Exception caught ***\n");}
		return "-1";
	}

	//Calculate savings for a particular purchase
	public double getSavings(String pur){
		try{
			CallableStatement cs = conn.prepareCall("begin ? := instructions.purchase_saving(?); end;");
			cs.setString(2, pur);
			cs.registerOutParameter(1, OracleTypes.CURSOR);
			cs.execute();
			ResultSet rs = (ResultSet)cs.getObject(1);
			rs.next();
			return rs.getDouble(1);
		}
		catch (SQLException ex) { System.out.println ("\n*** SQLException caught ***\n" + ex.getMessage());}
   		catch (Exception e) {System.out.println ("\n*** other Exception caught ***\n");}
		return -1;
	}

	//Calculate saleActivity for a particular employee for each month
	public String getSaleActivity(String id){
		try{
			String sql = "begin instructions.monthly_sale_activities(?, ?); end;";
			CallableStatement cs = conn.prepareCall(sql);
			cs.setString(1, id);
			cs.registerOutParameter(2, OracleTypes.CURSOR);
			cs.execute();
			ResultSet rs = (ResultSet)cs.getObject(2);
			ResultSetMetaData rsmd = rs.getMetaData();
			int numColumns = rsmd.getColumnCount();
			String output = "";
			// print the results
			for(int i = 1; i <= numColumns; i++){
				output += String.format("%-20s", rsmd.getColumnName(i) + " ");
			}
			output += "\n";
			while (rs.next()) {
				for(int i = 1; i <= numColumns; i++){
					output += String.format("%-20s", rs.getString(i) + " ");
				}
				output += "\n";
			}
			cs.close();
			return output;
		}
		catch (SQLException ex) { System.out.println ("\n*** SQLException caught ***\n" + ex.getMessage());}
   		catch (Exception e) {System.out.println ("\n*** other Exception caught ***\n");}
		return "-1";
	}

	//Add a customer to the Customer table
	public void addCustomer(String cid, String name, String telephone){
		try{
			String sql = "begin instructions.add_customer(?, ?, ?); end;";
			CallableStatement cs = conn.prepareCall(sql);
			cs.setString(1, cid);
			cs.setString(2, name);
			cs.setString(3, telephone);
			cs.execute();
			cs.close();
		}
		catch (SQLException ex) { System.out.println ("\n*** SQLException caught ***\n" + ex.getMessage());}
   		catch (Exception e) {System.out.println ("\n*** other Exception caught ***\n");}
	}

	//Add a purchase to the purchase table
	public String addPurchase(String eid, String pid, String cid, String qty){
		try{
			//setting up callable statements
			String purSql = "begin instructions.add_purchase(?, ?, ?, ?); end;";
			String proSql = "begin ? := instructions.getProductRow(?); end;";
			CallableStatement purcs = conn.prepareCall(purSql);
			purcs.setString(1, eid);
			purcs.setString(2, pid);
			purcs.setString(3, cid);
			purcs.setString(4, qty);
			CallableStatement procs = conn.prepareCall(proSql);
			procs.registerOutParameter(1, OracleTypes.CURSOR);
			procs.setString(2, pid);
			
			//getting initial quantity
			procs.execute();
			ResultSet rs = (ResultSet)procs.getObject(1);
			ResultSetMetaData rsmd = rs.getMetaData();
			int numColumns = rsmd.getColumnCount();
			String output = "";
			int qohIndex, thrIndex;
			qohIndex = thrIndex = -1;
			//find the qoh and qoh_threshold columns
			for(int i = 1; i < numColumns; i++){
				if(rsmd.getColumnName(i).equals("QOH"))
					qohIndex = i;
				if(rsmd.getColumnName(i).equals("QOH_THRESHOLD"))
					thrIndex = i;
			}
			
			//compare qty ordered to qoh and qoh threshold
			rs.next();
			int qoh = Integer.parseInt(rs.getString(qohIndex));
			int thr = Integer.parseInt(rs.getString(thrIndex));
			if((qoh - Integer.parseInt(qty)) < thr){
				output += "Quantity on hand is less than the threshold, ordering from supplier\n";
			}

			//execute purchase and get new quantity.
			purcs.execute();
			procs.execute();
			rs = (ResultSet)procs.getObject(1);
			rs.next();
			if(!output.equals(""))
				output += "Purchase complete. New quantity on hand is " + rs.getString(qohIndex);
			if(output.equals(""))
				output += "Purchase complete.";
			return output; 
		}
		catch (SQLException ex) { System.out.println ("\n*** SQLException caught ***\n" + ex.getMessage());}
   		catch (Exception e) {System.out.println ("\n*** other Exception caught ***\n");}
		return "-1";
	}
}
