mominc
======

MOMinc is a small set of functions to read/write MINC files in Matlab and Octave. MINC stands for Medical Image NetCDF. It actually comes in two flavors: MINC1 (based on NetCDF), and MINC2 (based on HDF5). See the [http://en.wikibooks.org/wiki/MINC](MINC documentation) for more info. 

The plan is that both MINC1 and MINC2 will be supported for Matlab and Octave. Currently the reader works for MINC1 and MINC2 in Matlab, but has not been tested enough to be considered robust. The writer and the support for Octave are a work in progress.

**How to read a volume:** To read `file.mnc`, type:
```matlab
[hdr,vol] = minc_read('file.mc');
```
The extension can also be `.mnc.gz` (typically for minc1 files). The array `vol` contains the data, in voxel space (no re-orientation is performed to arrange dimensions in a specific order). The structure `hdr` contains all header infos. 

**The header:** the most important parameters are stored in `hdr.info` under names that should be self-explanatory, and includes dimension order (`xspace` is left->right, `yspace` is back->front, and `zspace` is foot->head). Details are available by typing:
```matlab
help minc_read
```

**Access header variables:** the structure to represent fields in the minc header is a bit convoluted. Basically you have a list of variables and corresponding attributes, stored in lists. There is a simple API to access them though:
```
minc_variable(hdr,'yspace','direction_cosines')
```
will give you the direction cosines of yspace. 
```
minc_variable(hdr)
```
will list all variables available in the header. And
```
minc_variable(hdr,'yspace')
```
will list all the attributes of the `'yspace'` variable. This API will work identically in MINC1 and MINC2. 
