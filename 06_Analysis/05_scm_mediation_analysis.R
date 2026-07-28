# ==============================================================================
# STRUCTURAL CAUSAL MODEL WITH MEDIATION ANALYSIS
# Imai, Keele, and Yamamoto (2010) Sensitivity Analysis
# ==============================================================================
#
# This script performs a complete mediation analysis for built-form effects
# on land surface temperature (LST) through vegetation change (NDVI).
#
# Framework: Difference-in-Differences (DiD) outcomes with pathway-specific 
#            associations and unmeasured confounding sensitivity analysis
#
# Reference: Imai, K., Keele, L., & Yamamoto, T. (2010).
#            Identification, Inference and Sensitivity Analysis for Causal 
#            Mediation Effects. Statistical Science, 25(1), 51–71.
#
# ==============================================================================

# SETUP & LIBRARIES ============================================================

library(mediation)      # Imai et al. mediation analysis
library(tidyverse)      # Data manipulation and visualization
library(ggplot2)        # Publication-quality plots
library(gridExtra)      # Arrange multiple plots
library(broom)          # Extract model results

# Suppress warnings for cleaner output
options(warn = -1)

# Set seed for reproducibility
set.seed(42)

# ==============================================================================
# LOAD DATA
# ==============================================================================

data_path <- paste0(
  "C:/Users/agz90fk/Documents/EO4CAM/3_Daten/Output/",
  "Masterarbeit/Analysis_v2/analysis_dataset.csv"
)

output_dir <- "C:/Users/agz90fk/Documents/EO4CAM/3_Daten/Output/Masterarbeit/Analysis_v2/SCM"

causal_df <- read.csv(
  data_path,
  stringsAsFactors = FALSE
)

cat("\n")
cat(strrep("=", 80), "\n")
cat("DATA LOADED\n")
cat(strrep("=", 80), "\n\n")

cat("Rows in full dataset:", nrow(causal_df), "\n")
cat("Columns in full dataset:", ncol(causal_df), "\n")

# ==============================================================================
# FILTER: ONLY NHDAs WITH AVAILABLE PRE-CONSTRUCTION NDVI VALUES
# ==============================================================================

# Keep only rows for which a pre-construction NDVI value is available
causal_df <- causal_df[
  !is.na(causal_df$pre_construction_difference_NDVI),
]

causal_df <- causal_df[
  !is.na(causal_df$pre_construction_difference_LST),
]

cat(
  "Rows with available pre-construction values:",
  nrow(causal_df),
  "\n"
)

cat(
  "Unique NHDAs:",
  length(unique(causal_df$nhda_id)),
  "\n"
)

# ==============================================================================
# STEP 1: CREATE DERIVED VARIABLES
# ==============================================================================

cat("\n")
cat(strrep("=", 80), "\n")
cat("STEP 1: Creating Derived Variables\n")
cat(strrep("=", 80), "\n\n")

# Difference-in-Differences outcomes:
# post-construction mean minus pre-construction mean

# NDVI change:
# Change in the NHDA-reference difference from pre- to post-construction
causal_df$NDVI_change <-
  causal_df$post_construction_difference_NDVI -
  causal_df$pre_construction_difference_NDVI

# LST change:
# Change in the NHDA-reference difference from pre- to post-construction
causal_df$LST_change <-
  causal_df$post_construction_difference_LST -
  causal_df$pre_construction_difference_LST


# ==============================================================================
# CHECK RESULTS
# ==============================================================================

cat("Available NDVI change values:",
    sum(!is.na(causal_df$NDVI_change)), "\n")

cat("Available LST change values:",
    sum(!is.na(causal_df$LST_change)), "\n")

summary(
  causal_df[
    c(
      "pre_construction_difference_NDVI",
      "post_construction_difference_NDVI",
      "NDVI_change",
      "pre_construction_difference_LST",
      "post_construction_difference_LST",
      "LST_change"
    )
  ]
)
# Built-form exposure variables (relative differences to reference areas)
causal_df$X_buildup   <- causal_df$reldiff_built_up_ratio
causal_df$X_height    <- causal_df$reldiff_avg_building_height
causal_df$X_footprint <- causal_df$reldiff_avg_building_footprint
causal_df$X_mfh       <- causal_df$diff_res_subclass_share_mfh_ab

# Mediator and outcome variables
causal_df$M  <- causal_df$NDVI_change      # Mediator: vegetation change
causal_df$Y  <- causal_df$LST_change       # Outcome: temperature change
causal_df$M0 <- causal_df$pre_construction_difference_NDVI
causal_df$Y0 <- causal_df$pre_construction_difference_LST

