
setClass("H5IdComponent",
         slots = c(ID = "character")
)

setClass("H5File", 
         contains = "H5IdComponent"
)

setClass("H5Dataset", 
         slots = c(native = "logical"),
         contains = "H5IdComponent"
)

setClass("H5PropertyList", 
         contains = "H5IdComponent"
)
