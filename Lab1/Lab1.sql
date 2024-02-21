--                                                    Task 1 - Table
CREATE TABLE MYTABLE (
    id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    val NUMBER
);

SELECT * FROM MYTABLE;

--                                                    Task 2 - Anonymous block
DECLARE
    val NUMBER;
BEGIN
    FOR i IN 1..10000 LOOP
        INSERT INTO MYTABLE(val) VALUES (ROUND(DBMS_RANDOM.VALUE(-100, 100)));
    END LOOP;
    COMMIT;
END;

TRUNCATE TABLE MYTABLE;

--                                                   Task 3 - Function CheckNumbers
CREATE OR REPLACE FUNCTION CheckNumbers RETURN VARCHAR2 IS
    count_odd NUMBER; --nechet
    count_even NUMBER; --chet
    text_str VARCHAR2(10);
BEGIN
    SELECT COUNT(CASE WHEN MOD(val, 2) != 0 THEN 1 END),
           COUNT(CASE WHEN MOD(val, 2) = 0 THEN 1 END)
    INTO count_odd, count_even
    FROM mytable;

    IF count_odd > count_even THEN
        text_str := 'FALSE';
    ELSIF count_odd < count_even THEN
        text_str := 'TRUE';
    ELSE
        text_str := 'EQUAL';
    END IF;

    RETURN text_str;
END;

SELECT CHECKNUMBERS() FROM DUAL;

--                                                       Task 4 - INSERT GENERATION FUNCTION
CREATE OR REPLACE FUNCTION Insert_Generation(input_id NUMBER) RETURN VARCHAR2 IS
    temp_id NUMBER;
    temp_val NUMBER;
    text_str VARCHAR2(100);
BEGIN
    IF input_id <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'ID must be positive');
    END IF;

    SELECT id, val
    INTO temp_id, temp_val
    FROM MYTABLE
    WHERE id = input_id;

    text_str := 'INSERT INTO MYTABLE (id, val) VALUES (' || temp_id || ', ' || temp_val || ')';

    RETURN text_str;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Data for ID ' || input_id || ' not found';

END;

SELECT Insert_Generation(121) FROM DUAL;

--                                                         Task 5 - MyProcedures
CREATE OR REPLACE PROCEDURE Insert_Record(
    p_val NUMBER
) AS
    v_id NUMBER;
BEGIN
    IF p_val IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'VAL cannot be NULL');
    END IF;

    BEGIN
        SELECT id INTO v_id FROM MYTABLE WHERE val = p_val;
        RAISE_APPLICATION_ERROR(-20002, 'Record with the same VAL already exists');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;
    INSERT INTO MYTABLE (val) VALUES (p_val) RETURNING id INTO v_id;
    COMMIT;
END Insert_Record;

CREATE OR REPLACE PROCEDURE Update_Record(
    p_id NUMBER,
    p_val NUMBER
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM MYTABLE WHERE id = p_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Data with this ID cannot be found');
    END IF;

    UPDATE MYTABLE SET val = p_val WHERE id = p_id;

    COMMIT;
END Update_Record;


CREATE OR REPLACE PROCEDURE Delete_Record(
    p_id NUMBER
) AS
    v_count NUMBER;
BEGIN
    IF p_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'ID can not be NULL');
    END IF;

    SELECT COUNT(*) INTO v_count FROM MYTABLE WHERE id = p_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Data with this ID not found');
    END IF;

    DELETE FROM MYTABLE WHERE id = p_id;

    COMMIT;
END Delete_Record;


BEGIN
    Insert_Record(999999);
END;

-- SELECT * FROM MYTABLE WHERE val=999999
--
-- SELECT * FROM ALL_OBJECTS WHERE OBJECT_NAME = 'UPDxATE_RECORD';

BEGIN
    Update_Record(1751, 123456);
END;

-- SELECT * FROM MYTABLE WHERE val=123456

BEGIN
    Delete_Record(1751);
END;

--                                                  Task 6 - Function for avg_salary
CREATE OR REPLACE FUNCTION Count_Annual_Reward(salary_input VARCHAR2, deposit_percent_rate VARCHAR2) RETURN FLOAT IS
    deposit_rate FLOAT;
    salary FLOAT;
    reward NUMBER :=0 ;
    month_count INTEGER := 12;
BEGIN
    salary:= TO_NUMBER(salary_input);
    deposit_rate := TO_NUMBER(deposit_percent_rate);
        IF salary < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Salary must be positive!');
        END IF;
        IF deposit_percent_rate < 0 OR deposit_percent_rate > 100 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Percentage rate must be in range(0..100]');
        END IF;
        deposit_rate := deposit_percent_rate/100;
        reward := (1 + deposit_rate) * month_count * salary;
        return reward;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error occurred!: ' || SQLERRM);
END Count_Annual_Reward;

SELECT Count_Annual_Reward('abcd', 10) FROM dual;
