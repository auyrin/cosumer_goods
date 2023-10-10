/* request 1 */
SELECT 
    market
FROM
    gdb023.dim_customer
WHERE
    region = 'APAC'
        AND customer = 'Atliq Exclusive';

/* request 2 */
SELECT 
    COUNT(DISTINCT CASE
            WHEN cost_year = '2020' THEN product_code
        END) AS unique_products_2020,
    COUNT(DISTINCT CASE
            WHEN cost_year = '2021' THEN product_code
        END) AS unique_products_2021,
    ((COUNT(DISTINCT CASE
            WHEN cost_year = '2021' THEN product_code
        END) - COUNT(DISTINCT CASE
            WHEN cost_year = '2020' THEN product_code
        END)) / COUNT(DISTINCT CASE
            WHEN cost_year = '2020' THEN product_code
        END)) * 100 AS percentage_change
FROM
    fact_manufacturing_cost;

/* request 3 */
SELECT 
    segment, COUNT(DISTINCT product_code) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;

/* request 4 */
SELECT 
    p.segment,
    COUNT(DISTINCT CASE
            WHEN cost_year = '2020' THEN fmc.product_code
        END) AS product_count_2020,
    COUNT(DISTINCT CASE
            WHEN cost_year = '2021' THEN fmc.product_code
        END) AS product_count_2021,
    COUNT(DISTINCT CASE
            WHEN fmc.cost_year = '2021' THEN fmc.product_code
        END) - COUNT(DISTINCT CASE
            WHEN fmc.cost_year = '2020' THEN fmc.product_code
        END) AS difference
FROM
    dim_product p
        INNER JOIN
    fact_manufacturing_cost fmc ON fmc.product_code = p.product_code
GROUP BY p.segment
ORDER BY difference DESC;

/* request 5 */
SELECT 
    fmc.product_code, p.product, fmc.manufacturing_cost
FROM
    dim_product p
        INNER JOIN
    fact_manufacturing_cost fmc ON fmc.product_code = p.product_code
WHERE
    fmc.manufacturing_cost = (SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
        OR fmc.manufacturing_cost = (SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
ORDER BY fmc.manufacturing_cost DESC;

/* same request 5: but i show products within a range from the max and min*/
SELECT 
    fmc.product_code, p.product, fmc.manufacturing_cost
FROM
    dim_product p
        INNER JOIN
    fact_manufacturing_cost fmc ON fmc.product_code = p.product_code
WHERE
    fmc.manufacturing_cost between (select MAX(manufacturing_cost) from fact_manufacturing_cost) - 10 and (select MAX(manufacturing_cost) from fact_manufacturing_cost)
        or fmc.manufacturing_cost between ( select MIN(manufacturing_cost) from fact_manufacturing_cost) and ( select MIN(manufacturing_cost) from fact_manufacturing_cost) + 1.5
order by fmc.manufacturing_cost desc;

/* request 6 */
SELECT 
    pid.customer_code,
    c.customer,
    AVG(pid.pre_invoice_discount_pct) AS average_discount_percentage
FROM
    fact_pre_invoice_deductions pid
        INNER JOIN
    dim_customer c ON pid.customer_code = c.customer_code
WHERE
    pid.fiscal_year = '2021'
        AND c.market = 'India'
GROUP BY pid.customer_code, c.customer
order by average_discount_percentage desc
limit 5;

/* request 7 */
with temp as(
	SELECT
		MONTH(s.date) AS Month_,
		YEAR(s.date) AS Year_,
		SUM(s.sold_quantity) * gp.gross_price as gross
	FROM
		dim_customer c
			right JOIN
		fact_sales_monthly s ON c.customer_code = s.customer_code
			left JOIN
		fact_gross_price gp ON s.product_code = gp.product_code
	WHERE
		c.customer = 'Atliq Exclusive'
	GROUP BY Month_ , Year_, s.product_code, gp.gross_price
	ORDER BY Year_ ASC
)
SELECT 
    Month_, Year_, 
	round(SUM(gross), 2) AS gross_sales_amount
FROM
    temp
GROUP BY Month_ , Year_
ORDER BY Year_, Month_ ASC;
    
/* request 8 */
SELECT 
	quarter(s.date) as Quarter_,
    SUM(s.sold_quantity) AS total_quantity_sold
FROM
    fact_sales_monthly s
where fiscal_year = '2020'
group by Quarter_
order by total_quantity_sold desc;

/* request 9 */
with temp as(
	SELECT
		c.channel,
		s.product_code,
		SUM(s.sold_quantity) * gp.gross_price as gross
	FROM
		dim_customer c
			inner JOIN
		fact_sales_monthly s ON c.customer_code = s.customer_code
			inner JOIN
		fact_gross_price gp ON s.product_code = gp.product_code
	WHERE
		s.fiscal_year = '2021'
	GROUP BY  s.product_code, gp.gross_price, c.channel
)

SELECT 
	channel, 
	round(SUM(gross)/1000000, 2) AS gross_sales_mln
FROM
	temp
GROUP BY channel
ORDER BY gross_sales_mln desc;

/* request 10 */
with temp as (SELECT 
    p.division, p.product_code, sum(s.sold_quantity) as quantity,
    ROW_NUMBER() OVER (PARTITION BY p.division ORDER by sum(s.sold_quantity) DESC) AS row_num
FROM
    dim_product p
        INNER JOIN
    fact_sales_monthly s ON s.product_code = p.product_code
    where fiscal_year = '2021'
    group by p.division, p.product_code
    order by division)
    
select division, product_code from temp where row_num <= 3;