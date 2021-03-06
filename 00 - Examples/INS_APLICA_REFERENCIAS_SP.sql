USE [Tesoreria]
GO
/****** Object:  StoredProcedure [dbo].[INS_APLICA_REFERENCIAS_SP]    Script Date: 01/11/2018 17:35:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[INS_APLICA_REFERENCIAS_SP]
	@idReferencia INT
AS
BEGIN
	DECLARE @idReferencianNueva INT,  @idBanco INT, @idBancoFinal INT, @Referencia VARCHAR(20)
	
	SET @idBanco		= ( SELECT IDBanco FROM Tesoreria.dbo.Referencia WHERE idReferencia = @idReferencia );
	SET @idBancoFinal	= ( SELECT depositoID FROM Tesoreria.dbo.Referencia WHERE idReferencia = @idReferencia );
	SET @Referencia		= ( SELECT [referencia] FROM [Tesoreria].[dbo].[Referencia] WHERE [idReferencia] = @idReferencia );

	IF(@idBanco = 1)
		BEGIN
			UPDATE [referencias].[dbo].[Bancomer] SET [referencia] = @Referencia, estatus = 1 WHERE [idBmer] = @idBancoFinal;
		END
	ELSE IF(@idBanco = 3)
		BEGIN
			 UPDATE [referencias].[dbo].[Santander] SET [referencia] = @Referencia, estatus = 1 WHERE [idSantander] = @idBancoFinal;
		END

	INSERT INTO [referencias].[dbo].Referencia
	SELECT 
		   [idEmpresa]
		  ,[fecha]
		  ,[referencia]
		  ,[tipoReferencia]
		  ,[numeroConsecutivo]
		  ,[estatus]
	FROM [Tesoreria].[dbo].[Referencia]
	WHERE [idReferencia] = @idReferencia

	SET @idReferencianNueva = SCOPE_IDENTITY()

	INSERT INTO [referencias].[dbo].[DetalleReferencia]
	SELECT 
		   [idSucursal]
		  ,[idDepartamento]
		  ,[idTipoDocumento]
		  ,[importeDocumento]
		  ,[documento]
		  ,[idCliente]
		  ,[idAlmacen]
		  ,@idReferencianNueva
	FROM [Tesoreria].[dbo].[DetalleReferencia]
	WHERE [idReferencia] = @idReferencia

	UPDATE  [Tesoreria].[dbo].[Referencia] SET [estatus] = 2 WHERE [idReferencia] = @idReferencia;
	
	-- Obtenemos si hay mas de una sucursal en el detalle
	DECLARE @SucVarios INT = (SELECT COUNT(DISTINCT(idSucursal)) Sucursal FROM [Tesoreria].[dbo].[Referencia] REF
	INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DET ON REF.idReferencia = DET.idReferencia
	WHERE REF.idReferencia = @idReferencia);
	
	DECLARE @idEmpresa INT = (SELECT idEmpresa FROM [Tesoreria].[dbo].[Referencia] WHERE [idReferencia] = @idReferencia);
	DECLARE @Cartera VARCHAR(255) = (SELECT '[' + ip_servidor + '].[' + nombre_base_matriz + '].dbo.VIS_CONCAR01' FROM [Centralizacionv2].[dbo].[DIG_CAT_BASES_BPRO] WHERE emp_idempresa = @idEmpresa AND tipo = 2);
	
	-- Se guarda el registro en refantipag
	DECLARE @DepartamentosNissan VARCHAR(MAX) = 
	'CASE REF.idEmpresa 							WHEN 4 THEN (											CASE (SELECT dep_nombrecto from [ControlAplicaciones].[dbo].[cat_departamentos] where  dep_iddepartamento = DET.idDepartamento)												WHEN ''OT'' THEN (																	CASE DET.idSucursal																		WHEN 6 THEN 26																		WHEN 7 THEN 31																		WHEN 8 THEN 36																	END																)												ELSE CONVERT(VARCHAR(18),DET.idDepartamento)											END										)							ELSE CONVERT(VARCHAR(18),DET.idDepartamento)						END';
	
	DECLARE @RAPreferencia VARCHAR(MAX) = 
	'CASE  -- Unidades Nuevas y Seminuevas						WHEN (SELECT dep_nombrecto from [ControlAplicaciones].[dbo].[cat_departamentos] where  dep_iddepartamento = DET.idDepartamento) IN (''UN'',''US'')						 THEN  (									CASE WHEN ( SELECT CONVERT(VARCHAR(18),ucu_idcotizacion) FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSALUNIDADES WHERE ucn_idFactura COLLATE Modern_Spanish_CS_AS = DET.documento ) IS NOT NULL
										 THEN (SELECT ucu_foliocotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSAL WHERE ucu_idcotizacion = (SELECT ucu_idcotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSALUNIDADES WHERE ucn_idFactura COLLATE Modern_Spanish_CS_AS = DET.documento)) COLLATE Modern_Spanish_CS_AS
										ELSE DET.documento
									END								)						ELSE DET.documento				   END';
	
	DECLARE @RAPiddocto VARCHAR(MAX) = 
	'CASE  -- Unidades Nuevas y Seminuevas						WHEN (SELECT dep_nombrecto from [ControlAplicaciones].[dbo].[cat_departamentos] where  dep_iddepartamento = DET.idDepartamento) IN (''UN'',''US'')						 THEN  (									CASE WHEN ( SELECT ucu_idcotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSALUNIDADES WHERE ucn_idFactura COLLATE Modern_Spanish_CS_AS = DET.documento ) IS NOT NULL
										 THEN DET.documento
										ELSE ''''
									END								)						ELSE ''''				   END';
	
	DECLARE @RAPcotped VARCHAR(MAX) = 
	'CASE  -- Unidades Nuevas y Seminuevas						WHEN (SELECT dep_nombrecto from [ControlAplicaciones].[dbo].[cat_departamentos] where  dep_iddepartamento = DET.idDepartamento) IN (''UN'',''US'')						 THEN  (									CASE WHEN ( SELECT ucu_idcotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSALUNIDADES WHERE ucn_idFactura COLLATE Modern_Spanish_CS_AS = DET.documento ) IS NOT NULL
										 THEN ''COTIZACION UNIVERSAL''
										ELSE ''''
									END								)						ELSE ''''				   END';
						
	DECLARE @Query NVARCHAR(MAX);
	SET @Query = 'INSERT INTO GA_Corporativa.dbo.cxc_refantypag
					SELECT
						rap_idempresa = REF.idEmpresa,
						rap_idsucursal = (CASE WHEN ' + CONVERT( VARCHAR(20),@SucVarios ) + ' = 1 THEN DET.idSucursal ELSE 3 END ),
						-- rap_iddepartamento = DET.idDepartamento,
						rap_iddepartamento = ' + @DepartamentosNissan + ',
						rap_idpersona = DET.idCliente,
						rap_cobrador = ''MMK'',
						rap_moneda = ''PE'',
						rap_tipocambio = 1,
						-- rap_referencia = '''',
						rap_referencia = CASE SUBSTRING(DET.documento,1,2)
											WHEN ''AA'' THEN (SELECT ucu_foliocotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSAL WHERE ucu_idcotizacion = 
															(SELECT ucu_idcotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSALUNIDADES WHERE ucn_idFactura COLLATE Modern_Spanish_CS_AS = DET.documento))
											WHEN ''AB'' THEN (SELECT ucu_foliocotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSAL WHERE ucu_idcotizacion = 
															(SELECT ucu_idcotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSALUNIDADES WHERE ucn_idFactura COLLATE Modern_Spanish_CS_AS = DET.documento))
											WHEN ''AC'' THEN (SELECT ucu_foliocotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSAL WHERE ucu_idcotizacion = 
															(SELECT ucu_idcotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSALUNIDADES WHERE ucn_idFactura COLLATE Modern_Spanish_CS_AS = DET.documento))
											WHEN ''AD'' THEN (SELECT ucu_foliocotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSAL WHERE ucu_idcotizacion = 
															(SELECT ucu_idcotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSALUNIDADES WHERE ucn_idFactura COLLATE Modern_Spanish_CS_AS = DET.documento))
											WHEN ''AE'' THEN (SELECT ucu_foliocotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSAL WHERE ucu_idcotizacion = 
															(SELECT ucu_idcotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSALUNIDADES WHERE ucn_idFactura COLLATE Modern_Spanish_CS_AS = DET.documento))
											ELSE ''''
										  END,
						rap_iddocto =  DET.documento,
						-- rap_cotped = '''',
						rap_cotped = CASE SUBSTRING(DET.documento,1,2)
										WHEN ''AA'' THEN ''COTIZACION UNIVERSAL''
										WHEN ''AB'' THEN ''COTIZACION UNIVERSAL''
										WHEN ''AC'' THEN ''COTIZACION UNIVERSAL''
										WHEN ''AD'' THEN ''COTIZACION UNIVERSAL''
										WHEN ''AE'' THEN ''COTIZACION UNIVERSAL''
										ELSE ''''
									  END,
						rap_consecutivo = (SELECT top 1 CCP_CONSCARTERA FROM '+ @Cartera +' WHERE CCP_VFDOCTO COLLATE Modern_Spanish_CS_AS = DET.documento AND CCP_IDDOCTO COLLATE Modern_Spanish_CS_AS= DET.documento AND CCP_IDPERSONA = DET.IdCliente),
						rap_importe = convert(decimal(32,2),DET.importeDocumento),
						rap_formapago = (select top 1 co.CodigoBPRO  from [referencias].[dbo].Bancomer b inner join  [referencias].[dbo].CodigoIdentificacion co  on co.CodigoBanco = b.codigoLeyenda),
						rap_numctabanc = SUBSTRING(txtOrigen,5,20),
						rap_fecha = GETDATE(),
						rap_idusuari = (SELECT top 1 usu_idusuario FROM ControlAplicaciones..cat_usuarios WHERE usu_nombreusu = ''GMI''),
						rap_idstatus = ''1'',
						rap_banco = C.IdBanco_bpro,
						rap_referenciabancaria = REF.referencia,
						rap_anno = (SELECT top 1 Vcc_Anno FROM '+ @Cartera +' WHERE CCP_VFDOCTO COLLATE Modern_Spanish_CS_AS = DET.documento  AND CCP_IDDOCTO COLLATE Modern_Spanish_CS_AS= DET.documento AND CCP_IDPERSONA = DET.IdCliente),
						RAP_AplicaPago = convert(decimal(32,2),DET.importeBPRO),
						RAP_NumDeposito = ROW_NUMBER() OVER(ORDER BY DET.idDetallereferencia ASC)
					FROM [Tesoreria].[dbo].[DetalleReferencia] DET
					INNER JOIN [Tesoreria].[dbo].[Referencia] REF		ON DET.idReferencia = REF.idReferencia
					INNER JOIN Centralizacionv2..DIG_CAT_BASES_BPRO BP	ON REF.idEmpresa = BP.emp_idempresa AND DET.idSucursal = BP.suc_idsucursal
					INNER JOIN [Tesoreria].[dbo].[DepositoBancoView] B	ON REF.depositoID = B.idBmer
					INNER JOIN [referencias].[dbo].Rel_BancoCobro C		ON REF.idEmpresa = C.emp_idempresa AND B.idBanco = C.IdBanco
					WHERE REF.idReferencia = ' + CONVERT(VARCHAR(18), @idReferencia);
	EXEC( @Query );

	SELECT 1 idEstatus ,'SE APLICO REFERENCIA' descripcion
END
