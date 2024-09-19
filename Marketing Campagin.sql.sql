## Check out the cardinality of following columns:

-- Different color segments (categories) provided by the company.

SELECT COUNT(DISTINCT Item_Category) 
FROM Item;

--  States where the company is currently delivering its products and services.


SELECT COUNT(DISTINCT State) 
FROM CityData;

-- Different Coupon Types that are offered.

SELECT COUNT(DISTINCT couponType) 
FROM CouponMapping;

-- Different Order Types.

SELECT COUNT(DISTINCT OrderType) 
FROM CustomerTransactionData;

## Check which of the following options are correct in below questions.Identify total number of sales (transactions) happened by.

--  Yearly basis

SELECT YEAR(PurchaseDate),

COUNT(Trans_Id) AS Total_Trans

FROM CustomerTransactionData

GROUP BY YEAR(PurchaseDate);

-- Quarterly basis

SELECT QUARTER(PurchaseDate),

COUNT(Trans_Id) AS Total_Trans

FROM CustomerTransactionData

GROUP BY QUARTER(PurchaseDate);

--- Yearly and Monthly basis

SELECT YEAR(PurchaseDate), MONTH(PurchaseDate),COUNT(Trans_Id) AS Total_count 
FROM CustomerTransactionData
GROUP BY YEAR(PurchaseDate), MONTH(PurchaseDate)
ORDER BY YEAR(PurchaseDate), MONTH(PurchaseDate);

## Identify the total purchase order by:

---  Product category

SELECT SUM(PurchasingAmt) AS Total_Sales, I.Item_Category
FROM Item I 
JOIN CustomerTransactionData C ON I.Item_id = C.Item_id
GROUP BY I.Item_Category; 

--- Yearly and Quarterly basis

SELECT SUM(PurchasingAmt) AS Total_Purchase,YEAR(PurchaseDate),QUARTER(PurchaseDate)
FROM CustomerTransactionData
GROUP BY YEAR(PurchaseDate),QUARTER(PurchaseDate);

-- Order Type

SELECT OrderType,
SUM(PurchasingAmt) AS Total_Sales
FROM CustomerTransactionData
GROUP BY OrderType;

-- City Tier 

SELECT Ci.CityTier , SUM(CT.PurchasingAmt) AS Total_Sales
FROM CustomerTransactionData CT
JOIN Customer C ON C.Customer_Id = CT.Cust_Id
JOIN CityData Ci ON C.City_Id = Ci.City_Id
GROUP BY Ci.CityTier;


## Understanding lead conversion :
# Company wants to understand the customer path to conversion as a potential purchaser based on our campaigns.

--  Identify the total number of transactions with campaign coupon vs total number of transactions without campaign coupon. 

SELECT 'Without Coupons' AS CampaignCoupons,
COUNT(*) AS TotalTransactions FROM CustomerTransactionData
WHERE campaign_id IS NULL
UNION ALL
SELECT 'With Coupons' AS CampaignCoupons,
COUNT(*) AS TotalTransactions FROM CustomerTransactionData
WHERE campaign_id IS NOT NULL;

--- Identify the number of customers with first purchase done with or without campaign coupons .

SELECT COUNT(coupon_id) AS TotalCustomersFirstPurchaseWcoupon, COUNT(*) - COUNT(coupon_id) AS TotalCustomersFirstPurchaseWithoutcoupon
FROM CustomerTransactionData
WHERE Trans_Id IN (
SELECT
FIRST_VALUE(Trans_Id) OVER(PARTITION BY Cust_Id ORDER BY PurchaseDate RANGE BETWEEN
UNBOUNDED PRECEDING AND
UNBOUNDED FOLLOWING) AS trans_id
FROM CustomerTransactionData);

## Understanding company growth and decline
# Marketing team is interested in understanding the growth and decline pattern of the company in terms of new leads or sales amount by the customers.

-- Identify the total growth on an year by year basis
--  Based on Quantity of paint that's sold. Identify the correct option:

SELECT *
FROM (
SELECT year_purchase, Total_Quantity AS Total_Quantity_2022, 
LAG(Total_Quantity) OVER(ORDER BY year_purchase) AS pastoffset_1,
LAG(Total_Quantity,2) OVER(ORDER BY year_purchase) AS pastoffset_2,
LAG(Total_Quantity,3) OVER(ORDER BY year_purchase) AS pastoffset_3
FROM(
SELECT EXTRACT(YEAR FROM PurchaseDate) AS year_purchase,
SUM(Quantity) AS Total_Quantity 
FROM CustomerTransactionData
  WHERE EXTRACT(YEAR FROM PurchaseDate) < 2023
GROUP BY EXTRACT(YEAR FROM PurchaseDate)) AS T) AS T
WHERE year_purchase = 2022;

-- Based on amount of paint that's sold. Identify the correct option.

