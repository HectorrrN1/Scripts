
-- Crear la base de datos
CREATE DATABASE chepeat
GO

-- Acceder a la base de datos
USE chepeat
GO

-- Crear la tabla Users
CREATE TABLE Users (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    Email VARCHAR(255) UNIQUE NOT NULL,
    Password VARCHAR(255) NOT NULL,
    Fullname VARCHAR(120) NOT NULL
);

-- Crear la tabla Roles
CREATE TABLE Roles (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    Name VARCHAR(6) UNIQUE NOT NULL
);

-- Crear la tabla intermedia (relación muchos a muchos) entre usuarios y roles
CREATE TABLE UserRoles (
    IdUser UNIQUEIDENTIFIER NOT NULL,
    IdRol UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY (IdUser, IdRol),
    FOREIGN KEY (IdUser) REFERENCES Users(Id) ON DELETE CASCADE,
    FOREIGN KEY (IdRol) REFERENCES Roles(Id) ON DELETE CASCADE
);

-- Crear la tabla para los datos de usuarios vendedores
CREATE TABLE Sellers (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    StoreName VARCHAR(120) NOT NULL,
	Street VARCHAR(100) NOT NULL,
	ExtNumber VARCHAR(6),
	IntNumber VARCHAR(6),
	Neighborhood VARCHAR(100),
	City VARCHAR(100),
	State VARCHAR(100),
	Country VARCHAR(100),
	CP VARCHAR(10) NOT NULL,
	AddressNotes VARCHAR(255),
	IdUser UNIQUEIDENTIFIER NOT NULL,
    FOREIGN KEY (IdUser) REFERENCES Users(Id) ON DELETE CASCADE
);

-- Agregar los roles básicos 
INSERT INTO Roles (Id, name)
VALUES (NEWID(), 'ADMIN'), (NEWID(), 'SELLER'), (NEWID(), 'BUYER');
