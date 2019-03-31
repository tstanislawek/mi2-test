library(dplyr)

# adapted from: https://github.com/petzi53/bib2academic

httr::set_config(httr::config(http_version = 0))

scholar_df <- lapply(c("pub_data/mateusz-staniak",
                       "pub_data/michal-burdukiewicz",
                       "pub_data/przemyslaw-biecek",
                       "pub_data/tomasz-stanislawek"),
                     function(ith_file) {
                       scholar::get_publications(last(strsplit(readLines(paste0(ith_file, "/scholar.txt")), "=")[[1]])) %>%
                         select(title = title, cid = cid) %>%
                         mutate(clean_title = cleanStr(tolower(title)))
                     }) %>%
  bind_rows() %>%
  unique

pub_df <- lapply(c("pub_data/mateusz-staniak",
                   "pub_data/michal-burdukiewicz",
                   "pub_data/przemyslaw-biecek",
                   "pub_data/tomasz-stanislawek"),
                 function(ith_file) {
                   bib_list <- RefManageR::ReadBib(paste0(ith_file, "/citations.bib"),
                                                   check = FALSE,
                                                   .Encoding = "UTF-8")

                   data.frame(bib_list) %>%
                     mutate(pubtype = case_when(bibtype == "Article" ~ "2",
                                                bibtype == "Article in Press" ~ "2",
                                                bibtype == "InProceedings" ~ "1",
                                                bibtype == "Proceedings" ~ "1",
                                                bibtype == "Conference" ~ "1",
                                                bibtype == "Conference Paper" ~ "1",
                                                bibtype == "MastersThesis" ~ "3",
                                                bibtype == "PhdThesis" ~ "3",
                                                bibtype == "Manual" ~ "4",
                                                bibtype == "TechReport" ~ "4",
                                                bibtype == "Book" ~ "5",
                                                bibtype == "InCollection" ~ "6",
                                                bibtype == "InBook" ~ "6",
                                                bibtype == "Misc" ~ "0",
                                                TRUE ~ "0"),
                            key = gsub("[/:]", "", sapply(bib_list, function(i) i$key)))
                 }) %>%
  bind_rows() %>%
  mutate(clean_title = cleanStr(tolower(title))) %>%
  filter(!duplicated(.[["clean_title"]]))

all_distances <- stringdist::stringdistmatrix(a = pub_df[["clean_title"]],
                                              b = scholar_df[["clean_title"]],
                                              method = "jaccard", q = 5)

pub_scholar_df <- data.frame(pub_title = pub_df[["title"]],
                             scholar_title = scholar_df[["title"]][apply(all_distances, 1, which.min)],
                             distance = apply(all_distances, 1, min),
                             stringsAsFactors = FALSE)

final_bib_df <- select(pub_df, -clean_title) %>%
  inner_join(pub_scholar_df, by = c("title" = "pub_title")) %>%
  inner_join(scholar_df, by = c("scholar_title" = "title")) %>%
  select(-clean_title, -title) %>%
  rename(title = scholar_title)

RefManageR::ReadBib("pub_data/mateusz-staniak/citations.bib",
                    check = FALSE,
                    .Encoding = "UTF-8") %>%
  data.frame()

lapply(1L:nrow(final_bib_df), function(ith_pub) {
  filepath <- paste0("content/publication/",
                     gsub("[/:-]", "", final_bib_df[ith_pub, "key"]))

  dir.create(filepath)

  try(RefManageR::WriteBib(RefManageR::as.BibEntry(final_bib_df[ith_pub, ]),
                           file = paste0(filepath, "/references.bib")))

  try(create_md(final_bib_df[ith_pub, ], file = paste0(filepath, "/index.md")))
})




