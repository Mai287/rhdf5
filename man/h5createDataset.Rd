\name{h5createDataset}
\alias{h5createDataset}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{Create HDF5 dataset}
\description{R function to create an HDF5 dataset and defining its dimensionality and compression behaviour.
}
\usage{
h5createDataset (file, dataset, 
		dims, maxdims = dims, 
		storage.mode = "double", H5type = NULL, 
		size = NULL, chunk = dims, fillValue, 
		level = 6, filter = "gzip", shuffle = TRUE,
        native = FALSE)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{file}{The filename (character) of the file in which the dataset will be located. For advanced programmers it is possible to provide an object of class \code{\link{H5IdComponent}} representing a H5 location identifier (file or group). See \code{\link{H5Fcreate}}, \code{\link{H5Fopen}}, \code{\link{H5Gcreate}}, \code{\link{H5Gopen}} to create an object of this kind.}
  \item{dataset}{Name of the dataset to be created. The name can contain group names, e.g. 'group/dataset', but the function will fail, if the group does not yet exist.}
  \item{dims}{The dimensions of the array as they will appear in the file. Note, the dimensions will appear in inverted order when viewing the file with a C-programm (e.g. HDFView), because the fastest changing dimension in R is the first one, whereas the fastest changing dimension in C is the last one.}
  \item{maxdims}{The maximum extension of the array. Use \code{H5Sunlimited()} to indicate an extensible dimension.}
  \item{storage.mode}{The storage mode of the data to be written. Can be obtained by \code{storage.mode(mydata)}.}
  \item{H5type}{Advanced programmers can specify the datatype of the dataset within the file. See \code{h5const("H5T")} for a list of available datatypes. If \code{H5type} is specified the argument \code{storage.mode} is ignored. It is recommended to use \code{storage.mode}}
  \item{size}{For \code{storage.mode='character'} the maximum string length has
  to be specified. rhdf5 writes null padded strings by dafault, thus the value
  provided here should be the length of the longest string.  HDF5 then stores
  the string as fixed length character vectors. Together with compression, this
  should be efficient.}
  \item{chunk}{The chunk size used to store the dataset. It is an integer vector of the same length as \code{dims}. This argument is usually set together with a compression property (argument \code{level}). }
  \item{fillValue}{Standard value for filling the dataset. The storage.mode of value has to be convertable to the dataset type by HDF5.}
  \item{level}{The compression level used. An integer value between 0 (no compression) and 9 (highest and slowest compression).}
  \item{filter}{Character defining which compression filter should be applied 
  to the chunks of the dataset.  See the Details section for more information
  on the options that can be provided here.}
  \item{shuffle}{Logical defining whether the byte-shuffle algorithm should be 
  applied to data prior to compression.}
  \item{native}{An object of class \code{logical}. If TRUE, array-like objects are treated as stored in HDF5 row-major rather than R column-major orientation. Using \code{native = TRUE} increases HDF5 file portability between programming languages. A file written with \code{native = TRUE} should also be read with \code{native = TRUE}}.
}
\details{
Creates a new dataset in an existing HDF5 file. The function will fail if the 
file doesn't exist or if there exists already another dataset with the same 
name within the specified file.

The \code{filter} argument can take several options matching to compression
filters distributed in either with the HDF5 library in \pkg{Rhdf5lib} or via the 
\pkg{rhdf5filters} package.  The plugins available and the corresponding values 
for selecting them are shown below:

\describe{
\item{zlib:  Ubiquitous deflate compression algrithm used in GZIP or ZIP files.  
    All three options below achieve the same result.}{
    \itemize{
        \item{\code{"GZIP"}}, 
        \item{\code{"ZLIB"}}, 
        \item{\code{"DEFLATE"}}
    }
}
\item{szip: Compression algorithm maintained by the HDF5 group.}{
    \itemize{
        \item{\code{"SZIP"}}
    }
}
\item{bzip2}{
    \itemize{
        \item{\code{"BZIP2"}}
    }
}
\item{BLOSC meta compressor: As a meta-compressor BLOSC wraps several different
    compression algorithms.  Each of the options below will active a different 
    compression filter. }{
    \itemize{
        \item{\code{"BLOSC_BLOSCLZ"}}
        \item{\code{"BLOSC_LZ4"}}
        \item{\code{"BLOSC_LZ4HC"}}
        \item{\code{"BLOSC_SNAPPY"}}
        \item{\code{"BLOSC_ZLIB"}}
        \item{\code{"BLOSC_ZSTD"}}
    }
}
\item{Disable: It is possible to write chunks without and compression 
    applied.}{
    \itemize{
        \item{\code{"NONE"}}
    }
}
}
}

\value{Returns TRUE is dataset was created successfully and FALSE otherwise.}
\references{\url{https://portal.hdfgroup.org/display/HDF5}}
\author{Bernd Fischer, Mike L. Smith}
\seealso{
\code{\link{h5createFile}}, \code{\link{h5createGroup}}, \code{\link{h5read}}, \code{\link{h5write}}, \link{rhdf5}
}
\examples{
h5createFile("ex_createDataset.h5")

# create dataset with compression
h5createDataset("ex_createDataset.h5", "A", c(5,8), storage.mode = "integer", chunk=c(5,1), level=6)

# create dataset without compression
h5createDataset("ex_createDataset.h5", "B", c(5,8), storage.mode = "integer")
h5createDataset("ex_createDataset.h5", "C", c(5,8), storage.mode = "double")

# create a dataset of strings & define size based on longest string
ex_strings <- c('long', 'longer', 'longest')
h5createDataset("ex_createDataset.h5", "D",  
    storage.mode = "character", chunk = 3, level = 6,
    dims = length(ex_strings), size = max(nchar(ex_strings)))


# write data to dataset
h5write(matrix(1:40,nr=5,nc=8), file="ex_createDataset.h5", name="A")
# write second column
h5write(matrix(1:5,nr=5,nc=1), file="ex_createDataset.h5", name="B", index=list(NULL,2))
# write character vector
h5write(ex_strings, file = "ex_createDataset.h5", name = "D")

h5dump("ex_createDataset.h5")
}
\keyword{ programming }
\keyword{ interface }
\keyword{ IO }
\keyword{ file }