# Confounders: spatial and contextual variables
causal_df$C_degurba   <- as.factor(causal_df$nhda_degurba_code)
causal_df$C_landclass <- as.factor(causal_df$nhda_sur_class_2021_short)

# Remove rows with missing values
causal_df <- causal_df %>%
  filter(!is.na(X_buildup),
         !is.na(X_height),
         !is.na(X_footprint),
         !is.na(X_mfh),
         !is.na(M),
         !is.na(Y),
         !is.na(M0),
         !is.na(Y0),
         !is.na(lat),
         !is.na(lon),
         !is.na(C_degurba),
         !is.na(C_landclass))

cat("Created variables:\n")
cat(sprintf("  - NDVI_change (mediator M): mean = %.6f, sd = %.6f\n",
            mean(causal_df$M), sd(causal_df$M)))
cat(sprintf("  - LST_change (outcome Y):   mean = %.6f, sd = %.6f\n",
            mean(causal_df$Y), sd(causal_df$Y)))
cat(sprintf("  - N observations: %d\n\n", nrow(causal_df)))


# ==============================================================================
# STEP 2: FIT JOINT MEDIATOR AND OUTCOME MODELS
# ==============================================================================

# These models include ALL four built-form variables simultaneously.
# When testing each exposure, we will isolate its effect while keeping
# the others as adjustment covariates.

cat("STEP 2: Fitting Joint Models (all exposures)", "\n")

# MEDIATOR MODEL: M ~ X (all 4) + M0 + controls
# This model predicts vegetation change as a function of built-form characteristics
mediator.model <- lm(
  M ~ X_buildup + X_height + X_footprint + X_mfh +
    M0 + lat + lon + C_degurba + C_landclass,
  data = causal_df
)

cat("Mediator Model (NDVI_change):\n")
cat(sprintf("  R² = %.4f\n", summary(mediator.model)$r.squared))
cat(sprintf("  Adj. R² = %.4f\n", summary(mediator.model)$adj.r.squared))
cat(sprintf("  N = %d\n\n", nobs(mediator.model)))

# OUTCOME MODEL: Y ~ X (all 4) + M + M0 + Y0 + controls
# This model predicts temperature change as a function of built-form
# characteristics and vegetation change
outcome.model <- lm(
  Y ~ X_buildup + X_height + X_footprint + X_mfh +
    M + M0 + Y0 + lat + lon + C_degurba + C_landclass,
  data = causal_df
)

cat("Outcome Model (LST_change):\n")
cat(sprintf("  R² = %.4f\n", summary(outcome.model)$r.squared))
cat(sprintf("  Adj. R² = %.4f\n", summary(outcome.model)$adj.r.squared))
cat(sprintf("  N = %d\n\n", nobs(outcome.model)))


# ==============================================================================
# STEP 3 & 4: MEDIATION ANALYSIS FOR EACH EXPOSURE
# ==============================================================================

# For each built-form characteristic, we perform:
# 1. Fit mediator and outcome models specific to that exposure
# 2. Run mediate() with 500 bootstrap simulations
# 3. Extract ACME (indirect), ADE (direct), and total effects
# 4. Calculate proportion mediated

cat("STEP 3 & 4: Mediation Analysis for Each Exposure Variable", "\n")

# Define exposure variables to analyze
exposures <- list(
  list(name = "X_buildup", label = "Built-up Ratio"),
  list(name = "X_height", label = "Building Height"),
  list(name = "X_footprint", label = "Building Footprint"),
  list(name = "X_mfh", label = "MFH-AB Share")
)

# Storage for results
mediation_results <- list()
medsens_results <- list()

# ==============================================================================
# LOOP THROUGH EACH EXPOSURE
# ==============================================================================