create_md <- function(x, file) {
  # define a date and create filename_md by appending date and bibTex key
  if (!is.na(x[["year"]])) {
    x[["date"]] <- paste0(x[["year"]], "-01-01")
  } else {
    x[["date"]] <- "2999-01-01"
  }

  # start writing

  write("+++", file.path(file))

  # title and date
  # title has sometimes with older bibTex files special characters "{}"
  # escape " and \ (e.g. the "ampersand"\&) with funtion escapeStr

  write(paste0("title = \"", cleanStr(x[["title"]]), "\""),
        fileConn, append = TRUE)
  write(paste0("date = \"", x[["date"]], "\""),
        fileConn, append = TRUE)

  # Publication type. Legend:
  # 0 = Uncategorized, 1 = Conference paper, 2 = Journal article
  # 3 = Manuscript, 4 = Report, 5 = Book,  6 = Book section
  write(paste0("publication_types = [\"", x[["pubtype"]],"\"]"),
        fileConn, append = TRUE)


  if (!is.na(x[["author"]])) {
    # Authors. Comma separated list, e.g.
    # `["Bob Smith", "David Jones"]`.
    authors <- stringr::str_replace_all(
      stringr::str_squish(x["author"]), " and ", "\", \"")
    authors <- stringi::stri_trans_general(authors, "latin-ascii")
    write(paste0("authors = [\"", authors,"\"]"),
          fileConn, append = TRUE)
  } else {
    # Editors. Comma separated list, e.g.
    # `["Bob Smith", "David Jones"]`.
    editors <- stringr::str_replace_all(
      stringr::str_squish(x["editor"]), " and ", "\", \"")
    editors <- stringi::stri_trans_general(editors, "latin-ascii")
    write(paste0("editors = [\"", editors,"\"]"),
          fileConn, append = TRUE)
  }


  # Publication details:
  # start with title: every bib entry has a title field!
  # then check if field booktitle or journal
  # if booktitle, then: booktitle, year and maybe pages
  # if journal, then: journal, check if volume, number, pages
  # check first if field is available and then if it is.na
  # only if both conditions are satiesfied: write field content
  # NOTE: This will not generate a complete citation record
  # NOTE: Only summary information providing links to detailed infos
  # NOTE: One of these infos is to see & copy the complete bib record


  publication <- NULL # variable to collect data and to write it to file

  if ("booktitle" %in% names(x) && !is.na(x[["booktitle"]])) {
    publication <- paste0(publication,
                          "In: ", cleanStr(x[["booktitle"]]))
    if ("publisher" %in% names(x) && !is.na(x[["publisher"]])) {
      publication <- paste0(publication, ", ",
                            cleanStr(x[["publisher"]]))
    }
    if ("address" %in% names(x) && !is.na(x[["address"]])) {
      publication <- paste0(publication, ", ",
                            cleanStr(x[["address"]]))
    }
    if ("pages" %in% names(x) && !is.na(x[["pages"]])) {
      publication <- paste0(publication, ", _pp. ",
                            cleanStr(x[["pages"]]), "_")
    }
  }

  if ("journal" %in% names(x) && !is.na(x[["journal"]])) {
    publication <- paste0(publication, "In: ",
                          cleanStr(x[["journal"]]))
    if ("volume" %in% names(x) && !is.na(x[["volume"]])) {
      publication <- paste0(publication, ", (",
                            cleanStr(x[["volume"]]), ")")
    }
    if ("number" %in% names(x) && !is.na(x[["number"]])) {
      publication <- paste0(publication, ", ",
                            cleanStr(x[["number"]]))
    }
    if ("pages" %in% names(x) && !is.na(x[["pages"]])) {
      publication <- paste0(publication, ", _pp. ",
                            cleanStr(x[["pages"]]), "_")
    }
    if ("doi" %in% names(x) && !is.na(x[["doi"]])) {
      publication <- paste0(publication, ", ",
                            paste0("https://doi.org/",
                                   cleanStr(x[["doi"]])))
    }
    if ("url" %in% names(x) && !is.na(x[["url"]])) {
      publication <- paste0(publication, ", ",
                            cleanStr(x[["url"]]))
    }


  }

  write(paste0("publication = \"", publication, "\""),
        fileConn, append = TRUE)

  write("abstract = \"\"", fileConn, append = TRUE)
  write(paste0("abstract_short = \"","\""),
        fileConn, append = TRUE)


  # other possible fields are kept empty.
  # They can be customized later by editing the created md

  write("image_preview = \"\"", fileConn, append = TRUE)
  write("selected = false", fileConn, append = TRUE)
  write("projects = []", fileConn, append = TRUE)
  write("tags = []", fileConn, append = TRUE)
  #links
  write("url_pdf = \"\"", fileConn, append = TRUE)
  write("url_preprint = \"\"", fileConn, append = TRUE)
  write("url_code = \"\"", fileConn, append = TRUE)
  write("url_dataset = \"\"", fileConn, append = TRUE)
  write("url_project = \"\"", fileConn, append = TRUE)
  write("url_slides = \"\"", fileConn, append = TRUE)
  write("url_video = \"\"", fileConn, append = TRUE)
  write("url_poster = \"\"", fileConn, append = TRUE)
  write("url_source = \"\"", fileConn, append = TRUE)

  if (!is.na(x[["cid"]])) {
    write(paste0('url_custom = [{name = "Google Scholar", url = "https://scholar.google.pl/scholar?cites=',
                 x[["cid"]], '"}]'), fileConn, append = TRUE)
  }

  #other stuff
  write("math = true", fileConn, append = TRUE)
  write("highlight = true", fileConn, append = TRUE)
  # Featured image
  write("[header]", fileConn, append = TRUE)
  write("image = \"\"", fileConn, append = TRUE)
  write("caption = \"\"", fileConn, append = TRUE)

  write("+++", fileConn, append = TRUE)

}

cleanStr <- function(str) {
  gsub('\\', '\\\\', str, fixed = TRUE) %>%
    gsub("[{}]", '', .) %>%
    gsub('"', '\\\\"', .)
}

