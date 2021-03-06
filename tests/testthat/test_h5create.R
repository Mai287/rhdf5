library(rhdf5)

############################################################
context("h5createFile")
############################################################

## output file name
h5File <- tempfile(pattern = "ex_save", fileext = ".h5")
if(file.exists(h5File))
    file.remove(h5File)

test_that("Default arguments", {
    expect_true( h5createFile(file = h5File) )
    expect_true( file.exists(h5File) )
})

test_that("Don't overwrite existing file", {
    expect_message(h5createFile(file = h5File), 
                   regexp = "already exists.\n$")
})

############################################################
context("h5createGroup")
############################################################

if(!file.exists(h5File))
    h5createFile(file = h5File)

test_that("Create simple group", {
    expect_true( h5createGroup(file = h5File, group = "foo") )
})

test_that("Create group heirachy", {
    expect_true( h5createGroup(file = h5File, group = "foo/baa") )
})

test_that("Fail if toplevel group missing", {
    ## this is really an error, but doesn't get thrown as one
    h5errorHandling(type = "suppress")
    expect_false( h5createGroup(file = h5File, group = "baa/foo") )
    h5closeAll()
})

############################################################
context("h5createDataset")
############################################################

h5File <- tempfile(pattern = "ex_createDS", fileext = ".h5")
if(file.exists(h5File))
    file.remove(h5File)
## create empty file
h5createFile(file = h5File)

test_that("Create single dataset", {
    expect_true( h5createDataset(file = h5File, dataset = "A", dims = c(2,1)) )
    expect_true( "A" %in% names(h5dump(file = h5File)) )
    A <- h5read(file = h5File, name = "A")
    
    expect_is(A, "matrix")
    expect_true(nrow(A) == 2)
    expect_true(ncol(A) == 1)
    expect_is(A[1,1], "numeric")
    
})

test_that("Create more datasets with different data types", {
    expect_true( h5createDataset(file = h5File, dataset = "int", dims = c(4,5), storage.mode = "integer") )
    expect_true( h5createDataset(file = h5File, dataset = "bool", dims = c(4,5), storage.mode = "logical") )
    expect_true( h5createDataset(file = h5File, dataset = "char", dims = c(4,5), storage.mode = "character", size = 255) )
    
    contents <- h5dump(file = h5File)
    
    expect_true( all(c("int", "bool", "char") %in% names(contents)) )

    expect_is(contents$int, "matrix")
    expect_true(nrow(contents$int) == 4)
    expect_true(ncol(contents$int) == 5)
    
    expect_is(contents$int[1,1], "integer")
    expect_is(contents$bool[1,1], "logical")
    expect_is(contents$char[1,1], "character")
})

test_that("Invalid storage mode arguments", {
    expect_error( h5createDataset(file = h5File, dataset = "foo", dims = c(1,1), storage.mode = "foo") )
    expect_error( h5createDataset(file = h5File, dataset = "foo", dims = c(1,1), storage.mode = 10) ) 
    expect_error( h5createDataset(file = h5File, dataset = "foo", dims = c(1,1), storage.mode = 1L) )
    expect_error( h5createDataset(file = h5File, dataset = "foo", dims = c(1,1), storage.mode = FALSE) )
    ## character without size argument
    expect_error( h5createDataset(file = h5File, dataset = "foo", dims = c(1,1), storage.mode = "character", size = NULL) )
})


test_that("Datasets with different compression levels", {
    
    dataMatrix <- matrix(runif(n = 1e5), nrow = 10000, ncol = 10)
    
    h5File_0 <- tempfile(pattern = "level0_", fileext = ".h5")
    if(file.exists(h5File_0)) 
        file.remove(h5File_0)
    h5createFile(h5File_0)
    expect_true( h5createDataset(file = h5File_0, dataset = "A", dims = dim(dataMatrix), level = 0) )
    h5write( dataMatrix, file = h5File_0, name = "A")
    
    h5File_9 <- tempfile(pattern = "level9_", fileext = ".h5")
    if(file.exists(h5File_9)) 
        file.remove(h5File_9)
    h5createFile(h5File_9)
    expect_true( h5createDataset(file = h5File_9, dataset = "A", dims = dim(dataMatrix), level = 9) )
    h5write( dataMatrix, file = h5File_9, name = "A")
    ## expect compressed file to be at least a small as uncompressed
    expect_lte( file.size(h5File_9), file.size(h5File_0) )
})


