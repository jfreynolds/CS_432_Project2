--Insert tuple with required information into 
--logs table after an insert on customers table
create or replace trigger insertCustomerTrigger
after insert on customers
for each row
begin
    insert into logs values (log#_seq.NEXTVAL, USER, 'Insert', SYSDATE, 'Customers', :NEW.cid);
end;
/

--Insert tuple with required information into
--logs table after an update of last_visit_date
--on customers table
create or replace trigger updateLastVisitTrigger
after update of last_visit_date on customers
for each row
begin
    insert into logs values (log#_seq.NEXTVAL, USER, 'Update', SYSDATE, 'Customers', :NEW.cid);
end;
/

--Insert tuple with required information into
--logs table after an update of qoh on
--products table
create or replace trigger updateQohTrigger
after update of qoh on products
for each row
begin
    insert into logs values (log#_seq.NEXTVAL, USER, 'Update', SYSDATE, 'Products', :NEW.pid);
end;
/

--Insert tuple with required information into
--logs table after an insert on supplies table.
--Then add the quantity of product supplied
--to the existing product's qoh column
--in products table
create or replace trigger insertSuppliesTrigger
after insert on supplies
for each row
begin
    insert into logs values (log#_seq.NEXTVAL, USER, 'Insert', SYSDATE, 'Supplies', :NEW.sup#);

    --Add purchased quantity to product's qoh column
    --in products table
    update products set qoh = (qoh + :NEW.quantity)
    where pid = :NEW.pid;
end;
/

--Insert tuple with required information into
--logs table after an insert on supplies table.
--Subtracts the purchase quantity from the
--qoh column of products table for the purchased product.
--Determine if the purchase brings the product's qoh
--below the threshold. If so, purchase more of that
--product from a previous supplier with the lowest
--sid column value. Finally, adds 1 to the purchasing
--customer's visits_made column and updates their 
--last_visit_date column to the most recent purchase
--if neccesary.
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

    --Subtract purchase quantity from the qoh
    --column of products table.
    select * into productRow
      from products
     where pid = :NEW.pid;

    update products set qoh = (productRow.qoh - :NEW.qty)
     where pid = :NEW.pid;

    select * into productRow
      from products
     where pid = :NEW.pid;

    --Checks to see if qoh of product is below its
    --threshold after purchase. If so, order more
    --of that product
    if(productRow.qoh_threshold > productRow.qoh) then
        dbms_output.put_line('Product ' || productRow.pid || ' has qoh below its threshold. New supply is required');

        --Quantity ordered is specified by 10 + M + qoh such that
        --M + qoh > qoh_threshold. Add 1 to satisy strictly greater
        --than condition.
        qohToSupply := (productRow.qoh_threshold - productRow.qoh + 10) + 1;

        select count(*) into supplierCount
          from supplies
         where pid = productRow.pid;

        --No supplier able to be found
        if(supplierCount < 1) then
            raise_application_error(-20007, 'Product ' || productRow.pid || ' has never been supplied before. Unable to order more from a supplier.');
        end if;

        --Gets sid of supplier that has supplied product
        --in the past. Gets the lowest sid if
        --multiple options available
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

    --Update customer's visits values if needed
    if(to_char(customerRow.last_visit_date, 'DD-MON-YYYY HH24:MI:SS') != to_char(:NEW.ptime, 'DD-MON-YYYY HH24:MI:SS')) then
        update customers set visits_made = customerRow.visits_made + 1
         where cid = customerRow.cid;

        update customers set last_visit_date = :NEW.ptime
         where cid = customerRow.cid;
    end if;

end;
/
