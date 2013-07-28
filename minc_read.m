function [hdr,vol] = minc_read(file_name,opt)
% Read a MINC file
% To learn more about the MINC format :
% http://en.wikibooks.org/wiki/MINC
%
% SYNTAX:
% [HDR,VOL] = MINC_READ(FILE_NAME,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_NAME
%   (string) the name of a minc file.
%
% _________________________________________________________________________
% OUTPUTS:
%
% HDR (structure) the header of the MINC file.
%
%   FILE_NAME (empty string '') name of the file currently associated with the 
%      header.
%
%   TYPE (string) the file format (either 'minc1', 'minc2').
%
%   INFO (structure) simplified form of the header:
%      FILE_PARENT (string) name of the file that was read.
%      DIMENSIONS (vector 3*1) the number of elements in each dimensions of the 
%         data array. Warning : the first dimension is not necessarily 
%         the "x" axis. See the DIMENSION_ORDER field below.
%      PRECISION (string, 'float') the precision of data
%      VOXEL_SIZE (vector 1*3, default [1 1 1]) the size of voxels along each 
%         spatial dimension in the same order as in VOL.
%      TR (double, default 1) the time between two volumes (in second). 
%         This field is present only for 3D+t data.
%      T0 (double, default 0) the time corresponding to the first volume (in second).
%      MAT (2D array 4*4) an affine transform from voxel to world space.
%      DIMENSION_ORDER (cell of strings) describes the dimensions of vol. 
%         Typically 'xspace' (left to right), 'yspace' (posterior to anterior)
%         'zspace' (ventral to dorsal) and 'time', but could be anything really.
%      HISTORY (string) the history of the file.
%
%    DETAILS (structure) detailed form of the header, with the following fields:
%      DATA (structure) with the following fields:
%         IMAGE_MAX (double) the max of the volume.
%         IMAGE_MIN (double) the min of the volume.
%         TYPE (integer or string) the data type of the original minc volume.
%            VOL is always loaded as a float though.
%      GLOBALS (structure) with as many entries as global variables, and the 
%         following fields:
%         NAME (string) the name of the global variable 
%         VALUE (arbitrary) the value of the global variable.
%      VARIABLES (structure) with as many entries as variables, and the 
%         following fields:
%         NAME (string) the name of the global variable 
%         TYPE (integer or string) the type of the variable
%         ATTRIBUTES (cell) each entry is the (string) name of an attribute.
%         VALUES (cell) each entry is the (arbitrary) value of an attribute.      
%
% VOL
%       (array of double) the dataset.
%
% _________________________________________________________________________
% SEE ALSO:
% MINC_WRITE, MINC_VOXEL2WORLD, MINC_WORLD2VOXEL, MINC_VARIABLE
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
%   The strategy is different in Matlab and Octave.
%   In Matlab, the strategy is different for MINC1 (NetCDF) and MINC2 (HDF5).
%
%   In Matlab :
%      For MINC1, the function uses the NetCDF Matlab libraries. For MINC2, it
%      uses the HDF5 Matlab libraries.
%
%      For MINC2 files, the multiresolution feature is not supported. Only full
%      resolution images are read.
%
%   In Octave :
%      Octave is not currently supported, although this is part of the plan 
%      (with no clear timeline for completion). 
%
% NOTE 2:
%   VOL is the raw numerical array stored in the MINC file, in the so-called
%   voxel space. In particular, no operation is made to re-order dimensions.
%
% NOTE 3:
%   To read the content of variables in the minc file, (global or otherwise) it
%   is convenient to use MINC_VARIABLE.
%
% NOTE 4:
%   The multi resolution feature of minc2 is not supported. Only the full resolution 
%   image is read. 
%
% NOTE 5:
%   The data is always read in float precision, whatever the original precision 
%   may be. 
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de
% gériatrie de Montréal, Département d'informatique et de recherche
% opérationnelle, Université de Montréal, 2010.
%
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, I/O, reader, minc

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

if exist('OCTAVE_VERSION','builtin')
    %% This is Octave
    error('minc_read does not currently support Octave. Sorry dude I have to quit.')
else
    %% This is Matlab
    %% Test if the file is in MINC1 or MINC2 format
    try
        % MINC2 ?
        str_data      = hdf5info(file_name);
        hdr.type      = 'minc2';
        
    catch
        % MINC1 ?
        try
            ncid     = netcdf.open(file_name,'NOWRITE');
            [ndims,nvars,ngatts] = netcdf.inq(ncid);
            hdr.type = 'minc1';
        catch
            % Huho, neither format seems to work
            if exist(file_name,'file')
                error('This file does not seem to be in either MINC1 or MINC2 format.')
            else
                error('I could not find the file')
            end
        end
    end
    if strcmp(hdr.type,'minc1')
        if nargout>1
            [hdr,vol] = sub_read_matlab_minc1(hdr,ncid,ndims,nvars,ngatts);
        else
            hdr = sub_read_matlab_minc1(hdr,ncid,ndims,nvars,ngatts);
        end
    else
        if nargout>1
            [hdr,vol] = sub_read_matlab_minc2(str_data,hdr,file_name);
        else
            hdr = sub_read_matlab_minc2(str_data,hdr,file_name);
        end
    end
end

hdr.info = minc_hdr2info(hdr);
hdr.info.file_parent = which(file_name); % Add the name of the parent file 
hdr.info.dimension_order = hdr.dimension_order; % Put "dimension_order" under the info branche
hdr.info.dimensions = hdr.dimensions; % Put "dimensions" under the info branche
hdr = rmfield(hdr,{'dimensions','dimension_order'});

%%%%%%%%%%%%%%%%%%%%%%
%% Matlab and MINC1 %%
%%%%%%%%%%%%%%%%%%%%%%
function [hdr,vol] = sub_read_matlab_minc1(hdr,ncid,ndims,nvars,ngatts)
hdr.file_name = '';

%% Read global attributes
for num_g = 1:ngatts
    hdr.details.globals(num_g).name   = netcdf.inqAttName(ncid,netcdf.getConstant('NC_GLOBAL'),num_g-1);
    hdr.details.globals(num_g).values = netcdf.getAtt(ncid,netcdf.getConstant('NC_GLOBAL'),hdr.details.globals(num_g).name);
end

%% Read dimensions
hdr.dimension_order = cell(1,ndims);
hdr.dimensions = zeros(1,ndims);
for num_d = 1:ndims
    [hdr.dimension_order{num_d},hdr.dimensions(num_d)] = netcdf.inqDim(ncid,num_d-1);
end
hdr.dimension_order = hdr.dimension_order(end:-1:1); % in matlab, ordering of dimensions is reversed compared to NETCDF

%% Read variables
for num_v = 1:nvars
    [hdr.details.variables(num_v).name,hdr.details.variables(num_v).type,dimids,natts] = netcdf.inqVar(ncid,num_v-1);
    hdr.details.variables(num_v).attributes = cell([natts 1]);
    hdr.details.variables(num_v).values     = cell([natts 1]);
    for num_a = 1:natts        
        hdr.details.variables(num_v).attributes{num_a} = netcdf.inqAttName(ncid,num_v-1,num_a-1);
        hdr.details.variables(num_v).values{num_a}     = netcdf.getAtt(ncid,num_v-1,hdr.details.variables(num_v).attributes{num_a});        
    end
end

%% Read image-min / image-max / image type
var_names = {hdr.details.variables(:).name};
hdr.details.data.image_min = netcdf.getVar(ncid,find(ismember(var_names,'image-min'))-1);
hdr.details.data.image_max = netcdf.getVar(ncid,find(ismember(var_names,'image-max'))-1);
[tmp,hdr.data.details.type] = netcdf.inqVar(ncid,find(ismember(var_names,'image'))-1);

%% Read volume
if nargout > 1
    vol = netcdf.getVar(ncid,find(ismember(var_names,'image'))-1);
end
netcdf.close(ncid);

%%%%%%%%%%%%%%%%%%%%%%
%% Matlab and MINC2 %%
%%%%%%%%%%%%%%%%%%%%%%

function [hdr,vol] = sub_read_matlab_minc2(str_data,hdr,file_name)
hdr.history = hdf5read(file_name,'/minc-2.0/history');
hdr.ident     = hdf5read(file_name,'/minc-2.0/ident');
hdr.file_name = '';
labels        = {str_data.GroupHierarchy.Groups.Groups(:).Name};

%% Read dimensions
mask_dim        = ismember(labels,'/minc-2.0/dimensions');
list_dimensions = {str_data.GroupHierarchy.Groups.Groups(mask_dim).Datasets(:).Name};

for num_d = 1:length(list_dimensions)
    hdr.dimensions(num_d).name        = list_dimensions{num_d}(22:end);
    hdr.dimensions(num_d).attributes  = {str_data.GroupHierarchy.Groups.Groups(mask_dim).Datasets(num_d).Attributes(:).Name};
    hdr.dimensions(num_d).values      = {str_data.GroupHierarchy.Groups.Groups(mask_dim).Datasets(num_d).Attributes(:).Value};
end

%% Read Info
mask_info  = ismember(labels,'/minc-2.0/info');
if ~isempty(str_data.GroupHierarchy.Groups.Groups(mask_info).Datasets)
    list_info = {str_data.GroupHierarchy.Groups.Groups(mask_info).Datasets(:).Name};
    for num_d = 1:length(list_info)
        hdr.info(num_d).name        = list_info{num_d}(16:end);
        hdr.info(num_d).attributes  = {str_data.GroupHierarchy.Groups.Groups(mask_info).Datasets(num_d).Attributes(:).Name};
        hdr.info(num_d).values      = {str_data.GroupHierarchy.Groups.Groups(mask_info).Datasets(num_d).Attributes(:).Value};
    end
else
    hdr.info.name       = {};
    hdr.info.attributes = {};
    hdr.info.values     = {};
end

%% Read Image info
mask_image  = ismember(labels,'/minc-2.0/image');
list_image = {str_data.GroupHierarchy.Groups.Groups(mask_image).Groups.Datasets(:).Name};
for num_d = 1:length(list_image)
    hdr.image(num_d).name        = list_image{num_d}(19:end);
    hdr.image(num_d).attributes  = {str_data.GroupHierarchy.Groups.Groups(mask_image).Groups.Datasets(num_d).Attributes(:).Name};
    hdr.image(num_d).values      = {str_data.GroupHierarchy.Groups.Groups(mask_image).Groups.Datasets(num_d).Attributes(:).Value};
end

%% Read image-min / image-max
hdr.data.image_min = hdf5read(file_name,'/minc-2.0/image/0/image-min');
hdr.data.image_max = hdf5read(file_name,'/minc-2.0/image/0/image-max');

%% Read volume
if nargout>1
    vol = hdf5read(file_name,'/minc-2.0/image/0/image');
end
