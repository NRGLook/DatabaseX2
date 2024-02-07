-- 1. Создание таблицы
CREATE TABLE MyTable (
    id NUMBER,
    val NUMBER
);

-- 2. Анонимный блок для вставки 10 000 случайных записей
DECLARE
    v_id NUMBER;
BEGIN
    FOR i IN 1..10000 LOOP
        v_id := i;
        INSERT INTO MyTable (id, val) VALUES (v_id, ROUND(DBMS_RANDOM.VALUE(1, 100)));
    END LOOP;
    COMMIT;
END;
/

-- 3. Функция для проверки количества четных и нечетных значений в столбце val
CREATE OR REPLACE FUNCTION CheckEvenOdd RETURN VARCHAR2 IS
    v_even_count NUMBER := 0;
    v_odd_count NUMBER := 0;
BEGIN
    FOR rec IN (SELECT val FROM MyTable) LOOP
        IF MOD(rec.val, 2) = 0 THEN
            v_even_count := v_even_count + 1;
        ELSE
            v_odd_count := v_odd_count + 1;
        END IF;
    END LOOP;

    IF v_even_count > v_odd_count THEN
        RETURN 'TRUE';
    ELSIF v_even_count < v_odd_count THEN
        RETURN 'FALSE';
    ELSE
        RETURN 'EQUAL';
    END IF;
END;
/

-- 4. Функция для генерации команды INSERT по ID
CREATE OR REPLACE FUNCTION GenerateInsert(id_value NUMBER) RETURN VARCHAR2 IS
    v_insert_cmd VARCHAR2(1000);
BEGIN
    SELECT 'INSERT INTO MyTable (id, val) VALUES (' || id_value || ', ' || val || ')' INTO v_insert_cmd FROM MyTable WHERE id = id_value;
    RETURN v_insert_cmd;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'ID not found';
END;
/

-- 5. Процедуры для DML операций
CREATE OR REPLACE PROCEDURE InsertRecord(p_id NUMBER, p_val NUMBER) AS
BEGIN
    INSERT INTO MyTable (id, val) VALUES (p_id, p_val);
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE UpdateRecord(p_id NUMBER, p_val NUMBER) AS
BEGIN
    UPDATE MyTable SET val = p_val WHERE id = p_id;
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE DeleteRecord(p_id NUMBER) AS
BEGIN
    DELETE FROM MyTable WHERE id = p_id;
    COMMIT;
END;
/

-- 6. Функция для вычисления общего вознаграждения за год
CREATE OR REPLACE FUNCTION CalculateTotalReward(p_monthly_salary NUMBER, p_annual_bonus_percentage NUMBER) RETURN NUMBER IS
    v_total_reward NUMBER;
BEGIN
    IF p_annual_bonus_percentage IS NULL OR p_monthly_salary IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Input values cannot be null');
    END IF;

    IF p_annual_bonus_percentage < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Annual bonus percentage cannot be negative');
    END IF;

    v_total_reward := (1 + p_annual_bonus_percentage / 100) * 12 * p_monthly_salary;

    RETURN v_total_reward;

EXCEPTION
    WHEN OTHERS THEN
        -- Обработка любых других исключений
        -- Получить сообщение об ошибке и вывести его
        RAISE_APPLICATION_ERROR(-20003, 'An error occurred: ' || SQLERRM);
END;
/
