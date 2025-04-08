ipw_sample <- function(df, controls_per_case, seed = 137, sample_exposed) {
  # Set seed -------------------------------------------------------------------
  print("Set seed")

  set.seed(seed)

  # Split cases and controls ---------------------------------------------------
  print("Split cases and controls")

  cases <- df[df$outcome_status == TRUE, ]
  controls <- df[df$outcome_status == FALSE, ]

  print(paste0("Cases: ", nrow(cases)))
  print(summary(cases))

  print(paste0("Controls: ", nrow(controls)))
  print(summary(controls))

  # Sample controls if more than enough, otherwise retain all controls ---------

  if (sample_exposed == TRUE) {
    if (nrow(cases) * controls_per_case < nrow(controls)) {
      print("Sample controls, including exposed control individuals")
      controls <- controls[
        sample(
          seq_len(nrow(controls)),
          nrow(cases) * controls_per_case,
          replace = FALSE
        ),
      ]
      controls$cox_weight <- (nrow(df) - nrow(cases)) / nrow(controls)
      print(paste0(
        nrow(controls),
        " controls sampled with Cox weight of ",
        controls$cox_weight[1]
      ))
    } else {
      print("Retain all controls")
      controls$cox_weight <- 1
    }
  }

  if (sample_exposed == FALSE) {
    print("Separate exposed controls so they are not sampled")
    controls_exposed <- controls[!is.na(controls$exposure), ]
    controls_exposed$cox_weight <- 1
    print(paste0(nrow(controls_exposed), " exposed controls"))

    print("Exposed controls:")
    print(summary(controls_exposed))

    print("Sample unexposed controls")
    controls_unexposed <- controls[is.na(controls$exposure), ]

    if (nrow(cases) * controls_per_case < nrow(controls_unexposed)) {
      controls_unexposed <- controls_unexposed[
        sample(
          seq_len(nrow(controls_unexposed)),
          nrow(cases) * controls_per_case,
          replace = FALSE
        ),
      ]
      controls_unexposed$cox_weight <- (nrow(df) -
        nrow(cases) -
        nrow(controls_exposed)) /
        nrow(controls_unexposed)
      print(paste0(
        nrow(controls_unexposed),
        " unexposed controls sampled with Cox weight of ",
        controls_unexposed$cox_weight[1]
      ))

      print("Unexposed controls:")
      print(summary(controls_unexposed))

      print("Add exposed control individuals back to control dataset")
      controls <- NULL
      controls <- rbind(controls_unexposed, controls_exposed)
      print(paste0("Controls (N=", nrow(controls), "):"))
      print(summary(controls))
    } else {
      print("Insufficient controls so retain all controls")
      rm(controls_exposed, controls_unexposed)
      controls$cox_weight <- 1
    }
  }

  # Specify cox weight for cases -----------------------------------------------
  print("Specify cox weight for cases")

  cases$cox_weight <- 1

  # Recombine cases and controls -----------------------------------------------
  print("Recombine cases and controls")

  return_df <- rbind(cases, controls)

  # Return dataset -------------------------------------------------------------

  return(return_df)
}
