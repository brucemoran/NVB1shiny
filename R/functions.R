#! R

#' Launch the app
#' @return launched app
#' @rdname launchNVB1
#' @export

launchNVB1 <- function(){
  shiny::runApp(system.file(package = "NVB1shiny", "app"))
}

#' Take filename INPUT and parse
#' @param INPUT session input
#' @param VALS data reactiveVal
#' @return NULL
#' @rdname obsev_FILENAMES
#' @export

obsev_FILENAMES <- function(INPUT, VALS){
  print("obsev_FILENAMES")

  shiny::observeEvent(INPUT$FILENAMES, ignoreInit = TRUE, ignoreNULL = TRUE, {

    VALS$input_file <- INPUT$FILENAMES$datapath[1]
    VALS$CSV <- readr::read_csv(VALS$input_file)

    if(dim(VALS$CSV)[1] > 0){
      modal_fill_pdf(INPUT, VALS$CSV)
    }
  })

}

#' Take filename INPUT and parse
#' @param INPUT session input
#' @param VALS data reactiveVal
#' @return NULL
#' @rdname obsev_manual
#' @export

obsev_manual <- function(INPUT, VALS){
  print("obsev_manual")

  shiny::observeEvent(INPUT$manual, ignoreInit = TRUE, ignoreNULL = TRUE, {

    VALS$input_file <- system.file(package = "NVB1shiny", "extdata", "example_input.csv")
    VALS$CSV <- readr::read_csv(VALS$input_file)

    if(dim(VALS$CSV)[1] > 0){
      modal_fill_pdf(INPUT, VALS$CSV)
    }
  })
}

#' Modal from which to fill PDF
#' @param INPUT session input
#' @param VALS data reactiveVal
#' @return NULL
#' @rdname modal_fill_pdf
#' @export

modal_fill_pdf <- function(INPUT, VALSCSV){

    col_names <- grep("REF", colnames(VALSCSV), value = TRUE, invert = TRUE)
    leng <- length(col_names)
    spleng <- list(aa = c(1:5, 7:11),
                   ba = c(12:19, 6),
                   ca = c(20:leng))

    showModal(
      modalDialog(title = "NVB1 Fillout",
        column(12,
         column(4, lapply(spleng$aa, function(f){
           create_inputs(INPUT = INPUT,
                         VALSCSV = VALSCSV,
                         colname = col_names[f])})
         ),
         column(4, lapply(spleng$ba, function(f){
           create_inputs(INPUT = INPUT,
                         VALSCSV = VALSCSV,
                         colname = col_names[f])})
         ),
         column(4, lapply(spleng$ca, function(f){
           create_inputs(INPUT = INPUT,
                         VALSCSV = VALSCSV,
                         colname = col_names[f])})
         )
        ),
        easyClose = TRUE,
        footer = tagList(
         actionButton(paste0("go_fill_pdf"), "Generate PDF"),
         modalButton("Cancel")
        )
      )
    )
}

#' Use selectInput, textInput, dateInput based on column name
#' @param INPUT session input
#' @param VALS session values
#' @param colname character string to match colname
#' @return *Input for shiny
#' @rdname create_inputs
#' @export

create_inputs <- function(INPUT, VALSCSV, colname){
  ##output appropriate function and params for each column
  if(! colname %in% c("Consent_cbox", "Role")){
    return(textInput(inputId = paste0(colname, "_fill"),
                     label = colname,
                     value = ifelse(colname == "Email",
                                    VALSCSV[[colname]],
                                    toupper(VALSCSV[[colname]]))))
  }

  if(colname %in% "Consent_cbox"){
    if(VALSCSV[["Consent_cbox"]] == "Accept"){
      valu <- TRUE
    } else {
      valu <- FALSE
    }
    return(checkboxInput(inputId = "Consent_cbox_fill",
                          label = "Consent",
                          value = TRUE))
  }

  if(colname %in% "Role"){
    return(selectizeInput(inputId = paste0(colname, "_fill"),
                          label = colname,
                          multiple = FALSE,
                          selected = "SCOUTER",
                          choices = toupper(c("Scouter",
                                      "Scouter/Rover Scout",
                                      "Rover Scout",
                                      "Venture Scout",
                                      "Adult Supporter – Group Chairperson",
                                      "Adult Supporter – Group Secretary",
                                      "Adult Supporter – Group Treasurer",
                                      "Adult Supporter – Group Quartermaster",
                                      "Adult Supporter – Spiritual Advisor",
                                      "Adult Supporter – Band Member",
                                      "Adult Supporter – Special Needs As."))))

  }
}

#' Split into the many millions of single chars on this vec
#' @rdname split_name_vec
#' @export

split_name_vec <- function(){
  c(Forename = "Fn_",
    Middlename = "Mn_",
    Surname = "Sn_",
    Email = "Em_",
    Contact = "Co_",
    Role = "Ro_",
    Address_1 = "Ad_1_",
    Address_2 = "Ad_2_",
    Address_3 = "Ad_3_",
    Address_4 = "Ad_4_",
    Address_5 = "Ad_5_",
    Eircode = "Ec_",
    Today_day = "Ds_d_",
    Today_month = "Ds_m_",
    Today_year = "Ds_y_",
    DOB_day = "Dob_d_",
    DOB_month = "Dob_m_",
    DOB_year = "Dob_y_",
    DOB_day_doc = "Dob_do_",
    DOB_month_doc = "Dob_mo_",
    DOC_year_doc = "Dob_yo_",
    Eircode_doc = "Ec_o_",
    IDcheck_day_doc = "Ds_do_",
    IDcheck_month_doc = "Ds_mo_",
    IDcheck_year_doc = "Ds_yo_")
}

