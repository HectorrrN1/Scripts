-- ====================================================
-- Author:        Alexis Eduardo Santana Vega
-- Create date:   3 Octubre 2024
-- Description:   Script para entorno de desarrollo
-- ====================================================

-- Crear la base de datos
CREATE DATABASE chepeat
GO

-- Acceder a la base de datos
USE chepeat
GO

-- Tabla de usuarios
CREATE TABLE Users (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    Email VARCHAR(255) UNIQUE NOT NULL,
    Password VARCHAR(255) NOT NULL,
    Fullname VARCHAR(120) NOT NULL
);

-- Tabla de roles
CREATE TABLE Roles (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    Name VARCHAR(10) UNIQUE NOT NULL  -- Puede ser 'ADMIN', 'SELLER', 'BUYER'
);

-- Relación muchos a muchos entre usuarios y roles
CREATE TABLE UserRoles (
    IdUser UNIQUEIDENTIFIER NOT NULL,
    IdRole UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY (IdUser, IdRole),
    FOREIGN KEY (IdUser) REFERENCES Users(Id) ON DELETE CASCADE,
    FOREIGN KEY (IdRole) REFERENCES Roles(Id) ON DELETE CASCADE
);

-- ====================================================
-- Author:        Hector Nuñez Cruz
-- Create date:   09 Octubre 2024
--Modification Date: 10 Octubre 2024
-- Description:   Propuesta para base de datos
-- ====================================================

-- Tabla para vendedores (usuarios que son sellers)
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

-- Tabla para los productos
CREATE TABLE Products (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Description VARCHAR(255),
    Price DECIMAL(10, 2) NOT NULL,
    Image VARCHAR(255),  -- URL de la imagen del producto
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IdSeller UNIQUEIDENTIFIER NOT NULL,
    FOREIGN KEY (IdSeller) REFERENCES Sellers(Id) ON DELETE CASCADE
);

-- Tabla para solicitudes de compra (relación entre compradores y productos)
CREATE TABLE PurchaseRequests (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    IdProduct UNIQUEIDENTIFIER NOT NULL,
    IdBuyer UNIQUEIDENTIFIER NOT NULL,
    RequestDate DATETIME NOT NULL DEFAULT GETDATE(),
    Status VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- Puede ser 'PENDING', 'ACCEPTED', 'REJECTED'
    FOREIGN KEY (IdProduct) REFERENCES Products(Id) ON DELETE CASCADE,
    FOREIGN KEY (IdBuyer) REFERENCES Users(Id) ON DELETE NO ACTION 
);

-- Tabla para las transacciones de ventas
CREATE TABLE Transactions (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    IdPurchaseRequest UNIQUEIDENTIFIER NOT NULL,
    TransactionDate DATETIME NOT NULL DEFAULT GETDATE(),
    Status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',  -- 'COMPLETED' o 'CANCELLED'
    FOREIGN KEY (IdPurchaseRequest) REFERENCES PurchaseRequests(Id) ON DELETE CASCADE
);

-- Agregar los roles básicos (ADMIN, SELLER, BUYER)
INSERT INTO Roles (Id, Name)
VALUES (NEWID(), 'ADMIN'), (NEWID(), 'SELLER'), (NEWID(), 'BUYER');