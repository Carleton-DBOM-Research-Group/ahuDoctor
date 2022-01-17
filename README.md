# ahuDoctor
**ahuDoctor  detects hard and soft faults in multiple zone VAV AHU systems**

https://github.com/Carleton-DBOM-Research-Group/ahuDoctor

 **system-level hard faults covered:**
 
       1) mixing box dampers behave outside AMCA curves
       
       2) heating coil valve stuck
       
       3) cooling coil valve stuck 
       
 **zone-level hard faults covered:**
 
       4) vav terminal fault
       
       5) zone temperature and airflow control fault 
       
 **soft faults covered:**
 
       6) deviation from expected state of operation
       
       7) deviation from expected mode of operation
       
       8) deviation from expected supply air temperature reset behaviour
        
       9) deviation from expected supply air pressure reset behaviour   
       
  *ahuDoctor generates nine visualizations for each fault category*
  
  *ahuDoctor computes a KPI for the health of the VAV AHU system*
  
  # Installation requirements 
  
  Verify that version 9.11 (R2021b) of the MATLAB Runtime is installed.
  
  Download and install the Windows version of the MATLAB Runtime for R2021b 
  from the following link on the MathWorks website:

    https://www.mathworks.com/products/compiler/mcr/index.html
    
  # Input files format
  
  *files from VAV zones must be placed in a seperate folder*
  
  *file name format for VAV zones is "zone_XXXXXX.xlsx" where XXXXXX numeric values indicating the controller ID.*
  
  example: zone_431282.xlsx
    
  *file name format for the AHU serving the VAVs is "ahu_XXXXXX.xlsx" where XXXXXX numeric values indicating the controller ID.*
      
  example: ahu_431200.xlsx
  
  *time series data in each file must have identical start/stop dates*
  
  *hourly intervals and a full calendar year (8760 h) are recommended*
  
  **Zone data files contain time series data in the following format**
  
  column 1 - time strings (yyyy-mm-dd hh:mm)
  
  column 2 - indoor temperature (degC)
  
  column 3 - vav airflow rate (L/s)
  
  column 4 - vav airflow setpoint (L/s)
  
  column 5 - damper position (%)   
  
  **ahu data file contains time series data in the following format**
  
  column 1 - time strings (yyyy-mm-dd hh:mm)
  
  column 2 - supply air temperature (degC)
  
  column 3 - return air temperature (degC)
  
  column 4 - outdoor air temperature (degC)
  
  column 5 - heating coil valve (%)
  
  column 6 - cooling coil valve (%)
  
  column 7 - outdoor air damper (%)
  
  column 8 - fan state (%) 
  
  column 9 - supply air pressure (Pa)
  
  
