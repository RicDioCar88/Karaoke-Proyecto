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


-- CONSULTAS SQL

-- listado de todos los empleados que han trabajado en un dia especifico y ordenados.
select e.* from Empleado e inner join Horario h
on e.id_emp =h.id_emp 
where h.dia ='2021-08-22'
order by CAST(SUBSTRING(e.id_emp ,5)as UNSIGNED);

-- listado de todas las reservas de las salas entre dos fechas especificadas
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
LEFT JOIN ValoracionCritica vc ON c.telefono = vc.telefono_cliente
WHERE
    r.fec_reserva BETWEEN '2021-08-01' AND '2021-08-31'
ORDER BY
    r.fec_reserva;
   
-- Muestra una lista de clientes que han hecho reservas, junto con el número total de reservas realizadas y la puntuación promedio de sus valoraciones.
SELECT
	UPPER(CONCAT(c.nombre,' ',c.apellido)) as 'nombre',
    c.telefono,
    (SELECT COUNT(*)
     FROM Reserva r
     WHERE r.telefono_cliente = c.telefono) AS N_reservas,
    (SELECT AVG(vc.puntuacion)
     FROM ValoracionCritica vc
     WHERE vc.telefono_cliente = c.telefono) AS promedio_puntuacion
FROM
    Cliente c
ORDER BY
    N_reservas DESC; 
    
-- 
SELECT
    r.id_reserva,
    CONCAT(UPPER(c.nombre), ' ', UPPER(c.apellido)) AS nombre_completo_cliente,
    s.num_sala,
    s.precio,
    s.tamano,
    (SELECT estado
     FROM Equipo e
     WHERE e.num_sala = s.num_sala
     LIMIT 1) AS estado_equipo,
    DATE_FORMAT(r.fec_reserva, '%d-%m-%Y') AS fecha_reserva,
    CONCAT(TIMESTAMPDIFF(HOUR, r.hora_ini, r.hora_fin), ' horas') AS duracion_reserva,
    (SELECT AVG(vc.puntuacion)
     FROM ValoracionCritica vc
     WHERE vc.telefono_cliente = r.telefono_cliente) AS promedio_puntuacion_cliente
FROM
    Reserva r
    INNER JOIN Cliente c ON r.telefono_cliente = c.telefono
    INNER JOIN Sala s ON r.num_sala = s.num_sala
ORDER BY
    r.fec_reserva DESC;
    
-- MUestra una lista de los empleados y su turno de trabajo especifico
SELECT 
    CONCAT(nombre, ' ', apellido) AS nombre_completo,
    turno
FROM 
    Empleado
WHERE 
    turno = 'Nocturno';
    
-- VISTAS SQL

-- Para consultar el resumen de actividad de clientes
CREATE VIEW Resumen_Actividad_Clientes AS
SELECT 
    CONCAT(c.nombre, ' ', c.apellido) AS nombre_completo,
    COUNT(r.id_reserva) AS total_reservas,
    ROUND(AVG(vc.puntuacion), 2) AS promedio_puntuacion
FROM 
    Cliente c
    LEFT JOIN Reserva r ON c.telefono = r.telefono_cliente
    LEFT JOIN ValoracionCritica vc ON c.telefono = vc.telefono_cliente
GROUP BY 
    c.telefono;
   
SELECT * FROM Resumen_Actividad_Clientes;
   
-- Para consultar los detalles de las reservas y equipos
CREATE VIEW Detalles_Reservas_Equipos AS
SELECT 
    CONCAT(c.nombre, ' ', c.apellido) AS nombre_completo_cliente,
    r.fec_reserva AS fecha_reserva,
    r.num_sala,
    e.estado AS estado_equipo,
    TIMESTAMPDIFF(HOUR, r.hora_ini, r.hora_fin) AS duracion_reserva_horas
FROM 
    Reserva r
    INNER JOIN Cliente c ON r.telefono_cliente = c.telefono
    LEFT JOIN Equipo e ON r.num_sala = e.num_sala;
   
select * from Detalles_Reservas_Equipos;

-- FUNCIONES

-- 
DELIMITER &&
CREATE FUNCTION CalcularEdad(fecha_nacimiento DATE)
RETURNS INT
BEGIN
    DECLARE edad INT;
    SET edad = YEAR(CURRENT_DATE()) - YEAR(fecha_nacimiento);
    IF MONTH(CURRENT_DATE()) < MONTH(fecha_nacimiento) OR (MONTH(CURRENT_DATE()) = MONTH(fecha_nacimiento) AND DAY(CURRENT_DATE()) < DAY(fecha_nacimiento)) THEN
        SET edad = edad - 1;
    END IF;
    RETURN edad;
END &&
DELIMITER ;



DELIMITER &&

CREATE FUNCTION ConcatenarNombreApellido(nombre VARCHAR(50), apellido VARCHAR(50))
RETURNS VARCHAR(100)
BEGIN
    DECLARE nombre_completo VARCHAR(100);
    SET nombre_completo = CONCAT(nombre, ' ', apellido);
    RETURN nombre_completo;
END &&

DELIMITER ;

    
