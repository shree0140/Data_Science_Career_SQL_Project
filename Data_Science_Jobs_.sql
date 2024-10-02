USE data_science_jobs;

SELECT * FROM salaries;             -- COMPLETE DATA SET

 /* 1.	You're a compensation analyst employed by a multinational corporation. 
Your assignment is to pinpoint countries who give fully remote work, for the title 'managers’ paying salaries exceeding $90,000 USD */

SELECT DISTINCT company_location  FROM salaries 
WHERE job_title LIKE '%Manager%' AND salary_in_usd > 90000 AND remote_ratio = 100;
/* ------------------------------------------------------------------------------------------------------------------------------------*/

/* 2.	As a remote work advocate working for a progressive HR tech startup who place their freshers (clients) in large tech firms. 
You're tasked with identifying top 5 countries having greatest count of large (company size) number of companies. */

SELECT company_location, COUNT(company_size) AS large_companies_count FROM salaries 
WHERE company_size = 'L' AND experience_level = 'EN'
GROUP BY company_location
ORDER BY large_companies_count DESC
LIMIT 5; 

/* SELECT company_location, COUNT(company_size) AS large_companies_count FROM 
( SELECT * FROM salaries WHERE company_size = 'L' AND experience_level = 'EN') AS sub_query_table
GROUP BY company_location 
ORDER BY large_companies_count DESC
LIMIT 5; */
/*-------------------------------------------------------------------------------------------------------------------------------------*/

/* 3.   Picture yourself as a data scientist working for a workforce management platform. 
Your objective is to calculate the percentage of employees, who enjoy fully remote roles with salaries exceeding $100,000 USD, 
shedding light on the attractiveness of high-paying remote positions in today's job market.*/

SET @total = (SELECT COUNT(*) FROM salaries WHERE salary_in_usd > 100000);
SET @required_count = (SELECT COUNT(*) FROM salaries WHERE salary_in_usd > 100000 AND remote_ratio = 100);
SET @percentage_count= ROUND(((SELECT @required_count)/(SELECT @total))*100,3);
SELECT @percentage_count AS 'Percentage_Count';
/*-------------------------------------------------------------------------------------------------------------------------------------*/

/* 4.	Imagine you're a data analyst working for a global recruitment agency. 
Your task is to identify the locations where entry-level average salaries exceed the average salary for that job title,
in market for entry level, helping your agency guide candidates towards lucrative opportunities. */

SELECT a.job_title, company_location, highest_avg_salary_country, avg_salary_per_job_title FROM
(SELECT company_location, job_title, AVG(salary_in_usd) AS 'highest_avg_salary_country' FROM salaries WHERE experience_level = 'EN' GROUP BY job_title, company_location) AS a
INNER JOIN 
(SELECT job_title, AVG(salary_in_usd) AS 'avg_salary_per_job_title' FROM salaries WHERE experience_level = 'EN' GROUP BY job_title) AS b
ON a.job_title = b.job_title
WHERE highest_avg_salary_country > avg_salary_per_job_title
ORDER BY job_title;
/*-------------------------------------------------------------------------------------------------------------------------------------*/

/* 5.	You've been hired by a big HR consultancy to look at how much people get paid in different countries.
 Your job is to find out for each job title which country pays the maximum average salary.
 This helps you to place your candidates in those countries. */
 
SELECT * FROM
(
SELECT job_title, company_location, DENSE_RANK() OVER( PARTITION BY job_title ORDER BY max_avg_salary DESC) AS 'Company_Rank'
FROM
(
SELECT job_title, company_location, AVG(salary_in_usd) AS 'max_avg_salary' FROM salaries GROUP BY job_title, company_location
) AS inner_subquery
) AS outer_subquery
WHERE Company_Rank =1 ;
/*-------------------------------------------------------------------------------------------------------------------------------------*/
 
/* 6.	As a data-driven business consultant, 
you've been hired by a multinational corporation to analyze salary trends across different company locations. 
Your goal is to pinpoint locations where the average salary has consistently increased over the past few years 
countries where data is available for 3 years only (present year and past two years) providing insights
into locations experiencing sustained salary growth.*/

