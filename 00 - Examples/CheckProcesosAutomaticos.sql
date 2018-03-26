USE [referencias];

DECLARE @idEmpresa INT = 4;
EXEC [Check_Automaticas_Bancomer_SP] @idEmpresa;
EXEC [Check_Automaticas_Santander_SP] @idEmpresa;


-- SELECT * FROM [RAPDeposito] ORDER BY idRAPDeposito DESC;
-- SELECT * FROM [LogRAP] ORDER BY log_id DESC;
-- SELECT * FROM GA_Corporativa.dbo.cxc_refantypag ORDER BY rap_folio DESC;

-- SELECT * FROM [RAPDeposito] WHERE idEmpresa = 4 ORDER BY idRAPDeposito DESC;

-- SELECT * FROM Tesoreria.dbo.Referencia ORDER BY idReferencia DESC