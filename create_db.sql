DROP TABLE IF EXISTS automobile CASCADE;
DROP TABLE IF EXISTS service CASCADE;
DROP TABLE IF EXISTS type_of_work CASCADE;
DROP TABLE IF EXISTS partner CASCADE;
DROP TABLE IF EXISTS rent CASCADE;
DROP TABLE IF EXISTS client CASCADE;
DROP TABLE IF EXISTS invoice CASCADE;
DROP TABLE IF EXISTS claim CASCADE;

SET lc_monetary TO "ru_RU.UTF-8";

CREATE TABLE automobile (
    id_automobile SERIAL PRIMARY KEY,
    manufacturer text NOT NULL,
    registration_number text NOT NULL,
    year_of_car_manufacture date NOT NULL,
    mileage int NOT NULL,
    air_conditioner boolean NOT NULL,
    engine_capacity int Not NULL,
	luggage_capacity int not NULL,
	maintenance_date date not NULL,
	cost_per_day money
);

CREATE TABLE type_of_work (
    id_type_of_work SERIAL PRIMARY KEY,
	type_of_work text,
	description text
);

CREATE TABLE partner (
    id_partner SERIAL PRIMARY KEY,
  	organization_name text,
	legal_address text,
  	bank_details text
);

CREATE TABLE service (
    id_service SERIAL PRIMARY KEY,
	day_of_work date,
	adress text,
	automobile_id bigint not NULL,
	FOREIGN KEY (automobile_id) REFERENCES automobile (id_automobile),
	type_of_work_id bigint not NULL,
	FOREIGN KEY (type_of_work_id) REFERENCES type_of_work (id_type_of_work),
	parter_id bigint not NULL,
	FOREIGN KEY (parter_id) REFERENCES partner (id_partner)
);

CREATE TABLE client (
	id_client SERIAL PRIMARY KEY,
	client_surname text,
	client_name text,
	client_fathersname text,
	client_birthday DATE,
	passport_details text,
	driver_license_info boolean,
	client_email text,
	client_phone varchar(20)
);

CREATE TABLE rent(
	id_rent SERIAL PRIMARY KEY,
	automobile_id bigint not NULL,
	FOREIGN KEY (automobile_id) REFERENCES automobile (id_automobile),
	client_id bigint not NULL,
	FOREIGN KEY (client_id) REFERENCES client (id_client),
	start_of_rent date,
	end_of_rent date,
	starting_point text,
	end_point text,
	mileage int,
	claims boolean
);

CREATE TABLE invoice (
	id_invoice SERIAL PRIMARY KEY,
	rent_id bigint not NULL,
	FOREIGN KEY (rent_id) REFERENCES rent (id_rent),
	date_of_creation date,
	rent_cost money
);

CREATE TABLE claim (
	id_claim SERIAL PRIMARY KEY,
	rent_id bigint not NULL,
	FOREIGN KEY (rent_id) REFERENCES rent (id_rent),
	date_of_creation date,
	description text
);



-- TRIGGERS
CREATE OR REPLACE FUNCTION check_age()
RETURNS TRIGGER AS $$
BEGIN
    IF age(NEW.client_birthday) < interval '18 years'
	OR age(NEW.client_birthday) > interval '80 years' THEN
        RAISE EXCEPTION 'В силу вашего возраста мы не можем вам позволить использовать наш сервис';
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_age
BEFORE INSERT ON client
FOR EACH ROW
EXECUTE FUNCTION check_age();


CREATE or REPLACE FUNCTION format_phone()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
BEGIN
    CASE LENGTH(NEW.client_phone)
        WHEN 10 THEN
            NEW.client_phone = '+7' || ' (' || SUBSTRING(NEW.client_phone FROM 1 FOR 3) || ') '
                || SUBSTRING(NEW.client_phone FROM 4 FOR 3) || '-' 
                || SUBSTRING(NEW.client_phone FROM 7 FOR 2) || '-'
                || SUBSTRING(NEW.client_phone FROM 9 FOR LENGTH(NEW.client_phone));
        WHEN 11 THEN
            NEW.client_phone = '+' || SUBSTRING(NEW.client_phone FROM 1 FOR 1) || ' (' || SUBSTRING(NEW.client_phone FROM 2 FOR 3) || ') ' 
                || SUBSTRING(NEW.client_phone FROM 5 FOR 3) || '-' 
                || SUBSTRING(NEW.client_phone FROM 8 FOR 2) || '-'
                || SUBSTRING(NEW.client_phone FROM 10 FOR LENGTH(NEW.client_phone));
    END CASE;
    RETURN NEW;
END;
$$;


CREATE TRIGGER format_phone_trigger
BEFORE INSERT ON client
FOR EACH ROW
EXECUTE FUNCTION format_phone();

CREATE OR REPLACE FUNCTION check_driver_license()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.driver_license_info = FALSE THEN
        RAISE EXCEPTION 'У вас нет водительских прав';
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_driver_license
BEFORE INSERT ON client
FOR EACH ROW
EXECUTE FUNCTION check_driver_license();


CREATE OR REPLACE FUNCTION check_passport_format()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.passport_details ~ E'^\\d{10}$' THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'Неверный формат номера паспорта.';
    END IF;
END;
$$;

CREATE TRIGGER check_passport_format_trigger
BEFORE INSERT OR UPDATE ON client
FOR EACH ROW
EXECUTE FUNCTION check_passport_format();