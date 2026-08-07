
-- 1. Покажіть середню зарплату співробітників за кожен рік, до 2005 року.
-- Show the average employee salary for each year up to 2005.
SELECT 	YEAR(sal.to_date) AS ByYear, 	
		ROUND(AVG(sal.salary),0) AS AvgSal
FROM employees.salaries sal
GROUP BY ByYear
HAVING ByYear BETWEEN MIN(YEAR(sal.from_date)) AND 2005
ORDER BY ByYear;

-- 2. Покажіть середню зарплату співробітників по кожному відділу. Примітка: потрібно розрахувати по поточній зарплаті, та поточному відділу співробітників
-- Show the average employee salary for each department. Note: Calculate it using employees' current salary and current department.
SELECT 	dep.dept_no,	
		ROUND(AVG(sal.salary)) AS AvgSal
FROM employees.employees emp
INNER JOIN employees.salaries sal ON emp.emp_no = sal.emp_no AND sal.to_date > CURDATE()
LEFT JOIN employees.dept_emp dep ON sal.emp_no = dep.emp_no AND dep.to_date > CURDATE()
GROUP BY dep.dept_no
ORDER BY dep.dept_no;

-- 3. Покажіть середню зарплату співробітників по кожному відділу за кожний рік
-- Show the average employee salary for each department for each year.
SELECT 	dep.dept_no,
		YEAR(sal.to_date) AS ByYear,
        ROUND(AVG(sal.salary),0) AS AvgSal
FROM employees.employees emp
INNER JOIN employees.salaries sal ON emp.emp_no = sal.emp_no AND sal.to_date 
INNER JOIN employees.dept_emp dep ON sal.emp_no = dep.emp_no AND dep.to_date 
-- WHERE sal.from_date BETWEEN dep.from_date AND dep.to_date (запис для видалення дублікатів, не знаю чи потрібний)
GROUP BY dep.dept_no, ByYear
ORDER BY dep.dept_no;

-- 4. Покажіть відділи в яких зараз працює більше 15000 співробітників.
-- Show the departments that currently have more than 15,000 employees.
SELECT 	dep.dept_no,
		COUNT(dep.emp_no) AS count_staff
FROM employees.employees emp
INNER JOIN employees.salaries sal ON emp.emp_no = sal.emp_no AND sal.to_date > CURDATE()
INNER JOIN employees.dept_emp dep ON sal.emp_no = dep.emp_no AND dep.to_date > CURDATE()
GROUP BY dep.dept_no
HAVING count_staff > 15000
ORDER BY dep.dept_no;

-- 5. Для менеджера який працює найдовше покажіть його номер, відділ, дату прийому на роботу, прізвище
-- *Співробітник, що працює найдовше саме на посаді менеджера
-- For the longest-serving manager, show their employee ID, department, hire date, and last name
SELECT 	dep.dept_no,
		emp.first_name,
        emp.last_name,
        titl.title,
        emp.hire_date,
        titl.from_date AS FromDateAsManager, 
        titl.to_date,
		TIMESTAMPDIFF(YEAR,titl.from_date,REPLACE(titl.to_date, '9999-01-01', CURDATE())) AS  YearsAsManager
FROM employees.employees emp
INNER JOIN employees.dept_emp dep ON emp.emp_no = dep.emp_no
INNER JOIN employees.titles titl ON emp.emp_no = titl.emp_no
WHERE titl.title = "Manager"
GROUP BY dep.dept_no,
		emp.first_name,
        emp.last_name,
        titl.title,
        emp.hire_date,
        FromDateAsManager, 
        titl.to_date
ORDER BY YearsAsManager DESC
LIMIT 1;	

-- 6. Покажіть топ-10 діючих співробітників компанії з найбільшою різницею між їх зарплатою і середньою зарплатою в їх відділі.
-- Show the top 10 current employees with the largest difference between their salary and the average salary of their department.
CREATE TEMPORARY TABLE t_DepartmentSalaries
AS
SELECT 	emp.emp_no,
		CONCAT(emp.first_name, " " , emp.last_name) AS FullName,
        sal.salary,
        dep.dept_no,
		ROUND(AVG(sal.salary) OVER (PARTITION BY dep.dept_no),0) AS AvgSalByDep
FROM employees.employees emp
INNER JOIN employees.salaries sal ON emp.emp_no = sal.emp_no AND sal.to_date > CURDATE()
LEFT JOIN employees.dept_emp dep ON sal.emp_no = dep.emp_no AND dep.to_date > CURDATE()
ORDER BY emp.emp_no;

