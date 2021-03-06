
if( !exists( "ENERGYPROC_DIR" ) ){
    if( Sys.getenv( "ENERGYPROC" ) != "" ){
        ENERGYPROC_DIR <- Sys.getenv( "ENERGYPROC" )
    } else {
        stop("Could not determine location of energy data system. Please set the R var ENERGYPROC_DIR to the appropriate location")
    }
}

# Universal header file - provides logging, file support, etc.
source(paste(ENERGYPROC_DIR,"/../_common/headers/GCAM_header.R",sep=""))
source(paste(ENERGYPROC_DIR,"/../_common/headers/ENERGY_header.R",sep=""))
logstart( "LA131.enduse.R" )
adddep(paste(ENERGYPROC_DIR,"/../_common/headers/GCAM_header.R",sep=""))
adddep(paste(ENERGYPROC_DIR,"/../_common/headers/ENERGY_header.R",sep=""))
printlog( "Historical energy consumption by end-use sectors" )

# -----------------------------------------------------------------------------
# 1. Read files
sourcedata( "COMMON_ASSUMPTIONS", "A_common_data", extension = ".R" )
sourcedata( "ENERGY_ASSUMPTIONS", "A_energy_data", extension = ".R" )
A_regions <- readdata( "ENERGY_ASSUMPTIONS", "A_regions" )
enduse_sector_aggregation <- readdata( "ENERGY_MAPPINGS", "enduse_sector_aggregation" )
L1011.en_bal_EJ_R_Si_Fi_Yh <- readdata( "ENERGY_LEVEL1_DATA", "L1011.en_bal_EJ_R_Si_Fi_Yh" )
L121.in_EJ_R_unoil_F_Yh <- readdata( "ENERGY_LEVEL1_DATA", "L121.in_EJ_R_unoil_F_Yh" )
L122.in_EJ_R_refining_F_Yh <- readdata( "ENERGY_LEVEL1_DATA", "L122.in_EJ_R_refining_F_Yh" )
L124.in_EJ_R_heat_F_Yh <- readdata( "ENERGY_LEVEL1_DATA", "L124.in_EJ_R_heat_F_Yh" )
L124.out_EJ_R_heat_F_Yh <- readdata( "ENERGY_LEVEL1_DATA", "L124.out_EJ_R_heat_F_Yh" )
L124.out_EJ_R_heatfromelec_F_Yh <- readdata( "ENERGY_LEVEL1_DATA", "L124.out_EJ_R_heatfromelec_F_Yh" )
L126.out_EJ_R_electd_F_Yh <- readdata( "ENERGY_LEVEL1_DATA", "L126.out_EJ_R_electd_F_Yh" )

# -----------------------------------------------------------------------------
# 2. Perform computations
# ELECTRICITY SCALING
# First, subset and aggregate the "upstream" electricity demands by the energy system that are not being scaled
L131.in_EJ_R_Sen_elec_Yh <- rbind(
      subset( L121.in_EJ_R_unoil_F_Yh, fuel == "electricity" ),
      subset( L122.in_EJ_R_refining_F_Yh, fuel == "electricity" ) )
L131.in_EJ_R_en_elec_Yh <- aggregate( L131.in_EJ_R_Sen_elec_Yh[ X_historical_years ], by=as.list( L131.in_EJ_R_Sen_elec_Yh[ R_F ] ), sum )

#Subtract this from total delivered electricity (output of t&d sector). This is the amount that is available for scaling to end uses
L131.in_EJ_R_enduse_elec_Yh <- L131.in_EJ_R_en_elec_Yh
L131.in_EJ_R_enduse_elec_Yh[ X_historical_years ] <- L126.out_EJ_R_electd_F_Yh[ X_historical_years ] - L131.in_EJ_R_en_elec_Yh[ X_historical_years ]

