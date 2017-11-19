import java.sql.*;
import oracle.jdbc.*;
import java.math.*;
import java.io.*;
import java.awt.*;
import oracle.jdbc.pool.OracleDataSource;

public class instructions{
	OracleDataSource ds;
	Connection conn;
	public instructions(){
		try{
			ds = new oracle.jdbc.pool.OracleDataSource();
			System.out.println("Attempting to connect...");
			ds.setURL("jdbc:oracle:thin:@castor.cc.binghamton.edu:1521:acad111");
			conn = ds.getConnection("jnull1", "95987Vcs");
		}
		catch (SQLException ex) { System.out.println ("\n*** SQLException caught ***\n" + ex.getMessage());}
   		catch (Exception e) {System.out.println ("\n*** other Exception caught ***\n");}
	}

	public void showTable(String tblname){
		try{
			CallableStatement cs = conn.prepareCall("begin ? := instructions.showTable(?); end;");
			cs.setString(2, tblname);
			cs.registerOutParameter(1, OracleTypes.CURSOR);
			cs.execute();
			ResultSet rs = (ResultSet)cs.getObject(1);
			ResultSetMetaData rsmd = rs.getMetaData();
			int numColumns = rsmd.getColumnCount();

			// print the results
			for(int i = 1; i <= numColumns; i++){
				System.out.format("%-20s", rsmd.getColumnName(i) + " ");
			}
			System.out.println();
			while (rs.next()) {
				for(int i = 1; i <= numColumns; i++){
					System.out.format("%-20s", rs.getString(i) + " ");
				}
				System.out.println();
			}

			//close the result set, statement, and the connection
			cs.close();
		}
		catch (SQLException ex) { System.out.println ("\n*** SQLException caught ***\n" + ex.getMessage());}
   		catch (Exception e) {System.out.println ("\n*** other Exception caught ***\n");}
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
}
