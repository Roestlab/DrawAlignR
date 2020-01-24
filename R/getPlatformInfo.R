getPlatformInfo <- function(){
  this_platform <- list()
  if(.Platform$OS.type == "unix") {
    
    if( Sys.info()["sysname"] == "linux"){
      message("Platform: linux")
    } else if ( Sys.info()["sysname"] == "Darwin" ) {
      message("Platform: Darwin")
    } else {
      stop( sprintf("Unknown unix OS: %s\n"), Sys.info()['sysname'] )
    }
    
  } else if ( .Platform$OS.type == "windows" ) {
    message("Platform: windows")
  this_platform$.Platform <- .Platform
  this_platform$Sys.info <- Sys.info()
  this_platform$home <- normalizePath("~")
  
} else {
  stop( sprintf("Unknown OS: %s\n"), .Platform$OS.type )
}
}