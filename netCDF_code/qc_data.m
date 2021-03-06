% SNOTEL Quality Control

% probably end up with too large a file, make single precision? Or make QC
% 'mask' to apply to avy events?

% get all .nc files in directory so can loop over snotels
fils = dir('*.nc');

    
for iFil = 1:length(fils)
% get name
fname = fils(iFil).name;
% hardcoded example

% SWE
SWE = ncread(fname,'SWE');
SWE_rev = SWE; % revised SWE

% Step 1: see how many NaN's (original)
snotel_QC(iFil).initNaN = nansum(isnan(SWE));

% Step N: can check for crazy values
% [nanmin(SWE) nanmax(SWE)]
% foo = sort(SWE,'ascend');
%

% Step 2: find negative SWE, set to missing
ind = find(SWE<0);
SWE_rev(ind) = NaN;

% Step 3: find delta SWE > 150 mm, set to missing
flag150 = 0; % flag if exceedences of 150 mm occcur
dSWE = diff(SWE);
dSWE = [0; dSWE];

ind = find(dSWE>150);
if any(ind)
    flag150 = 1;
end
snotel_QC(iFil).flag150 = flag150;

ind = find(dSWE>180); % Paradise had a few legit 150's, so bumping this up from 2017 paper.
SWE_rev(ind) = NaN;

% store revised values
snotel_QC(iFil).swe = SWE_rev;

%%%% Precipitation
ppt = ncread(fname,'Precipitation');
ppt_rev = ppt;

% Step 1: find negative precip, set to missing
ind = find(ppt<0);
ppt_rev(ind) = NaN;

% Step 2: find precip greater than 180 mm, set to missing
ind = find(ppt>180);
ppt_rev(ind) = NaN;

snotel_QC(iFil).ppt = ppt_rev;


% Temperature
% Replace temps if outside of reasonable parameters (-56C ? 50C)

tmax = ncread(fname,'Temp_Max');
tmin = ncread(fname,'Temp_Min');

ind = find(tmin<-69.3); % Peters Sink, UT record low
tmin(ind) = NaN;
ind = find(tmin>50); % Scorching...fire?
tmin(ind) = NaN;

ind = find(tmax<-69.3); % Peters Sink, UT record low
tmax(ind) = NaN;
ind = find(tmax>50); % Scorching...fire?
tmax(ind) = NaN;

% store revised values
snotel_QC(iFil).tmax = tmax;
snotel_QC(iFil).tmin = tmin;

% set up dates using matlab datenum
ncf = fname; % this will become fname when working in local dir
ncf = strsplit(ncf,{'.','_'});

foo = strsplit(ncf{3},'-');
stdate = datenum(str2double(foo{1}),str2double(foo{2}),str2double(foo{3}));

foo = strsplit(ncf{4},'-');
endate = datenum(str2double(foo{1}),str2double(foo{2}),str2double(foo{3}));

snotel_QC(iFil).dates = stdate:1:endate;

% for some applications, it can be helpful to output where you're at.
snotel_QC(iFil).swe = single(snotel_QC(iFil).swe);
snotel_QC(iFil).ppt = single(snotel_QC(iFil).ppt);
snotel_QC(iFil).tmax = single(snotel_QC(iFil).tmax);
snotel_QC(iFil).tmin = single(snotel_QC(iFil).tmin);
snotel_QC(iFil).dates = single(snotel_QC(iFil).dates);

% save lat/lon
lat = ncread(fname,'Latitude',[1],[1],[1]);
lon = ncread(fname,'Longitude',[1],[1],[1]);

% global vars
site_id = ncreadatt(fname,'/','site_id');
state = ncreadatt(fname,'/','State');
elevation = ncreadatt(fname,'/','Elevation');


snotel_QC(iFil).lat = lat;
snotel_QC(iFil).lon = lon;
snotel_QC(iFil).site_id = site_id;

test = fname;
new = 'new_';
fname1 = append(new,fname);

% Create a netCDF file.
ncid = netcdf.create(fname1,'NC_NOCLOBBER');


% Define an unlimited dimension.
long_dimID = netcdf.defDim(ncid,'longitude',...
		netcdf.getConstant('NC_UNLIMITED'));
long_varID = netcdf.defVar(ncid,'my_var','double',long_dimID);

lat_dimID = netcdf.defDim(ncid,'latitude',...
		netcdf.getConstant('NC_UNLIMITED'));
lat_varID = netcdf.defVar(ncid,'latitude','double',lat_dimID);

swe_dimID = netcdf.defDim(ncid,'swe',...
		netcdf.getConstant('NC_UNLIMITED'));
swe_varID = netcdf.defVar(ncid,'swe','double',swe_dimID);

tmax_dimID = netcdf.defDim(ncid,'tmax',...
		netcdf.getConstant('NC_UNLIMITED'));
tmax_varID = netcdf.defVar(ncid,'tmax','double',tmax_dimID);

tmin_dimID = netcdf.defDim(ncid,'tmin',...
		netcdf.getConstant('NC_UNLIMITED'));
tmin_varID = netcdf.defVar(ncid,'tmin','double',tmin_dimID);

ppt_dimID = netcdf.defDim(ncid,'ppt',...
		netcdf.getConstant('NC_UNLIMITED'));
ppt_varID = netcdf.defVar(ncid,'ppt','double',ppt_dimID);

netcdf.endDef(ncid);

% Write data to variable
netcdf.putVar(ncid,long_varID,snotel_QC(iFil).lat);
netcdf.putVar(ncid,lat_varID,snotel_QC(iFil).lat);
netcdf.putVar(ncid,swe_varID,snotel_QC(iFil).swe);
netcdf.putVar(ncid,tmax_varID,snotel_QC(iFil).tmax);
netcdf.putVar(ncid,tmin_varID,snotel_QC(iFil).tmin);
netcdf.putVar(ncid,ppt_varID,snotel_QC(iFil).ppt);


varid_site = netcdf.getConstant('GLOBAL');
netcdf.putAtt(ncid,varid_site,'site_id',site_id);

varid_state = netcdf.getConstant('GLOBAL');
netcdf.putAtt(ncid,varid,'state',varid_state);

varid_elevation = netcdf.getConstant('GLOBAL');
netcdf.putAtt(ncid,varid_elevation,'elevation',elevation);


netcdf.close(ncid);


end

save('snotel_QC.mat','snotel_QC','-v7.3');


%%

