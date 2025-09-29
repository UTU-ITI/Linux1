CREATE TABLE registro (
    id INT AUTO_INCREMENT PRIMARY KEY,
    Fecha VARCHAR(10),   -- O DATE si el formato es YYYY-MM-DD
    SN VARCHAR(50),      -- Número de Serie
    Estado INT(1),  -- Estado
    procesado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);