
drop table market_price;
drop table exchange;
drop table employee;
drop table company;
drop table investor;

create table investor(
investor_id number primary key,
name varchar(30) not null,
account_balance number,
city varchar(15)
);

create table company(
company_code varchar(10) primary key,
name varchar(35) not null,
sector varchar(20),
total_volume number
);

create table employee(
employee_id number primary key,
name varchar(10) not null,
city varchar(15)
);

create table market_price(
company_code varchar(10),
openning_price number(6,2) not null,
current_price number(6,2),
percentage number(6,2),
volume_traded number,
value_traded number,
foreign key(company_code) references company on delete cascade
);

create table exchange(
investor_id number,
company_code varchar(10),
employee_id number,
volume number,
buy_price number(6,2),
foreign key(investor_id) references investor on delete cascade,
foreign key(company_code) references company on delete cascade,
foreign key(employee_id) references employee on delete cascade
);

describe investor;
describe employee;
describe company;
describe market_price;
describe exchange;

insert into investor values(1001,'Mohammad Nayeem Islam',20000,'Dhaka');
insert into investor values(1002,'Mohammad Shahriar Kabir',50000,'Dhaka');
insert into investor values(1003,'Fatema Islam',12000,'Chittagong');
insert into investor values(1004,'Habibur Rahman',54000,'Chittagong');
insert into investor values(1005,'Naima Sharkar',34000,'Dhaka');
insert into investor values(1006,'Bilkis Hatun',13000,'Dhaka');

insert into company values('ACI','Aci Limited','pharmacy',2000);
insert into company values('ALARABANK','Al-arafa Islami Bank','bank',8000);
insert into company values('BDTHAI','BDThai Aluminium','crookeries',4000);
insert into company values('BDCOM','BDCom Online Limited','internet',2000);
insert into company values('CITYBANK','City Bank','bank',3200);
insert into company values('FARCHEM','Far Chemical Industries Ltd.','pharmacy',2500);
insert into company values('GPHISPAT','GPH Ispat Ltd.','industry',2090);
insert into company values('ISLAMIBANK','Islami Bank','bank',4500);
insert into company values('OLYMPIC','Olympic Industries','industry',8700);
insert into company values('PADMAOIL','Padma Oil Co.','pharmacy',7000);
insert into company values('PRIMELIFE','Prime Life Insurance Ltd.','insurance',9500);
insert into company values('RAHIMAFOOD','Rahima Food','food',6700);
insert into company values('SPCL','Shahjibazar Power Co. Ltd.','fuel',5000);
insert into company values('TITASGAS','Titas Gas Transmission Co. Ltd.','fuel',2100);

insert into employee values(201,'Jahangir','Maymonsingh');
insert into employee values(202,'Jewel','Rangpur');
insert into employee values(203,'Abdur','Narayongong');

insert into exchange values(1001,'BDTHAI',201,200,26.30);
insert into exchange values(1002,'SPCL',202,400,48.00);
insert into exchange values(1003,'BDTHAI',203,200,32.98);
insert into exchange values(1004,'PRIMELIFE',201,150,29.50);
insert into exchange values(1001,'PADMAOIL',201,330,56.70);
insert into exchange values(1005,'GPHISPAT',202,500,85.60);

insert into market_price values('BDTHAI',20.00,32.00,1.30,500,10400);
insert into market_price values('SPCL',50.00,45,0.45,750,25700);
insert into market_price values('OLYMPIC',66.00,34,2.19,340,9590);
insert into market_price values('PRIMELIFE',32.00,19,0.95,120,2289);
insert into market_price values('PADMAOIL',33.00,43.65,3.33,798,35000);
insert into market_price values('GPHISPAT',99.00,102.20,0.78,150,15100);
commit;
select * from investor;
select * from employee;
select * from company;
select * from exchange;
select * from market_price;

select * from market_price where rownum<=10 order by value_traded desc;

select company_code,total_volume from company where company_code='OLYMPIC';

