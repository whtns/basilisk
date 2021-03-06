# Tests the basilisk.utils::clearExternalDir() utility.
# We put these tests in here rather than in basilisk.utils because 
# these functions depend on basilisk being installed.
#
# library(testthat); library(basilisk); source("test-clear.R")

test_that("clearing out the external directory works as expected", {
    tmp <- tempfile()
    dir.create(tmp)

    version <- as.character(packageVersion("basilisk"))
    placeholder <- file.path(tmp, paste0(version, "000"))
    dir.create(placeholder, showWarnings=FALSE)
    expect_true(file.exists(placeholder))

    version2 <- "0.0.0"
    placeholder2 <- file.path(tmp, version2)
    dir.create(placeholder2, showWarnings=FALSE)
    expect_true(file.exists(placeholder2))

    old <- basilisk.utils::setVariable("BASILISK_EXTERNAL_DIR", tmp)
    expect_identical(basilisk.utils::getExternalDir(), file.path(tmp, version))

    basilisk.utils::clearExternalDir()
    expect_false(file.exists(placeholder))
    expect_true(file.exists(placeholder2))

    basilisk.utils::setVariable("BASILISK_EXTERNAL_DIR", old)
})
