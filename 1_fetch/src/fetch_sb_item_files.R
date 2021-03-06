
#' use `dummy` to trigger rebuilds. Using the date, as a light reminder of when it was changed
 
download_sb_files <- function(target_name, sb_id, keyword, dest_folder, dummy, dest_file_prefix = NULL) {
  
  sb_check_login()
  
  sb_filenames <- list_sb_files(sb_id, keyword)
  
  if(!is.null(dest_file_prefix)) {
    dest_filenames <- sprintf("%s_%s", dest_file_prefix, sb_filenames)
  } else {
    dest_filenames <- sb_filenames
  }
  
  local_filenames <- item_file_download(
    sb_id, 
    names = sb_filenames, 
    destinations = file.path(dest_folder, dest_filenames),
    overwrite_file = TRUE)
  
  scipiper::sc_indicate(target_name, data_file = local_filenames)
}

download_sb_single_file <- function(target_name, sb_id, sb_filename, dummy) {
  
  sb_check_login()
  
  item_file_download(
    sb_id, 
    names = sb_filename, 
    destinations = target_name, 
    overwrite_file = TRUE)
  
}

sb_check_login <- function() {
  if (!sbtools::is_logged_in()){
    sb_secret <- dssecrets::get_dssecret("cidamanager-sb-srvc-acct")
    sbtools::authenticate_sb(username = sb_secret$username, password = sb_secret$password)
  }
}

list_sb_files <- function(sb_id, keyword) {
  sb_files <- item_list_files(sb_id)[["fname"]]
  keyword_sb_files <- sb_files[grepl(keyword, sb_files)]
  return(keyword_sb_files)
}
