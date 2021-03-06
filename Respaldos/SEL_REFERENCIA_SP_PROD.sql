USE [Tesoreria]
GO
/****** Object:  StoredProcedure [dbo].[SEL_REFERENCIA_SP]    Script Date: 01/04/2018 19:10:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [SEL_REFERENCIA_SP] @idEmpresa=2, @idSucursal=1, @idDepartamento=11, @idTipoDocumento=1, @folio='00283',@idCliente = 135,@idTipoReferencia = 4, @importeDocumento = 4382.22 ,@serie='YA'
ALTER PROCEDURE [dbo].[SEL_REFERENCIA_SP]
	@idEmpresa INT = 0,
	@idSucursal int = 0,
	@idDepartamento	 int = 0,
	@idTipoDocumento INT = 0,
	@serie VARCHAR(20) = '',
	@folio VARCHAR(30) = '',
	@idCliente INT = 0,
	@idAlma NVARCHAR(10) = 0,
	@importeDocumento NUMERIC(18,2) = 0,
	@idTipoReferencia NUMERIC(18,0) = 0,
	@depositoID NUMERIC(18,0) = 0,
	@idBanco NUMERIC(18,0) = 0,
	@importeAplica NUMERIC(18,2) = 0,
	@importeBPRO NUMERIC(18,2) = 0
AS
BEGIN				

-- SE DECLARAN LAS VARIABLES PARA GUARDAR LOS VALORES ORIGINALES DE SERIE Y FOLIO
			DECLARE @referencia VARCHAR(20) = ''
			DECLARE @serieOriginal VARCHAR(20) = @serie
			DECLARE @folioOriginal VARCHAR(20) = @folio
			DECLARE @idTipoDocOriginal  int = @idTipoDocumento
			DECLARE @idReferencia NUMERIC(18,0)
				-- SE DECLARA LA VARIABLE NUMERO CONSECUTIVO Y SE BUSCA SI YA EXISTE O NO
			DECLARE @numeroConsecutivo VARCHAR(10)
				-- SI EXISTE ALGUN NUMERO CONSECUTIVO DE ALGUNA EMPRESA BUSCA EL NUMERO MAS ALTO Y LE AGREGA UN MAS 1
			IF EXISTS (SELECT numeroConsecutivo FROM  [Tesoreria].[dbo].[Referencia] WHERE idEmpresa = @idEmpresa) 
				BEGIN
					SET @numeroConsecutivo = (SELECT TOP 1(numeroConsecutivo) FROM  [Tesoreria].[dbo].[Referencia] WHERE idEmpresa = @idEmpresa ORDER BY numeroConsecutivo DESC) +1
					--SELECT @numeroConsecutivo 
				END
			ELSE
				BEGIN
					SET @numeroConsecutivo = 1
					--SELECT @numeroConsecutivo
				END 

	-- PRIMERO SE COMPRUEBA QUE TIPO DE REFERENCIA ES, SI ES DE TIPO UNO ES IGUAL REFERENCIA INDIVIDUAL
	IF @idTipoReferencia = 1
		BEGIN
				-- SE HACE UNA BUSQUEDA PARA VER SI YA EXISTE LA REFERENCIA DEL DOCUMENTO INGRESADO
				IF EXISTS (SELECT referencia FROM [Tesoreria].[dbo].[Referencia] REF INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia WHERE DEREF.documento = @serieOriginal+@folioOriginal  AND DEREF.idSucursal = @idSucursal AND  DEREF.idDepartamento = @idDepartamento AND REF.tipoReferencia = 1 AND REF.idEmpresa = @idEmpresa)	
					BEGIN
						SELECT referencia as REFERENCIA, 'Referencia Existente 1' AS ESTATUS,  REF.idReferencia AS idReferencia FROM [Tesoreria].[dbo].[Referencia] REF INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia WHERE documento = @serieOriginal+@folioOriginal  AND idSucursal = @idSucursal AND  idDepartamento = @idDepartamento AND REF.tipoReferencia = 1 AND REF.idEmpresa = @idEmpresa
					END
					-- SI NO EXISTE SE DEBE CREAR LA REFERENCIA POR TIPO DE DOCUMENTO
				ELSE
					BEGIN
						IF @idTipoDocumento = 1 
							BEGIN
								SELECT @folio = SUBSTRING(@folio,LEN(@folio)-6,7)
								SELECT @serie = SUBSTRING(@serie,LEN(@serie)-2,3)
								SET @serie = REPLICATE('0',3-LEN(@serie)) + CONVERT(VARCHAR(3),@serie)
								SET @folio = REPLICATE('0',7-LEN(@folio)) + CONVERT(VARCHAR(7),@folio)
								-- SE GENERA LA REFERENCIA
								SET @referencia = [Tesoreria].[dbo].[referencia_fn](@serie,@folio, @idSucursal,@idTipoReferencia) + 
												  [Tesoreria].[dbo].[digito_verificador_fn]([Tesoreria].[dbo].[referencia_fn](@serie,@folio, @idSucursal,@idTipoReferencia)) 
								-- SE MUESTRA LA REFERENCIA
								-- SE INSERTA LA REFERENCIA EN LA TABLA REFERENCIA CON SUS RESPECTIVOS CAMPOS
								INSERT INTO [Tesoreria].[dbo].[Referencia] VALUES(@idEmpresa, GETDATE(), @referencia,@idTipoReferencia,@numeroConsecutivo,0, @depositoID)
								SET @idReferencia = SCOPE_IDENTITY()
								-- SE INSERTAN LOS DETALLES DE LA REFERENCIA
								INSERT INTO [Tesoreria].[dbo].[DetalleReferencia] VALUES(@idSucursal,@idDepartamento, @idTipoDocOriginal, @importeDocumento, @serieOriginal+@folioOriginal, @idCliente,@idAlma,@idReferencia)
								SELECT @referencia AS REFERENCIA , 'Nueva Referencia Factura'	AS ESTATUS, @idReferencia AS idReferencia
							END
						ELSE
							BEGIN
								IF EXISTS (SELECT referencia FROM [Tesoreria].[dbo].[Referencia] REF INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia WHERE documento = @folioOriginal  AND idSucursal = @idSucursal AND  idDepartamento = @idDepartamento AND REF.tipoReferencia = 1 AND REF.idEmpresa = @idEmpresa)	
									BEGIN
										SELECT referencia as REFERENCIA, 'Referencia Existente 2' AS ESTATUS,  REF.idReferencia AS idReferencia FROM [Tesoreria].[dbo].[Referencia] REF INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia WHERE documento = @folioOriginal  AND idSucursal = @idSucursal AND  idDepartamento = @idDepartamento AND REF.tipoReferencia = 1 AND REF.idEmpresa = @idEmpresa
									END
								ELSE
									BEGIN
										IF @idTipoDocumento = 5
											BEGIN
												SET @idTipoDocumento = 3
											END
										ELSE
											BEGIN
												SET @idTipoDocumento = 2
											END
										-- SE VALIDA SI EL DEPARTAMENTO ES DE REFACCIONES PARA HACER UNA DIFERENCTE REFERENCIA
										 DECLARE @deptoRef nvarchar(10)
										 SET @deptoRef = (SELECT dep_nombrecto FROM [ControlAplicaciones].[dbo].[cat_departamentos] WHERE dep_iddepartamento = @idDepartamento)
										 IF(@deptoRef = 'RE')
											BEGIN
												 SELECT @folio = SUBSTRING(@folio,LEN(@folio)-6,7)
												 SET @folio = REPLICATE('0',7-LEN(@folio)) + CONVERT(VARCHAR(7),@folio)
												 SET @referencia = [Tesoreria].[dbo].[referencia_pd](@folio,@idDepartamento,@idSucursal,@idTipoDocumento,@idTipoReferencia) + 
																   [Tesoreria].[dbo].[digito_verificador_fn]([Tesoreria].[dbo].[referencia_pd](@folio,@idDepartamento,@idSucursal,@idTipoDocumento,@idTipoReferencia)) 
												 SELECT @referencia AS REFERENCIA , 'Nueva referencia P o C'  as estatus4
												 INSERT INTO [Tesoreria].[dbo].[Referencia] VALUES(@idEmpresa, GETDATE(), @referencia,@idTipoReferencia,@numeroConsecutivo,0,@depositoID)
												 SET @idReferencia = SCOPE_IDENTITY()
												-- SE INSERTAN LOS DETALLES DE LA REFERENCIA
												INSERT INTO [Tesoreria].[dbo].[DetalleReferencia] VALUES(@idSucursal,@idDepartamento, @idTipoDocOriginal, @importeDocumento, @folioOriginal, @idCliente,@idAlma,@idReferencia)
												SELECT @referencia AS REFERENCIA , 'Nueva Referencia Refacciones ped o cot'	AS ESTATUS, @idReferencia AS idReferencia
											END
										 ELSE
											BEGIN
												DECLARE @deptoNuSe NVARCHAR(10)
											    SET @deptoNuSe = (SELECT dep_nombrecto FROM [ControlAplicaciones].[dbo].[cat_departamentos] WHERE dep_iddepartamento = @idDepartamento)
												IF(@deptoNuSe = 'UN' or @deptoNuSe ='US')
													BEGIN
														IF EXISTS (select ucu_idcotizacion from cuentasporcobrar.dbo.uni_cotizacionuniversal where ucu_foliocotizacion = @folioOriginal)
															BEGIN
																 DECLARE @nuevoFolio nvarchar(20)
																 SET @nuevoFolio = (select ucu_idcotizacion from cuentasporcobrar.dbo.uni_cotizacionuniversal where ucu_foliocotizacion = @folioOriginal)
																 --SELECT @folio = SUBSTRING(@folio,LEN(@folio)-7,8)
																 SET @nuevoFolio = REPLICATE('0',7-LEN(@nuevoFolio)) + CONVERT(VARCHAR(7),@nuevoFolio)

																 SET @referencia = [Tesoreria].[dbo].[referencia_pd](@nuevoFolio,@idDepartamento,@idSucursal,@idTipoDocumento,@idTipoReferencia) + 
																					[Tesoreria].[dbo].[digito_verificador_fn]([Tesoreria].[dbo].[referencia_pd](@nuevoFolio,@idDepartamento,@idSucursal,@idTipoDocumento,@idTipoReferencia)) 
																 SELECT @referencia AS REFERENCIA , 'Nueva referencia P o C'  as estatus4
																 INSERT INTO [Tesoreria].[dbo].[Referencia] VALUES(@idEmpresa, GETDATE(), @referencia,@idTipoReferencia,@numeroConsecutivo,0,@depositoID)
																 SET @idReferencia = SCOPE_IDENTITY()
																 -- SE INSERTAN LOS DETALLES DE LA REFERENCIA
																 INSERT INTO [Tesoreria].[dbo].[DetalleReferencia] VALUES(@idSucursal,@idDepartamento, @idTipoDocOriginal, @importeDocumento,@folioOriginal, @idCliente,@idAlma,@idReferencia)
																 SELECT @referencia AS REFERENCIA , 'Nueva Referencia UN o US ped o cot'	AS ESTATUS,@idReferencia AS idReferencia
															END
														ELSE
															BEGIN
																SELECT 'NO EXISTE ID COTIZACIÓN' as Estatus
															END
													END
												ELSE
													BEGIN 
														-- aqui se tiene que hacer la validación si el departamento es de refacciones o no, si es de refacciones debe obtener el id de almacen donde se encuentra las piezas 
														SELECT @folio = SUBSTRING(@folio,LEN(@folio)-6,7)
														SET @folio = REPLICATE('0',7-LEN(@folio)) + CONVERT(VARCHAR(7),@folio)
														SET @referencia = [Tesoreria].[dbo].[referencia_pd](@folio,@idDepartamento,@idSucursal,@idTipoDocumento,@idTipoReferencia) + 
																		  [Tesoreria].[dbo].[digito_verificador_fn]([Tesoreria].[dbo].[referencia_pd](@folio,@idDepartamento,@idSucursal,@idTipoDocumento,@idTipoReferencia)) 
														INSERT INTO [Tesoreria].[dbo].[Referencia] VALUES(@idEmpresa, GETDATE(), @referencia,@idTipoReferencia,@numeroConsecutivo,0,@depositoID)
														SET @idReferencia = SCOPE_IDENTITY()
														-- SE INSERTAN LOS DETALLES DE LA REFERENCIA
														INSERT INTO [Tesoreria].[dbo].[DetalleReferencia] VALUES(@idSucursal,@idDepartamento, @idTipoDocOriginal, @importeDocumento,@folioOriginal, @idCliente,@idAlma,@idReferencia)
														SELECT @referencia AS REFERENCIA , 'Nueva Referencia X ped o cot'	AS ESTATUS, @idReferencia AS idReferencia
													END
											END
									END
							END
					END
		END
	ELSE
		BEGIN
				IF @idTipoReferencia = 2
					BEGIN
						IF @idTipoDocumento = 1
							BEGIN
								IF EXISTS (SELECT referencia FROM [Tesoreria].[dbo].[Referencia] REF INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia WHERE DEREF.documento = @serieOriginal+ @folioOriginal  AND DEREF.idSucursal = @idSucursal AND  DEREF.idDepartamento = @idDepartamento AND REF.tipoReferencia = 2)	
									BEGIN
										SELECT referencia as REFERENCIA, 'Referencia por Lote Pre Existente FACTURA' AS ESTATUS, REF.idReferencia AS idReferencia FROM [Tesoreria].[dbo].[Referencia] REF INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia WHERE documento = @serieOriginal+@folioOriginal  AND idSucursal = @idSucursal AND  idDepartamento = @idDepartamento AND REF.tipoReferencia = 2
										PRINT 'PRIMER FILTRO'
									END
								ELSE
									BEGIN
				
										SELECT @numeroConsecutivo = SUBSTRING(@numeroConsecutivo,LEN(@numeroConsecutivo)-9,10)
										SET @numeroConsecutivo = REPLICATE('0',9-LEN(@numeroConsecutivo)) + CONVERT(VARCHAR(9),@numeroConsecutivo)

										SET @referencia = [Tesoreria].[dbo].[referencia_lote_pos](@numeroConsecutivo,@idEmpresa,@idTipoDocumento,@idTipoReferencia) + 
														  [Tesoreria].[dbo].[digito_verificador_fn]([Tesoreria].[dbo].[referencia_lote_pos](@numeroConsecutivo,@idEmpresa,@idTipoDocumento,@idTipoReferencia)) 
										INSERT INTO [Tesoreria].[dbo].[Referencia] VALUES(@idEmpresa, GETDATE(), @referencia,@idTipoReferencia,@numeroConsecutivo,0,@depositoID)
										SET @idReferencia = SCOPE_IDENTITY()
										-- SE INSERTAN LOS DETALLES DE LA REFERENCIA
										INSERT INTO [Tesoreria].[dbo].[DetalleReferencia] VALUES(@idSucursal,@idDepartamento, @idTipoDocOriginal, @importeDocumento, @serieOriginal+@folioOriginal, @idCliente,@idAlma,@idReferencia)
										SELECT @referencia AS REFERENCIA , 'Nueva Referencia por Lote Pre'	AS ESTATUS, @idReferencia AS idReferencia
									END
							END
						ELSE
							BEGIN
								IF EXISTS (SELECT referencia FROM [Tesoreria].[dbo].[Referencia] REF INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia WHERE DEREF.documento = @folioOriginal  AND DEREF.idSucursal = @idSucursal AND  DEREF.idDepartamento = @idDepartamento AND REF.tipoReferencia = 2)	
									BEGIN
										SELECT referencia as REFERENCIA, 'Referencia por Lote Existente Pre' AS ESTATUS, REF.idReferencia AS idReferencia FROM [Tesoreria].[dbo].[Referencia] REF INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia WHERE DEREF.documento = @folioOriginal  AND idSucursal = @idSucursal AND  idDepartamento = @idDepartamento AND REF.tipoReferencia = 2
										PRINT 'SEGUNDO FILTRO'
									END
								ELSE
									BEGIN
				
										SELECT @numeroConsecutivo = SUBSTRING(@numeroConsecutivo,LEN(@numeroConsecutivo)-9,10)
										SET @numeroConsecutivo = REPLICATE('0',10-LEN(@numeroConsecutivo)) + CONVERT(VARCHAR(10),@numeroConsecutivo)
										print @numeroConsecutivo
										SET @referencia = [Tesoreria].[dbo].[referencia_lote_pos](@numeroConsecutivo,@idEmpresa,@idTipoDocumento,@idTipoReferencia) + 
														  [Tesoreria].[dbo].[digito_verificador_fn]([Tesoreria].[dbo].[referencia_lote_pos](@numeroConsecutivo,@idEmpresa,@idTipoDocumento,@idTipoReferencia)) 
										INSERT INTO [Tesoreria].[dbo].[Referencia] VALUES(@idEmpresa, GETDATE(), @referencia,@idTipoReferencia,@numeroConsecutivo,0,@depositoID)
										SET @idReferencia = SCOPE_IDENTITY()
										-- SE INSERTAN LOS DETALLES DE LA REFERENCIA
										INSERT INTO [Tesoreria].[dbo].[DetalleReferencia] VALUES(@idSucursal,@idDepartamento, @idTipoDocOriginal, @importeDocumento, @folioOriginal, @idCliente,@idAlma,@idReferencia)
										SELECT @referencia AS REFERENCIA , 'Nueva Referencia por Lote  Pre'	AS ESTATUS, @idReferencia AS idReferencia
										PRINT 'SEGUNDO FILTRO INSERTAR'
									END
							END
					END
					ELSE
					BEGIN
					PRINT 'entro otra validacion'
						IF @idTipoReferencia = 3
							BEGIN
								IF EXISTS (SELECT referencia FROM [Tesoreria].[dbo].[Referencia] REF INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia WHERE DEREF.documento = @serieOriginal+@folioOriginal  AND DEREF.idSucursal = @idSucursal AND  DEREF.idDepartamento = @idDepartamento AND REF.tipoReferencia = 3 AND REF.idEmpresa = @idEmpresa)	
									BEGIN
										SELECT referencia as REFERENCIA, 'Referencia Factura Pos Existente' AS ESTATUS,  REF.idReferencia AS idReferencia FROM [Tesoreria].[dbo].[Referencia] REF INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia WHERE documento = @serieOriginal+@folioOriginal  AND idSucursal = @idSucursal AND  idDepartamento = @idDepartamento AND REF.tipoReferencia = 3 AND REF.idEmpresa = @idEmpresa
									END
								ELSE
									IF @idTipoDocumento = 1 
										BEGIN
											SELECT @folio = SUBSTRING(@folio,LEN(@folio)-6,7)
											SELECT @serie = SUBSTRING(@serie,LEN(@serie)-2,3)
											SET @serie = REPLICATE('0',3-LEN(@serie)) + CONVERT(VARCHAR(3),@serie)
											SET @folio = REPLICATE('0',7-LEN(@folio)) + CONVERT(VARCHAR(7),@folio)
											-- SE GENERA LA REFERENCIA
											SET @referencia = [Tesoreria].[dbo].[referencia_fn](@serie,@folio, @idSucursal,@idTipoReferencia) + 
															  [Tesoreria].[dbo].[digito_verificador_fn]([Tesoreria].[dbo].[referencia_fn](@serie,@folio, @idSucursal,@idTipoReferencia)) 
											-- SE MUESTRA LA REFERENCIA
											-- SE INSERTA LA REFERENCIA EN LA TABLA REFERENCIA CON SUS RESPECTIVOS CAMPOS
											INSERT INTO [Tesoreria].[dbo].[Referencia] VALUES(@idEmpresa, GETDATE(), @referencia,@idTipoReferencia,@numeroConsecutivo,0,@depositoID)
											SET @idReferencia = SCOPE_IDENTITY()
											-- SE INSERTAN LOS DETALLES DE LA REFERENCIA
											INSERT INTO [Tesoreria].[dbo].[DetalleReferencia] VALUES(@idSucursal,@idDepartamento, @idTipoDocOriginal, @importeDocumento, @serieOriginal+@folioOriginal, @idCliente,@idAlma,@idReferencia)
											SELECT @referencia AS REFERENCIA , 'Nueva Referencia Factura Pos'	AS ESTATUS, @idReferencia AS idReferencia

											

										END
								END
							ELSE
								BEGIN
										IF @idTipoDocumento = 1
											BEGIN
												IF EXISTS (SELECT referencia FROM [Tesoreria].[dbo].[Referencia] REF INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia WHERE DEREF.documento = @serieOriginal+ @folioOriginal  AND DEREF.idSucursal = @idSucursal AND  DEREF.idDepartamento = @idDepartamento AND REF.tipoReferencia = 4)	
													BEGIN
														SELECT referencia as REFERENCIA, 'Referencia por Lote Pos Existente FACTURA' AS ESTATUS, REF.idReferencia AS idReferencia FROM [Tesoreria].[dbo].[Referencia] REF INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia WHERE documento = @serieOriginal+@folioOriginal  AND idSucursal = @idSucursal AND  idDepartamento = @idDepartamento AND REF.tipoReferencia = 4
														PRINT 'PRIMER FILTRO'
													END
												ELSE
													BEGIN
				
														SELECT @numeroConsecutivo = SUBSTRING(@numeroConsecutivo,LEN(@numeroConsecutivo)-9,10)
														SET @numeroConsecutivo = REPLICATE('0',9-LEN(@numeroConsecutivo)) + CONVERT(VARCHAR(9),@numeroConsecutivo)

														SET @referencia = [Tesoreria].[dbo].[referencia_lote_pos](@numeroConsecutivo,@idEmpresa,@idTipoDocumento,@idTipoReferencia) + 
																		  [Tesoreria].[dbo].[digito_verificador_fn]([Tesoreria].[dbo].[referencia_lote_pos](@numeroConsecutivo,@idEmpresa,@idTipoDocumento,@idTipoReferencia)) 
														INSERT INTO [Tesoreria].[dbo].[Referencia] VALUES(@idEmpresa, GETDATE(), @referencia,@idTipoReferencia,@numeroConsecutivo,0,@depositoID)
														SET @idReferencia = SCOPE_IDENTITY()
														-- SE INSERTAN LOS DETALLES DE LA REFERENCIA
														INSERT INTO [Tesoreria].[dbo].[DetalleReferencia] VALUES(@idSucursal,@idDepartamento, @idTipoDocOriginal, @importeDocumento, @serieOriginal+@folioOriginal, @idCliente,@idAlma,@idReferencia)
														SELECT @referencia AS REFERENCIA , 'Nueva Referencia por Lote Pos'	AS ESTATUS, @idReferencia AS idReferencia
														
														
													END
											END
								END
						END
				END
	END


--- FALTA HACER VALIDACIONES POR TIPO DE REFERENCIA