for (i in seq_along(exposures)) {

  exposure_name <- exposures[[i]]$name
  exposure_label <- exposures[[i]]$label

  cat(sprintf("\n--- Analyzing: %s ---\n\n", exposure_label))

  # ============================================================================
  # Step 3a: Fit models specific to this exposure
  # ============================================================================

  # MEDIATOR MODEL: M ~ X_i + (other X's as covariates) + M0 + controls
  mediator_formula <- as.formula(
    "M ~ X_buildup + X_height + X_footprint + X_mfh + M0 + lat + lon + C_degurba + C_landclass"
  )

  mediator.fit <- lm(mediator_formula, data = causal_df)

  # OUTCOME MODEL: Y ~ X_i + M + (other X's as covariates) + M0 + Y0 + controls
  outcome_formula <- as.formula(
    "Y ~ X_buildup + X_height + X_footprint + X_mfh + M + M0 + Y0 + lat + lon + C_degurba + C_landclass"
  )

  outcome.fit <- lm(outcome_formula, data = causal_df)

  # ============================================================================
  # Step 4: Mediation analysis with bootstrap
  # ============================================================================

  # mediate() performs the causal mediation analysis
  # - treatment: the exposure variable (X_i)
  # - mediator: the mediating variable (M = NDVI_change)
  # - sims: number of bootstrap simulations (500 for inference)
  # - boot: use bootstrap instead of quasi-Bayesian approach

  cat(sprintf("Running mediate() for %s (500 bootstrap simulations)...\n", exposure_label))

  med.out <- mediate(
    model.m = mediator.fit,
    model.y = outcome.fit,
    treat = exposure_name,
    mediator = "M",
    sims = 500,
    boot = TRUE,
    boot.ci.type = "bca"  # Bias-corrected and accelerated bootstrap CI
  )

  # Store results
  mediation_results[[exposure_label]] <- med.out

  # Extract summary statistics
  indirect <- med.out$d0                    # ACME (Average Causal Mediation Effect)
  indirect_ci_lower <- med.out$d0.ci[1]
  indirect_ci_upper <- med.out$d0.ci[2]

  direct <- med.out$z0                      # ADE (Average Direct Effect)
  direct_ci_lower <- med.out$z0.ci[1]
  direct_ci_upper <- med.out$z0.ci[2]

  total <- med.out$tau.coef                 # Total effect
  total_ci_lower <- med.out$tau.ci[1]
  total_ci_upper <- med.out$tau.ci[2]

  # Proportion mediated
  prop_mediated <- med.out$n0

  # Print results
  cat(sprintf("\n  INDIRECT EFFECT (ACME - via NDVI):\n"))
  cat(sprintf("    Point estimate: %.6f\n", indirect))
  cat(sprintf("    95%% CI: [%.6f, %.6f]\n", indirect_ci_lower, indirect_ci_upper))
  cat(sprintf("    p-value: %.4f\n\n", med.out$d0.p))

  cat(sprintf("  DIRECT EFFECT (ADE - controlling for NDVI):\n"))
  cat(sprintf("    Point estimate: %.6f\n", direct))
  cat(sprintf("    95%% CI: [%.6f, %.6f]\n", direct_ci_lower, direct_ci_upper))
  cat(sprintf("    p-value: %.4f\n\n", med.out$z0.p))

  cat(sprintf("  TOTAL EFFECT:\n"))
  cat(sprintf("    Point estimate: %.6f\n", total))
  cat(sprintf("    95%% CI: [%.6f, %.6f]\n", total_ci_lower, total_ci_upper))
  cat(sprintf("    p-value: %.4f\n\n", med.out$tau.p))

  cat(sprintf("  PROPORTION MEDIATED:\n"))
  cat(sprintf("    Point estimate: %.4f (%.1f%%)\n", prop_mediated, prop_mediated * 100))
  cat(sprintf("    95%% CI: [%.4f, %.4f]\n\n",
              med.out$n0.ci[1], med.out$n0.ci[2]))

}  # End loop through exposures


# ==============================================================================
# STEP 5: SENSITIVITY ANALYSIS (Imai et al. 2010)
# ==============================================================================

# The medsens() function implements the Imai et al. (2010) sensitivity analysis.
# It assesses robustness to unmeasured mediator-outcome confounding by:
#
# 1. Varying rho (residual correlation between mediator and outcome errors)
# 2. Computing the adjusted ACME under different values of rho
# 3. Finding the critical rho where ACME = 0
# 4. Reporting R² values (proportion of variance explained by confounder)

cat("\n")
cat("STEP 5: Imai et al. (2010) Sensitivity Analysis", "\n")

medsens_results <- list()

