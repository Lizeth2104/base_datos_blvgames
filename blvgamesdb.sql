-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 24-10-2025 a las 16:11:34
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `blvgamesdb`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_AgregarCategoria` (IN `p_Nombre` VARCHAR(50), IN `p_Descripcion` VARCHAR(200), IN `p_Icono` VARCHAR(50), IN `p_Color` VARCHAR(20))   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error al agregar categoría';
    END;
    
    START TRANSACTION;
    
    IF EXISTS (SELECT 1 FROM Categorias WHERE Nombre = p_Nombre) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La categoría ya existe';
    END IF;
    
    INSERT INTO Categorias (Nombre, Descripcion, Icono, Color)
    VALUES (p_Nombre, p_Descripcion, p_Icono, p_Color);
    
    SELECT IdCategoria, Nombre, Descripcion, Icono, Color
    FROM Categorias
    WHERE IdCategoria = LAST_INSERT_ID();
    
    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_AgregarVideoJuego` (IN `p_Titulo` VARCHAR(200), IN `p_Descripcion` TEXT, IN `p_Precio` DECIMAL(10,2), IN `p_EmailDesarrollador` VARCHAR(100))   BEGIN
    DECLARE v_IdDesarrollador INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error al agregar juego';
    END;
    
    START TRANSACTION;
    
    SELECT IdUsuario INTO v_IdDesarrollador
    FROM Usuarios
    WHERE Email = p_EmailDesarrollador AND Rol = 'Desarrollador';
    
    IF v_IdDesarrollador IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Desarrollador no encontrado';
    END IF;
    
    INSERT INTO VideoJuegos (Titulo, Descripcion, Precio, IdDesarrollador)
    VALUES (p_Titulo, p_Descripcion, p_Precio, v_IdDesarrollador);
    
    COMMIT;
    SELECT 'Juego agregado exitosamente' AS mensaje;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ComprarJuego` (IN `p_EmailUsuario` VARCHAR(100), IN `p_IdJuego` INT)   BEGIN
    DECLARE v_IdUsuario INT;
    DECLARE v_Precio DECIMAL(10,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error al procesar compra';
    END;
    
    START TRANSACTION;
    
    SELECT IdUsuario INTO v_IdUsuario
    FROM Usuarios
    WHERE Email = p_EmailUsuario;
    
    IF v_IdUsuario IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM Compras WHERE IdUsuario = v_IdUsuario AND IdJuego = p_IdJuego) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya posees este juego';
    END IF;
    
    SELECT Precio INTO v_Precio
    FROM VideoJuegos
    WHERE IdJuego = p_IdJuego AND Activo = TRUE;
    
    IF v_Precio IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Juego no disponible';
    END IF;
    
    INSERT INTO Compras (IdUsuario, IdJuego, MontoTotal, MetodoPago)
    VALUES (v_IdUsuario, p_IdJuego, v_Precio, 'Tarjeta');
    
    COMMIT;
    SELECT 'Compra realizada exitosamente' AS mensaje;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_EliminarCategoria` (IN `p_IdCategoria` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error al eliminar categoría';
    END;
    
    START TRANSACTION;
    
    UPDATE VideoJuegos SET IdCategoria = NULL WHERE IdCategoria = p_IdCategoria;
    
    DELETE FROM Categorias WHERE IdCategoria = p_IdCategoria;
    
    COMMIT;
    SELECT 'Categoría eliminada exitosamente' AS mensaje;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_IniciarSesion` (IN `p_Email` VARCHAR(100), IN `p_Contrasena` VARCHAR(255))   BEGIN
    SELECT IdUsuario, Nombre, Email, Rol
    FROM Usuarios
    WHERE Email = p_Email 
      AND ContrasenaHash = p_Contrasena 
      AND Activo = TRUE;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ObtenerCategorias` ()   BEGIN
    SELECT IdCategoria, Nombre, Descripcion, Icono, Color, FechaCreacion
    FROM Categorias
    ORDER BY Nombre;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_RegistrarUsuario` (IN `p_Nombre` VARCHAR(100), IN `p_Email` VARCHAR(100), IN `p_Contrasena` VARCHAR(255), IN `p_Rol` VARCHAR(20))   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error al registrar usuario';
    END;
    
    START TRANSACTION;
    
    IF EXISTS (SELECT 1 FROM Usuarios WHERE Email = p_Email) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El email ya está registrado';
    END IF;
    
    INSERT INTO Usuarios (Nombre, Email, ContrasenaHash, Rol)
    VALUES (p_Nombre, p_Email, p_Contrasena, p_Rol);
    
    COMMIT;
    SELECT 'Usuario registrado exitosamente' AS mensaje;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `IdCategoria` int(11) NOT NULL,
  `Nombre` varchar(50) NOT NULL,
  `Descripcion` varchar(200) DEFAULT NULL,
  `Icono` varchar(50) DEFAULT 'fa-gamepad',
  `Color` varchar(20) DEFAULT '#667eea',
  `FechaCreacion` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `categorias`
--

INSERT INTO `categorias` (`IdCategoria`, `Nombre`, `Descripcion`, `Icono`, `Color`, `FechaCreacion`) VALUES
(1, 'Aventura', 'Juegos de exploración y descubrimiento', 'fa-compass', '#10b981', '2025-10-20 12:37:28'),
(2, 'Acción', 'Juegos de combate y adrenalina', 'fa-burst', '#ef4444', '2025-10-20 12:37:28'),
(3, 'Estrategia', 'Juegos de planificación y táctica', 'fa-chess', '#8b5cf6', '2025-10-20 12:37:28'),
(4, 'Deportes', 'Juegos deportivos y competitivos', 'fa-futbol', '#f59e0b', '2025-10-20 12:37:28'),
(5, 'RPG', 'Juegos de rol y aventura', 'fa-dragon', '#ec4899', '2025-10-20 12:37:28'),
(6, 'Battle Royale', 'Juegos de supervivencia multijugador', 'fa-crosshairs', '#06b6d4', '2025-10-20 12:37:28');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compras`
--

CREATE TABLE `compras` (
  `IdCompra` int(11) NOT NULL,
  `IdUsuario` int(11) NOT NULL,
  `IdJuego` int(11) NOT NULL,
  `FechaCompra` datetime DEFAULT current_timestamp(),
  `MontoTotal` decimal(10,2) NOT NULL,
  `MetodoPago` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `compras`
--

INSERT INTO `compras` (`IdCompra`, `IdUsuario`, `IdJuego`, `FechaCompra`, `MontoTotal`, `MetodoPago`) VALUES
(1, 4, 1, '2025-10-20 12:37:28', 150.00, 'Tarjeta'),
(2, 4, 3, '2025-10-20 12:37:28', 350.00, 'Tarjeta'),
(3, 5, 2, '2025-10-20 12:37:28', 280.00, 'PayPal'),
(4, 5, 6, '2025-10-20 12:37:28', 0.00, 'Gratis');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `listadeseos`
--

CREATE TABLE `listadeseos` (
  `IdListaDeseos` int(11) NOT NULL,
  `IdUsuario` int(11) NOT NULL,
  `IdJuego` int(11) NOT NULL,
  `FechaAgregado` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `listadeseos`
--

INSERT INTO `listadeseos` (`IdListaDeseos`, `IdUsuario`, `IdJuego`, `FechaAgregado`) VALUES
(1, 4, 2, '2025-10-20 12:37:29'),
(2, 4, 5, '2025-10-20 12:37:29'),
(3, 5, 1, '2025-10-20 12:37:29'),
(4, 5, 4, '2025-10-20 12:37:29');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sesiones`
--

CREATE TABLE `sesiones` (
  `IdSesion` int(11) NOT NULL,
  `IdUsuario` int(11) NOT NULL,
  `FechaInicio` datetime DEFAULT current_timestamp(),
  `FechaFin` datetime DEFAULT NULL,
  `DireccionIP` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `IdUsuario` int(11) NOT NULL,
  `Nombre` varchar(100) NOT NULL,
  `Email` varchar(100) NOT NULL,
  `ContrasenaHash` varchar(255) NOT NULL,
  `Rol` enum('Admin','Desarrollador','Usuario') NOT NULL DEFAULT 'Usuario',
  `FechaRegistro` datetime DEFAULT current_timestamp(),
  `Activo` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`IdUsuario`, `Nombre`, `Email`, `ContrasenaHash`, `Rol`, `FechaRegistro`, `Activo`) VALUES
(1, 'Administrador', 'admin@blvgames.bo', 'admin123', 'Admin', '2025-10-20 12:37:28', 1),
(2, 'Developer One', 'dev@blvgames.bo', 'dev123', 'Desarrollador', '2025-10-20 12:37:28', 1),
(3, 'María García', 'maria@blvgames.bo', 'maria123', 'Desarrollador', '2025-10-20 12:37:28', 1),
(4, 'Carlos Pérez', 'carlos@blvgames.bo', 'carlos123', 'Usuario', '2025-10-20 12:37:28', 1),
(5, 'Ana López', 'ana@blvgames.bo', 'ana123', 'Desarrollador', '2025-10-20 12:37:28', 1),
(6, 'Roberto Flores', 'roberto@blvgames.bo', 'roberto123', 'Desarrollador', '2025-10-24 09:58:42', 1),
(7, 'Patricia Quispe', 'patricia@blvgames.bo', 'patricia123', 'Desarrollador', '2025-10-24 09:58:42', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `valoraciones`
--

CREATE TABLE `valoraciones` (
  `IdValoracion` int(11) NOT NULL,
  `IdUsuario` int(11) NOT NULL,
  `IdJuego` int(11) NOT NULL,
  `Puntuacion` int(11) NOT NULL CHECK (`Puntuacion` between 1 and 5),
  `Comentario` varchar(1000) DEFAULT NULL,
  `FechaValoracion` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `valoraciones`
--

INSERT INTO `valoraciones` (`IdValoracion`, `IdUsuario`, `IdJuego`, `Puntuacion`, `Comentario`, `FechaValoracion`) VALUES
(1, 4, 1, 5, 'Excelente juego, muy adictivo', '2025-10-20 12:37:28'),
(2, 4, 3, 4, 'Buena simulación de fútbol', '2025-10-20 12:37:28'),
(3, 5, 2, 5, 'El mejor juego de mundo abierto', '2025-10-20 12:37:28'),
(4, 5, 6, 4, 'Divertido con amigos', '2025-10-20 12:37:28');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `videojuegos`
--

CREATE TABLE `videojuegos` (
  `IdJuego` int(11) NOT NULL,
  `Titulo` varchar(200) NOT NULL,
  `Descripcion` text DEFAULT NULL,
  `Precio` decimal(10,2) NOT NULL,
  `IdDesarrollador` int(11) NOT NULL,
  `IdCategoria` int(11) DEFAULT NULL,
  `ImagenUrl` varchar(500) DEFAULT NULL,
  `Categoria` varchar(50) DEFAULT NULL,
  `FechaPublicacion` datetime DEFAULT current_timestamp(),
  `CalificacionPromedio` decimal(3,2) DEFAULT 0.00,
  `Activo` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `videojuegos`
--

INSERT INTO `videojuegos` (`IdJuego`, `Titulo`, `Descripcion`, `Precio`, `IdDesarrollador`, `IdCategoria`, `ImagenUrl`, `Categoria`, `FechaPublicacion`, `CalificacionPromedio`, `Activo`) VALUES
(1, 'Minecraft', 'Juego sandbox de construcción y supervivencia', 150.00, 2, 1, 'https://upload.wikimedia.org/wikipedia/en/thumb/b/b6/Minecraft_2024_cover_art.png/250px-Minecraft_2024_cover_art.png', NULL, '2025-10-20 12:37:28', 0.00, 1),
(2, 'Grand Theft Auto V', 'Juego de acción y mundo abierto', 280.00, 2, 2, 'https://assetsio.gnwcdn.com/eurogamer-zjp1vx.jpg?width=1200&height=630&fit=crop&enable=upscale&auto=webp', NULL, '2025-10-20 12:37:28', 0.00, 1),
(3, 'FIFA 24', 'Simulador de fútbol más realista', 350.00, 3, 4, 'https://i.blogs.es/f83ad0/fifa24/840_560.jpeg', NULL, '2025-10-20 12:37:28', 0.00, 1),
(4, 'Call of Duty: Modern Warfare', 'Shooter en primera persona', 420.00, 2, 2, 'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/2000950/capsule_616x353.jpg?t=1678294805', NULL, '2025-10-20 12:37:28', 0.00, 1),
(5, 'The Legend of Zelda', 'Aventura épica de fantasía', 380.00, 3, 5, 'https://i.blogs.es/4ad18e/zelda-1/500_333.jpeg', NULL, '2025-10-20 12:37:28', 0.00, 1),
(6, 'Fortnite', 'Battle Royale gratuito', 0.00, 2, 6, 'https://i.ytimg.com/vi/adGdyCdvKz4/maxresdefault.jpg', NULL, '2025-10-20 12:37:28', 0.00, 1),
(8, 'Cyberpunk 2077', 'RPG de mundo abierto ambientado en Night City', 299.00, 2, 1, 'https://image.api.playstation.com/vulcan/ap/rnd/202111/3013/cKZ4tKNFj9C00giTzYtH8PF1.png', NULL, '2020-12-10 00:00:00', 0.00, 1),
(9, 'Red Dead Redemption 2', 'Épica aventura del salvaje oeste americano', 350.00, 2, 1, 'https://upload.wikimedia.org/wikipedia/en/4/44/Red_Dead_Redemption_II.jpg', NULL, '2018-10-26 00:00:00', 0.00, 1),
(10, 'Assassins Creed Valhalla', 'Vive la era vikinga como Eivor', 280.00, 2, 1, 'https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcS16Wk0INy5doa9tThQ9hLahQv-VtFoFV7FNPv-P6pFQlIpvAEgODF5S1l_cCtFlJWW_BYbZJmR8o0mqr6zS6pjSN9r1F91QgIEi0d4880', NULL, '2020-11-10 00:00:00', 0.00, 1),
(11, 'Hogwarts Legacy', 'Aventura mágica en el mundo de Harry Potter', 340.00, 2, 1, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRqvAryEu9AjQSPy65-w8zHfyYJpyb6qFbQ4vdcFoSAjyGbQ2e_n8VKGNIS2onLDryZpacBhKnlAp26bsIWxPAAXbtmfH_q3Pciz4aaLw', NULL, '2023-02-10 00:00:00', 0.00, 1),
(12, 'The Witcher 3', 'Aventura épica de Geralt de Rivia', 250.00, 3, 1, 'https://i.blogs.es/4373da/the-witcher-3/1200_800.webp', NULL, '2015-05-19 00:00:00', 0.00, 1),
(13, 'Elden Ring', 'RPG de acción en un mundo oscuro y épico', 380.00, 3, 1, 'https://image.api.playstation.com/vulcan/ap/rnd/202110/2000/aGhopp3MHppi7kooGE2Dtt8C.png', NULL, '2022-02-25 00:00:00', 0.00, 1),
(14, 'God of War Ragnarok', 'Kratos y Atreus enfrentan el Ragnarok', 420.00, 3, 1, 'https://image.api.playstation.com/vulcan/ap/rnd/202207/1210/4xJ8XB3bi888QTLZYdl7Oi0s.png', NULL, '2022-11-09 00:00:00', 0.00, 1),
(15, 'Spider-Man Miles Morales', 'Miles Morales protege Nueva York', 320.00, 3, 1, 'https://encrypted-tbn2.gstatic.com/images?q=tbn:ANd9GcRDHPKCCfttIua_HqmVlk5qeemylbbAgKm0Gqm82FzLzUhwK4PFYto9cKx9imCyx_St8LkftR-bgR6jxiqDSTRKfOKSrgR2yOgABLuG7iSl9w', NULL, '2020-11-12 00:00:00', 0.00, 1),
(16, 'Valorant', 'Shooter táctico 5v5 competitivo', 0.00, 5, 2, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQeh26DTTCtPRId8npkChidMmX5ygTFerW-JA&s', NULL, '2020-06-02 00:00:00', 0.00, 1),
(17, 'League of Legends', 'MOBA estratégico multijugador', 0.00, 5, 5, 'https://gaming-cdn.com/images/products/9456/616x353/league-of-legends-pc-juego-cover.jpg?v=1747212286', NULL, '2009-10-27 00:00:00', 0.00, 1),
(18, 'Counter-Strike 2', 'Shooter táctico competitivo renovado', 0.00, 5, 2, 'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/730/header.jpg', NULL, '2023-09-27 00:00:00', 0.00, 1),
(19, 'Apex Legends', 'Battle Royale con héroes únicos', 0.00, 5, 2, 'https://media.contentapi.ea.com/content/dam/apex-legends/images/2019/01/apex-featured-image-16x9.jpg', NULL, '2019-02-04 00:00:00', 0.00, 1),
(20, 'The Last of Us Part II', 'Secuela de la aclamada aventura post-apocalíptica', 380.00, 6, 1, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQbpUAsCegtncvJGWyFy8VYgJAb8VxaILJGbA&s', NULL, '2020-06-19 00:00:00', 0.00, 1),
(21, 'Resident Evil 4 Remake', 'Remake del clásico survival horror', 360.00, 6, 3, 'https://image.api.playstation.com/vulcan/ap/rnd/202210/0706/EVWyZD63pahuh95eKloFaJuC.png', NULL, '2023-03-24 00:00:00', 0.00, 1),
(22, 'Starfield', 'RPG espacial de exploración masiva', 390.00, 6, 1, 'https://cdn.akamai.steamstatic.com/steam/apps/1716740/header.jpg', NULL, '2023-09-06 00:00:00', 0.00, 1),
(23, 'Baldurs Gate 3', 'RPG por turnos basado en D&D', 340.00, 6, 1, 'https://dropinblog.net/34253310/files/featured/imagem-2024-08-30-140231874.png', NULL, '2023-08-03 00:00:00', 0.00, 1),
(24, 'Stray', 'Aventura como un gato en ciudad cyberpunk', 180.00, 7, 1, 'https://image.api.playstation.com/vulcan/ap/rnd/202206/0300/E2vZwVaDJbhLZpJo7Q10IyYo.png', NULL, '2022-07-19 00:00:00', 0.00, 1),
(25, 'It Takes Two', 'Aventura cooperativa para dos jugadores', 220.00, 7, 1, 'https://encrypted-tbn3.gstatic.com/images?q=tbn:ANd9GcTRIWmdnmj4638AVEfMI8RxS2PtQKgXZohOFF00uE9GBS_vdqT5mOKo4tmhTpsKhByxKnKc-tOqfk_cr2hvJ3brRA0rRV-474NMH1BuFR9n', NULL, '2021-03-26 00:00:00', 0.00, 1),
(26, 'Fall Guys', 'Battle royale casual y divertido', 0.00, 7, 6, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTVqfpOEsBPruRyPSbIMXhNgflXr6BWNeP_vQ&s', NULL, '2020-08-04 00:00:00', 0.00, 1),
(27, 'Rocket League', 'Fútbol con autos acrobáticos', 0.00, 7, 4, 'https://cdn.cloudflare.steamstatic.com/steam/apps/252950/header.jpg', NULL, '2015-07-07 00:00:00', 0.00, 1);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_estadisticasventas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_estadisticasventas` (
`IdJuego` int(11)
,`Titulo` varchar(200)
,`Desarrollador` varchar(100)
,`TotalVentas` bigint(21)
,`IngresoTotal` decimal(32,2)
,`CalificacionPromedio` decimal(14,4)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_juegoscompletos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_juegoscompletos` (
`IdJuego` int(11)
,`Titulo` varchar(200)
,`Descripcion` text
,`Precio` decimal(10,2)
,`ImagenUrl` varchar(500)
,`FechaPublicacion` datetime
,`CalificacionPromedio` decimal(3,2)
,`NombreDesarrollador` varchar(100)
,`IdDesarrollador` int(11)
,`NombreCategoria` varchar(50)
,`ColorCategoria` varchar(20)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_estadisticasventas`
--
DROP TABLE IF EXISTS `vw_estadisticasventas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_estadisticasventas`  AS SELECT `j`.`IdJuego` AS `IdJuego`, `j`.`Titulo` AS `Titulo`, `u`.`Nombre` AS `Desarrollador`, count(`c`.`IdCompra`) AS `TotalVentas`, sum(`c`.`MontoTotal`) AS `IngresoTotal`, avg(`v`.`Puntuacion`) AS `CalificacionPromedio` FROM (((`videojuegos` `j` join `usuarios` `u` on(`j`.`IdDesarrollador` = `u`.`IdUsuario`)) left join `compras` `c` on(`j`.`IdJuego` = `c`.`IdJuego`)) left join `valoraciones` `v` on(`j`.`IdJuego` = `v`.`IdJuego`)) GROUP BY `j`.`IdJuego`, `j`.`Titulo`, `u`.`Nombre` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_juegoscompletos`
--
DROP TABLE IF EXISTS `vw_juegoscompletos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_juegoscompletos`  AS SELECT `j`.`IdJuego` AS `IdJuego`, `j`.`Titulo` AS `Titulo`, `j`.`Descripcion` AS `Descripcion`, `j`.`Precio` AS `Precio`, `j`.`ImagenUrl` AS `ImagenUrl`, `j`.`FechaPublicacion` AS `FechaPublicacion`, `j`.`CalificacionPromedio` AS `CalificacionPromedio`, `u`.`Nombre` AS `NombreDesarrollador`, `u`.`IdUsuario` AS `IdDesarrollador`, `c`.`Nombre` AS `NombreCategoria`, `c`.`Color` AS `ColorCategoria` FROM ((`videojuegos` `j` join `usuarios` `u` on(`j`.`IdDesarrollador` = `u`.`IdUsuario`)) left join `categorias` `c` on(`j`.`IdCategoria` = `c`.`IdCategoria`)) WHERE `j`.`Activo` = 1 ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`IdCategoria`),
  ADD UNIQUE KEY `Nombre` (`Nombre`),
  ADD KEY `idx_nombre` (`Nombre`);

--
-- Indices de la tabla `compras`
--
ALTER TABLE `compras`
  ADD PRIMARY KEY (`IdCompra`),
  ADD KEY `idx_usuario` (`IdUsuario`),
  ADD KEY `idx_juego` (`IdJuego`),
  ADD KEY `idx_fecha` (`FechaCompra`);

--
-- Indices de la tabla `listadeseos`
--
ALTER TABLE `listadeseos`
  ADD PRIMARY KEY (`IdListaDeseos`),
  ADD UNIQUE KEY `unique_wishlist` (`IdUsuario`,`IdJuego`),
  ADD KEY `IdJuego` (`IdJuego`),
  ADD KEY `idx_usuario` (`IdUsuario`);

--
-- Indices de la tabla `sesiones`
--
ALTER TABLE `sesiones`
  ADD PRIMARY KEY (`IdSesion`),
  ADD KEY `idx_usuario` (`IdUsuario`),
  ADD KEY `idx_fecha` (`FechaInicio`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`IdUsuario`),
  ADD UNIQUE KEY `Email` (`Email`),
  ADD KEY `idx_email` (`Email`),
  ADD KEY `idx_rol` (`Rol`);

--
-- Indices de la tabla `valoraciones`
--
ALTER TABLE `valoraciones`
  ADD PRIMARY KEY (`IdValoracion`),
  ADD UNIQUE KEY `unique_user_game` (`IdUsuario`,`IdJuego`),
  ADD KEY `idx_juego` (`IdJuego`);

--
-- Indices de la tabla `videojuegos`
--
ALTER TABLE `videojuegos`
  ADD PRIMARY KEY (`IdJuego`),
  ADD KEY `idx_desarrollador` (`IdDesarrollador`),
  ADD KEY `idx_categoria` (`IdCategoria`),
  ADD KEY `idx_titulo` (`Titulo`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `IdCategoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `compras`
--
ALTER TABLE `compras`
  MODIFY `IdCompra` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `listadeseos`
--
ALTER TABLE `listadeseos`
  MODIFY `IdListaDeseos` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `sesiones`
--
ALTER TABLE `sesiones`
  MODIFY `IdSesion` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `IdUsuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `valoraciones`
--
ALTER TABLE `valoraciones`
  MODIFY `IdValoracion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `videojuegos`
--
ALTER TABLE `videojuegos`
  MODIFY `IdJuego` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `compras`
--
ALTER TABLE `compras`
  ADD CONSTRAINT `compras_ibfk_1` FOREIGN KEY (`IdUsuario`) REFERENCES `usuarios` (`IdUsuario`) ON DELETE CASCADE,
  ADD CONSTRAINT `compras_ibfk_2` FOREIGN KEY (`IdJuego`) REFERENCES `videojuegos` (`IdJuego`);

--
-- Filtros para la tabla `listadeseos`
--
ALTER TABLE `listadeseos`
  ADD CONSTRAINT `listadeseos_ibfk_1` FOREIGN KEY (`IdUsuario`) REFERENCES `usuarios` (`IdUsuario`) ON DELETE CASCADE,
  ADD CONSTRAINT `listadeseos_ibfk_2` FOREIGN KEY (`IdJuego`) REFERENCES `videojuegos` (`IdJuego`) ON DELETE CASCADE;

--
-- Filtros para la tabla `sesiones`
--
ALTER TABLE `sesiones`
  ADD CONSTRAINT `sesiones_ibfk_1` FOREIGN KEY (`IdUsuario`) REFERENCES `usuarios` (`IdUsuario`) ON DELETE CASCADE;

--
-- Filtros para la tabla `valoraciones`
--
ALTER TABLE `valoraciones`
  ADD CONSTRAINT `valoraciones_ibfk_1` FOREIGN KEY (`IdUsuario`) REFERENCES `usuarios` (`IdUsuario`) ON DELETE CASCADE,
  ADD CONSTRAINT `valoraciones_ibfk_2` FOREIGN KEY (`IdJuego`) REFERENCES `videojuegos` (`IdJuego`) ON DELETE CASCADE;

--
-- Filtros para la tabla `videojuegos`
--
ALTER TABLE `videojuegos`
  ADD CONSTRAINT `videojuegos_ibfk_1` FOREIGN KEY (`IdDesarrollador`) REFERENCES `usuarios` (`IdUsuario`) ON DELETE CASCADE,
  ADD CONSTRAINT `videojuegos_ibfk_2` FOREIGN KEY (`IdCategoria`) REFERENCES `categorias` (`IdCategoria`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
