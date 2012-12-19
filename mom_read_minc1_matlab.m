function [hdr,vol] = mom_read_minc1_matlab(file_name,opt)
% Read a MINC1 file in Matlab
% To learn more about the MINC format :
% http://en.wikibooks.org/wiki/MINC
%
% SYNTAX:
% [HDR,VOL] = MOM_READ_MINC1_MATLAB(FILE_NAME)
%
% INPUTS:
%    FILE_NAME (string) the name of a minc file
%
% OUTPUTS:
%    HDR (structure) the header of the MINC file
%    VOL (4D or 3D array of double) the dataset
%
% SEE ALSO:
%    MINC_WRITE
%
% EXAMPLE:
%    [hdr,vol] = mom_read_minc1_matlab('foo.mnc');
%
% COMMENTS:
%   NOTE 1: the function uses the NetCDF Matlab libraries.
%   NOTE 2: VOL is the raw numerical array stored in the MINC file, in the so-called
%      voxel world. In particular, no operation is made to re-order dimensions. 
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de
% gériatrie de Montréal, Département d'informatique et de recherche
% opérationnelle, Université de Montréal, 2012.
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

ncid     = netcdf.open(file_name,'NOWRITE');
[ndims,nvars,ngatts] = netcdf.inq(ncid);
hdr.type = 'minc1';
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