test_that("Extendible datasets", {
    mtx4x3 <- matrix(runif(n=12), nrow = 4)
    mtx3x3 <- matrix(runif(n=9), nrow = 3)
    mtx7x2 <- matrix(runif(n=14), nrow = 7)
    extendible <- H5Sunlimited()
    h5createDataset(file = h5File, dataset = "extend", dims = c(4,3), maxdims = c(extendible, extendible))
    h5write( mtx4x3, file = h5File, name = "extend")
    expect_equal(h5read(h5File, "extend"), mtx4x3)

    ## now extend in first dimension:
    ## [ mtx4x3 ]
    ## [ mtx3x3 ]

    h5set_extent(h5File, "extend", c(7,3))
    h5write(mtx3x3, file = h5File, name = "extend",
            start = c(5,1))
    expect_equal(h5read(h5File, "extend"),
                 rbind(mtx4x3, mtx3x3))

    
    ## now extend in the other dimension:
    ## [ mtx4x3 mtx7x2 ]
    ## [ mtx3x3 mtx7x2 ]
    h5set_extent(h5File, "extend", c(7,5))
    h5write(mtx7x2, file = h5File, name = "extend",
            start = c(1,4))
    expect_equal(h5read(h5File, "extend"),
                 cbind(rbind(mtx4x3, mtx3x3),
                       mtx7x2))

    ## This case, level = 0, used to lead to an error because the chunking, which is required for
    ## H5Sunlimited, was within a if(level > 0) branch. Mostly we are just checking here that
    ## no error is thrown, but we'll also do the first extension
    h5createDataset(file = h5File, dataset = "nonCompressed", dim = c(4,3), maxdims = c(extendible, extendible),
                    level = 0)
    h5write( mtx4x3, file = h5File, name = "nonCompressed")
    h5set_extent(h5File, "nonCompressed", c(7,3))
    h5write(mtx3x3, file = h5File, name = "nonCompressed",
            start = c(5,1))
    expect_equal(h5read(h5File, "nonCompressed"),
                 rbind(mtx4x3, mtx3x3))

})

test_that("Invalid inputs", {
    expect_message(suppressWarnings(
      h5createDataset(file = h5File, dataset = "fail", dims = "twenty"))
      ) %>%
      expect_false()
    expect_message(h5createDataset(file = h5File, dataset = "A", dims = c(20, 10))) %>%
      expect_false()
    expect_error(h5createDataset(file = h5File, dataset = "fail", dims = c(-10, 20)))
    expect_error(h5createDataset(file = h5File, dataset = "fail", dims = c(10, 20), maxdims = c(20)))
    expect_error(h5createDataset(file = h5File, dataset = "fail", 
                                 dims = c(10, 20), maxdims = c(20, 20), chunk = NULL))
    expect_error(h5createDataset(file = h5File, dataset = "fail", dims = c(10, 20), maxdims = c(20, 10)))
    expect_warning(h5createDataset(file = h5File, dataset = "fail", dims = c(10, 20), level = 1, chunk = NULL))
    
})

test_that("Using chunks greater than 4GB", {
    expect_message(h5createDataset(file = h5File, dataset = "large_double", 
                                   dims = c(25000, 25000), storage.mode = "double")) %>%
    expect_true()
    expect_message(h5createDataset(file = h5File, dataset = "large_int", 
                                  dims = c(50000, 50000), storage.mode = "integer")) %>%
    expect_true()
    expect_silent(h5createDataset(file = h5File, dataset = "small_int", 
                                  dims = c(500, 500), storage.mode = "integer")) %>%
    expect_true()
})

############################################################
context("h5createAttribute")
############################################################

h5File <- tempfile(pattern = "ex_createAttr", fileext = ".h5")
if(file.exists(h5File))
    file.remove(h5File)
## create a new file with a single dataset
h5createFile(h5File)
h5write(1:1, h5File, "foo")

test_that("attributes can be added using file name", {
    expect_true( h5createAttribute(obj = "foo", file = h5File, attr = "foo_attr", dims = c(1,1)) )
    expect_true( "foo_attr" %in% names(h5readAttributes(file = h5File, name = "foo")) )
})

test_that("Fail is attribute already exists", {
    expect_false( h5createAttribute(obj = "foo", file = h5File, attr = "foo_attr", dims = c(1,1)) )
    expect_message( h5createAttribute(obj = "foo", file = h5File, attr = "foo_attr", dims = c(1,1)),
                    "Can not create attribute")
})

test_that("Fail if dims or maxdims not numeric", {
    expect_error( h5createAttribute(obj = "foo", file = h5File, attr = "foo_attr2", dims = "A" ) )
    expect_error( h5createAttribute(obj = "foo", file = h5File, attr = "foo_attr2", dims = c(1,1), maxdims = "A" ) )
})

test_that("Invalid storage mode arguments", {
    expect_error( h5createAttribute(file = h5File, obj = "foo", dims = c(1,1), attr = "bad_attr", storage.mode = "foo") )
    expect_error( h5createAttribute(file = h5File, obj = "foo", dims = c(1,1), attr = "bad_attr", storage.mode = 10) ) 
    expect_error( h5createAttribute(file = h5File, obj = "foo", dims = c(1,1), attr = "bad_attr", storage.mode = 1L) )
    expect_error( h5createAttribute(file = h5File, obj = "foo", dims = c(1,1), attr = "bad_attr", storage.mode = FALSE) )
    ## character without size argument
    expect_error( h5createAttribute(file = h5File, obj = "foo", dims = c(1,1), attr = "bad_attr", storage.mode = "character", size = NULL) )
})

test_that("No open HDF5 objects are left", {
    expect_equal( length(h5validObjects()), 0 )
})


