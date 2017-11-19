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

create or replace trigger insertPurchasesTrigger
after insert on purchases
for each row
begin
    insert into logs values (log#_seq.NEXTVAL, USER, 'Insert', SYSDATE, 'Purchases', :NEW.pur#);
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

create or replace package instructions as
function showTable(tbl in varchar2)
return sys_refcursor;

function purchase_saving(pur# in purchases.pur#%type)
return number;

procedure monthly_sale_activities(eidArg in employees.eid%type,
                                  rc out sys_refcursor);

procedure add_customer(c_id in customers.cid%type,
                       c_name customers.name%type, 
                       c_telephone# customers.telephone#%type);
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
function purchase_saving(pur# in purchases.pur#%type) 
return number
is
saving number(10,2);
countPur# number(4);
begin
    --Check that the argument is not null
    if(pur# is NULL) then
        raise_application_error(-20001, 'Pur# argument is null');
    end if;

    --Check to see if the pur# is present in table
    select count(*) into countPur# from purchases where purchases.pur# = pur#;

    if(countPur# < 1) then
        raise_application_error(-20002, 'Pur# not present in the table');
    end if;

    select (original_price * qty) - total_price into saving
      from purchases
           inner join products
           on purchases.pid = products.pid
     where purchases.pur# = pur#;
    return saving;
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

end instructions;
/