SELECT *
FROM (
SELECT year_purchase, Total_Purchase AS Total_Purchase_2022, 
LAG(Total_Purchase) OVER(ORDER BY year_purchase) AS pastoffset_1,
LAG(Total_Purchase,2) OVER(ORDER BY year_purchase) AS pastoffset_2,
LAG(Total_Purchase,3) OVER(ORDER BY year_purchase) AS pastoffset_3
FROM(
SELECT EXTRACT(YEAR FROM PurchaseDate) AS year_purchase,
SUM(PurchasingAmt) AS Total_Purchase
FROM CustomerTransactionData
  WHERE EXTRACT(YEAR FROM PurchaseDate) < 2023
GROUP BY EXTRACT(YEAR FROM PurchaseDate)) AS T) AS T
WHERE year_purchase = 2022;

-- Customers that's acquired [New + Repeated].

SELECT *
FROM (
SELECT year_purchase, NewUsers AS NewUsers_2022, 
LAG(NewUsers) OVER(ORDER BY year_purchase) AS pastoffset_1,
LAG(NewUsers,2) OVER(ORDER BY year_purchase) AS pastoffset_2,
LAG(NewUsers,3) OVER(ORDER BY year_purchase) AS pastoffset_3
FROM(
SELECT EXTRACT(YEAR FROM PurchaseDate) AS year_purchase,
COUNT(DISTINCT Cust_Id) AS NewUsers
FROM CustomerTransactionData
  WHERE EXTRACT(YEAR FROM PurchaseDate) < 2023
GROUP BY EXTRACT(YEAR FROM PurchaseDate)) AS T) AS T
WHERE year_purchase = 2022;

-- Segregate the above By OrderType

SELECT *
FROM (
SELECT year_purchase, OrderType,
  NewUsers AS NewUsers_2022, 
LAG(NewUsers) OVER(PARTITION BY OrderType ORDER BY year_purchase) AS pastoffset_1,
LAG(NewUsers,2) OVER(PARTITION BY OrderType ORDER BY year_purchase) AS pastoffset_2,
LAG(NewUsers,3) OVER(PARTITION BY OrderType ORDER BY year_purchase) AS pastoffset_3
FROM(
SELECT EXTRACT(YEAR FROM PurchaseDate) AS year_purchase,
  OrderType,
COUNT(DISTINCT Cust_Id) AS NewUsers
FROM CustomerTransactionData
  WHERE EXTRACT(YEAR FROM PurchaseDate) < 2023
GROUP BY EXTRACT(YEAR FROM PurchaseDate), OrderType) AS T) AS T
WHERE year_purchase = 2022;

## Market basket analysis

# A market basket analysis is defined as a customer’s overall buying pattern of different sets of products. Essentially, the marketing team wants to understand customer purchasing patterns. 
# Their proposal is if they promote the products in their next campaign, which are bought a couple of times together, then this will increase the revenue for the company.

-- Please identify the dates when the same customer has purchased some product from the company outlets.

SELECT C1.Cust_Id, C1.PurchaseDate AS PurchaseDate1, C2.PurchaseDate AS PurchaseDate 
FROM CustomerTransactionData AS C1 
INNER JOIN CustomerTransactionData AS C2 ON C1.Cust_Id = C2.Cust_Id 
WHERE C1.Trans_Id != C2.Trans_Id AND C1.OrderType = C2.OrderType AND C1.item_id != C2.item_id;

-- Out of the first query where you have captured a repeated set of customers, please identify the same combination of products coming at least thrice sorted in descending order of their appearance.

SELECT CONCAT_WS(",", C1.item_id, C2.item_id) AS Item_Combination,
COUNT(*) AS TotalTransaction
FROM CustomerTransactionData AS C1
INNER JOIN CustomerTransactionData AS C2
ON C1.Cust_Id = C2.Cust_Id
WHERE C1.Trans_Id != C2.Trans_Id 
AND C1.OrderType = C2.OrderType
AND C1.item_id != C2.item_id
GROUP BY CONCAT_WS(",", C1.item_id, C2.item_id)
HAVING COUNT(*) >= 3
ORDER BY COUNT(*) DESC;


-- Out of the above combinations that are coming thrice for repeated sets of customers, please check which of these combinations are popular in the household sector.

SELECT C1.OrderType, CONCAT_WS(",", C1.item_id, C2.item_id) AS Item_Combination,
COUNT(*) AS TotalTransaction
FROM CustomerTransactionData AS C1
INNER JOIN CustomerTransactionData AS C2
ON C1.Cust_Id = C2.Cust_Id
WHERE C1.Trans_Id != C2.Trans_Id 
AND C1.OrderType = C2.OrderType
AND C1.item_id != C2.item_id
GROUP BY C1.OrderType, CONCAT_WS(",", C1.item_id, C2.item_id)
HAVING COUNT(*) >= 3
ORDER BY COUNT(*) DESC;