SELECT c.company_code,c.name,c.total_volume from company c where c.company_code in (SELECT m.company_code FROM market_price m WHERE m.value_traded>20000);

select investor_id,name from investor where investor_id=1002 union select i.investor_id,i.name from investor i where i.investor_id=1003;


select i.name,i.account_balance,e.company_code,e.employee_id,e.volume,e.buy_price from investor i join exchange e using(investor_id);

select i.name,i.account_balance,e.company_code,e.employee_id,e.volume from investor i right outer join exchange e using(investor_id);

select c.company_code,c.total_volume,m.current_price,m.value_traded,m.volume_traded from company c left outer join  market_price m on c.company_code=m.company_code;

alter table employee rename column name to employee_name;

alter table investor modify (name varchar(28));



-------------------------- procedure to share exchange-------------------------------------------
set serveroutput on;
create or replace procedure transact(buyer_id number,seller_id number,company_name company.company_code%type,quantity number,price number)
as
product number;
begin
product := price*quantity;
update investor set account_balance=account_balance+product where investor_id=seller_id;
update investor set account_balance=account_balance-product where investor_id=buyer_id;
update market_price set volume_traded=volume_traded+quantity,value_traded=value_traded+product where company_code=company_name;
DBMS_OUTPUT.PUT_LINE('Transaction complete!');

update exchange set investor_id=buyer_id,buy_price=price
where investor_id=seller_id and company_code=company_name and volume=quantity;
DBMS_OUTPUT.PUT_LINE('Update complete!');

end;
/

create or replace procedure trade(buyer_id number,seller_id number,company_name company.company_code%type,quantity number)
as
price market_price.current_price%type;
product number;
balance number;
begin
select current_price into price
from market_price where company_code=company_name;
select account_balance into balance from investor where investor_id=buyer_id;

product := price*quantity;

if balance>product then
transact(buyer_id,seller_id,company_name,quantity,price);
else DBMS_OUTPUT.PUT_LINE('Not enough money to buy the share!');
end if;

end;
/
	--------------------------- trigger -----------------------------
	
CREATE OR REPLACE TRIGGER check_balance BEFORE insert ON investor
FOR EACH ROW
BEGIN
  IF :new.account_balance<500 THEN
  RAISE_APPLICATION_ERROR(-20000,'Not enough money invested to become an investor');
END IF;
END;
/

CREATE OR REPLACE TRIGGER check_balance after update ON investor
FOR EACH ROW
BEGIN
  IF :new.account_balance<100 THEN
  RAISE_APPLICATION_ERROR(-20000,'Your account balance is running low');
END IF;
END;
/

create or replace trigger change_per before update on market_price
for each row
declare
sub number;
product number;
begin
if :new.current_price > :old.current_price then
sub := :new.current_price - :old.current_price;
else
sub :=  :old.current_price - :new.current_price;
end if;
product := sub * 100;
:new.percentage := product / :old.current_price;
end;
/

---------------------------  function ------------------------------------

create or replace function avg_value_traded return number is
average market_price.value_traded%type;
begin
select avg(value_traded) into average from market_price;
return average;
end;
/

create or replace function max_volume_traded return number is
maximum market_price.volume_traded%type;
begin
select max(volume_traded) into maximum from market_price;
return maximum;
end;
/
--------------------------- cursor--------------------------

declare
cursor find is select * from company where sector='pharmacy';
find_cur find%rowtype;
begin
open find;
loop
fetch find into find_cur;
exit when find%notfound;
dbms_output.put_line('Trade code: '||find_cur.company_code||' Name: '||find_cur.name||' total volume: '||find_cur.total_volume);
end loop;
close find;

end;
/
---------------------------------------output testing-------------------------------------------------------------
execute trade(1004,1002,'SPCL',400);
select * from exchange;
select * from market_price;
select * from investor;


begin
dbms_output.put_line('total money traded on average: '||avg_value_traded);
end;
/

begin
dbms_output.put_line('maximum trade done today: '||max_volume_traded);
end;
/

update market_price set current_price=34 where company_code='BDTHAI';
select * from market_price;