for (i in seq_along(exposures)) {
  
  exposure_label <- exposures[[i]]$label
  
  cat(sprintf(
    "\n--- Sensitivity Analysis for: %s ---\n\n",
    exposure_label
  ))
  
  # Get mediation output for the current exposure
  med.out <- mediation_results[[exposure_label]]
  
  cat(
    "Computing sensitivity curves ",
    "(rho from approximately -0.99 to 0.99)...\n\n",
    sep = ""
  )
  
  # rho.by defines the step size; medsens creates the rho sequence itself
  sens.out <- medsens(
    med.out,
    rho.by = 0.01,
    effect.type = "indirect"
  )
  
  # Store sensitivity results
  medsens_results[[exposure_label]] <- sens.out
  
  rho_values  <- sens.out$rho
  acme_values <- sens.out$d0
  
  # --------------------------------------------------------------------------
  # Critical rho
  # --------------------------------------------------------------------------
  
  # medsens already provides the rho at which ACME becomes zero
  critical_rho <- sens.out$err.cr.d
  
  if (
    length(critical_rho) > 0 &&
    any(is.finite(critical_rho))
  ) {
    
    critical_rho_print <- critical_rho[which(is.finite(critical_rho))[1]]
    
    cat(sprintf(
      "  Critical rho: %.4f\n",
      critical_rho_print
    ))
    
    cat(sprintf(
      paste0(
        "  Interpretation: A residual correlation of rho = %.4f ",
        "between the mediator and outcome models would reduce ",
        "the indirect effect to zero.\n\n"
      ),
      critical_rho_print
    ))
    
  } else {
    
    cat(
      "  No zero-crossing of ACME detected ",
      "within the evaluated rho range.\n\n",
      sep = ""
    )
  }
  
  # --------------------------------------------------------------------------
  # Sensitivity result at rho = 0
  # --------------------------------------------------------------------------
  
  # Avoid exact floating-point comparison with rho_values == 0
  zero_idx <- which.min(abs(rho_values))
  
  cat(
    "  Sensitivity summary at rho = 0 ",
    "(no residual correlation):\n",
    sep = ""
  )
  
  cat(sprintf(
    "    ACME: %.6f\n",
    acme_values[zero_idx]
  ))
  
  cat(sprintf(
    "    95%% CI: [%.6f, %.6f]\n\n",
    sens.out$lower.d0[zero_idx],
    sens.out$upper.d0[zero_idx]
  ))
}

# ==============================================================================
# STEP 6: COMPILE RESULTS TABLE
# ==============================================================================

cat("\n")
cat("STEP 6: Compiling Results", "\n")

# Create a comprehensive results table
results_table <- data.frame()

# ==============================================================================
# CREATE COMBINED RESULTS TABLE
# ==============================================================================

# Return one numeric value or NA if the element does not exist
get_scalar <- function(x, default = NA_real_) {
  if (is.null(x) || length(x) == 0) {
    return(default)
  }
  
  as.numeric(x[1])
}

results_table <- data.frame()

for (exposure_label in names(mediation_results)) {
  
  med.out  <- mediation_results[[exposure_label]]
  sens.out <- medsens_results[[exposure_label]]
  
  # ---------------------------------------------------------------------------
  # Extract critical rho
  # ---------------------------------------------------------------------------
  
  critical_rho <- NA_real_
  
  if (!is.null(sens.out)) {
    
    acme_values <- sens.out$d0
    rho_values  <- sens.out$rho
    
    if (
      !is.null(acme_values) &&
      !is.null(rho_values) &&
      length(acme_values) > 1 &&
      length(rho_values) > 1
    ) {
      
      sign_changes <- which(
        diff(sign(acme_values)) != 0
      )
      
      if (length(sign_changes) > 0) {
        critical_rho <- rho_values[sign_changes[1]]
      }
    }
    
    # Prefer the critical rho calculated directly by medsens(),
    # if it is available
    if (
      !is.null(sens.out$err.cr.d) &&
      length(sens.out$err.cr.d) > 0 &&
      is.finite(sens.out$err.cr.d[1])
    ) {
      critical_rho <- sens.out$err.cr.d[1]
    }
  }
  
  # ---------------------------------------------------------------------------
  # Create one results row
  # ---------------------------------------------------------------------------
  
  row <- data.frame(
    exposure = exposure_label,
    
    # Indirect effect: ACME
    indirect_effect   = get_scalar(med.out$d0),
    indirect_se       = get_scalar(med.out$d0.se),
    indirect_ci_lower = get_scalar(med.out$d0.ci[1]),
    indirect_ci_upper = get_scalar(med.out$d0.ci[2]),
    indirect_pvalue   = get_scalar(med.out$d0.p),
    
    # Direct effect: ADE
    direct_effect   = get_scalar(med.out$z0),
    direct_se       = get_scalar(med.out$z0.se),
    direct_ci_lower = get_scalar(med.out$z0.ci[1]),
    direct_ci_upper = get_scalar(med.out$z0.ci[2]),
    direct_pvalue   = get_scalar(med.out$z0.p),
    
    # Total effect
    total_effect   = get_scalar(med.out$tau.coef),
    total_se       = get_scalar(med.out$tau.se),
    total_ci_lower = get_scalar(med.out$tau.ci[1]),
    total_ci_upper = get_scalar(med.out$tau.ci[2]),
    total_pvalue   = get_scalar(med.out$tau.p),
    
    # Proportion mediated
    prop_mediated          = get_scalar(med.out$n0),
    prop_mediated_ci_lower = get_scalar(med.out$n0.ci[1]),
    prop_mediated_ci_upper = get_scalar(med.out$n0.ci[2]),
    prop_mediated_pvalue   = get_scalar(med.out$n0.p),
    
    # Sensitivity analysis
    rho_critical = get_scalar(critical_rho),
    
    stringsAsFactors = FALSE
  )
  
  results_table <- rbind(
    results_table,
    row
  )
}

