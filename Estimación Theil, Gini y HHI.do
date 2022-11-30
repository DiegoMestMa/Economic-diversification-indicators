clear all
set more off
capture log close
*set matsize 800

******
* 1. Establecer carpetas de trabajo
******

global o1 "C:/Users/Diego/OneDrive/Escritorio/IDIC 2022/"

global o2 "$o1/1 Bases de Datos/ICE"

global o3 "$o1/2 Resultados/Theil"
/* Este último global solo se utiliza en la sección 3.2 */


* Establecer numero de productos y paises
*********************
global indicador VADF /*VAX XB ID_V FD VBP*/
global nproductos 1209
global npaises 131
*********************

******
* 2. Gini
******

forv anio=1995(1)2018{
		/*
		use "$o1/2 Resultados/ICIO/Dataset_2.dta", clear
		drop if anio != `anio'
		keep anio pais sector $indicador
		
		sum $indicador
		replace $indicador = ($indicador - `r(min)') / (`r(max)'-`r(min)')
	
		sort pais $indicador
		*/
		use "$o2/Harvard/dataverse_files/country_partner_hsproduct4digit_year_`anio'.dta", clear

		keep export_value location_code location_id product_id
		merge m:1 location_code location_id using "$o2/country_list" /* unir los países que pasaron los filtros */
		keep if _merge == 3
		drop _merge
	
		merge m:1 product_id using "$o2/product_list" /* unir los productos que pasaron los filtros */
		keep if _merge == 3
		drop _merge

		collapse (sum) export_value, by(location_id product_id)
		fillin location_id product_id
		drop _fillin		
		replace export_value = 0 if export_value ==.
		sort location_id export_value

		*ineqdeco export_value, by(location_id)
		
		
		/*Gini - Parametros */
		/* sabemos que aplicando los filtros nos quedamos solo 131 paises y 1209 productos (o lineas de productos) */
		mata: X = J($nproductos * $npaises ,1,.)
		mata: Y = J($nproductos * $npaises ,1,.)
		mata: G = J($npaises ,1,.)
		
		mata: k = J(1,1,1..$nproductos )'
		
		mata: i = 1
		mata: j = $nproductos
		mata: n = 0
		
		/*Gini - Cumulative shares*/
		mata: xc = st_data(., "export_value")
		
		mata: $nproductos * $npaises /*Esto es igual a 3,015*/
		forv paisprod = 1(1)158379{
		
		mata: X[`paisprod',.] = sum(xc[i..n+1,.])/sum(xc[i..j,.])
		mata: n = n+1
		
		mata{
			if (`paisprod' == j) {
				i= i+ $nproductos
				j= j+ $nproductos	
			}
			
			if (`paisprod' == i){
				Y[`paisprod',.] = X[`paisprod',.]
			}
			else {
				Y[`paisprod',.] = X[`paisprod',.]-X[`paisprod'-1,.]
			}
			
		}		
		}			

		/*Gini - Estimación final*/		
		mata: i = 1
		mata: j = $nproductos
		
		forv pais=1(1)$npaises {
		
			mata: G[`pais',.] = abs(1-sum(Y[i..j,.]:*((2*k:-1):/rows(xc[i..j,.]))))

			mata: i= i+ $nproductos
			mata: j= j+ $nproductos		
			
		}
	
		/*Gini - Pasar a Stata*/		
		*drop sector-$indicador
		*duplicates drop pais, force
		drop *
		mata: st_matrix("G", G)
		svmat G, names(col)
		rename c1 Gini
			
		merge 1:1 _n using "$o2/country_list", keepusing(location_code)	
		drop _merge
		
		gen anio = `anio'

		save "$o1/2 Resultados/Gini/Gini_X/Gini_`anio'", replace
}

/* Gini - Panel data */
clear all

use "$o1/2 Resultados/Gini/Gini_X/Gini_1995", clear


forv anio=1996(1)2018{ 
	
	
	append using "$o1/2 Resultados/Gini/Gini_X/Gini_`anio'"
	

}
rename location_code pais
order pais anio Gini

save "$o1/2 Resultados/Gini/Gini_X/Gini_1995-2018", replace

******
* 3. Theil estándar (unweighted) y sus margenes 
******

clear all
**3.1. Método 1 (Theil y desagregación) - Solo como ejemplo

forv anio=1995(1)1995{
		/*
		use "$o1/2 Resultados/ICIO/Dataset_2.dta", clear
		drop if anio != `anio'
		keep anio pais sector $indicador
		
		sum $indicador
		replace $indicador = ($indicador - `r(min)') / (`r(max)'-`r(min)')

		sort pais sector
		*/
		
		use "$o2/Harvard/dataverse_files/country_partner_hsproduct4digit_year_`anio'.dta", clear

			
		keep export_value location_code location_id product_id
		merge m:1 location_code location_id using "$o2/country_list" /* unir los países que pasaron los filtros */
		keep if _merge == 3
		drop _merge
		
		merge m:1 product_id using "$o2/product_list" /* unir los productos que pasaron los filtros */
		keep if _merge == 3
		drop _merge
		
		
		collapse (sum) export_value, by(location_id product_id)
		fillin location_id product_id
		
		
		/* ejemplo con Perú */
		drop if pais != 56
		*drop _fillin
		*replace export_value = 0 if export_value ==.
		gen grupo = .
		replace grupo = 1 if $indicador == 0
		replace grupo = 2 if $indicador > 0

		theildeco $indicador , byg(grupo)

		
		}

**3.2. Método 2

**3.2.1. Theil

clear all
forv anio=1995(1)2018{
		/*
		use "$o1/2 Resultados/ICIO/Dataset_2.dta", clear
		drop if anio != `anio'
		keep anio pais sector $indicador
		
		sum $indicador
		replace $indicador = ($indicador - `r(min)') / (`r(max)'-`r(min)')
	
		sort pais sector	
		
		*/
	
		use "$o2/Harvard/dataverse_files/country_partner_hsproduct4digit_year_`anio'.dta", clear

		keep export_value location_code location_id product_id
		merge m:1 location_code location_id using "$o2/country_list" /* unir los países que pasaron los filtros */
		keep if _merge == 3
		drop _merge
	
		merge m:1 product_id using "$o2/product_list" /* unir los productos que pasaron los filtros */
		keep if _merge == 3
		drop _merge
	
		*tab location_id
		collapse (sum) export_value, by(location_id product_id)
		fillin location_id product_id
		replace export_value = 0 if export_value ==.
		*preserve
	
		/* sabemos que aplicando los filtros nos quedamos solo 131 paises y 1209 productos (o lineas de productos) */
		/*Theil y sus margenes - Parametros*/
		mata: Tc = J($npaises ,1,.) 
		mata: Em = J($npaises ,1,.) 
		
		mata: i= 1
		mata: j= $nproductos
		
		/*Theil y sus margenes - Estimación final*/
		mata: xc = st_data(., "export_value")
		
		forv pais=1(1)$npaises {
		
			mata: Tc[`pais',.] = (1/rows(xc[i..j,.]))*sum((xc[i..j,.]:/(sum(xc[i..j,.])/rows(xc[i..j,.]))):*ln((xc[i..j,.]:/(sum(xc[i..j,.])/rows(xc[i..j,.])))))
			
			/*Extensive margin (solo dos grupos: 1. lineas activas; 2. lineas inactivas)*/
			mata: Em[`pais',.] = ln(1/(rows(select(xc[i..j,.], (xc[i..j,.] :> 0)))/rows(xc[i..j,.])))
			
			mata: i= i+ $nproductos
			mata: j= j+ $nproductos
		
		*if `pais' != 131 restore, preserve
		*else restore
		}
		
		/*Theil y sus margenes - Pasar a Stata*/		
		*drop sector-$indicador
		*duplicates drop pais, force
		drop *
		mata: st_matrix("Tc", Tc)
		svmat Tc, names(col)
		rename c1 Tc
		
		mata: st_matrix("Em", Em)
		svmat Em, names(col)
		rename c1 Em
		
		merge 1:1 _n using "$o2/country_list", keepusing(location_code)
		
		drop _merge
		
		gen anio = `anio'
		
		/*Theil y sus margenes - Intensive margin*/
		gen Im = Tc-Em
		
		save "$o3/Theil_X/Theil_unweight_`anio'", replace
		
}	


/* Theil - Panel data */
clear all

use "$o3/Theil_X/Theil_unweight_1995", clear


forv anio=1996(1)2018{ 
	
	
	append using "$o3/Theil_X/Theil_unweight_`anio'"
	

}

rename location_code pais 
order pais anio Tc

save "$o3/Theil_X/Theil_unweight_1995-2018", replace

/*
/* Comparar con resultados de IMF */

/* Colocar nombre a los paises */
merge m:1 location_code using "$o2/Harvard/location", keepusing(location_name_short_en)

drop if _merge!=3
drop _merge

/* Merge con los valores reportados por IMF (solo tiene estimaciones hasta 2014) */
merge m:1 location_name_short_en anio using "$o1/1 Bases de Datos/Theil/IMF database", keepusing(Theil_imf Extensive_margin_imf Intensive_margin_imf)

drop if _merge!=3
drop _merge
*/
******
* 3. Theil (weighted)
******


******
* 4. HHI
******
clear all
forv anio=1995(1)2018{  
		/*
		use "$o1/2 Resultados/ICIO/Dataset_2.dta", clear
		drop if anio != `anio'
		keep anio pais sector $indicador
		
		sum $indicador
		replace $indicador = ($indicador - `r(min)') / (`r(max)'-`r(min)')
	
		sort pais sector
		*/
		use "$o2/Harvard/dataverse_files/country_partner_hsproduct4digit_year_`anio'.dta", clear

		keep export_value location_code location_id product_id
		merge m:1 location_code location_id using "$o2/country_list" /* unir los países que pasaron los filtros */
		keep if _merge == 3
		drop _merge
	
		merge m:1 product_id using "$o2/product_list" /* unir los productos que pasaron los filtros */
		keep if _merge == 3
		drop _merge
	
		*tab location_id
		collapse (sum) export_value, by(location_id product_id)
		fillin location_id product_id
		replace export_value = 0 if export_value ==.
		*preserve

		hhi5 export_value, by(location_id)

		collapse (mean) hhi_export_value , by(location_id)
		
		merge 1:1 _n using "$o2/country_list", keepusing(location_code)	
		drop _merge
		
		gen anio = `anio'
		
		rename hhi_export_value hhi
		rename location_code pais
		keeporder pais anio hhi
		
		save "$o1/2 Resultados/HHI/HHI_X/HHI_`anio'", replace

}

/* Panel data del HHI */
clear all

use "$o1/2 Resultados/HHI/HHI_X/HHI_1995", clear


forv anio=1996(1)2018{ 
	
	
	append using "$o1/2 Resultados/HHI/HHI_X/HHI_`anio'"
	

}

/* Generar hhi normalizado, como sabemos: n productos es 1209 */
gen hhi_normalized = (hhi - (1/$nproductos ))/(1-(1/$nproductos ))

save "$o1/2 Resultados/HHI/HHI_X/HHI_1995-2018", replace

/*PENDIENTE: pasar los artículos de donde te guiaste para el proceso de selección de paises y productos, asi como para el cálculo de los indicadores (Gini, Theil, HHI normalizado, ICE)*/