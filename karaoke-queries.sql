use KaraokeV3;
-- Restricciones adicionales para Empleado
ALTER TABLE Empleado
ADD CONSTRAINT uq_email UNIQUE (email),
ADD CONSTRAINT chk_fec_nac CHECK (fec_nac < CURDATE());

-- Restricciones adicionales para Horario
ALTER TABLE Horario
ADD CONSTRAINT chk_horario CHECK (h_entrada < h_salida);

-- Restricciones adicionales para Cliente
ALTER TABLE Cliente
ADD CONSTRAINT uq_email UNIQUE (email);

-- Restricciones adicionales para Reserva
ALTER TABLE Reserva
ADD CONSTRAINT chk_reserva CHECK (hora_ini < hora_fin);

-- Cambiar restricciones de integridad referencial para permitir cascada en borrado

-- Horario: Añadir ON DELETE CASCADE a la relación con Empleado
ALTER TABLE Horario DROP FOREIGN KEY fk_horario_empleado; -- Usa el nombre real de la FK si es diferente
ALTER TABLE Horario
ADD CONSTRAINT fk_horario_empleado
FOREIGN KEY (id_emp) REFERENCES Empleado(id_emp) ON DELETE CASCADE;

-- Equipo: Añadir ON DELETE CASCADE a la relación con Sala
ALTER TABLE Equipo DROP FOREIGN KEY fk_equipo_sala; -- Usa el nombre real de la FK si es diferente
ALTER TABLE Equipo
ADD CONSTRAINT fk_equipo_sala
FOREIGN KEY (num_sala) REFERENCES Sala(num_sala) ON DELETE CASCADE;

-- Reserva: Añadir ON DELETE CASCADE a las relaciones con Cliente y Sala
ALTER TABLE Reserva DROP FOREIGN KEY fk_reserva_cliente; -- Usa el nombre real de la FK si es diferente
ALTER TABLE Reserva DROP FOREIGN KEY fk_reserva_sala; -- Usa el nombre real de la FK si es diferente
ALTER TABLE Reserva
ADD CONSTRAINT fk_reserva_cliente
FOREIGN KEY (telefono_cliente) REFERENCES Cliente(telefono) ON DELETE CASCADE;
ALTER TABLE Reserva
ADD CONSTRAINT fk_reserva_sala
FOREIGN KEY (num_sala) REFERENCES Sala(num_sala) ON DELETE CASCADE;

-- ValoracionCritica: Añadir ON DELETE CASCADE a la relación con Cliente
ALTER TABLE ValoracionCritica DROP FOREIGN KEY fk_valoracion_cliente; -- Usa el nombre real de la FK si es diferente
ALTER TABLE ValoracionCritica
ADD CONSTRAINT fk_valoracion_cliente
FOREIGN KEY (telefono_cliente) REFERENCES Cliente(telefono) ON DELETE CASCADE;





-- ****************************************************************************************************************
-- CONSULTAS SQL
-- ****************************************************************************************************************

-- LISTA Y ORDENA TODOS LOS EMPREADOS QUE HAN TRABAJADO EN UN DIA ESPECÍFICO
select e.* from Empleado e inner join Horario h
on e.id_emp =h.id_emp
where h.dia ='2021-08-22'
order by CAST(SUBSTRING(e.id_emp ,5)as UNSIGNED);





-- LISTA TODAS LAS RESERVAS DE LAS SALAS ENTRE DOS FECHAS ESPECIFICAS
SELECT
    r.id_reserva,
    r.fec_reserva,
    r.hora_ini,
    r.hora_fin,
    c.nombre,
    c.apellido,
    c.telefono AS telefono_cliente,
    c.email AS email_cliente,
    s.num_sala,
    s.precio,
    s.tamanio,
    vc.puntuacion,
    vc.comentario
FROM
    Reserva r
INNER JOIN Cliente c ON r.telefono_cliente = c.telefono
INNER JOIN Sala s ON r.num_sala = s.num_sala
INNER JOIN ValoracionCritica vc ON c.telefono = vc.telefono_cliente
WHERE
    r.fec_reserva BETWEEN '2021-08-01' AND '2021-08-31'