print(results_table)

# Round for readability
results_table <- results_table %>%
  mutate(across(where(is.numeric), ~round(., 6)))

cat("Results Table:\n")
print(results_table)
cat("\n")


# ==============================================================================
# COUNTERFACTUAL SZENARIO-VORHERSAGEN: BUILT-UP RATIO
# Zerlegung in Total / Direct (kontrollierter direkter Effekt) /
# Vegetation-mediated pathway, analog zu Abbildung 5.21
#
# Dieses Skript setzt voraus, dass das Hauptskript bereits gelaufen ist,
# sodass causal_df, output_dir, mediator_formula_full-Variablen etc.
# verfügbar sind (M, Y, X_buildup, X_height, X_footprint, X_mfh, M0, Y0,
# lat, lon, C_degurba, C_landclass).
# ==============================================================================

library(tidyverse)

exposure_var <- "X_buildup"

# ------------------------------------------------------------------------------
# 1) Referenzwerte ("Baseline"-NHDA) fuer alle Kovariaten
#    -> Mittelwert fuer stetige Variablen, Modus fuer Faktoren
# ------------------------------------------------------------------------------

get_mode <- function(x) {
  ux <- na.omit(unique(x))
  ux[which.max(tabulate(match(x, ux)))]
}

ref_values <- list(
  X_buildup   = mean(causal_df$X_buildup),
  X_height    = mean(causal_df$X_height),
  X_footprint = mean(causal_df$X_footprint),
  X_mfh       = mean(causal_df$X_mfh),
  M0          = mean(causal_df$M0),
  Y0          = mean(causal_df$Y0),
  lat         = mean(causal_df$lat),
  lon         = mean(causal_df$lon),
  C_degurba   = get_mode(causal_df$C_degurba),
  C_landclass = get_mode(causal_df$C_landclass)
)

# ------------------------------------------------------------------------------
# 2) Wertebereich von X_buildup (empirisch, 2%-98%-Perzentil um Ausreisser
#    an den Raendern abzufedern -> analog "empirical range" in Abb. 5.21)
# ------------------------------------------------------------------------------

x_seq <- seq(
  quantile(causal_df$X_buildup, 0.02, na.rm = TRUE),
  quantile(causal_df$X_buildup, 0.98, na.rm = TRUE),
  length.out = 30
)

# ------------------------------------------------------------------------------
# 3) Hilfsfunktion: newdata-Zeile mit Referenzwerten, ausser den explizit
#    uebergebenen Overrides
# ------------------------------------------------------------------------------

make_newdata <- function(overrides = list(), ref = ref_values) {
  vals <- modifyList(ref, overrides)
  as.data.frame(vals, stringsAsFactors = FALSE)
}

# ------------------------------------------------------------------------------
# 4) Kernfunktion: berechnet die drei Pfade fuer ein gegebenes Modellpaar
#    (wird auf Originaldaten UND in jeder Bootstrap-Iteration aufgerufen)
# ------------------------------------------------------------------------------

