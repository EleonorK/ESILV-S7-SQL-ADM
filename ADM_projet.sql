-- Projet Advanced database management
-- Théophile NELSON, Eléonor KIOULOU, Khadija MOKHTARI - DIA 4


drop table purchaseorderdetail;
drop table purchaseorderheader;
drop table productvendor;
drop table Vendor;

CREATE TABLE Vendor 
( 
    businessentityid integer not null,  
    accountnumber VARCHAR2(20), 
    name VARCHAR2(100), 
    creditrating integer, 
    preferredvendorstatus VARCHAR2(50) CHECK( preferredvendorstatus IN ('false                ', 'true                 ') ), 
    activeflag VARCHAR2(50) CHECK( activeflag IN ('false     ', 'true      ') ), 
    purchasingwebserviceurl VARCHAR2(100), 
    modifieddate TIMESTAMP, 
    constraint vendor primary key(businessentityid) 
);

 

create table productvendor
(
    productid integer not null, 
    businessentityid integer not null, 
    averageleadtime integer, 
    standardprice float(100), 
    lastreceiptcost float(100),
    lastreceiptdate timestamp, 
    minorderqty integer, 
    maxorderqty integer, 
    onorderqty varchar2(30), 
    unitmeasurecode varchar2(30),
    modifieddate timestamp,
    constraint productvendor_pk primary key (productid, businessentityid), 
    constraint productvendor_fk2 foreign key (businessentityid) references vendor(businessentityid) ON DELETE CASCADE
);

 

create table purchaseorderheader
(
    purchaseorderid integer not null, 
    revisionnumber integer, 
    status integer, 
    employeeid integer, 
    vendorid integer,
    shipmethodid integer,
    orderdate timestamp, 
    shipdate timestamp,
    subtotal float(30), 
    taxamt float(30), 
    freight float(30),
    modifieddate timestamp,
    constraint purchaseorderheader_pk primary key (purchaseorderid)
);


create table purchaseorderdetail
(
    purchaseorderid integer not null, 
    purchaseorderdetailid integer not null, 
    duedate timestamp, 
    orderqty integer, 
    productid integer, 
    unitprice float(30), 
    receivedqty integer, 
    rejectedqty integer, 
    modifieddate timestamp,
    constraint purchaseorderdetail_pk primary key (purchaseorderid,purchaseorderdetailid),
    constraint purchaseorderdetail_fk1 foreign key(purchaseorderid) references purchaseorderheader(purchaseorderid) ON DELETE CASCADE
);

select * from purchaseorderdetail;
select * from purchaseorderheader;
select * from productvendor;
select * from Vendor;


--qA
select name , productid from vendor
inner join productvendor on vendor.businessentityid = productvendor.businessentityid
and vendor.creditrating = 5 and productvendor.productid > 500;


-- Question B (INNER JOIN) --
SELECT purchaseorderheader.purchaseorderid, purchaseorderheader.orderdate, purchaseorderdetail.purchaseorderdetailid, purchaseorderdetail.orderqty, purchaseorderdetail.productid 
FROM purchaseorderheader
INNER JOIN purchaseorderdetail
ON purchaseorderdetail.purchaseorderid = purchaseorderheader.purchaseorderid
INNER JOIN productvendor
ON purchaseorderdetail.productid = productvendor.productid
WHERE purchaseorderdetail.orderqty > 500;



-- Question B --
SELECT ph.purchaseorderid, ph.orderdate, pd.purchaseorderdetailid, pd.orderqty, pv.productid 
FROM purchaseorderheader ph, purchaseorderdetail pd, productvendor pv
WHERE pd.purchaseorderid = ph.purchaseorderid
AND pd.productid = pv.productid
AND pd.orderqty > 500;



--qC
--Display the purchase order number, vendor number, purchase order detail id,
--product number and unit price. For purchase order numbers from 1400 to 1600.
select pod.purchaseorderid, v.accountnumber, pod.purchaseorderdetailid, pod.productid, pod.unitprice from purchaseorderdetail pod
inner join productvendor pv on pv.productid = pod.productid
inner join vendor v on v.businessentityid = pv.businessentityid
and pod.purchaseorderid > = 1400 and pod.purchaseorderid < = 1600;