ORDER BY
    r.fec_reserva;
  
   
   
   
   
-- LISTA EL TOTAL DE SALAS QUE HA RESERVADO CADA CLIENTE DESDE QUE INICIO LA EMPRESA
SELECT
	c.telefono,
	CONCAT(c.nombre, ' ', c.apellido) AS nombre_completo,
	(SELECT
		COUNT(*)
	FROM
		Reserva r
	INNER JOIN Sala s 
     ON
		r.num_sala = s.num_sala
	WHERE
		r.telefono_cliente = c.telefono
		) AS total_reservas
FROM
	Cliente c
ORDER BY
	total_reservas DESC;





-- LISTA Y ORDENA EL TOTAL DE HORAS TRABAJADAS POR UN EMPLEADO EN UN DETERMINADO MES
SELECT
	e.id_emp,
	concat(e.nombre, ' ', e.apellido)as nombre_completo,
	SUM(TIMESTAMPDIFF(HOUR, h.h_entrada, h.h_salida)) AS total_horas
FROM
	Empleado e
INNER JOIN 
    Horario h 
ON 
	e.id_emp = h.id_emp
WHERE
	-- solo en los meses agosto(8), septiembre(9) y octubre(10)
	MONTH (h.dia)= 8
GROUP BY
	e.id_emp
order by
	CAST(SUBSTRING(e.id_emp , 5)as UNSIGNED);




   
-- LISTA Y ORDENA EL TOTAL DE GANANCIAS DE CADA DIA DE LAS SALAS PEQUEÑAS, MEDIANAS Y GRANDES POR SEPARADO
-- DENTRO DE UN MES DETERMINADO
SELECT
    DAY(r.fec_reserva) AS 'Día',
    SUM(IF(s.tamanio = 'pequeño', s.precio , 0)) AS 'Total Pequeño',
    SUM(IF(s.tamanio = 'mediano', s.precio , 0)) AS 'Total Mediano',
    SUM(IF(s.tamanio = 'grande', s.precio , 0)) AS 'Total Grande'
FROM
    Reserva r
INNER JOIN 
    Sala s 
ON
    r.num_sala = s.num_sala
WHERE
    MONTH(r.fec_reserva) = 10 	-- 8,9 o 10
GROUP BY 
    DAY(r.fec_reserva)
ORDER BY 
	DAY(r.fec_reserva);





-- ****************************************************************************************************************
-- VISTAS SQL
-- ****************************************************************************************************************
   
-- VISTA PARA CLIENTES Y EL NUMERO DE RESERVAS QUE HA REALIZADO CADA UNO
DROP VIEW IF EXISTS Clientes_Con_Reservas;
CREATE VIEW Clientes_Con_Reservas AS
SELECT DISTINCT
    CONCAT(c.nombre, ' ', c.apellido) AS nombre_completo,
    c.telefono,
    c.email,
    COUNT(r.id_reserva) AS total_reservas
FROM 
    Cliente c
    INNER JOIN Reserva r ON c.telefono = r.telefono_cliente
GROUP BY 
    c.telefono;
   
SELECT * FROM Clientes_Con_Reservas;
   

-- VISTA PARA EL TOTAL DE HORAS TRABAJADAS POR EMPLEADO EN UN MES ESPECÍFICO
DROP VIEW IF EXISTS Horas_Trabajadas_Empleado;
CREATE VIEW Horas_Trabajadas_Empleado AS
SELECT 
    e.id_emp,
    CONCAT(e.nombre, ' ', e.apellido) AS nombre_completo,
    SUM(TIMESTAMPDIFF(HOUR, h.h_entrada, h.h_salida)) AS total_horas_trabajadas
FROM 
    Empleado e
    INNER JOIN Horario h ON e.id_emp = h.id_emp
WHERE 
    MONTH(h.dia) = 8 -- OPCIONES: 8, 9, 10
GROUP BY 
    e.id_emp
ORDER BY 
	total_reservas;
   
SELECT * FROM Horas_Trabajadas_Empleado;





-- ****************************************************************************************************************
-- FUNCIONES
-- ****************************************************************************************************************