predict_pathways <- function(mediator.fit, outcome.fit, x_seq, exposure_var, ref) {
  
  # Referenz-Mediatorwert bei X = Referenzwert (x0)
  nd_ref <- make_newdata(ref = ref)
  M_ref  <- predict(mediator.fit, newdata = nd_ref)
  
  out <- data.frame(
    x = x_seq,
    total = NA_real_,
    direct = NA_real_,
    vegetation = NA_real_
  )
  
  for (i in seq_along(x_seq)) {
    
    x_i <- x_seq[i]
    
    # M(x): vorhergesagter Mediatorwert, wenn nur X_buildup auf x_i gesetzt wird
    nd_x <- make_newdata(setNames(list(x_i), exposure_var), ref = ref)
    M_x  <- predict(mediator.fit, newdata = nd_x)
    
    # --- TOTAL: X = x_i, M = M(x_i) --------------------------------------
    nd_total <- nd_x
    nd_total$M <- M_x
    out$total[i] <- predict(outcome.fit, newdata = nd_total)
    
    # --- DIRECT: X = x_i, M = M(x0) (Mediator auf Referenzwert fixiert) --
    nd_direct <- nd_x
    nd_direct$M <- M_ref
    out$direct[i] <- predict(outcome.fit, newdata = nd_direct)
    
    # --- VEGETATION: X = x0 (Referenz), M = M(x_i) ------------------------
    nd_veg <- nd_ref
    nd_veg$M <- M_x
    out$vegetation[i] <- predict(outcome.fit, newdata = nd_veg)
  }
  
  out
}

# ------------------------------------------------------------------------------
# 5) Modellformeln (identisch zum Hauptskript) und Punktschaetzung
# ------------------------------------------------------------------------------

mediator_formula_full <- as.formula(
  "M ~ X_buildup + X_height + X_footprint + X_mfh + M0 + lat + lon + C_degurba + C_landclass"
)
outcome_formula_full <- as.formula(
  "Y ~ X_buildup + X_height + X_footprint + X_mfh + M + M0 + Y0 + lat + lon + C_degurba + C_landclass"
)

mediator.fit.full <- lm(mediator_formula_full, data = causal_df)
outcome.fit.full  <- lm(outcome_formula_full,  data = causal_df)

point_est <- predict_pathways(
  mediator.fit.full, outcome.fit.full,
  x_seq, exposure_var, ref_values
)

# ------------------------------------------------------------------------------
# 6) Bootstrap-Konfidenzintervalle (500 Wiederholungen, wie im Hauptskript)
# ------------------------------------------------------------------------------

n_boot <- 500
n <- nrow(causal_df)

boot_array <- array(
  NA_real_,
  dim = c(length(x_seq), 3, n_boot),
  dimnames = list(NULL, c("total", "direct", "vegetation"), NULL)
)

set.seed(42)

cat("Running bootstrap for counterfactual predictions (built-up ratio)...\n")

for (b in 1:n_boot) {
  
  idx <- sample(seq_len(n), n, replace = TRUE)
  boot_df <- causal_df[idx, ]
  
  ref_values_b <- list(
    X_buildup   = mean(boot_df$X_buildup),
    X_height    = mean(boot_df$X_height),
    X_footprint = mean(boot_df$X_footprint),
    X_mfh       = mean(boot_df$X_mfh),
    M0          = mean(boot_df$M0),
    Y0          = mean(boot_df$Y0),
    lat         = mean(boot_df$lat),
    lon         = mean(boot_df$lon),
    C_degurba   = get_mode(boot_df$C_degurba),
    C_landclass = get_mode(boot_df$C_landclass)
  )
  
  med_b <- tryCatch(lm(mediator_formula_full, data = boot_df), error = function(e) NULL)
  out_b <- tryCatch(lm(outcome_formula_full,  data = boot_df), error = function(e) NULL)
  
  if (is.null(med_b) || is.null(out_b)) next
  
  res_b <- tryCatch(
    predict_pathways(med_b, out_b, x_seq, exposure_var, ref_values_b),
    error = function(e) NULL
  )
  
  if (!is.null(res_b)) {
    boot_array[, "total", b]      <- res_b$total
    boot_array[, "direct", b]     <- res_b$direct
    boot_array[, "vegetation", b] <- res_b$vegetation
  }
  
  if (b %% 50 == 0) cat(sprintf("  Bootstrap %d / %d\n", b, n_boot))
}

# ------------------------------------------------------------------------------
# 7) CI aus Bootstrap-Verteilung (2.5% / 97.5% Perzentile)
# ------------------------------------------------------------------------------

ci_lower <- apply(boot_array, c(1, 2), quantile, probs = 0.025, na.rm = TRUE)
ci_upper <- apply(boot_array, c(1, 2), quantile, probs = 0.975, na.rm = TRUE)

plot_df <- data.frame(
  x = x_seq,
  
  total    = point_est$total,
  total_lo = ci_lower[, "total"],
  total_hi = ci_upper[, "total"],
  
  direct    = point_est$direct,
  direct_lo = ci_lower[, "direct"],
  direct_hi = ci_upper[, "direct"],
  
  vegetation    = point_est$vegetation,
  vegetation_lo = ci_lower[, "vegetation"],
  vegetation_hi = ci_upper[, "vegetation"]
)

