##NASHVILLE HOUSING
use portfolioproject;

CREATE TABLE NashvilleHousing (
    UniqueID INT,
    ParcelID TEXT,
    LandUse VARCHAR(100),
    PropertyAddress TEXT,
    SaleDate DATE,
    SalePrice BIGINT,
    LegalReference VARCHAR(50),
    SoldAsVacant VARCHAR(5),
    OwnerName VARCHAR(100),
    OwnerAddress TEXT,
    Acreage DOUBLE,
    TaxDistrict VARCHAR(100),
    LandValue BIGINT,
    BuildingValue BIGINT,
    TotalValue BIGINT,
    YearBuilt INT,
    Bedrooms INT,
    FullBath INT,
    HalfBath INT
);

select count(*) from information_schema.columns where table_name = 'NashvilleHousing'; 

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Nashville Housing Data for Data Cleaning.csv'
into table NashvilleHousing
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

select * from nashvillehousing;


##standardizing 'saledate'
select saledate from nashvillehousing;

alter table nashvillehousing add saledate_converted date;

update nashvillehousing
set saledate_converted = convert(saledate, date);


##populate property address
select propertyaddress from nashvillehousing;

update nashvillehousing
set propertyaddress = null where propertyaddress='';

select * from nashvillehousing 
where propertyaddress is null
order by ParcelID;

select a.parcelid, a.PropertyAddress, b.parcelid, b.propertyaddress, coalesce(a.propertyaddress, b.propertyaddress) as xxx from nashvillehousing a    #doing self-join
inner join nashvillehousing b 
on a.parcelid=b.parcelid 
AND a.uniqueid != b.uniqueid
where a.propertyaddress is null;	

UPDATE nashvillehousing a   #now, setting property addresses to matching property address
INNER JOIN nashvillehousing b 
ON a.parcelid = b.parcelid 
AND a.uniqueid != b.uniqueid
SET a.propertyaddress = COALESCE(a.propertyaddress, b.propertyaddress)
WHERE a.propertyaddress IS NULL;


#Breaking down address into address, city, state, country....
select propertyaddress from nashvillehousing;

alter table nashvillehousing add property_split_city varchar(100);
alter table nashvillehousing add property_split_address text;

update nashvillehousing
set property_split_city = substr(propertyaddress, locate(',', propertyaddress)+2);

SHOW PROCESSLIST; #faced an error : ERROR 1205, so did this and re-ran above query
SELECT trx_mysql_thread_id FROM INFORMATION_SCHEMA.INNODB_TRX;
kill 12;

update nashvillehousing
set property_split_address = substring_index(propertyaddress, ',', 1);

select propertyaddress, property_split_address, property_split_city from nashvillehousing order by rand(); ##checking for errors, looks good

#doing the same thing with OwnerAddress
select owneraddress from nashvillehousing;

alter table nashvillehousing add owner_split_city varchar(100);
alter table nashvillehousing add owner_split_address text;
alter table nashvillehousing add owner_split_state varchar(50);

update nashvillehousing
set owner_split_address = substring_index(owneraddress, ',', 1); #for the address part

update nashvillehousing
set owner_split_city= substr(SUBSTRING_INDEX(owneraddress, ',', 2), locate(',',owneraddress)+2); #for the city part

update nashvillehousing
set owner_split_state= substr(SUBSTRING_INDEX(owneraddress, ',', locate(',',owneraddress)),LENGTH(SUBSTRING_INDEX(owneraddress, ',', 2))+2); #for the state part

select owneraddress, owner_split_address, owner_split_city, owner_split_State from nashvillehousing order by rand(); ##checking for errors, looks good


##Change Y and N to Yes and No in SoldAsVacant column
select Soldasvacant, count(Soldasvacant) from nashvillehousing group by soldasvacant;

select Soldasvacant, 
case
when soldasvacant="Y" then "Yes"
when soldasvacant="N" then "No"
else soldasvacant
end
from nashvillehousing;

update nashvillehousing
set soldasvacant = case
when soldasvacant="Y" then "Yes"
when soldasvacant="N" then "No"
else soldasvacant
end;

select Soldasvacant, count(Soldasvacant) from nashvillehousing group by soldasvacant; #Checking for errors, looks good



##Removing duplicates
select *, row_number() over(partition by parcelID, propertyaddress, legalreference, saleprice, saledate order by uniqueid) row_num from nashvillehousing where saledate = '2015-02-02'; #so two rows (26089 and 27111) are fully identical. So we will remove them next. Used ROW_NUMBER() to find the repetition instance of a row

#now, use the above query in a temp table and delete

CREATE TEMPORARY TABLE temp_table AS 
SELECT *, ROW_NUMBER() OVER (PARTITION BY parcelID, propertyaddress, legalreference, saleprice, saledate ORDER BY uniqueid) AS row_num
FROM nashvillehousing;

Drop temporary table temp_table;

DELETE FROM nashvillehousing 
WHERE (parcelID, propertyaddress, legalreference, saleprice, saledate, uniqueid) 
IN (SELECT parcelID, propertyaddress, legalreference, saleprice, saledate, uniqueid 
FROM temp_table WHERE row_num > 1);

#Done, removed duplicates



#Delete unused columns
select * from nashvillehousing;

alter table nashvillehousing
drop column owneraddress, drop column propertyaddress, 	drop column taxdistrict, drop column saledate;