#' Use selectInput, textInput, dateInput based on column name
#' @param INPUT session input
#' @param VALS session values
#' @return *Input for shiny
#' @rdname obsev_go_fill_pdf
#' @export

obsev_go_fill_pdf <- function(INPUT, VALS){
  shiny::observeEvent(INPUT$go_fill_pdf, {

    shiny::removeModal()
    ##download file to fill
    pdf_url <- system.file(package = "NVB1shiny", "extdata", "Garda_eVetting_SI_fillable.pdf")
    pdf_f <- staplr::get_fields(pdf_url)
    ##what names in input are available to be split
    inp_nam <- gsub("_fill", "", grep("_fill", names(INPUT), value = TRUE))
    pdf_snv <- inp_nam[inp_nam %in% names(split_name_vec())]
    pdf_ons <- split_name_vec()[names(split_name_vec()) %in% inp_nam]

    pdf_list <- lapply(pdf_snv, function(f){
      rnid <- split_name_vec()[f]
      rnss <- strsplit(gsub("^353", "", gsub("^\\+", "", INPUT[[paste0(f, "_fill")]])), "")[[1]]

      rvec <- nvec <- c()
      if(rnid %in% c("Ds_d_", "Ds_m_",
                     "Dob_d_", "Dob_m_",
                     "Ds_do_", "Ds_mo_",
                     "Dob_do_", "Dob_mo_")){
        if(length(rnss) == 1){
          rnss <- c(0, rnss)
        }
      }
      if(rnid %in% c("Ds_y_", "Ds_yo_")){
        if(length(rnss) == 2){
          rnss <- c(2, 2, rnss)
        }
      }
      if(rnid %in% c("Co_")){
        rnss <- na.omit(readr::parse_number(rnss))
        if(length(rnss) > 10){
          if(rnss[1] == 3 && rnss[2] == 5 && rnss[3] == 3){
            rnss <- rnss[-c(1,2,3)]
          }
        }
        if(length(rnss) == 9){
          rnss <- c(0, rnss)
        }
      }
      if(rnid %in% c("Ec_", "Ec_o_")){
        if(length(rnss) > 7){
          rnss <- grep(" ", rnss, value = TRUE, invert = TRUE)
        }
      }
      if(rnid %in% c("Em_")){
        if(length(rnss) > 25){
          rnss <- c(rnss[1:25], paste(rnss[26:length(rnss)], collapse = ""))
        }
      }
      for(x in 1:length(rnss)){
        nvec <- c(nvec, paste0(rnid, x))
        rvec <- c(rvec, "Text", paste0(rnid, x), rnss[x])
      }
      return(list(rvec, nvec))
    })

    for(fx in 1:length(pdf_list)){
      for(x in 1:(length(pdf_list[[fx]][[1]])/3)){
        xx <- x*3
        pdf_l <- list(type = pdf_list[[fx]][[1]][[xx-2]],
                      name = pdf_list[[fx]][[1]][[xx-1]],
                      value = pdf_list[[fx]][[1]][[xx]])
        pdf_f[[pdf_list[[fx]][[1]][[xx-1]]]] <- pdf_l
      }
    }

    pdf_f$Consent_cbox$value <- ifelse(INPUT[["Consent_cbox_fill"]] == TRUE, "Yes", "Off")
    levels(pdf_f$Consent_cbox$value) <- c("Off", "Yes")
    pdf_f$Name_approver$value <-  INPUT[["Name_approver_fill"]]
    pdf_f$Name_doc$value <- INPUT[["Name_doc_fill"]]

    ##output
    fnam <- paste(unlist(lapply(pdf_f[grep("Fn",names(pdf_f))], function(fc){if(fc$value!=""){fc$value}})), collapse = "")
    snam <- paste(unlist(lapply(pdf_f[grep("Sn",names(pdf_f))], function(fc){if(fc$value!=""){fc$value}})), collapse = "")
    VALS$outpath <- paste0(dirname(VALS$input_file), "/",
                      fnam, "_", snam, "_GV_", Sys.Date(), ".pdf")
    VALS$pdf_url <- pdf_url
    VALS$pdf_f <- pdf_f
    VALS$tmp_out <- tempfile(fileext = ".pdf")
    print(paste0("Data saved: ", VALS$tmp_out))
    staplr::set_fields(input_filepath = VALS$pdf_url,
                       output_filepath = VALS$tmp_out,
                       fields = VALS$pdf_f,
                       overwrite = TRUE)
    shiny::showModal(
      shiny::modalDialog(
        title = "Success! Your PDF is available to Download:\n\n",
        easyClose = TRUE,
        footer = tagList(
         shiny::actionButton("go_get_pdf", "Let me get my PDF!")
        )
      )
    )
  })
}

#' Allow use to donwload the PDF made and save to tmp
#' @param INPUT session input
#' @param OUTPUT session output
#' @param VALS session values
#' @return NULL
#' @rdname obsev_go_get_pdf
#' @export

obsev_go_get_pdf <- function(INPUT, OUTPUT, VALS){
  shiny::observeEvent(INPUT$go_get_pdf, {
    OUTPUT$downloadData <- downloadHandler(
      filename = function() {
        basename(VALS$outpath)
      },
      content = function(file) {
        file.copy(VALS$tmp_out, file)
      }
    )
    shiny::removeModal()
  })
}
