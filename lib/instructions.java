import java.sql.*;
import oracle.jdbc.*;
import java.math.*;
import java.io.*;
import java.awt.*;
import oracle.jdbc.pool.OracleDataSource;

public class instructions{
	OracleDataSource ds;
	Connection conn;
	public instructions(String user, String pass){
		try{
			ds = new oracle.jdbc.pool.OracleDataSource();
			System.out.println("Attempting to connect...");
			ds.setURL("jdbc:oracle:thin:@castor.cc.binghamton.edu:1521:acad111");
			conn = ds.getConnection(user, pass);
		}
		catch (SQLException ex) { System.out.println ("\n*** SQLException caught ***\n" + ex.getMessage());}
   		catch (Exception e) {System.out.println ("\n*** other Exception caught ***\n");}
	}

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

			//close the result set, statement, and the connection
			cs.close();
			return output;
		}
		catch (SQLException ex) { System.out.println ("\n*** SQLException caught ***\n" + ex.getMessage());}
   		catch (Exception e) {System.out.println ("\n*** other Exception caught ***\n");}
		return "-1";
	}

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
}