WITH code_cte AS                                                                                                      /* STEP 4 */
(
	SELECT * FROM salaries WHERE company_location IN                                                                  /* STEP 3*/
	(
	SELECT company_location FROM                                                                                      /* step 2*/
	(
	SELECT company_location, AVG(salary_in_usd) AS Avg_salary, COUNT( DISTINCT work_year) AS 'count' FROM salaries   /* step 1*/
	WHERE work_year >= (YEAR(CURRENT_DATE()) -2) GROUP BY company_location HAVING count = 3                           /* 1*/
	ORDER BY company_location                                                                                         /* 1*/
	) AS a                                                                                                         /* inner_subquery- step 2*/
	)                                                                                                               /* STEP 3*/
)                                                                                                                   /*STEP 4*/
    
SELECT company_location,                                                                                           /*step -7 */
MAX(CASE WHEN work_year = 2022 THEN  Avg_Salary END) AS AVG_salary_2022,
MAX(CASE WHEN work_year = 2023 THEN Avg_Salary END) AS AVG_salary_2023,
MAX(CASE WHEN work_year = 2024 THEN Avg_Salary END) AS AVG_salary_2024 
FROM 
(
 SELECT company_location, AVG(salary_in_usd) AS 'Avg_Salary', work_year FROM code_cte GROUP BY company_location, work_year   /*step- 5*/
 ) AS b GROUP BY company_location HAVING AVG_salary_2024>AVG_salary_2023 AND AVG_salary_2023>AVG_salary_2022;   /* step-8*/
 /*------------------------------------------------------------------------------------------------------------------------------------*/

/* 7.	 Picture yourself as a workforce strategist employed by a global HR tech startup. 
Your mission is to determine the percentage of fully remote work for each experience level in 2021 and compare it with
the corresponding figures for 2024, highlighting any significant increases or decreases in remote work adoption over the years. */

SELECT pqr.experience_level, 2021_ratio, 2024_ratio FROM 

(
SELECT experience_level, ((total_2021_remote_count)/(total_2021_count)*100) AS '2021_ratio' FROM 
(
SELECT a.experience_level, total_2021_count, total_2021_remote_count FROM
(
SELECT experience_level, COUNT(work_year) AS 'total_2021_count'  FROM salaries WHERE work_year = 2021 GROUP BY experience_level
) AS a
INNER JOIN 
(
SELECT experience_level, COUNT(work_year) AS 'total_2021_remote_count' FROM salaries WHERE work_year = 2021 AND remote_ratio = 100 GROUP BY experience_level
) AS b
ON a.experience_level = b.experience_level
) AS sub_q_2021
) AS pqr

INNER JOIN

(
SELECT experience_level, ((total_2024_remote_count)/(total_2024_count)*100) AS '2024_ratio' FROM 
(
SELECT c.experience_level, total_2024_count, total_2024_remote_count FROM
(
SELECT experience_level, COUNT(work_year) AS 'total_2024_count'  FROM salaries WHERE work_year = 2024 GROUP BY experience_level
) AS c
INNER JOIN 
(
SELECT experience_level, COUNT(work_year) AS 'total_2024_remote_count' FROM salaries WHERE work_year = 2024 AND remote_ratio = 100 GROUP BY experience_level
) AS d
ON c.experience_level = d.experience_level
) AS sub_q_2024
) AS xyz 

ON pqr.experience_level = xyz.experience_level;
/*-------------------------------------------------------------------------------------------------------------------------------------*/

/*8.	As a compensation specialist at a fortune 500 company, you're tasked with analyzing salary trends over time.
Your objective is to calculate the average salary increase percentage for each experience level 
and job title between the years 2023 and 2024, helping the company stay competitive in the talent market.*/


WITH code_cte AS 
(
SELECT experience_level, job_title ,work_year, round(AVG(salary_in_usd),2) AS 'average_salary'  FROM salaries
WHERE work_year IN (2023,2024) GROUP BY experience_level, job_title, work_year
)

