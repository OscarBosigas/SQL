--TALLER FINAL--
--1.Elabore una consulta que reporte todos los nombres completos de los
--empleados en cuyo departamento trabajan entre 15 y 20 personas
SELECT first_name, last_name
FROM EMPLOYEES e, DEPARTMENTS d, (SELECT COUNT(employee_id) conteo
								  FROM EMPLOYEES e, DEPARTMENTS d
								  WHERE d.department_id = e.department_id
								  GROUP BY d.department_id)
WHERE e.department_id = d.department_id
AND conteo >=15
AND conteo <=20;


--2.Elabore una consulta que muestre el top–n de salarios con el
--respectivo empleado que lo devenga, teniendo en cuenta que el valor de n
--lo debe ingresar el usuario (Para este caso consulte la función RANK de Oracle).
SELECT NOMBRE_EMPLEADO, salary
FROM 
(SELECT first_name || ' ' || last_name NOMBRE_EMPLEADO, RANK() OVER(ORDER BY salary DESC) RANGO, salary 
FROM EMPLOYEES)
WHERE RANGO <=&r;

--3..Plantee un programa PL/SQL que solicite al usuario un id de empleado y
--esta retorne si el empleado existe o no.
DECLARE
	v_id NUMBER:= &id;
	v_name VARCHAR2(30);
BEGIN
	SELECT first_name 
	INTO
	v_name
	FROM EMPLOYEES
	WHERE employee_id = v_id;
	IF v_name IS NOT NULL THEN
	DBMS_OUTPUT.PUT_LINE('Existe');
	END IF;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN 		
		DBMS_OUTPUT.PUT_LINE('No existe');
END;
/

--4.Cree una tabla con los sub-gerentes (dependientes directos de los 
--dependientes de King).
CREATE TABLE SUB_BOSS AS(SELECT *
	FROM EMPLOYEES 
	WHERE manager_id IN(SELECT employee_id 
						 FROM EMPLOYEES
						 WHERE manager_id IN(SELECT employee_id
						 					  FROM EMPLOYEES
						 					  WHERE lasT_namE LIKE 'King'
						 					  AND manager_id is null)));


-- 5.
DECLARE
	CURSOR c_empleados IS SELECT e.first_name, e.lasT_name, j.job_title
	, TRUNC(MONTHS_BETWEEN(SYSDATE, e.hire_date),0) meses,
	CASE  when TO_CHAR(EXTRACT(DAY from e.hire_date)) < 15 then (e.salary*0.8)
	else e.salary*0.4
	end salario
	FROM EMPLOYEES e, EMPLOYEES m, JOBS j, DEPARTMENTS d, REGIONS r, COUNTRIES c,
	LOCATIONS l
	WHERE e.job_id = j.job_id
	AND e.department_id = d.department_id
	AND d.location_id = l.location_id
	AND c.country_id = l.country_id
	AND c.region_id = r.region_id
	AND m.employee_id = e.manager_id
	AND EXTRACT(MONTH from e.hire_date) = EXTRACT(MONTH from m.hire_date)
	AND UPPER(r.region_name) = UPPER('&REGION');
BEGIN
	FOR i IN c_empleados LOOP
	DBMS_OUTPUT.PUT_LINE(i.first_name||' '||i.lasT_name||'--'||i.job_title
		||'--'||i.meses||'--'||i.salario);
	END LOOP;
END;
/

--6. Reporte el nombre de los países con la cantidad de departamentos 
--por país que no tienen empleados asignados.

SELECT country_name, count(dept) departamentos
FROM COUNTRIES c, LOCATIONS l, DEPARTMENTS d,
(SELECT department_id dept
 FROM DEPARTMENTS 
 MINUS
 SELECT department_id
 FROM EMPLOYEES
 GROUP BY department_id
 HAVING count(employee_id) > 0)
WHERE d.location_id = l.location_id
AND dept = d.department_id
AND c.country_id = l.country_id
GROUP BY country_name;

--7.
create or replace view proyeccion AS (
select e.first_name, e.phone_number, r.region_name,case 
    when e.salary < aux.salario  then e.salary+(e.salary*0.10)
    when  e.salary > aux.salario  then e.salary+(e.salary*0.05)
    else e.salary
    end salario
from employees e,departments d, regions r,countries c, locations l, (select avg(salary) salario, department_id
                                            from employees
                                            group by employees.department_id) aux
where e.department_id = aux.department_id 
and r.region_id = c.region_id
and c.country_id = l.country_id
and l.location_id = d.location_id
and d.department_id = e.department_id
and d.department_id = e.department_id
)