-- Question D --
SELECT v.name, count(ph.purchaseorderid), sum(pd.unitprice) AS costorders
FROM vendor v, purchaseorderheader ph, purchaseorderdetail pd, productvendor pv
WHERE v.businessentityid = pv.businessentityid
AND pv.productid = pd.productid
AND pd.purchaseorderid = ph.purchaseorderid
GROUP BY v.name
ORDER BY costorders DESC;


--qE
-- Display the average number of orders purchased across all vendors and the
-- average cost across all vendors
select Round(avg(orderqty), 2)orderqty,Round(avg(unitprice), 2)unitprice from purchaseorderdetail;


-- Question F --
SELECT v.name, count(pd.rejectedqty)/count(pd.receivedqty) AS rejectedreceiveditems
FROM vendor v, purchaseorderdetail pd, productvendor pv
WHERE v.businessentityid = pv.businessentityid
AND pv.productid = pd.productid
GROUP BY v.name
ORDER BY rejectedreceiveditems DESC
FETCH NEXT 10 ROWS ONLY;


-- qG
-- Display The top ten vendors with the largest orders (in terms of quantity purchased)
select v.name from vendor v
inner join productvendor pv on v.businessentityid = pv.businessentityid
group by pv.onorderqty, v.name
order by pv.onorderqty desc
FETCH FIRST 10 ROWS ONLY;



-- Question H --
SELECT pv.productid, SUM(pd.orderqty) AS qtypurchased
FROM productvendor pv, purchaseorderdetail pd
WHERE pv.productid = pd.productid
GROUP BY pv.productid
ORDER BY qtypurchased DESC
FETCH NEXT 10 ROWS ONLY;


--qI
--Propose some complex sql queries using analytic functions

-- Display the vendor's name and its max order
select v.name, pv.maxorderqty from vendor v
inner join productvendor pv on v.businessentityid = pv.businessentityid
group by v.name, pv.maxorderqty
order by pv.maxorderqty desc
FETCH FIRST 1 ROWS ONLY;
-- AJOUTER D'AUTRE EXEMPLES DE REQUETES !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!




DROP TRIGGER tg_after_update;
DROP TABLE transaction_history;
-- Question J --
CREATE TABLE transaction_history AS SELECT * FROM purchaseorderdetail;

CREATE TRIGGER tg_after_update 
AFTER UPDATE ON purchaseorderdetail
FOR EACH ROW
BEGIN
    INSERT INTO transaction_history
    SELECT * FROM purchaseorderdetail
    WHERE purchaseorderdetailid = :NEW.purchaseorderdetailid;
    
    UPDATE purchaseorderdetail
    SET modifieddate = CURRENT_TIMESTAMP
    WHERE purchaseorderdetailid = :NEW.purchaseorderdetailid;
    
    UPDATE purchaseorderheader
    SET subtotal = (SELECT SUM(unitprice) FROM purchaseorderdetail WHERE purchaseorderid = :NEW.purchaseorderid) 
    WHERE purchaseorderid = :NEW.purchaseorderid;
END;
/




DROP TRIGGER tg_before_update;

-- Question K --
CREATE TRIGGER tg_before_update
BEFORE UPDATE ON purchaseorderheader
FOR EACH ROW
DECLARE 
    new_subtotal float(30);
    subtotal_detail float(30);
BEGIN
    SELECT SUM(unitprice * orderqty)
    INTO subtotal_detail
    FROM purchaseorderdetail
    WHERE purchaseorderid = :NEW.purchaseorderid;
    
    IF new_subtotal != subtotal_detail THEN 
        RAISE_APPLICATION_ERROR(-2000, 'Cannot update purchase order subtotal: the corresponding data in the purchaseorderdetail 
                                        table is not consistent with the new value of the purchaseorderheader.subtotal column.');
    END IF;
END;
/

