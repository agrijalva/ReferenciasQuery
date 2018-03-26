USE [referencias]
GO

/****** Object:  Table [dbo].[Banamex]    Script Date: 03/26/2018 15:28:02 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Banamex]') AND type in (N'U'))
DROP TABLE [dbo].[Banamex]
GO

USE [referencias]
GO

/****** Object:  Table [dbo].[Banamex]    Script Date: 03/26/2018 15:28:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO


/*
== Prefijos
OB[Aa-Zz] => Openning Balance
SL[Aa-Zz] => Statement Line
AO[Aa-Zz] => Account Owner
CB[Aa-Zz] => Closing Balance
CAB[Aa-Zz] => Closing Available Balance
*/

CREATE TABLE [dbo].[Banamex](
	[idBanamex] [bigint] IDENTITY(1,1) NOT NULL,
	[noCuenta] [varchar](50) NULL,
	[consecutivo] [bigint] NULL,
	[OBCredito] [varchar](2) NULL,
	[OBFechaApertura] [date] NULL,
	[OBMoneda] [varchar](3) NULL,
	[OBMontoApertura] [numeric](18, 4) NULL,
	[SLFechaTransaccion] [date] NULL,
	[SLFechaEntrada] [varchar](4) NULL,
	[SLCredito] [varchar](2) NULL,
	[SLMonedaTC] [varchar](1) NULL,
	[SLMonto] [numeric](18, 4) NULL,
	[SLRazon] [varchar](3) NULL,
	[SLTipoReferencia] [varchar](10) NULL,
	[SLReferencia] [varchar](50) NULL,
	[SLCodigoTransaccion] [varchar](3) NULL,
	[SLTransaccion] [varchar](50) NULL,
	[AOTipoProductoID] [varchar](4) NULL,
	[AOTipoProducto] [varchar](10) NULL,
	[AODescripcion] [varchar](255) NULL,
	[CBCredito] [varchar](2) NULL,
	[CBFechaReserva] [date] NULL,
	[CBMoneda] [varchar](3) NULL,
	[CBMonto] [numeric](18, 4) NULL,
	[CABCredito] [varchar](2) NULL,
	[CABFechaReserva] [date] NULL,
	[CABMoneda] [varchar](3) NULL,
	[CABMonto] [numeric](18, 4) NULL,
PRIMARY KEY CLUSTERED 
(
	[idBanamex] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


