function [] = mom_write_minc1_matlab(hdr,vol)
% Write a MINC1 file in Octave
% To learn more about the MINC format :
% http://en.wikibooks.org/wiki/MINC
%
% SYNTAX:
% [] = MOM_WRITE_MINC1_MATLAB(HDR,VOL)
%
% INPUTS:
%    HDR (structure) The header of a MINC1 file (see MINC_READ)
%        HDR.FILE_NAME is the name of the file to be written
%    VOL (array) the data associated with the file
%
% SEE ALSO:
%    MINC_READ
%
% COMMENTS:
%    VOL is the raw numerical array stored in the MINC file, in the so-called
%    voxel world. In particular, no operation is made to re-order dimensions. 
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de
% gériatrie de Montréal, Département d'informatique et de recherche
% opérationnelle, Université de Montréal, 2013.
%
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, I/O, reader, minc, minc1, matlab

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

if ~strcmp(hdr.type,'minc1')
    error('This writer only supports MINC1')
end

if isempty(hdr.file_name)
    error('Please specify a non-empty file name in HDR.FILE_NAME');
end

%% Open file
nc = netcdf.create(hdr.file_name,'CLOBBER');

%% # of variables
nvars = length(hdr.variables);

%% # of attributes
ngatts = length(hdr.globals);

%% # of dimensions
ndim = length(hdr.dimensions);

%% Set global attributes
for num_g = 1:ngatts
    if strcmp(hdr.globals(num_g).name,'history')
        % The history specified in hdr.info.history overrides what's stored in the header
        netcdf.putAtt(nc,netcdf.getConstant('NC_GLOBAL'),hdr.globals(num_g).name,hdr.info.history);         
    else
        netcdf.putAtt(nc,netcdf.getConstant('NC_GLOBAL'),hdr.globals(num_g).name,hdr.globals(num_g).values);
    end
end

%% Create dimensions
dimid = zeros([1 ndim]); 
for num_d = ndim:-1:1 % Matlab and NetCDF use different ordering for dimensions
    dimid(num_d) = netcdf.defDim(nc,hdr.dimensions(num_d).name,hdr.dimensions(num_d).length);
end

%% Set variables
for num_v = 1:nvars
    natts = length(hdr.variables(num_v).attributes);
    name_v = hdr.variables(num_v).name;
    if strcmp(name_v,'image')
        varid = netcdf.defVar(nc,name_v,hdr.variables(num_v).type,dimid);
    else
        varid = netcdf.defVar(nc,name_v,hdr.variables(num_v).type,[]);
    end
    switch name_v
        case 'image'
            imgid = varid;
        case 'image-min'
            minid = varid;
        case 'image-max'
            maxid = varid;
    end
    for num_a = 1:natts
        netcdf.putAtt(nc,varid,hdr.variables(num_v).attributes{num_a},hdr.variables(num_v).values{num_a});
    end    
end

%% Write data
netcdf.endDef(nc);
netcdf.putVar(nc,imgid,vol);
netcdf.putVar(nc,minid,min(vol(:)));
netcdf.putVar(nc,maxid,max(vol(:)));
netcdf.close(nc);