# ------------------------------------------------------------------------------
# 8) Ergebnisse speichern
# ------------------------------------------------------------------------------

results_dir <- file.path(output_dir, "results")
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(
  plot_df,
  file.path(results_dir, "counterfactual_predictions_buildup.csv"),
  row.names = FALSE
)

cat("  Saved: counterfactual_predictions_buildup.csv\n")

# ------------------------------------------------------------------------------
# 9) Plot analog zu Abbildung 5.21
# ------------------------------------------------------------------------------

p <- ggplot(plot_df, aes(x = x)) +
  
  geom_ribbon(aes(ymin = total_lo,      ymax = total_hi),      fill = "#1f77b4", alpha = 0.15) +
  geom_ribbon(aes(ymin = direct_lo,     ymax = direct_hi),     fill = "#ff7f0e", alpha = 0.15) +
  geom_ribbon(aes(ymin = vegetation_lo, ymax = vegetation_hi), fill = "#2ca02c", alpha = 0.15) +
  
  geom_hline(
    yintercept = point_est$total[which.min(abs(x_seq - ref_values$X_buildup))],
    linetype = "dashed", color = "grey60"
  ) +
  
  geom_line(aes(y = total, color = "Total response"), linewidth = 1) +
  geom_point(aes(y = total, color = "Total response"), size = 2) +
  
  geom_line(aes(y = direct, color = "Direct pathway"), linetype = "dashed", linewidth = 1) +
  geom_point(aes(y = direct, color = "Direct pathway"), shape = 15, size = 2) +
  
  geom_line(aes(y = vegetation, color = "Vegetation pathway"), linetype = "dotted", linewidth = 1) +
  geom_point(aes(y = vegetation, color = "Vegetation pathway"), shape = 17, size = 2) +
  
  scale_color_manual(
    name = NULL,
    values = c(
      "Total response"      = "#1f77b4",
      "Direct pathway"      = "#ff7f0e",
      "Vegetation pathway"  = "#2ca02c"
    )
  ) +
  
  labs(
    x = "Relative built-up ratio difference to reference area",
    y = "Predicted LST change (\u00b0C)"
  ) +
  
  theme_minimal() +
  theme(legend.position = "bottom")

p

ggsave(
  filename = file.path(output_dir, "Counterfactual_buildup_ratio.png"),
  plot = p,
  width = 8, height = 5.5, dpi = 300
)

print(p)

cat("\nCounterfactual scenario predictions (built-up ratio) complete.\n")


# ==============================================================================
# STEP 7: CREATE FIGURES
# ==============================================================================