--8.Elabore un programa PL/SQL almacenado que solicite al usuario dos
--nombres de regiones y retorne la cantidad de jefes de empleados que hay 
--en dichas regiones.
CREATE OR REPLACE PROCEDURE jefes(v_region OUT VARCHAR2(10), v_jefes OUT NUMBER)
IS
	CURSOR c_jefes IS
	SELECT r.region_id, r.region_name,COUNT(e.employee_id) jefes
	FROM EMPLOYEES e, EMPLOYEES m, DEPARTMENTS d, LOCATIONS L, REGIONS R, COUNTRIES c  
	WHERE e.manager_id = m.employee_id
	AND e.department_id = d.department_id
	AND d.location_id = l.location_id
	AND l.country_id = c.country_id
	AND c.region_id = r.region_id
	OR UPPER(r.region_name) = UPPER('&region 1')
	OR UPPER(r.region_name) = UPPER('&region 2')
	GROUP BY r.region_id, r.region_name;
BEGIN
	FOR i IN c_jefes LOOP
	DBMS_OUTPUT.PUT_LINE(i.region_name||'  '||i.jefes);
	END LOOP;
END jefes;
/

--9.Haciendo uso de JOINS, elabore una consulta que retorne la cantidad de
--empleados y el promedio de salario por ciudad. Para las ciudades en las 
--cuales no hay empleados debe mostrarse al frente el número “0”. No tenga 
--en cuenta los empleados que fueron contratados en un mes impar.
SELECT city, NVL(COUNT(employee_id),0) cantidad, NVL(AVG(salary),0) salario
FROM EMPLOYEES e
INNER JOIN DEPARTMENTS d ON e.department_id = d.department_id
RIGHT OUTER JOIN LOCATIONS l ON d.location_id = l.location_id
AND MOD((EXTRACT(MONTH FROM hire_date)),2) = 0
GROUP BY city;

--10.Haga un programa PL/SQL que solicite un EMPLOYEE_ID y con base en esto
--imprima si el salario del empleado en mención, está por debajo, igual o por
--encima del promedio de los salarios de la región a la que pertenece el empleado.
--No haga uso de CASE.
DECLARE
 v_id NUMBER:= &id;
 v_salary NUMBER;
 v_average NUMBER;
 v_region NUMBER;
BEGIN
	SELECT salary, r.region_id
	INTO v_salary, v_region
	FROM EMPLOYEES e, DEPARTMENTS d, REGIONS r, COUNTRIES c, LOCATIONS L
	WHERE e.department_id = d.department_id
	AND d.location_id = l.location_id
	AND c.country_id = l.country_id
	AND c.region_id = r.region_id
	AND employee_id = v_id;

	SELECT AVG(e.salary)
	INTO v_average
	FROM EMPLOYEES e, DEPARTMENTS d, REGIONS r, COUNTRIES c, LOCATIONS L
	WHERE e.department_id = d.department_id
	AND d.location_id = l.location_id
	AND c.country_id = l.country_id
	AND c.region_id = r.region_id 
	AND r.region_id = v_region
	GROUP BY r.region_id;

	IF v_salary > v_average THEN
		DBMS_OUTPUT.PUT_LINE('ESTA POR ENCIMA');
	ELSIF v_salary < v_average THEN
		DBMS_OUTPUT.PUT_LINE('ESTA POR DEBAJO');
	ELSIF v_salary = v_average THEN
		DBMS_OUTPUT.PUT_LINE('ES IGUAL');
	END IF;
END;
/

--11. Cree una tabla con la misma estructura de la tabla EMPLOYEES, 
--posterior a esto elabore un bloque anónimo que al eliminarse un 
--empleado de la tabla, lo inserte en la tabla creada, adicionalmente
--controle que si el empleado es jefe no se podrá eliminar.
CREATE TABLE unemployees AS (SELECT * FROM employees WHERE employee_id=0);

DECLARE
 v_employee_id EMPLOYEES.EMPLOYEE_ID%TYPE:=&ID;
 v_employee EMPLOYEES%ROWTYPE;
 v_aux NUMBER;
BEGIN
 SELECT *
 INTO v_employee
 FROM employees
 WHERE employee_id=v_employee_id;
 
 SELECT COUNT(employee_id) 
 INTO v_aux
 FROM employees
 WHERE manager_id=v_employee_id;

  IF v_aux<>0 THEN
   DBMS_OUTPUT.PUT_LINE('El empleado es jefe y no se puede eliminar');
  ELSE
   INSERT INTO unemployees VALUES (v_employee.employee_id, v_employee.first_name,      v_employee.last_name, v_employee.email, v_employee.phone_number, v_employee.hire_date,       v_employee.job_id, v_employee.salary, v_employee.commission_pct, v_employee.manager_id,      v_employee.department_id);
  DELETE FROM employees
  WHERE employee_id=v_employee_id;
  DBMS_OUTPUT.PUT_LINE('Empleado eliminado');
 END IF;
 
