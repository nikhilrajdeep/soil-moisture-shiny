# Soil Moisture Estimation Shiny App

## 🔗 Soil Moisture application
You can try the app right now at  
[https://nikhilrajdeep.shinyapps.io/Soil_Moisture_Estimation/](https://nikhilrajdeep.shinyapps.io/Soil_Moisture_Estimation/)

## Overview
This Shiny application implements a physics‑based workflow to estimate volumetric soil moisture from microwave brightness temperature (BT):

1. **Tau‑Omega Radiative Transfer Model**  
   Simulate the microwave brightness temperature of the soil–vegetation system under a user‑selected incidence angle.

2. **Permittivity Inversion**  
   Invert the simulated brightness temperature to retrieve the complex soil dielectric permittivity (ε) via the Tau‑Omega inverse formulation.

3. **Mironov et al. Dielectric Mixing Equation**  
   Apply Mironov et al. (2004) to compute volumetric water content W:
   \[
     W = \frac{n_d - \sqrt{\varepsilon} + \omega_t\,(\,n_b - n_u\,)}{1 - n_u}
   \]
   where  
   - \(n_d=1.506\), \(n_b=6.591\), \(n_u=10.428\) are empirical refractive indices,  
   - \(\omega_t\) is the volumetric water fraction input,  
   - \(\varepsilon\) is the inverted permittivity.  

## Usage
1. **Upload** your permittivity dataset (`.xlsx`).  
2. **Select** incidence angle (30°, 40°, 50°).  
3. **Choose** observed vs. predicted channels.  
4. **Explore** scatter plots (with RMSE, bias, R², ubRMSE) and time‑series diagnostics.

## Dependencies
- R (>= 4.0)  
- shiny  
- dplyr, ggplot2, Metrics, readxl  
- shinythemes  

---
*Feel free to customize and contribute!*  