-- FUNCION PARA GENERAR UN CODIGO DE RESERVA UNICO
DELIMITER $$
CREATE FUNCTION GenerarCodigoReserva(fecha_reserva DATE, telefono_cliente VARCHAR(20), num_sala INT)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE codigo_reserva VARCHAR(30);
    DECLARE anio_mes_dia VARCHAR(8);
    DECLARE primeros_tres_digitos VARCHAR(3);
    DECLARE ultimos_tres_digitos VARCHAR(3);
    
    SET anio_mes_dia = DATE_FORMAT(fecha_reserva, '%Y%m%d');
    
    SET primeros_tres_digitos = LEFT(telefono_cliente, 3);
    
    SET ultimos_tres_digitos = RIGHT(telefono_cliente, 3);
    
    SET codigo_reserva = CONCAT('RES', anio_mes_dia, primeros_tres_digitos, ultimos_tres_digitos, 'S', num_sala);
    
    RETURN codigo_reserva;
END $$
DELIMITER ;

SELECT GenerarCodigoReserva('2024-6-8', '111222333', 1);

-- Inserto un nuevo registro en la tabla de Reserva utilizando la función GenerarCodigoReserva
INSERT INTO Reserva (id_reserva, fec_reserva, hora_ini, hora_fin, telefono_cliente, num_sala)
VALUES (
    GenerarCodigoReserva('2021-6-8', '799 815 243', 1), -- Funcion
    '2021-6-8',
    '9:30',
    '10:30',
    '799 815 243',
    1
);
-- DELETE from Reserva WHERE id_reserva='RES20210608799243S1';
-- select * from Reserva r ;
-- SELECT * FROM Cliente c ;





-- FUNCION PARA MOSTRAR CUAL ES LA SALA MAS CONCURRIDA O FAVORITA POR LOS CLIENTES
DROP FUNCTION IF EXISTS ObtenenfoSalaMasConcurrida;
DELIMITER &&
CREATE FUNCTION ObtenerInfoSalaMasConcurrida() 
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE info_sala VARCHAR(100);
    DECLARE sala_concurrida INT;
    DECLARE total_reservas INT;
    DECLARE total_clientes INT;
    
    -- Obtener la sala más concurrida y sus detalles
    SELECT num_sala, COUNT(*) AS total_reservas, COUNT(DISTINCT telefono_cliente) AS total_clientes 
    INTO sala_concurrida, total_reservas, total_clientes
    FROM Reserva
    GROUP BY num_sala
    ORDER BY total_reservas DESC
    LIMIT 1;
    
    -- Verificar si se encontró una sala más concurrida
    IF sala_concurrida IS NOT NULL THEN
        -- Construir la cadena de información
        SET info_sala = CONCAT('Sala más concurrida: Sala-', sala_concurrida, '\nTotal de reservas: ', total_reservas, '\nTotal de clientes: ', total_clientes);
    ELSE
        SET info_sala = 'No hay información disponible';
    END IF;
    
    RETURN info_sala;
END &&
DELIMITER ;

SELECT ObtenerInfoSalaMasConcurrida() AS Info_Sala_Mas_Concurrida;




-- ****************************************************************************************************************
-- PROCEDIMIENTOS ALMANCENADOS
-- ****************************************************************************************************************

-- ESTE PROCEDIMIENTO PERMITE ACTUALIZAR EL TURNO DE UN EMPLEADO
-- DE mañana A tarde Y VICEVERSA
DROP PROCEDURE IF EXISTS ActualizarTurnoEmpleado;
DELIMITER &&
CREATE PROCEDURE ActualizarTurnoEmpleado(IN p_id_emp CHAR(10))
BEGIN
    DECLARE turno_actual VARCHAR(20);
    DECLARE turno_nuevo VARCHAR(20);

    -- Obtener el turno actual del empleado
    SELECT turno INTO turno_actual
    FROM Empleado
    WHERE id_emp = p_id_emp;

    -- Decidir el nuevo turno basado en el turno actual
    IF turno_actual = 'mañana' THEN
        SET turno_nuevo = 'tarde';
    ELSEIF turno_actual = 'tarde' THEN
        SET turno_nuevo = 'mañana';
    ELSE
        -- Si el turno es "Completo", no se realiza ningún cambio
        SET turno_nuevo = turno_actual;
    END IF;

    -- Actualizar el turno del empleado si es diferente al turno actual
    IF turno_actual != 'completo' AND turno_actual != turno_nuevo THEN
        UPDATE Empleado
        SET turno = turno_nuevo
        WHERE id_emp = p_id_emp;
    END IF;