SELECT *,round((((AVG_salary_2024-AVG_salary_2023)/AVG_salary_2023)*100),2)  AS 'Avg_salary_change'
FROM 
(
SELECT experience_level, job_title,
MAX(CASE WHEN work_year = 2023 THEN average_salary END) AS AVG_salary_2023,
MAX(CASE WHEN work_year = 2024 THEN average_salary END) AS AVG_salary_2024
FROM  code_cte GROUP BY experience_level , job_title
) AS a WHERE (((AVG_salary_2024-AVG_salary_2023)/AVG_salary_2023)*100) IS NOT NULL;
/*-------------------------------------------------------------------------------------------------------------------------------------*/

/*9.	You're a database administrator tasked with role-based access control for a company's employee database. 
Your goal is to implement a security measure where employees in different experience level (e.g. Entry Level, Senior level etc.) 
can only access details relevant to their respective experience level,
ensuring data confidentiality and minimizing the risk of unauthorized access.*/

CREATE USER 'entry_level'@'%' IDENTIFIED BY 'EN';
CREATE USER 'Junior_Mid_level'@'%' IDENTIFIED BY ' MI '; 
CREATE USER 'Intermediate_Senior_level'@'%' IDENTIFIED BY 'SE';
CREATE USER 'Expert Executive-level '@'%' IDENTIFIED BY 'EX ';

CREATE OR REPLACE VIEW entry_level_view AS
(
SELECT * FROM salaries WHERE experience_level = 'EN'
);
CREATE OR REPLACE VIEW Junior_Mid_level_view AS
(
SELECT * FROM salaries WHERE experience_level = 'MI'
);
CREATE OR REPLACE VIEW Intermediate_Senior_level_view AS
(
SELECT * FROM salaries WHERE experience_level = 'SE'
);
CREATE OR REPLACE VIEW Expert_Executive_level_view AS
(
SELECT * FROM salaries WHERE experience_level = 'EX'
);
 /* SHOW PRIVELEGES*/
GRANT SELECT ON data_science_jobs.entry_level_view TO 'entry_level'@'%';
GRANT SELECT ON data_science_jobs.entry_level_view TO 'Junior_Mid_level'@'%';
GRANT SELECT ON data_science_jobs.entry_level_view TO 'Intermediate_Senior_level'@'%';
GRANT SELECT ON data_science_jobs.entry_level_view TO 'Expert Executive-level'@'%';
/*-------------------------------------------------------------------------------------------------------------------------------------*/

/*10.	You are working with a consultancy firm, your client comes to you with certain data and preferences such as
 (their year of experience , their employment type, company location and company size )
 and want to make an transaction into different domain in data industry
 (like  a person is working as a data analyst and want to move to some other domain such as data science or data engineering etc.)
 your work is to  guide them to which domain they should switch to base on  the input they provided,
 so that they can now update their knowledge as  per the suggestion/.. The Suggestion should be based on average salary.*/
 
 
 DELIMITER $$
 CREATE PROCEDURE GetAvgSalary(IN exp_lev VARCHAR(2), IN comp_loc VARCHAR(2), IN comp_size VARCHAR(2), IN emp_type VARCHAR(3))
 BEGIN
	 SELECT job_title, experience_level, employment_type, company_location, company_size, AVG(salary) AS 'Avg_salary' 
	 FROM salaries
	 WHERE experience_level = exp_lev AND company_location = comp_loc AND company_size = comp_size AND employment_type = emp_type
	 GROUP BY job_title, company_location, company_size, employment_type,experience_level 
	 ORDER BY Avg_salary DESC;
 END $$
 DELIMITER ;
 
CALL GetAvgSalary('EN', 'AU', 'M', 'FT');
CALL GetAvgSalary('EN', 'US', 'L', 'FT');
DROP PROCEDURE GetAvgSalary;
/*-------------------------------------------------------------------------------------------------------------------------------------*/
 
 