EXCEPTION 
 WHEN NO_DATA_FOUND THEN 
 DBMS_OUTPUT.PUT_LINE('El empleado no existe');
END;

--12-Cree un bloque anónimo para con base en un código de empleado 
--ingresado el usuario, se pueda conocer:
-- El número de veces que el empleado ha cambiado de trabajo,
-- El número de veces que el empleado ha cambiado de departamento
DECLARE
	v_emp_id employees.employee_id%TYPE:=&employee_id;
	v_jobs NUMBER;
	v_departments NUMBER;
	v_employee_name VARCHAR2(100);
BEGIN
	SELECT e.first_name||' '||e.last_name, COUNT(DISTINCT jh.job_id) CAMBIOS_TRABAJO, 
		COUNT(DISTINCT jh.department_id) CAMBIOS_DEPARTAMENTO
	INTO v_employee_name, v_jobs, v_departments
	FROM employees e, job_history jh
	WHERE e.employee_id=jh.employee_id
	AND e.employee_id = v_emp_id
	GROUP BY e.first_name||' '||e.last_name;

	DBMS_OUTPUT.PUT_LINE('El empleado '||v_employee_name||' ha cambiado '||v_jobs||' veces 
		de trabajo y '||v_departments||' de departamento');
END;
/

--13-Elabore una estructura PL/SQL que retorne el salario de un empleado,
--considerando las siguientes reglas:
-- Si el NOMBRE tiene una longitud par el salario debe incluir la comisión, de lo
--contrario solo se imprime el salario.
-- Si el CÓDIGO termina en un numero par, descuente al salario anterior 500, de
--lo contrario sume 1000.
CREATE OR REPLACE FUNCTION salarioCondicion(v_id IN NUMBER)
RETURN NUMBER
IS
v_salario NUMBER;
v_aux NUMBER;
BEGIN
	SELECT CASE
		   WHEN MOD(LENGTH(first_name),2) = 0 THEN salary*NVL(commission_pct,1)+salary
		   ELSE salary
		   END "salario"
	INTO
	v_aux
	FROM EMPLOYEES
		   WHERE employee_id = v_id;

	SELECT CASE 
		   WHEN MOD(SUBSTR(employee_id, -1, 1),2) = 0 THEN v_aux-500
		   WHEN MOD(SUBSTR(employee_id, -1, 1),2) != 0 THEN v_aux+1000
		   END "SALARIO"
		   INTO 
		   v_salario
		   FROM EMPLOYEES
		   WHERE employee_id = v_id;
	RETURN(v_salario);
END salarioCondicion;
/

--14.Elabore un trigger que permita controlar que todos los empleados
--tengan un alario que se encuentre dentro del rango de salario 
--sugerido para el trabajo que desempeña
CREATE OR REPLACE TRIGGER salarioEmpleado
BEFORE INSERT OR UPDATE OF salary ON EMPLOYEES
FOR EACH ROW
WHEN (OLD.salary <> NEW.salary)
DECLARE
v_min NUMBER;
v_max NUMBER;
BEGIN
	IF INSERTING THEN SELECT min_salary, max_salary
					  INTO v_min, v_max
					  FROM JOBS 
					  WHERE job_id = :NEW.job_id;					  
	IF :NEW.salary BETWEEN v_min AND v_max THEN
		INSERT INTO EMPLOYEES VALUES(:NEW.employee_id,
									 :NEW.first_name,
									 :NEW.last_name,
									 :NEW.email,
									 :NEW.phone_number,
									 :NEW.hire_date,
									 :NEW.job_id,
									 :NEW.salary,
									 :NEW.commission_pct,
									 :NEW.manager_id,
									 :NEW.department_id);
	ELSE
		RAISE_APPLICATION_ERROR (-20001,'El salario no concuerda');
	END IF;
	END IF;

	IF UPDATING THEN SELECT min_salary, max_salary
					    INTO v_min, v_max
					    FROM JOBS j
					    WHERE job_id = :NEW.job_id;
	IF :NEW.salary BETWEEN v_min y AND v_max THEN
		UPDATE EMPLOYEES SET salary = :NEW.salary
		WHERE employee_id = :OLD.employee_id;
	ELSE
		RAISE_APPLICATION_ERROR (-20001,'El salario no concuerda');
	END IF;
END;
/