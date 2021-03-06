USE [Tesoreria]
GO
/****** Object:  StoredProcedure [dbo].[INS_DETALLE_REFERENCIA_LOTE_SP]    Script Date: 01/04/2018 19:14:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [INS_DETALLE_REFERENCIA_LOTE_SP] @idReferencia = 37, @idSucursal=12,@idDepartamento = 70, @idTipoDocumento = 3, @folio =9182,@idCliente = 135, @idAlma=GEN,@importeDocumento=11799.2400
ALTER PROCEDURE [dbo].[INS_DETALLE_REFERENCIA_LOTE_SP]
@idReferencia INT = 0,
@idSucursal int = 0,
@idDepartamento	 int = 0,
@idTipoDocumento INT = 0,
@serie VARCHAR(20) = '',
@folio VARCHAR(30) = '',
@idCliente INT = 0,
@idAlma NVARCHAR(10) = 0,
@importeDocumento DECIMAL(18,2) = 0
AS
BEGIN
	
		IF @idTipoDocumento = 1
			BEGIN
				IF EXISTS (SELECT DEREF.documento FROM [Tesoreria].[dbo].[Referencia] REF 
							INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia 
							WHERE DEREF.documento = @serie+@folio  
							AND DEREF.idSucursal = @idSucursal 
							AND DEREF.idDepartamento = @idDepartamento AND REF.tipoReferencia = 4 
							AND REF.idReferencia = @idReferencia)
					BEGIN
						SELECT 'FACTURA EXISTENTE'
					END
				ELSE
					BEGIN
						IF EXISTS (SELECT DEREF.documento FROM [Tesoreria].[dbo].[Referencia] REF 
							INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia 
							WHERE DEREF.documento = @serie+@folio  
							AND DEREF.idSucursal = @idSucursal 
							AND DEREF.idDepartamento = @idDepartamento AND REF.tipoReferencia = 3 
							AND REF.idReferencia = @idReferencia)
							BEGIN
								SELECT 'FACTURA EXISTENTE'
							END
						ELSE
							BEGIN
								INSERT INTO [Tesoreria].[dbo].[DetalleReferencia] VALUES
								(
								@idSucursal,
								@idDepartamento, 
								@idTipoDocumento, 
								@importeDocumento, 
								@serie+@folio, 
								@idCliente,
								@idAlma,
								@idReferencia
								)
								select 'se inserto en uno'
							END
					END					
			END
		ELSE
			BEGIN
				IF EXISTS (SELECT DEREF.documento FROM [Tesoreria].[dbo].[Referencia] REF 
							INNER JOIN [Tesoreria].[dbo].[DetalleReferencia] DEREF ON REF.idReferencia = DEREF.idReferencia 
							WHERE DEREF.documento = @folio  
							AND DEREF.idSucursal = @idSucursal 
							AND DEREF.idDepartamento = @idDepartamento 
							AND REF.tipoReferencia = 3 
							AND REF.idReferencia = @idReferencia)
					BEGIN
						SELECT 'PEDIDO O COTIZACIÓN EXISTENTE'
					END
				ELSE
					BEGIN
							INSERT INTO [Tesoreria].[dbo].[DetalleReferencia] VALUES
							(
							@idSucursal,
							@idDepartamento, 
							@idTipoDocumento, 
							@importeDocumento, 
							@folio, 
							@idCliente,
							@idAlma,
							@idReferencia
							)
							select 'se inserto en dos'
					END
			END
END
