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

insert into customers values ('1001', 'John Null', '123-456-7890', 1, SYSDATE);
insert into customers values ('1002', 'John Reynolds', '555-555-5555', 3, SYSDATE);

--q2 function
create or replace package instructions as
function showTable(tbl in varchar2)
return sys_refcursor;
end instructions;
/

create or replace package body instructions as
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
end instructions;
/