SELECT *,
t_dep.salary - t_dep.AvgSalByDep AS SalDiff
FROM t_DepartmentSalaries t_dep
ORDER BY SalDiff DESC
LIMIT 10;

DROP TEMPORARY TABLE t_DepartmentSalaries;


-- 7. Для кожного відділу покажіть другого по порядку менеджера. Необхідно вивести відділ, 
-- прізвище ім’я менеджера, дату прийому на роботу менеджера і дату коли він став менеджером відділу
-- For each department, show the second manager in chronological order. Display the department, manager's first and last name, hire date, and the date they became the department manager.
CREATE TEMPORARY TABLE TempDepartments
AS
SELECT 	depm.dept_no,
		CONCAT(emp.first_name, " " , emp.last_name) AS FullName,
		emp.hire_date,
		depm.from_date as From_date_As_Manager,
		ROW_NUMBER () OVER (PARTITION BY depm.dept_no ORDER BY depm.dept_no, depm.emp_no ) AS Numb 
FROM employees.dept_manager depm
INNER JOIN employees.dept_emp dep ON dep.emp_no = depm.emp_no
INNER JOIN employees.employees emp ON dep.emp_no = emp.emp_no ;

SELECT 
    t_dep.dept_no,
    t_dep.FullName,
    t_dep.hire_date,
    t_dep.From_date_As_Manager
FROM
    TempDepartments t_dep
WHERE
    t_dep.Numb = 2;
    
DROP TEMPORARY TABLE TempDepartments;


-- Дизайн бази даних:
-- 1. Створіть базу даних для управління курсами. База має включати наступні таблиці:
-- Create a database for course management. The database should include the following tables:
DROP  DATABASE IF EXISTS CoursesDB;
CREATE DATABASE IF NOT EXISTS CoursesDB;
USE CoursesDB;

CREATE TABLE IF NOT EXISTS courses ( 
		course_no INT AUTO_INCREMENT PRIMARY KEY,
		course_name VARCHAR(255) NOT NULL,
		start_date DATE,
        end_date DATE
);

