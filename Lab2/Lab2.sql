--                                                           Task 1 - Creating tables
CREATE TABLE STUDENTS (
    ID NUMBER,
    NAME VARCHAR2(50) NOT NULL,
    GROUP_ID NOT NULL,

    CONSTRAINT student_id PRIMARY KEY (ID),
    CONSTRAINT fk_group FOREIGN KEY (GROUP_ID) REFERENCES GROUPS(ID)
);

CREATE TABLE GROUPS (
    ID NUMBER,
    NAME VARCHAR2(50) NOT NULL,
    C_VAL NUMBER NOT NULL,

    CONSTRAINT group_pk PRIMARY KEY (ID)
);

-- Task 2 - Triggers
-- a) Integrity Students
CREATE OR REPLACE TRIGGER id_checking
BEFORE INSERT OR UPDATE OF id ON STUDENTS
FOR EACH ROW
DECLARE
    id_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO id_count
    FROM STUDENTS
    WHERE id = :NEW.id;

    IF id_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'ID must be unique in Students table');
    END IF;
END;
-- b) Integrity Groups
CREATE OR REPLACE TRIGGER id_checking_groups
BEFORE INSERT OR UPDATE OF id ON GROUPS
FOR EACH ROW
DECLARE
    id_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO id_count
    FROM GROUPS
    WHERE id = :NEW.id;

    IF id_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'ID must be unique in Groups table');
    END IF;
END;

--c) Creating sequences
CREATE SEQUENCE student_id_seq;
CREATE SEQUENCE group_id_seq;

--d) For Students
CREATE OR REPLACE TRIGGER generate_student_id
BEFORE INSERT ON STUDENTS
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        SELECT student_id_seq.NEXTVAL INTO :NEW.id FROM DUAL;
    END IF;
END;

--e) For Groups
CREATE OR REPLACE TRIGGER generate_group_id
BEFORE INSERT ON GROUPS
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        SELECT group_id_seq.NEXTVAL INTO :NEW.id FROM DUAL;
    END IF;
END;

--f) Unique group name
CREATE OR REPLACE TRIGGER name_unique_check
BEFORE INSERT OR UPDATE OF name ON GROUPS
FOR EACH ROW
DECLARE
    name_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO name_count
    FROM GROUPS
    WHERE name = :NEW.name;

    IF name_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Name must be unique in Groups table');
    END IF;
END;

-- -//- ALTER TABLE GROUPS ADD CONSTRAINT name_unique_constraint UNIQUE (name);