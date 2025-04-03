
-- Using a Common Table Expression (CTE) to assign row numbers based on salary within each gender category
With CTE_E AS
(
	SELECT dem.first_name, dem.last_name, dem.gender, dem.employee_id, sal.salary,
    ROW_NUMBER () OVER(PARTITION BY Gender ORDER BY salary) AS row_num
    FROM employee_demographics AS dem
    JOIN employee_salary AS sal
    ON dem.employee_id = sal.employee_id
    )
    SELECT *
    FROM CTE_E;
    
    -- Creating a temporary table to store employees with salary >= 50,000
    CREATE TEMPORARY TABLE temp_table
    SELECT *
    FROM employee_salary
    WHERE salary >= 50000;
    
    SELECT *
    FROM temp_table;
    
    -- Creating a stored procedure named 'sample' to retrieve employee details with row numbers partitioned by gender
    CREATE PROCEDURE sample()
    SELECT dem.first_name, dem.last_name, dem.gender, dem.employee_id, sal.salary,
    ROW_NUMBER () OVER(PARTITION BY Gender ORDER BY salary) AS row_num
    FROM employee_demographics AS dem
    JOIN employee_salary AS sal
    ON dem.employee_id = sal.employee_id;
    
    
    -- Defining a stored procedure 'sample2' that retrieves all male employees and employees earning more than 10,000
DELIMITER $$
    DELIMITER $$
    CREATE PROCEDURE sample2()
    BEGIN
		SELECT * 
        FROM employee_demographics
        WHERE gender = "Male";
        SELECT *
        FROM employee_salary
        WHERE salary >= 10000;
    END $$
    DELIMITER ;
    
    CALL sample2()
    
    
-- Creating a trigger that inserts a new employee record into employee_demographics when a record is inserted into employee_salary
DELIMITER $$
CREATE TRIGGER sample_trigger
	AFTER INSERT ON employee_salary
    FOR EACH ROW
BEGIN
	INSERT INTO employee_demographics (employee_id, first_name, last_name)
    VALUES (NEW.employee_id, NEW.first_name, NEW.last_name);
END $$
DELIMITER ;

SELECT *
FROM employee_salary;

INSERT INTO employee_salary
VALUES (13, "Happy", "Kabantiok", "State Manager", 200000, 6);

SELECT *
FROM employee_salary;

SELECT*
FROM employee_demographics;

-- Events_Automation

SHOW VARIABLES LIKE 'event%';

-- Creating an event that automatically deletes employees aged 60 or above every month
DELIMITER $$
DELIMITER $$
CREATE EVENT test_event
ON SCHEDULE EVERY 1 MONTH
DO
BEGIN
	DELETE 
    FROM employee_demographics
    WHERE age >= 60;
END $$
DELIMITER ;

SELECT * 
FROM employee_demographics;