CREATE TABLE IF NOT EXISTS teachers ( 
		teacher_no INT AUTO_INCREMENT PRIMARY KEY,
		teacher_name VARCHAR(255) NOT NULL,
		phone_no VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS students ( 
         student_no INT AUTO_INCREMENT,
         course_no INT NOT NULL,
         teacher_no INT NOT NULL,
         student_name VARCHAR(255) NOT NULL, 
         email VARCHAR(255) NOT NULL, 
         birth_date DATE,
         PRIMARY KEY ( student_no, course_no, teacher_no ),
         FOREIGN KEY (course_no) REFERENCES courses (course_no) ON UPDATE RESTRICT ON DELETE CASCADE,
         FOREIGN KEY (teacher_no) REFERENCES teachers (teacher_no) ON UPDATE RESTRICT ON DELETE CASCADE
); 

-- 2. Додайте будь-які данні (7-10 рядків) в кожну таблицю.
-- Insert sample data (7–10 rows) into each table.
START TRANSACTION;
INSERT INTO courses 
VALUES	('1', "DataScience",'2025-02-01','2025-08-01'),
		('2', "Marketing",'2025-03-01','2025-010-01'),
        ('3', "PythonDevelopment",'2025-04-01','2025-012-01'),
        ('4', "ExcelAdvanced",'2025-05-01','2026-05-01'),
        ('5', "WordAdvanced",'2025-06-01','2026-01-01'),
        ('6', "BIDevelopment",'2025-07-01','2026-06-01'),
        ('7', "DataAnalytics",'2025-08-01','2026-05-01');

INSERT INTO teachers 
VALUES	('1', "Maxim",'0972524245'),
		('2', "Anna",'0972864730'),
        ('3', "Maria",'097240932'),
        ('4', "Vlad",'097149746');

INSERT INTO students
VALUES	('1', '1','1','Oleksandr','Oleksandr1@gmail.com','2000-09-30'),
		('2', '4','3','Ludmila','Ludmila@gmail.com','1990-07-10'),
        ('3', '6','4','Olga','Olga@gmail.com','1986-01-09'),
        ('4', '5','3','Oleksandra','Oleksandra@gmail.com','1995-11-23'),
        ('5', '3','1','Oleg','Oleg@gmail.com','1999-12-01'),
        ('6', '5','3','Mykola','Mykola@gmail.com','1989-04-05'),
        ('7', '7','4','Serghiy','Serghiy@gmail.com','1980-06-06'),
		('8', '2','2','Anastasia','Anastasia@gmail.com','1993-07-02'),
		('9', '1','1','Vlad','Vlad@gmail.com','2001-02-03'),
		('10', '7','4','Oleksandr','Oleksandr2@gmail.com','1991-08-27'),
		('11', '6','4','Nazar','Naza@gmail.comr','1988-07-17'),
		('12', '2','2','Stepan','Stepan@gmail.com','1993-05-20'),
		('13', '4','3','Kateryna','Kateryna@gmail.com','1995-11-01'),
		('14', '3','1','Valentyna','Valentyna@gmail.com','1996-03-09');
COMMIT;

-- 3. По кожному викладачу покажіть кількість студентів з якими він працював
-- For each instructor, show the number of students they have worked with.
SELECT s.teacher_no,
		t.teacher_name,
        COUNT(s.student_no) AS StudentsNumberByTeacher
FROM students s
INNER JOIN teachers t ON s.teacher_no = t.teacher_no
GROUP BY s.teacher_no,
		t.teacher_name;

-- 4. Спеціально зробіть 3 дубляжі в таблиці students (додайте ще 3 однакові рядки) 
-- Intentionally create three duplicate records in the students table (insert three additional identical rows).
INSERT INTO students (course_no, teacher_no, student_name, email, birth_date)
VALUES	( '1','1','Oleksandr','Oleksandr1@gmail.com','2000-09-30'),
		( '4','3','Ludmila','Ludmila@gmail.com','1990-07-10'),
        ('6','4','Olga','Olga@gmail.com','1986-01-09'),
        ( '5','3','Oleksandra','Oleksandra@gmail.com','1995-11-23'),
        ( '3','1','Oleg','Oleg@gmail.com','1999-12-01'),
        ( '5','3','Mykola','Mykola@gmail.com','1989-04-05'),
        ( '7','4','Serghiy','Serghiy@gmail.com','1980-06-06'),
		('2','2','Anastasia','Anastasia@gmail.com','1993-07-02'),
		( '1','1','Vlad','Vlad@gmail.com','2001-02-03'),
		('7','4','Oleksandr','Oleksandr2@gmail.com','1991-08-27'),
		( '6','4','Nazar','Naza@gmail.comr','1988-07-17'),
		( '2','2','Stepan','Stepan@gmail.com','1993-05-20'),
		( '4','3','Kateryna','Kateryna@gmail.com','1995-11-01'),
		( '3','1','Valentyna','Valentyna@gmail.com','1996-03-09'),
        ( '1','1','Oleksandr','Oleksandr1@gmail.com','2000-09-30'),
		( '4','3','Ludmila','Ludmila@gmail.com','1990-07-10'),
        ('6','4','Olga','Olga@gmail.com','1986-01-09'),
        ( '5','3','Oleksandra','Oleksandra@gmail.com','1995-11-23'),
        ( '3','1','Oleg','Oleg@gmail.com','1999-12-01'),
        ( '5','3','Mykola','Mykola@gmail.com','1989-04-05'),
        ( '7','4','Serghiy','Serghiy@gmail.com','1980-06-06'),
		('2','2','Anastasia','Anastasia@gmail.com','1993-07-02'),
		( '1','1','Vlad','Vlad@gmail.com','2001-02-03'),
		('7','4','Oleksandr','Oleksandr2@gmail.com','1991-08-27'),
		( '6','4','Nazar','Naza@gmail.comr','1988-07-17'),
		( '2','2','Stepan','Stepan@gmail.com','1993-05-20'),
		( '4','3','Kateryna','Kateryna@gmail.com','1995-11-01'),
		( '3','1','Valentyna','Valentyna@gmail.com','1996-03-09');

SELECT *
FROM students;

-- 5. Напишіть запит який виведе дублюючі рядки в таблиці students
-- Write a query that returns the duplicate rows in the students table.
SELECT 
		s.course_no,
        s.teacher_no,
        s.student_name,
        s.email,
        s.birth_date
FROM students s
GROUP BY s.course_no,
        s.teacher_no,
        s.student_name,
        s.email,
        s.birth_date
HAVING COUNT(*)>1;
    