#Subset the end use sectors and aggregate by fuel
L131.in_EJ_R_Senduse_F_Yh <- subset( L1011.en_bal_EJ_R_Si_Fi_Yh, sector %in% enduse_sector_aggregation$sector )
L131.in_EJ_R_Senduse_elec_Yh <- subset( L131.in_EJ_R_Senduse_F_Yh, fuel == "electricity" )
L131.in_EJ_R_enduse_elec_Yh_unscaled <- aggregate( L131.in_EJ_R_Senduse_elec_Yh[ X_historical_years ], by=as.list( L131.in_EJ_R_Senduse_elec_Yh[ R_F ] ), sum )

#Calculate the scalers required to balance electricity within each region
L131.scaler_R_enduse_elec_Yh <- L131.in_EJ_R_enduse_elec_Yh
L131.scaler_R_enduse_elec_Yh[ X_historical_years ] <- L131.in_EJ_R_enduse_elec_Yh[ X_historical_years ] / L131.in_EJ_R_enduse_elec_Yh_unscaled[ X_historical_years ]

#Multiply the electricity scalers by the original estimates of electricity consumption by end use sectors
L131.in_EJ_R_Senduse_elec_Yh[ X_historical_years ] <- L131.in_EJ_R_Senduse_elec_Yh[ X_historical_years ] * L131.scaler_R_enduse_elec_Yh[
      match( L131.in_EJ_R_Senduse_elec_Yh$GCAM_region_ID, L131.scaler_R_enduse_elec_Yh$GCAM_region_ID ),
      X_historical_years ]
       
#Replace unscaled estimates of end use sector electricity consumption in full table
L131.in_EJ_R_Senduse_F_Yh[ L131.in_EJ_R_Senduse_F_Yh$fuel == "electricity", ] <- L131.in_EJ_R_Senduse_elec_Yh

#HEAT SCALING
#Total delivered heat = output of district heat sector + secondary (heat) output of electric sector
L131.in_EJ_R_enduse_heat_Yh <- aggregate( L124.out_EJ_R_heat_F_Yh[ X_historical_years ], by=as.list( L124.out_EJ_R_heat_F_Yh[ R ] ), sum )
L131.out_EJ_R_heatfromelec_Yh <- aggregate( L124.out_EJ_R_heatfromelec_F_Yh[ X_historical_years ], by=as.list( L124.out_EJ_R_heatfromelec_F_Yh[ R ] ), sum )
L131.in_EJ_R_enduse_heat_Yh[ X_historical_years ] <- L131.in_EJ_R_enduse_heat_Yh[ X_historical_years ] + L131.out_EJ_R_heatfromelec_Yh[
      match( L131.in_EJ_R_enduse_heat_Yh[[R]], L131.out_EJ_R_heatfromelec_Yh[[R]] ),
      X_historical_years ]

#Subset the end use sectors and aggregate by fuel. Only in regions where heat is modeled as a separate fuel.
heat_regionIDs <- A_regions$GCAM_region_ID[ A_regions$heat == 1 ]
L131.in_EJ_R_Senduse_heat_Yh <- subset( L131.in_EJ_R_Senduse_F_Yh, fuel == "heat" & GCAM_region_ID %in% heat_regionIDs )
L131.in_EJ_R_enduse_heat_Yh_unscaled <- aggregate( L131.in_EJ_R_Senduse_heat_Yh[ X_historical_years ], by=as.list( L131.in_EJ_R_Senduse_heat_Yh[ R_F ] ), sum )

#Calculate the scalers required to balance district heat production and consumption within each region
L131.scaler_R_enduse_heat_Yh <- L131.in_EJ_R_enduse_heat_Yh
L131.scaler_R_enduse_heat_Yh[ X_historical_years ] <- L131.in_EJ_R_enduse_heat_Yh[ X_historical_years ] / L131.in_EJ_R_enduse_heat_Yh_unscaled[
      match( L131.in_EJ_R_enduse_heat_Yh[[R]], L131.in_EJ_R_enduse_heat_Yh_unscaled[[R]] ),
      X_historical_years ]