create_sensitivity_plot <- function(sens.out, exposure_label, filename) {
  
  # Extract sensitivity results
  rho_values <- sens.out$rho
  acme_values <- sens.out$d0
  acme_lower <- sens.out$lower.d0
  acme_upper <- sens.out$upper.d0
  
  # Check whether all required values exist
  required_lengths <- c(
    rho = length(rho_values),
    acme = length(acme_values),
    lower = length(acme_lower),
    upper = length(acme_upper)
  )
  
  if (any(required_lengths == 0)) {
    stop(
      paste0(
        "Missing sensitivity values for ", exposure_label, ": ",
        paste(
          names(required_lengths)[required_lengths == 0],
          collapse = ", "
        )
      )
    )
  }
  
  if (length(unique(required_lengths)) != 1) {
    stop(
      paste0(
        "Sensitivity vectors have different lengths for ",
        exposure_label,
        ": ",
        paste(
          names(required_lengths),
          required_lengths,
          sep = "=",
          collapse = ", "
        )
      )
    )
  }
  
  # Create plotting data
  plot_data <- data.frame(
    rho = rho_values,
    acme = acme_values,
    acme_lower = acme_lower,
    acme_upper = acme_upper
  )
  
  # Remove non-finite values
  plot_data <- plot_data[
    is.finite(plot_data$rho) &
      is.finite(plot_data$acme) &
      is.finite(plot_data$acme_lower) &
      is.finite(plot_data$acme_upper),
  ]
  
  # Critical rho supplied by medsens()
  critical_rho <- NA_real_
  
  if (
    !is.null(sens.out$err.cr.d) &&
    length(sens.out$err.cr.d) > 0 &&
    is.finite(sens.out$err.cr.d[1])
  ) {
    critical_rho <- sens.out$err.cr.d[1]
  }
  
  # Create plot
  p <- ggplot(
    plot_data,
    aes(x = rho, y = acme)
  ) +
    geom_ribbon(
      aes(
        ymin = acme_lower,
        ymax = acme_upper
      ),
      alpha = 0.2
    ) +
    geom_line(
      linewidth = 0.8
    ) +
    geom_hline(
      yintercept = 0,
      linetype = "dashed"
    ) +
    geom_vline(
      xintercept = 0,
      linetype = "dotted"
    ) +
    labs(
      title = paste(
        "Sensitivity analysis:",
        exposure_label
      ),
      x = expression(
        rho
      ),
      y = "Average causal mediation effect"
    ) +
    theme_minimal()
  
  # Add critical-rho line only if available
  if (is.finite(critical_rho)) {
    p <- p +
      geom_vline(
        xintercept = critical_rho,
        linetype = "dashed"
      ) +
      annotate(
        "text",
        x = critical_rho,
        y = max(plot_data$acme_upper, na.rm = TRUE),
        label = sprintf(
          "Critical rho = %.2f",
          critical_rho
        ),
        hjust = ifelse(critical_rho < 0, 0, 1),
        vjust = -0.4,
        size = 3
      )
  }
  
  # Ensure output directory exists
  dir.create(
    dirname(filename),
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  ggsave(
    filename = filename,
    plot = p,
    width = 7,
    height = 5,
    dpi = 300
  )
  
  return(p)
}

sensitivity_plots <- list()

for (exposure_label in names(medsens_results)) {
  
  sens.out <- medsens_results[[exposure_label]]
  
  exposure_short <- tolower(
    gsub("[^A-Za-z0-9]+", "_", exposure_label)
  )
  
  filename <- file.path(
    output_dir,
    sprintf("Sensitivity_%s.png", exposure_short)
  )
  
  p <- create_sensitivity_plot(
    sens.out = sens.out,
    exposure_label = exposure_label,
    filename = filename
  )
  
  sensitivity_plots[[exposure_label]] <- p
}
# ==============================================================================
# STEP 8: SAVE NUMERICAL RESULTS
# ==============================================================================

cat("STEP 8: Saving Results to CSV Files", "\n")

# Create output directory
results_dir <- file.path(output_dir, "results")
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(
  results_table,
  file.path(results_dir, "mediation_results.csv"),
  row.names = FALSE
)

cat("  Saved: mediation_results.csv\n")


for (exposure_label in names(medsens_results)) {
  
  sens.out <- medsens_results[[exposure_label]]
  
  # Create data frame with sensitivity results
  sens_df <- data.frame(
    exposure = rep(exposure_label, length(sens.out$rho)),
    rho = sens.out$rho,
    acme = sens.out$d0,
    acme_ci_lower = sens.out$lower.d0,
    acme_ci_upper = sens.out$upper.d0
  )
  
  # Create safe filename
  exposure_short <- tolower(
    gsub("[^A-Za-z0-9]+", "_", exposure_label)
  )
  
  exposure_short <- gsub("^_|_$", "", exposure_short)
  
  filename <- file.path(
    results_dir,
    sprintf("sensitivity_%s.csv", exposure_short)
  )
  
  # Save to CSV
  write.csv(
    sens_df,
    filename,
    row.names = FALSE
  )
  
  cat(sprintf("  Saved: %s\n", filename))
}


# ==============================================================================
# STEP 9: SUMMARY AND INTERPRETATION
# ==============================================================================

cat("ANALYSIS COMPLETE", "\n")
 

cat("Summary of Results:\n\n")

for (i in 1:nrow(results_table)) {

  row <- results_table[i, ]

  cat(sprintf("%s\n", row$exposure))
  cat(sprintf("  %s\n", strrep("-", 70)))

  cat(sprintf("  Indirect Effect (ACME): %.6f [%.6f, %.6f]\n",
              row$indirect_effect,
              row$indirect_ci_lower,
              row$indirect_ci_upper))

  cat(sprintf("  Direct Effect (ADE):    %.6f [%.6f, %.6f]\n",
              row$direct_effect,
              row$direct_ci_lower,
              row$direct_ci_upper))

  cat(sprintf("  Total Effect:           %.6f [%.6f, %.6f]\n",
              row$total_effect,
              row$total_ci_lower,
              row$total_ci_upper))

  cat(sprintf("  Proportion Mediated:    %.4f [%.4f, %.4f]\n",
              row$prop_mediated,
              row$prop_mediated_ci_lower,
              row$prop_mediated_ci_upper))

  cat(sprintf("  Critical ρ:             %s\n\n",
              ifelse(is.na(row$rho_critical), "No zero-crossing",
                     sprintf("%.4f", row$rho_critical))))
}

