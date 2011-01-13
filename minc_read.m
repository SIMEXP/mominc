function [hdr,vol] = minc_read(file_name,opt)
% Read 3D or 3D+t data in MINC format.
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
%
% OPT
%   (structure, optional) with the following fields :
%
% _________________________________________________________________________
% OUTPUTS:
%
% HDR
%       a structure containing the header of the MINC file..
%
% VOL
%       (4D or 3D array of double) the dataset.
%
% _________________________________________________________________________
% SEE ALSO:
% MINC_WRITE
%
% _________________________________________________________________________
% COMMENTS:
%
% The strategy is different in Matlab and Octave.
% In Matlab, the strategy is different for MINC1 (NetCDF) and MINC2 (HDF5).
%
% In Matlab :
% For MINC1, the function uses the NetCDF Matlab libraries. For MINC2, it
% uses the HDF5 Matlab libraries.
% For MINC2 files, the multiresolution feature is not supported. Only full
% resolution images are read.
%
% In Octave :
% The function uses system calls to MINCINFO (for minc1), MINCHEADER and 
% MINCTORAW which requires a proper install of minc tools.
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de
% gériatrie de Montréal, Département d'informatique et de recherche
% opérationnelle, Université de Montréal, 2010.
%
% Maintainer : pbellec@bic.mni.mcgill.ca
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

%%%%%%%%%%%%%%%%%%%%%%
%% Matlab and MINC1 %%
%%%%%%%%%%%%%%%%%%%%%%
function [hdr,vol] = sub_read_matlab_minc1(hdr,ncid,ndims,nvars,ngatts)

hdr.file_name = '';

%% Read global attributes
for num_g = 1:ngatts
    hdr.globals(num_g).name = netcdf.inqAttName(ncid,netcdf.getConstant('NC_GLOBAL'),num_g-1);
    hdr.globals(num_g).value = netcdf.GetAtt(ncid,netcdf.getConstant('NC_GLOBAL'),hdr.globals(num_g).name);
end

%% Read variables
for num_v = 1:nvars
    [hdr.variables(num_v).name,hdr.variables(num_v).type,dimids,natts] = netcdf.inqVar(ncid,num_v-1);
    hdr.variables(num_v).attributes                                    = cell([natts 1]);
    hdr.variables(num_v).values                                        = cell([natts 1]);
    for num_a = 1:natts        
        hdr.variables(num_v).attributes{num_a} = netcdf.inqAttName(ncid,num_v-1,num_a-1);
        hdr.variables(num_v).values{num_a}     = netcdf.getAtt(ncid,num_v-1,hdr.variables(num_v).attributes{num_a});        
    end
end

%% Read image-min / image-max
var_names = {hdr.variables(:).name};
hdr.data.image_min = netcdf.getVar(ncid,find(ismember(var_names,'image-min'))-1);
hdr.data.image_max = netcdf.getVar(ncid,find(ismember(var_names,'image-max'))-1);

%% Read volume
if nargout > 1
    vol = netcdf.getVar(ncid,find(ismember(var_names,'image'))-1);
end
netcdf.close(ncid);

%%%%%%%%%%%%%%%%%%%%%%
%% Matlab and MINC2 %%
%%%%%%%%%%%%%%%%%%%%%%

function [hdr,vol] = sub_read_matlab_minc2(str_data,hdr,file_name)

hdr.history   = hdf5read(file_name,'/minc-2.0/','history');
hdr.ident     = hdf5read(file_name,'/minc-2.0/','ident');
hdr.file_name = '';
labels        = {str_data.GroupHierarchy.Groups.Groups(:).Name};

%% Read dimensions
mask_dim        = ismember(labels,'/minc-2.0/dimensions');
list_dimensions = {str_data.GroupHierarchy.Groups.Groups(mask_dim).Datasets(:).Name};

for num_d = 1:length(list_dimensions)
    hdr.dimensions(num_d).name        = list_dimensions{num_d}(22:end);
    hdr.dimensions(num_d).attributes  = {str_data.GroupHierarchy.Groups.Groups(mask_dim).Datasets(num_d).Attributes(:).Shortname};
    hdr.dimensions(num_d).values      = {str_data.GroupHierarchy.Groups.Groups(mask_dim).Datasets(num_d).Attributes(:).Value};
end

%% Read Info
mask_info  = ismember(labels,'/minc-2.0/info');
if ~isempty(str_data.GroupHierarchy.Groups.Groups(mask_info).Datasets)
    list_info = {str_data.GroupHierarchy.Groups.Groups(mask_info).Datasets(:).Name};
    for num_d = 1:length(list_info)
        hdr.info(num_d).name        = list_info{num_d}(16:end);
        hdr.info(num_d).attributes  = {str_data.GroupHierarchy.Groups.Groups(mask_info).Datasets(num_d).Attributes(:).Shortname};
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
    hdr.image(num_d).attributes  = {str_data.GroupHierarchy.Groups.Groups(mask_image).Groups.Datasets(num_d).Attributes(:).Shortname};
    hdr.image(num_d).values      = {str_data.GroupHierarchy.Groups.Groups(mask_image).Groups.Datasets(num_d).Attributes(:).Value};
end

%% Read image-min / image-max
hdr.data.image_min = hdf5read(file_name,'/minc-2.0/image/0/image-min');
hdr.data.image_max = hdf5read(file_name,'/minc-2.0/image/0/image-max');

%% Read volume
if nargout>1
    vol = hdf5read(file_name,'/minc-2.0/image/0/image');
end