END &&
DELIMITER ;

-- CALL ActualizarTurnoEmpleado('EMP-10');

-- select * from Empleado e where id_emp ='EMP-10';





-- HACIENDO USO DE LA FUNCION GenerarCodigoReserva()
-- ESTE PROCEDIMIENTO PERMITE INSERTAR UNA NUEVA RESERVA CON UN CODIGO PERSONALIZADO

DROP PROCEDURE IF EXISTS InsertarNuevaReserva;
DELIMITER $$
CREATE PROCEDURE InsertarNuevaReserva(
    IN p_fecha_reserva DATE, 
    IN p_hora_ini TIME, 
    IN p_hora_fin TIME, 
    IN p_telefono_cliente VARCHAR(20), 
    IN p_num_sala INT
)
BEGIN
    DECLARE p_codigo_reserva VARCHAR(50);

    -- Generar el código de reserva utilizando la función GenerarCodigoReserva
    SET p_codigo_reserva = GenerarCodigoReserva(p_fecha_reserva, p_telefono_cliente, p_num_sala);

    -- Insertar la nueva reserva en la tabla Reserva
    INSERT INTO Reserva (id_reserva, fec_reserva, hora_ini, hora_fin, telefono_cliente, num_sala)
    VALUES (p_codigo_reserva, p_fecha_reserva, p_hora_ini, p_hora_fin, p_telefono_cliente, p_num_sala);
END $$
DELIMITER ;

CALL InsertarNuevaReserva('2021-6-8', '9:30', '10:30', '799 815 243', 1);
select * from Reserva r  where  r.telefono_cliente ='799 815 243';





-- HACIENDO USO DE UN CURSOR, ESTE PROCEDIMIENTO LISTA Y MUESTRA 
-- DE FORMA SEPARADA LOS EMPLEADOS DE CADA TURNO(mañana y tarde),
-- DEVIDO A QUE EL TURNO DEL JEFE NO VARIA NO SE MUESTRA EN NINGUN MOMENTO.

DROP PROCEDURE IF EXISTS GenerarInformeTurnoEmpleados;
DELIMITER $$
CREATE PROCEDURE GenerarInformeTurnoEmpleados()
BEGIN
	DECLARE done INT DEFAULT FALSE;
	DECLARE total INT DEFAULT 0;
	DECLARE salida VARCHAR(5000) DEFAULT '';
	DECLARE salida2 VARCHAR(5000) DEFAULT '';
	DECLARE cont INT DEFAULT 1;
	DECLARE cont2 INT DEFAULT 1;

	DECLARE nom_emp VARCHAR(250) DEFAULT '';
	DECLARE ape_emp VARCHAR(250) DEFAULT '';
	DECLARE turno_emp VARCHAR(50) DEFAULT '';


	DECLARE cursor_empleados CURSOR FOR
		SELECT e.nombre ,e.apellido,e.turno FROM Empleado e;
	
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

	SELECT COUNT(*) INTO total FROM Empleado e where e.turno ='mañana';

	set salida = CONCAT(salida, '===================== TURNO MAÑANA =====================\n');
	set salida = CONCAT(salida, '\nTotal Empleados: ', total,'\n');

	SELECT COUNT(*) INTO total FROM Empleado e  where e.turno = 'tarde'; 

	OPEN cursor_empleados;
	leer_empleados:LOOP
		FETCH cursor_empleados INTO nom_emp, ape_emp, turno_emp;
		IF done THEN
			LEAVE leer_empleados;
		END IF;
	
		IF(turno_emp='mañana') THEN
			SET salida = CONCAT(salida, '\n', cont, '. ', nom_emp,' ', ape_emp); 
			SET cont = cont + 1;
		END IF;
		IF(turno_emp='tarde') THEN
			SET salida2 = CONCAT(salida2, '\n', cont2, '. ', nom_emp,' ', ape_emp); 
			SET cont2 = cont2 + 1;
		END IF;
	END LOOP leer_empleados;
	SET salida = CONCAT(salida, '\n\n====================== TURNO TARDE =====================');
	SET salida = CONCAT(salida, '\nTotal Empleados: ', total,'\n');
	SET salida = CONCAT(salida, salida2);
	SELECT salida;
	CLOSE cursor_empleados;
