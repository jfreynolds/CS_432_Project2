--Run script to initialize everything needed for
--Project 2

--Create sequences (Question #1)
--Used to generate pur# when inserting into
--purchases table
create sequence pur#_seq
start with 100000
maxvalue 999999
increment by 1;

--Used to generate sup# when ordering more
--supply of a product after a purchase
create sequence sup#_seq
start with 1000
maxvalue 9999
increment by 1;

--Used to generate log# when logging an
--operation in the logs table
create sequence log#_seq
start with 10000
maxvalue 99999
increment by 1;

--Package that contains all functions/procedures
--used to answer each question in Project 2
create or replace package instructions as
function showTable(tbl in varchar2)
return sys_refcursor;

function purchase_saving(pur#Arg in purchases.pur#%type)
return sys_refcursor;

procedure monthly_sale_activities(eidArg in employees.eid%type,
                                  rc out sys_refcursor);

procedure add_customer(c_id in customers.cid%type,
                       c_name customers.name%type, 
                       c_telephone# customers.telephone#%type);

procedure add_purchase(e_id in purchases.eid%type,
                       p_id in purchases.pid%type,
                       c_id in purchases.cid%type,
                       pur_qty in purchases.qty%type);

function getProductRow(pid in products.pid%type)
return sys_refcursor;

end instructions;
/

create or replace package body instructions as

--Function for Question 2
--Returns a refcursor to a given table
--to display for user
--@param tbl: string for table name
--@return: ref cursor to result set
--of specified table
function showTable(tbl in varchar2)
return sys_refcursor
is
rc sys_refcursor;
sqlstmt varchar(255);

begin
    --Concatenate table name to select
    --statement to create needed query
    sqlstmt := 'select * from '||tbl;
    open rc for
    sqlstmt;
    return rc;
end;

--Function for Question 3
--Calculates total saving for a given purchase
--@param pur#Arg: pur# (primary key) to calculate saving
--@return: ref cursor to result set containing saving
function purchase_saving(pur#Arg in purchases.pur#%type) 
return sys_refcursor
is
rc sys_refcursor;
countPur# number(4);
begin
    --Check that the argument is not null
    if(pur#Arg is NULL) then
        raise_application_error(-20001, 'Pur# argument is null');
    end if;

    --Check to see if the pur# is present in table
    select count(*) into countPur#
      from purchases
     where purchases.pur# = pur#Arg;

    if(countPur# < 1) then
        raise_application_error(-20002, 'Pur# not present in the table');
    end if;

    --Creates result set with saving for pur#
    open rc for
    select (original_price * qty) - total_price
      from purchases
           inner join products
           on purchases.pid = products.pid
     where purchases.pur# = pur#Arg;

    return rc;
end;

--Procedure for Question 4
--Finds monthly sale information for a given employee
--@param eidArg: eid of employee
--@param rc: ref cursor to contain final result set
procedure monthly_sale_activities(eidArg in employees.eid%type,
                                  rc out sys_refcursor)
is
countEid number(4);
begin
    --Check that the argument is not null
    if(eidArg is NULL) then
        raise_application_error(-20001, 'Eid argument is null');
    end if;

    --Check to see if the eid is present in table
    select count(*) into countEid
      from employees
     where eidArg = eid;

    if(countEid < 1) then
        raise_application_error(-20002, 'Eid not present in the table');
    end if;

    --Find information needed for result set
    open rc for
    select e.eid, e.name, 
           to_char(ptime, 'MON') as Month,
           to_char(ptime, 'YYYY') as Year,
           count(*) as Total_Purchases,
           sum(qty) as Total_Qty_Sold,
           sum(total_price) as Total_Price
      from employees e
           inner join purchases pur
           on e.eid = pur.eid
     where eidArg = e.eid
     group by e.eid, e.name, to_char(ptime, 'MON'), to_char(ptime, 'YYYY');
end;

--Procedure for Question 5
--Adds new customer tuple into customers table
--@param c_id: cid of new customer
--@param c_name: name of new customer
--@param c_telephone#: telephone# of new customer
procedure add_customer(c_id in customers.cid%type,
                       c_name in customers.name%type,
                       c_telephone# in customers.telephone#%type)
is
string_arg_too_big exception;
pragma exception_init(string_arg_too_big, -12899);
begin
    --Nulla rgument checking
    if(c_id is NULL) then
        raise_application_error(-20001, 'C_id argument is null');
    elsif(c_name is NULL) then
        raise_application_error(-20001, 'C_name argument is null');
    elsif(c_telephone# is NULL) then
        raise_application_error(-20001, 'C_telephone# argument is null');
    end if;

    insert into customers values (c_id, c_name, c_telephone#, 1, SYSDATE);

exception
    --Primary key is already in the table
    when dup_val_on_index then
        raise_application_error(-20003, 'C_id argument ' || c_id || ' already exists in the table. Failed to add customer to table.');
    --One of the string arguments is larger than defined in table
    when string_arg_too_big then
        raise_application_error(-20004, 'String argument passed into procedure is too long. Failed to add customer to table.');
end;

--Procedure for Question 7
--Adds purchase tuple into purchases table
--@param e_id: eid of employee who sold new purchase
--@param p_id: pid of product sold in new purchase
--@param c_id: cid of customer who bought new purchase
--@param pur_qty: quantity of product sold in new purchase
procedure add_purchase(e_id in purchases.eid%type,
                       p_id in purchases.pid%type,
                       c_id in purchases.cid%type,
                       pur_qty in purchases.qty%type)
is
string_arg_too_big exception;
pragma exception_init(string_arg_too_big, -12899);

bad_foreign_key_value exception;
pragma exception_init(bad_foreign_key_value, -02291);

productRow products%rowtype;
totalPrice purchases.total_price%type;
discountRate discounts.discnt_rate%type;
begin
    --NULL argument checks
    if(e_id is NULL) then
        raise_application_error(-20001, 'E_id argument is null');
    elsif(p_id is NULL) then
        raise_application_error(-20001, 'P_id argument is null');
    elsif(c_id is NULL) then
        raise_application_error(-20001, 'C_id argument is null');
    elsif(pur_qty is NULL) then
        raise_application_error(-20001, 'Pur_qty argument is null');
    end if;

    select * into productRow
      from products
     where pid = p_id;

    --Not enough quantity to facilitate new purchase
    if(pur_qty > productRow.qoh) then
        raise_application_error(-20005, 'Product ' || productRow.pid || ' does not have enough stock to fulfill the purchase.');
    end if;

    --Calculate total price of new purchase
    select discnt_rate into discountRate
      from discounts
     where discnt_category = productRow.discnt_category; 

    totalPrice := pur_qty * (productRow.original_price * (1 - discountRate));

    insert into purchases values (pur#_seq.NEXTVAL, e_id, p_id, c_id, pur_qty, SYSDATE, totalPrice);
exception
    --Arguments are too big for variable size
    when string_arg_too_big then
        raise_application_error(-20004, 'String argument passed into procedure is too long. Failed to add purchase to table.');

    --No foreign key exists in other table for given argument
    when bad_foreign_key_value then
        raise_application_error(-20006, 'No parent key found for a foreign key value passed to procedure. Failed to add purchase to table.');
end;

--Helper function to get a row in products column
--based on pid
--@param pid: pid of row to fetch
--@return: ref cursor to result set containing row
--of all attributes for given pid
function getProductRow(pid in products.pid%type)
return sys_refcursor
is rc sys_refcursor;
begin
    open rc for
    select *
      from products pro
     where pid = pro.pid;

    return rc;
end;

end instructions;
/
