-- Elimina la base de datos solo si existe
DROP DATABASE IF EXISTS KaraokeV3;
-- CRea la base de datos
CREATE DATABASE KaraokeV3;

-- Usa la base de datos
use KaraokeV3;

-- Borra la tabla Empleado si existe y la crea
DROP TABLE IF EXISTS Empleado;
CREATE TABLE Empleado (
    id_emp char(10) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    fec_nac DATE NOT NULL,
    email VARCHAR(100) NOT NULL,
    tlf VARCHAR(20),
    tipo_emp VARCHAR(50),
    turno VARCHAR(20) NOT NULL,
    genero enum('M','F') NOT NULL
);

-- Borra la tabla Horario y la crea de nuevo
DROP TABLE IF EXISTS Horario;
CREATE TABLE Horario (
    dia VARCHAR(20) NOT NULL,
    h_entrada TIME NOT NULL,
    h_salida TIME NOT NULL,
    id_emp CHAR(10) NOT NULL,
    FOREIGN KEY (id_emp) REFERENCES Empleado(id_emp),
    PRIMARY KEY (dia, id_emp)
);

-- Borra la tabla Sala y la crea
DROP TABLE IF EXISTS Sala;
CREATE TABLE Sala (
    num_sala INT PRIMARY KEY,
    precio DECIMAL(10, 2) NOT NULL,
    tamaño ENUM('grande', 'mediano', 'pequeño') NOT NULL
);

-- Borra la tabla equipo y la crea
DROP TABLE IF EXISTS Equipo;
CREATE TABLE Equipo (
    id_equi INT PRIMARY KEY,
    estado VARCHAR(50) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    marca VARCHAR(50),
    num_sala INT,
    FOREIGN KEY (num_sala) REFERENCES Sala(num_sala)
);

-- Borra la tabla cliente y la crea
DROP TABLE IF EXISTS Cliente;
CREATE TABLE Cliente (
    telefono VARCHAR(20) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50),
    email VARCHAR(100),
    genero enum('M','F') NOT NULL
);

-- Borra y crea la tabla Reserva
DROP TABLE IF EXISTS Reserva;
CREATE TABLE Reserva (
    id_reserva VARCHAR(30) PRIMARY KEY,
    fec_reserva DATE NOT NULL,
    hora_ini TIME NOT NULL,
    hora_fin TIME NOT NULL,
    telefono_cliente VARCHAR(20) NOT NULL,
    num_sala INT NOT NULL,
    FOREIGN KEY (telefono_cliente) REFERENCES Cliente(telefono),
    FOREIGN KEY (num_sala) REFERENCES Sala(num_sala)
);

-- Borra y crea la tabla ValoracionCrítica
DROP TABLE IF EXISTS ValoracionCritica;
CREATE TABLE ValoracionCritica (
    id_val INT PRIMARY KEY,
    fec_val DATE NOT NULL,
    puntuacion int check(puntuacion between 1 and 5) NOT NULL,
    comentario VARCHAR(255),
    telefono_cliente VARCHAR(20) NOT NULL,
    FOREIGN KEY (telefono_cliente) REFERENCES Cliente(telefono)
);