L131.scaler_R_enduse_heat_Yh[ is.na( L131.scaler_R_enduse_heat_Yh) ] <- 0

#Multiply the district heat scalers by the original estimates of district heat consumption by end use sectors
L131.in_EJ_R_Senduse_heat_Yh[ X_historical_years ] <- L131.in_EJ_R_Senduse_heat_Yh[ X_historical_years ] * L131.scaler_R_enduse_heat_Yh[
      match( L131.in_EJ_R_Senduse_heat_Yh$GCAM_region_ID, L131.scaler_R_enduse_heat_Yh$GCAM_region_ID ),
      X_historical_years ]

#Replace unscaled estimates of end use sector electricity consumption in full table
L131.in_EJ_R_Senduse_F_Yh[ L131.in_EJ_R_Senduse_F_Yh$fuel == "heat" & L131.in_EJ_R_Senduse_F_Yh[[R]] %in% heat_regionIDs, ] <- L131.in_EJ_R_Senduse_heat_Yh

#Heat in some regions is not modeled separately from the fuels used to produce it.
noheat_regionIDs <- A_regions$GCAM_region_ID[ A_regions$heat == 0]

#In these regions, calculate the share of regional heat demand by each sector
L131.in_EJ_R_totenduse_F_Yh <- aggregate( L131.in_EJ_R_Senduse_F_Yh[ X_historical_years ],
      by=as.list( L131.in_EJ_R_Senduse_F_Yh[ R_F ] ), sum )
L131.in_EJ_R_Senduse_heat_Yh <- subset( L131.in_EJ_R_Senduse_F_Yh, fuel == "heat" & GCAM_region_ID %in% noheat_regionIDs )
L131.share_R_Senduse_heat_Yh <- L131.in_EJ_R_Senduse_heat_Yh
L131.share_R_Senduse_heat_Yh[ X_historical_years ] <- L131.in_EJ_R_Senduse_heat_Yh[ X_historical_years ] / L131.in_EJ_R_totenduse_F_Yh[
      match( vecpaste( L131.in_EJ_R_Senduse_heat_Yh[ R_F ] ),
             vecpaste( L131.in_EJ_R_totenduse_F_Yh[R_F ] ) ),
      X_historical_years ]

#Regions may have zero heat consumption by demand sectors while nevertheless having heat production. Assign this to industry
L131.share_R_Senduse_heat_Yh[ L131.share_R_Senduse_heat_Yh$sector == "in_industry_general", X_historical_years ][
      is.na( L131.share_R_Senduse_heat_Yh[ L131.share_R_Senduse_heat_Yh$sector == "in_industry_general", X_historical_years ] ) ] <- 1
L131.share_R_Senduse_heat_Yh[ is.na( L131.share_R_Senduse_heat_Yh ) ] <- 0

# -----------------------------------------------------------------------------
# 3. Output
#Add comments for each table
comments.L131.in_EJ_R_Senduse_F_Yh <- c( "Final scaled energy input by GCAM region / end-use sector (incl CHP) / fuel / historical year","Unit = EJ" )
comments.L131.share_R_Senduse_heat_Yh <- c( "Share of heat consumption by end-use sector within GCAM region / historical year","Unitless" )

#write tables as CSV files
writedata( L131.in_EJ_R_Senduse_F_Yh, domain="ENERGY_LEVEL1_DATA", fn="L131.in_EJ_R_Senduse_F_Yh", comments=comments.L131.in_EJ_R_Senduse_F_Yh )
writedata( L131.share_R_Senduse_heat_Yh, domain="ENERGY_LEVEL1_DATA", fn="L131.share_R_Senduse_heat_Yh", comments=comments.L131.share_R_Senduse_heat_Yh )

# Every script should finish with this line
logstop()
