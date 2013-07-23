function [hdr,vol] = mom_read_minc1_octave(file_name,opt)
% Read a MINC1 file in Octave
% To learn more about the MINC format :
% http://en.wikibooks.org/wiki/MINC
%
% SYNTAX:
% [HDR,VOL] = MOM_READ_MINC1_OCTAVE(FILE_NAME)
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
%    [hdr,vol] = mom_read_minc1_octave('foo.mnc');
%
% COMMENTS:
%   NOTE 1: the function uses the Octdf package from octave forge. It has been tested with Octave 1.1.5
%   NOTE 2: VOL is the raw numerical array stored in the MINC file, in the so-called
%      voxel space. In particular, no operation is made to re-order dimensions. 
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de
% gériatrie de Montréal, Département d'informatique et de recherche
% opérationnelle, Université de Montréal, 2012.
%
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, I/O, reader, minc, minc1, octave

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

%% Open file
nc = netcdf(file_name,'nowrite');

%% Read info on dimensions
dims = ncdim(nc);
ndims = length(dims);

%% Read info on variables
var = ncvar(nc);
nvars = length(var);

%% Read info on attributes
att = ncatt(nc);
ngatts = length(att);

%% Initialize the header
hdr.format    = 'minc1';
hdr.file_name = '';

%% Read global attributes
for num_g = 1:ngatts
    hdr.globals(num_g).name = ncname(att{num_g});
    hdr.globals(num_g).type = ncdatatype(att{num_g});
    hdr.globals(num_g).value = att{num_g}(:);
end

%% Read variables
for num_v = 1:nvars
    hdr.variables(num_v).name = ncname(var{num_v});
    hdr.variables(num_v).type = ncdatatype(var{num_v});    
    hdr.variables(num_v).size = size(var{num_v});
    dim_names = ncdim(var{num_v});
    if ~isempty(dim_names)
        hdr.variables(num_v).dim = cell(length(dim_names),1);
        for num_d = 1:length(dim_names)
            hdr.variables(num_v).dim{num_d} = ncname(dim_names{num_d});
        end
    else
        hdr.variables(num_v).dim = {};
    end
    attvar = ncatt(var{num_v});
    natts = length(attvar);
    hdr.variables(num_v).attributes = cell([natts 1]);
    hdr.variables(num_v).values     = cell([natts 1]);
    hdr.variables(num_v).type_att   = cell([natts 1]);
    for num_a = 1:natts        
        hdr.variables(num_v).attributes{num_a} = ncname(attvar{num_a});
        hdr.variables(num_v).values{num_a}     = attvar{num_a}(:);
        hdr.variables(num_v).type_att{num_a}   = ncdatatype(attvar{num_a});
    end
end

%% Read image-min / image-max
var_names = {hdr.variables(:).name};
ind_min = find(ismember(var_names,'image-min'));
ind_max = find(ismember(var_names,'image-max'));
hdr.data.image_min = var{ind_min}(:);
hdr.data.image_max = var{ind_max}(:);

%% Read volume
if nargout > 1
    vol = var{find(ismember(var_names,'image'))}(:);
    
    %% Apply intensity normalization
    if length(hdr.data.image_min)>1 
    
        %% This is slice-by-slice normalization
        
        %% Check the sanity of slice normalization
        if (length(hdr.data.image_min)~=size(vol,3))||(length(hdr.data.image_min)~=length(hdr.data.image_max))
            error('The length of image min/max are not consistent with the size of the volume');
        end
        
        %% Apply normalization on each slice
        for num_s = 1:size(vol,3)
            slice = vol(:,:,num_s,:);
            min_s = min(slice(:));
            max_s = max(slice(:));
            if (min_s ~= hdr.data.image_min(num_s))||(max_s ~= hdr.data.image_max(num_s))
                vol(:,:,num_s,:) = ((hdr.data.image_max(num_s)-hdr.data.image_min(num_s))/(max_s-min_s))*(slice-min_s) + hdr.data.image_min(num_s);
            end
        end
    else
        if (length(hdr.data.image_min)~=length(hdr.data.image_max))
            error('The length of image min/max are not consistent');
        end
        min_s = min(vol(:));
        max_s = max(vol(:));
        if (min_s ~= hdr.data.image_min)||(max_s ~= hdr.data.image_max)
            vol = ((hdr.data.image_max-hdr.data.image_min)/(max_s-min_s))*(vol-min_s) + hdr.data.image_min;
        end
    end
end

ncclose(nc);