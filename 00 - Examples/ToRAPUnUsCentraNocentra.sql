SELECT
										 THEN (SELECT ucu_foliocotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSAL WHERE ucu_idcotizacion = (SELECT ucu_idcotizacion FROM cuentasporcobrar.DBO.UNI_COTIZACIONUNIVERSALUNIDADES WHERE ucn_idFactura COLLATE Modern_Spanish_CS_AS = DR.documento)) COLLATE Modern_Spanish_CS_AS
										ELSE DR.documento
									END
										 THEN DR.documento
										ELSE ''
									END
										 THEN 'COTIZACION UNIVERSAL'
										ELSE ''
									END