USE [referencias];

DECLARE @idEmpresa INT				= 1;

DECLARE @FacturaQuery varchar(max)  = '';
DECLARE @Base VARCHAR(MAX)			= '';
DECLARE @idDeposito INT				= '';
DECLARE @idBanco INT				= 1;

-- Consulta de las bases de datos y sucursales activas
DECLARE @tableConf  TABLE(idEmpresa INT, idSucursal INT, servidor VARCHAR(250), baseConcentra VARCHAR(250), sqlCmd VARCHAR(8000), cargaDiaria VARCHAR(8000));
DECLARE @tableBancoFactura TABLE(consecutivo INT IDENTITY(1,1), idDeposito INT);
DECLARE @tableBancoCotizacion TABLE(consecutivo INT IDENTITY(1,1), idDeposito INT);
INSERT INTO @tableConf Execute [dbo].[SEL_ACTIVE_DATABASES_SP];

DECLARE @Current INT = 0, @Max INT = 0;
DECLARE @CurrentBanco INT = 0, @MaxBanco INT = 0;
DECLARE @CurrentBancoCoti INT = 0, @MaxBancoCoti INT = 0;

SELECT @Current = MIN(idSucursal),@Max = MAX(idSucursal) FROM @tableConf WHERE idEmpresa = @idEmpresa;
WHILE(@Current <= @Max )
	BEGIN
		-- FUNCIONAMIENTO PARA FACTURAS
		-- FUNCIONAMIENTO PARA FACTURAS
		-- FUNCIONAMIENTO PARA FACTURAS
		
		SET @FacturaQuery = 'SELECT								B.idBmer							 FROM [referencias].[dbo].[Referencia]				R 							 INNER JOIN [referencias].[dbo].[Bancomer]			B	ON R.Referencia = SUBSTRING(b.concepto,3,20)							 INNER JOIN [referencias].[dbo].[DetalleReferencia]	DR	ON DR.idReferencia = R.idReferencia							 WHERE R.idEmpresa			 = ' + CONVERT( VARCHAR(3), @idEmpresa ) + '								  AND DR.idSucursal		 = ' + CONVERT( VARCHAR(3), @Current ) + '								  AND B.estatusRevision	 = 1
								  AND B.esCargo			 = 0
								  AND DR.idTipoDocumento = 1;';

		INSERT INTO @tableBancoFactura
		EXECUTE( @FacturaQuery );
				
		-- SET del parametro Base		
		SET @Base = (SELECT servidor FROM @tableConf WHERE idSucursal = @Current);
		
		-- Inicia segundo cursor
		SELECT @CurrentBanco = MIN(consecutivo),@MaxBanco = MAX(consecutivo) FROM @tableBancoFactura;
		WHILE(@CurrentBanco <= @MaxBanco )
			BEGIN
				-- Funcionamiento de meter en cxc_refantypag
				-- Funcionamiento de meter en cxc_refantypag				
				BEGIN TRY		
					SET @idDeposito			  = ( SELECT TOP 1 idDeposito FROM @tableBancoFactura WHERE consecutivo = @CurrentBanco );
					SELECT @FacturaQuery	  = [dbo].[fnReferenciaBancomerFactura]( @Base, @idDeposito );
					EXECUTE( @FacturaQuery ); 
					
					-- PRINT( 'idDeposito: ' + @idDeposito );
					IF( @@ROWCOUNT > 0 )
						BEGIN
							-- INSERT INTO [referencias].[dbo].[RAPDeposito](rap_folio,idBanco,idDeposito,idOrigenReferencia) VALUES (@@IDENTITY,1,@idDeposito,'Procesos Automáticos | Factura');
							INSERT INTO [referencias].[dbo].[RAPDeposito](idEmpresa, idSucursal, rap_folio,idBanco,idDeposito,idOrigenReferencia) VALUES (@idEmpresa, @Current, @@IDENTITY, @idBanco, @idDeposito, 'Procesos Automáticos | Factura');
							UPDATE [referencias].[dbo].[Bancomer] SET estatusRevision = 2 WHERE idBmer = @idDeposito;
						END
					
				END TRY
				BEGIN CATCH	
					INSERT INTO LogRAP(log_error, log_origen, log_fecha, idBanco, idDeposito, idEmpresa, idSucursal) VALUES( ERROR_MESSAGE(), 'Procesos Automáticos | Factura', GETDATE(), @idBanco, @idDeposito, @idEmpresa, @Current );
				END CATCH
				-- Funcionamiento de meter en cxc_refantypag
				-- Funcionamiento de meter en cxc_refantypag
			SET	@CurrentBanco = @CurrentBanco + 1;
			END	
		-- /FUNCIONAMIENTO PARA FACTURAS
		-- /FUNCIONAMIENTO PARA FACTURAS
		-- /FUNCIONAMIENTO PARA FACTURAS
		
		
		-- FUNCIONAMIENTO PARA COTIZACIONES
		-- FUNCIONAMIENTO PARA COTIZACIONES
		-- FUNCIONAMIENTO PARA COTIZACIONES
		SET @FacturaQuery = 'SELECT
								B.idBmer
							 FROM Referencia R 
							 INNER JOIN Bancomer B ON R.Referencia = SUBSTRING(b.concepto,3,20)
							 INNER JOIN Centralizacionv2..DIG_CAT_BASES_BPRO BP ON R.idEmpresa = BP.emp_idempresa
							 INNER JOIN Rel_BancoCobro C ON R.idEmpresa = C.emp_idempresa
							 INNER JOIN DetalleReferencia DR ON  DR.idReferencia = R.idReferencia AND DR.idSucursal = BP.suc_idsucursal
							 WHERE R.idEmpresa				= ' + CONVERT( VARCHAR(3), @idEmpresa ) + '
								  AND DR.idSucursal			= ' + CONVERT( VARCHAR(3), @Current ) + '
								  AND B.estatusRevision		= 1
								  AND B.esCargo				= 0
								  AND DR.idTipoDocumento	= 2
								  AND C.IdBanco				= 1;';

		INSERT INTO @tableBancoCotizacion
		EXECUTE( @FacturaQuery );
		
		-- SELECT * FROM @tableBancoCotizacion;
		
		-- Inicia segundo cursor
		SELECT @CurrentBancoCoti = MIN(consecutivo),@MaxBancoCoti = MAX(consecutivo) FROM @tableBancoCotizacion;
		WHILE(@CurrentBancoCoti <= @MaxBancoCoti )
			BEGIN
				-- Funcionamiento de meter en cxc_refantypag
				-- Funcionamiento de meter en cxc_refantypag				
				BEGIN TRY		
					SET @idDeposito			  = ( SELECT TOP 1 idDeposito FROM @tableBancoCotizacion WHERE consecutivo = @CurrentBancoCoti );
					SELECT @FacturaQuery	  = [dbo].[fnReferenciaBancomerCotizacion]( @Base, @idDeposito );
					EXECUTE( @FacturaQuery ); 
					
					-- PRINT( 'idDeposito: ' + @idDeposito );
					IF( @@ROWCOUNT > 0 )
						BEGIN
							-- PRINT('Todo Bien');
							-- INSERT INTO [referencias].[dbo].[RAPDeposito](rap_folio,idBanco,idDeposito,idOrigenReferencia) VALUES (@@IDENTITY,1,@idDeposito,'Procesos Automáticos | Cotización');
							INSERT INTO [referencias].[dbo].[RAPDeposito](idEmpresa, idSucursal, rap_folio,idBanco,idDeposito,idOrigenReferencia) VALUES (@idEmpresa, @Current, @@IDENTITY, @idBanco, @idDeposito,'Procesos Automáticos | Cotización');
							UPDATE [referencias].[dbo].[Bancomer] SET estatusRevision = 2 WHERE idBmer = @idDeposito;
						END
					
				END TRY
				BEGIN CATCH	
					-- PRINT('Si hay error');
					INSERT INTO LogRAP(log_error, log_origen, log_fecha, idBanco, idDeposito, idEmpresa, idSucursal) VALUES( ERROR_MESSAGE(), 'Procesos Automáticos | Cotización', GETDATE(), @idBanco, @idDeposito, @idEmpresa, @Current );
				END CATCH
				-- Funcionamiento de meter en cxc_refantypag
				-- Funcionamiento de meter en cxc_refantypag
			SET	@CurrentBancoCoti = @CurrentBancoCoti + 1;
			END	
		
		
		
		-- /FUNCIONAMIENTO PARA COTIZACIONES
		-- /FUNCIONAMIENTO PARA COTIZACIONES
		-- /FUNCIONAMIENTO PARA COTIZACIONES
		
		DELETE FROM @tableBancoCotizacion;
		DELETE FROM @tableBancoFactura;
		SET	@Current = @Current + 1;
	END 