--Run script to create all necessary tables
--TODO: Populate Tables

--Create sequences (Question #1)
create sequence pur#_seq
start with 100000
maxvalue 999999
increment by 1;

create sequence sup#_seq
start with 1000
maxvalue 9999
increment by 1;

create sequence log#_seq
start with 10000
maxvalue 99999
increment by 1;

drop table supplies;
drop table suppliers;
drop table purchases;
drop table products;
drop table discounts;
drop table logs;
drop table employees;
drop table customers;

create table customers
(cid char(4) primary key,
name varchar2(15),
telephone# char(12),
visits_made number(4) check (visits_made >= 1),
last_visit_date date);

create table discounts
(discnt_category number(1) primary key check(discnt_category in (1, 2, 3, 4)),
discnt_rate number(3,2) check (discnt_rate between 0 and 0.8));

create table employees
(eid char(3) primary key,
name varchar2(15),
telephone# char(12),
email varchar2(20));

create table products
(pid char(4) primary key,
name varchar2(15),
qoh number(5),
qoh_threshold number(4),
original_price number(6,2),
discnt_category number(1) references discounts);

create table purchases
(pur# number(6) primary key,
eid char(3) references employees(eid),
pid char(4) references products(pid),
cid char(4) references customers(cid),
qty number(5),
ptime date,
total_price number(7,2));

create table suppliers
(sid char(2) primary key,
name varchar2(15) not null unique,
city varchar2(15),
telephone# char(12) not null unique,
email varchar2(20) unique);

create table supplies
(sup# number(4) primary key,
pid char(4) references products(pid),
sid char(2) references suppliers(sid),
sdate date,
quantity number(5),
unique(pid, sid, sdate));

create table logs
(log# number(5) primary key,
user_name varchar2(12) not null,
operation varchar2(6) not null,
op_time date not null,
table_name varchar2(20) not null,
tuple_pkey varchar2(6)); 

insert into customers values ('c001', 'John Null', '123-456-7890', 1, SYSDATE);
insert into customers values ('c002', 'John Reynolds', '555-555-5555', 3, SYSDATE);

insert into employees values ('e01', 'Tommy Wiseau', '111-222-3333', 'tm1@bing.edu');
insert into employees values ('e02', 'Cassie Smith', '222-333-4444', 'cs1@bing.edu');

insert into discounts values (1, 0.25);

insert into products values ('p001', 'TV', 10, 2, 1000.00, 1);

insert into suppliers values ('01', 'Saberists', 'New York', '478-120-2384', 'saber@comp.com');

insert into purchases values (100000, 'e01', 'p001', 'c001', 2, SYSDATE, 1500.00);
insert into purchases values (100001, 'e01', 'p001', 'c002', 1, SYSDATE, 750.00);
insert into purchases values (100002, 'e01', 'p001', 'c002', 1, to_date('12-AUG-2017 10:34:30', 'DD-MON-YYYY HH24:MI:SS'), 750.00);
insert into purchases values (100003, 'e02', 'p001', 'c001', 1, SYSDATE, 750.00);

--Triggers for Question 6
create or replace trigger insertCustomerTrigger
after insert on customers
for each row
begin
    insert into logs values (log#_seq.NEXTVAL, USER, 'Insert', SYSDATE, 'Customers', :NEW.cid);
end;
/

create or replace trigger updateLastVisitTrigger
after update of last_visit_date on customers
for each row
begin
    insert into logs values (log#_seq.NEXTVAL, USER, 'Update', SYSDATE, 'Customers', :NEW.cid);
end;
/

create or replace trigger updateQohTrigger
after update of qoh on products
for each row
begin
    insert into logs values (log#_seq.NEXTVAL, USER, 'Update', SYSDATE, 'Products', :NEW.pid);
end;
/

create or replace trigger insertSuppliesTrigger
after insert on supplies
for each row
begin
    insert into logs values (log#_seq.NEXTVAL, USER, 'Insert', SYSDATE, 'Supplies', :NEW.sup#);

    update products set qoh = (qoh + :NEW.quantity)
    where pid = :NEW.pid;
end;
/

create or replace trigger insertPurchasesTrigger
after insert on purchases
for each row
declare
productRow products%rowtype;
qohToSupply products.qoh%type;
supplierCount number(5);
firstSid supplies.sid%type;
customerRow customers%rowtype;
begin
    dbms_output.put_line('Product ' || :NEW.pid || ' was just purchased.');

    insert into logs values (log#_seq.NEXTVAL, USER, 'Insert', SYSDATE, 'Purchases', :NEW.pur#);

    select * into productRow
      from products
     where pid = :NEW.pid;

    update products set qoh = (productRow.qoh - :NEW.qty)
     where pid = :NEW.pid;

    select * into productRow
      from products
     where pid = :NEW.pid;

    if(productRow.qoh_threshold > productRow.qoh) then
        dbms_output.put_line('Product ' || productRow.pid || ' has qoh below its threshold. New supply is required');

        qohToSupply := (productRow.qoh_threshold - productRow.qoh + 10) - 1;

        select count(*) into supplierCount
          from supplies
         where pid = productRow.pid;

        if(supplierCount < 1) then
            raise_application_error(-20007, 'Product ' || productRow.pid || ' has never been supplied before. Unable to order more from a supplier.');
        end if;

        select sid into firstSID
          from supplies
         where pid = productRow.pid
           and rownum = 1
         order by sid asc;

        insert into supplies values (sup#_seq.NEXTVAL, productRow.pid, firstSID, SYSDATE, qohToSupply);
    end if;

    select * into customerRow
      from customers
     where cid = :NEW.cid;

    if(to_char(customerRow.last_visit_date, 'DD-MON-YYYY HH24:MI:SS') != to_char(:NEW.ptime, 'DD-MON-YYYY HH24:MI:SS')) then
        update customers set visits_made = customerRow.visits_made + 1
         where cid = customerRow.cid;

        update customers set last_visit_date = :NEW.ptime
         where cid = customerRow.cid;
    end if;

end;
/

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
function showTable(tbl in varchar2)
return sys_refcursor
is
rc sys_refcursor;
sqlstmt varchar(255);
begin
sqlstmt := 'select * from '||tbl;
open rc for sqlstmt;
return rc;
end;

--Function for Question 3
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
    select count(*) into countPur# from purchases where purchases.pur# = pur#Arg;

    if(countPur# < 1) then
        raise_application_error(-20002, 'Pur# not present in the table');
    end if;

    open rc for
    select (original_price * qty) - total_price
      from purchases
           inner join products
           on purchases.pid = products.pid
     where purchases.pur# = pur#Arg;
    return rc;
end;

--Procedure for Question 4
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
    select count(*) into countEid from employees where eidArg = eid;

    if(countEid < 1) then
        raise_application_error(-20002, 'Eid not present in the table');
    end if;

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
--INT VALUE ARGUMENTS ARE CONVERTED TO STRINGS AND BEING INSERTED
--NOT SURE IF CORRECT
procedure add_customer(c_id in customers.cid%type,
                       c_name in customers.name%type,
                       c_telephone# in customers.telephone#%type)
is
string_arg_too_big exception;
pragma exception_init(string_arg_too_big, -12899);
begin
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

    if(pur_qty > productRow.qoh) then
        raise_application_error(-20005, 'Product ' || productRow.pid || ' does not have enough stock to fulfill the purchase.');
    end if;

    select discnt_rate into discountRate
      from discounts
     where discnt_category = productRow.discnt_category; 

    totalPrice := (productRow.original_price * (1 - discountRate));

    insert into purchases values (pur#_seq.NEXTVAL, e_id, p_id, c_id, pur_qty, SYSDATE, totalPrice);
exception
    when string_arg_too_big then
        raise_application_error(-20004, 'String argument passed into procedure is too long. Failed to add purchase to table.');

    when bad_foreign_key_value then
        raise_application_error(-20006, 'No parent key found for a foreign key value passed to procedure. Failed to add purchase to table.');
end;

function getProductRow(pid in products.pid%type)
return sys_refcursor
is rc sys_refcursor;
begin
    open rc for
    select *
      from products pro
     where pid = pro.pid;
end;

end instructions;
/