END $$
DELIMITER ;

CALL GenerarInformeTurnoEmpleados();





-- ****************************************************************************************************************
-- TRIGGERS
-- ****************************************************************************************************************

-- TRIGGER QUE ASEGURA QUE EL ID DEL EMPLEADO SE CREE CORRECTAMENTE AL INSERTAR UN NUEVO EMPLEADO

DELIMITER &&
CREATE TRIGGER check_id_format BEFORE INSERT ON Empleado
FOR EACH ROW
BEGIN
    IF NEW.id_emp NOT LIKE 'EMP-%' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El formato del ID del empleado debe ser EMP-Número';
    END IF;
END &&
DELIMITER ;

-- Este insert debería fallar debido al trigger
INSERT INTO Empleado (id_emp, nombre, apellido, fec_nac, email, tlf, tipo_emp, turno, genero) 
VALUES ('E-001', 'Juan', 'Perez', '1990-01-01', 'juan.perez@example.com', '1234567890', 'Gerente', 'Diurno', 'M');

-- Este insert debería funcionar
INSERT INTO Empleado (id_emp, nombre, apellido, fec_nac, email, tlf, tipo_emp, turno, genero) 
VALUES ('EMP-009', 'Maria', 'Gomez', '1985-05-15', 'maria.gomez@example.com', '9876543210', 'Asistente', 'Nocturno', 'F');





-- TRIGGER QUE  SE ACTIVA DESPUES DE QUE EL CLIENTES REGISTRE SU VALORACION,
-- SOLO SI LA VALORACION ES INFERIOR A 3 ENTONCES SE GUARDAN LOS DATOS DELA VALORACION Y DEL CLIENTE
-- EN UNA NUEVA TABLA 'CLIENTES_INSATISFECHOS'

-- Crear la tabla CLIENTES_INSATISFECHOS
DROP TABLE IF EXISTS CLIENTES_INSATISFECHOS;
CREATE TABLE CLIENTES_INSATISFECHOS (
    id_cliente_insatisfecho INT AUTO_INCREMENT PRIMARY KEY,
    telefono_cliente VARCHAR(20) NOT NULL,
    email_cliente VARCHAR(100) NOT NULL,
    fecha_valoracion DATE NOT NULL,
    puntuacion INT NOT NULL,
    comentario VARCHAR(250) NOT NULL
);


DROP TRIGGER IF EXISTS registrarClienteInsatisfecho;
-- Crear el trigger para registrar clientes insatisfechos
DELIMITER $$
CREATE TRIGGER registrarClienteInsatisfecho
AFTER INSERT ON ValoracionCritica
FOR EACH ROW
BEGIN
	
    IF NEW.puntuacion < 3 THEN
        -- Insertar el teléfono del cliente en la tabla CLIENTES_INSATISFECHOS
        INSERT INTO CLIENTES_INSATISFECHOS (telefono_cliente,email_cliente, fecha_valoracion, puntuacion, comentario)
        VALUES (NEW.telefono_cliente, (SELECT email FROM Cliente WHERE telefono = NEW.telefono_cliente), CURDATE(), NEW.puntuacion, NEW.comentario);
        
    END IF;
END $$
DELIMITER ;


INSERT INTO ValoracionCritica (id_val,fec_val,puntuacion,comentario,telefono_cliente)
VALUES (2000,'2021-10-11',1,'No me gusto nada','795 305 972');

select *FROM ValoracionCritica vc ;
select * from CLIENTES_INSATISFECHOS;

DELETE  from ValoracionCritica where id_val=2000;




